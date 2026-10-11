# Design Doc: Catálogo Offline Global e Sincronização Delta de Escaladas

- **Status**: Proposto / Em Planejamento
- **Autor**: Renato / Aresta Climb Core Team
- **Data**: Outubro de 2026
- **Versão**: 1.0
- **Repositórios Envolvidos**: `aresta_app` (Frontend Flutter) e `aresta_db` (Pipeline de Compilação & Serving)

---

## 1. Sumário Executivo

Este documento especifica a nova arquitetura para **busca textual global de escaladas 100% offline** e **resolução instantânea de QR Codes físicos em formato de identificador opaco** (`https://aresta.cc/<nanoid>`), sem sobrecarregar a memória RAM dos dispositivos móveis e mantendo a sincronização de dados extremamente leve sobre redes celulares precárias (3G/4G).

A solução adota uma **Arquitetura em Duas Camadas**:
1. **Camada de Roteamento e Busca Global (SQLite Pré-Compilado):** Um banco embarcado local ultra-leve (`catalogo.db`, ~250 KB comprimido) que mapeia todos os NanoIDs do país, setores e vias para seus respectivos picos. É consultado sob demanda diretamente do disco (0 ms no cold start, 0 MB na RAM de boot).
2. **Camada de Conteúdo Gráfico e Traçado (Protobuf Sob Demanda):** Os arquivos pesados (`compilado.binarypb` e mídias visuais) continuam sendo carregados na memória apenas quando o usuário navega na tela daquele pico específico.
3. **Sincronização Delta na Borda (Cloudflare Edge Worker):** Atualizações rotineiras transferem apenas deltas lógicos de ~1.5 KB consolidados via Edge Worker, com o snapshot completo (`catalogo.db.gz`) servindo como garantia de integridade incondicional.

---

## 2. Contexto e Motivação

### 2.1 O Problema da Abordagem Ingênua (Carregar Tudo no Boot)
Atualmente, as vias e setores residem exclusivamente dentro de cada arquivo `compilado.binarypb`. Se o aplicativo precisasse carregar todos os croquis compilados na inicialização para popular a busca e resolver QR Codes:
- **Sobrecarga de Heap no Dart:** Um arquivo Protobuf descompactado em objetos Dart 64-bit expande de 5x a 10x. Para 500 picos, o consumo de RAM pularia para **150 MB a 300 MB**, forçando o Android Low Memory Killer (LMK) a matar o app em segundo plano.
- **Congelamento da Splash Screen (Cold Start):** A desserialização síncrona na UI thread travaria o boot por **2 a 6 segundos**, provocando advertências de ANR (*Application Not Responding*).

### 2.2 O Desafio dos QR Codes com NanoID Opaco
A nova geração de placas físicas e links compartilháveis adota URLs encurtadas opacas:
`https://aresta.cc/xkwjf8dk3ljkL3` (NanoID Base62 de 14 caracteres).
Como a URL não contém o identificador do pico (ex: `pedra_grande`), o aplicativo precisa de uma **Tabela de Resolução Invertida (Reverse Lookup)** local para saber instantaneamente qual `compilado.binarypb` abrir quando o usuário estiver offline na base da falésia.

---

## 3. Arquitetura Proposta

### 3.1 Separação de Responsabilidades em Duas Camadas

```
┌────────────────────────────────────────────────────────────────────────┐
│                        ARQUITETURA EM DUAS CAMADAS                     │
└────────────────────────────────────────────────────────────────────────┘

  1. CAMADA DE ROTEAMENTO E BUSCA (GLOBAL)
     Arquivo: 'catalogo.db' (SQLite local, ~250 KB sincronizado)
     Responsabilidade:
     • Resolver QR Codes instantaneamente (NanoID -> PicoId, SetorId)
     • Alimentar a Busca Global por qualquer via, grau e setor (FTS5)
     • 100% offline, 0 ms de overhead no boot, 0 MB na RAM.

                                │
                   Escaneou QR Code / Clicou na Busca
                   NanoID "xkwjf8dk3ljkL3" ──▶ Pico: "pedra_grande"
                                │
                                ▼

  2. CAMADA DE CONTEÚDO GRÁFICO (SOB DEMANDA)
     Arquivos: '<picoId>/compilado.binarypb' e Imagens
     Responsabilidade:
     • Traçados vetoriais, nós de desenho, linhas, polígonos, fotos.
     • Baixado sob demanda (online) OU sincronizado pelo usuário (offline).
     • Carregado na memória RAM APENAS quando a tela daquele pico específico abre!
```

### 3.2 Otimização Crucial: Simbiose entre `Indice` (RAM) e `Catalogo` (Disco)
O aplicativo já carrega o arquivo `indice.binarypb` (~11 KB) na memória RAM na abertura do app. O índice contém a lista de todos os picos cadastrados (`id`, `nome`, `caminhoRelativo`, etc.).

Portanto, **o banco SQLite não precisa duplicar nomes de picos, localidades ou caminhos de download**:
- O SQLite guarda apenas o identificador do croqui pai (`croqui_uid`).
- Quando uma via ou setor é encontrado, o app faz um lookup $O(1)$ na memória RAM para obter o nome do morro e formatar o card da interface.
- Economia direta de mais de 30 bytes por linha no banco de dados.

---

## 4. Especificação Técnica do SQLite (`catalogo_aresta`)

### 4.1 Schema da Tabela Principal

```sql
CREATE TABLE catalogo_aresta (
  uid TEXT PRIMARY KEY,               -- NanoID Base62 de 14 caracteres
  croqui_uid TEXT NOT NULL,           -- UID do croqui pai (conecta ao indice.binarypb)
  tipo_id INTEGER NOT NULL,          -- 1: grupo, 2: setor, 3: escalada, 4: botao
  
  -- Hierarquia Textual (para busca instantânea sem JOINs)
  nome_grupo TEXT,                   -- Preenchido se pertencer a um grupo
  nome_setor TEXT,                   -- Preenchido para setores e vias
  nome_escalada TEXT,                -- Preenchido APENAS para escaladas
  
  -- Metadados de Escalada
  grau TEXT,                         -- Ex: '7a', 'V5', 'E2'
  tipo_escalada INTEGER              -- 1: esportiva, 2: boulder, 3: movel, 4: multienfiada, 5: highline
);

-- Índices de Alta Performance
CREATE INDEX idx_catalogo_croqui ON catalogo_aresta(croqui_uid);
CREATE INDEX idx_catalogo_tipo ON catalogo_aresta(tipo_id);
```

### 4.2 Métricas de Armazenamento
- **Tamanho por registro de via:** ~45 bytes médios (SQLite comprime inteiros e armazena NULLs em 1 byte no cabeçalho).
- **Tamanho por botão:** ~34 bytes (apenas UIDs e tipo).
- **Catálogo de 20.000 itens (escala regional/nacional):**
  - No disco cru: **~900 KB a 1.1 MB**.
  - Comprimido com Gzip (`catalogo.db.gz` na CDN): **~220 KB a 280 KB**.

---

## 5. Fluxos de Operação

### 5.1 Resolução de QR Codes e Universal Links (`aresta.cc/<nanoid>`)

```
                        [ ESCANEOU QR CODE ]
                  https://aresta.cc/xkwjf8dk3ljkL3
                                 │
                                 ▼
                       UID: "xkwjf8dk3ljkL3"
                                 │
          ┌──────────────────────┴──────────────────────┐
          │                                             │
1. Checa na RAM (Indice)                      2. Se não estiver no Indice
Existe croqui com esse UID?                   Consulta o SQLite (catalogo.db):
          │                                   SELECT croqui_uid FROM catalogo_aresta
    SIM ──┴── NÃO                             WHERE uid = 'xkwjf8dk3ljkL3'
     │         │                                        │
     │         └────────────────────────────────────────┘
     ▼                                                  ▼
[ É um Croqui! ]                                  Acha o 'croqui_uid'
Abre direto a tela                              (que está no Indice na RAM)
do pico em 0.001 ms!                                     │
                                                        ▼
                                         [ Carrega compilado.binarypb ]
                                         do pico correspondente sob demanda.
                                         Localiza o objeto com o UID no croqui:
                                         • É escalada? Foca na via.
                                         • É setor? Foca no setor.
                                         • É grupo? Foca no grupo.
                                         • É botão? Aciona o botão!
```

### 5.2 Busca Global de Escaladas
A consulta SQL roda diretamente sobre os campos indexados, sem necessidade de alocar árvores fuzzy pesadas na memória:
```sql
SELECT uid, croqui_uid, tipo_id, nome_grupo, nome_setor, nome_escalada, grau, tipo_escalada
FROM catalogo_aresta
WHERE nome_escalada LIKE '%fissura%' OR nome_setor LIKE '%fissura%'
LIMIT 30;
```
A UI recebe as linhas e mescla com `indice.binarypb` em memória para exibir:
`Fissura do Totem • 7a • Setor Central • Pedra Grande (MG)`

---

## 6. Pipeline de Compilação & CI/CD (`deploy_generated.py`)

No repositório `aresta_db`, o script `deploy_generated.py` passa a incorporar a geração do SQLite logo após compilar os `.binarypb` e o `indice.binarypb`.

### 6.1 Geração Completa vs. Atualização Parcial
- **Deploy Total:** Limpa e recria o `catalogo.db` em uma única transação SQL. Leva **~50 a 100 ms** para 20.000 vias no Python.
- **Deploy Seletivo (`target_paths`):** Se o `catalogo.db` já existe, apenas apaga e reinsere os registros dos croquis modificados:
  ```sql
  DELETE FROM catalogo_aresta WHERE croqui_uid = :croqui_uid;
  INSERT INTO catalogo_aresta VALUES (...);
  ```
  Tempo de execução: **menos de 5 ms**.

### 6.2 Pre-bundling no App
- No momento do build do app (`sync_preload.dart`), o `catalogo.db` inicial é copiado para `frontend/assets/preload/catalogo.db`.
- O aplicativo já é instalado contendo 100% dos QR codes e vias pesquisáveis antes de qualquer conexão com a internet.

---

## 7. Sincronização Delta Remota com Cloudflare Edge Worker

Para minimizar o tráfego móvel e viabilizar atualizações instantâneas de 1.5 KB na montanha:

### 7.1 Versionamento Determinístico
O `indice.binarypb` passa a declarar a versão oficial do catálogo:
```protobuf
message Indice {
  // ...
  int32 versao_catalogo = 12;
  int32 total_itens_catalogo = 13;
}
```

### 7.2 Cálculo Automático de Deltas no GitHub Actions
O CI/CD não rastreia commits do Git; ele compara o banco gerado contra o banco anterior via SQL puro:
```sql
ATTACH 'catalogo_antigo.db' AS antigo;

-- Inserções e Modificações
SELECT * FROM main.catalogo_aresta EXCEPT SELECT * FROM antigo.catalogo_aresta;

-- Deleções (Tombstones)
SELECT uid FROM antigo.catalogo_aresta WHERE uid NOT IN (SELECT uid FROM main.catalogo_aresta);
```
As alterações geram um lote no Cloudflare D1 (SQLite distribuído na borda).

### 7.3 Comportamento do Cloudflare Edge Worker
1. O app checa `versao_local` vs `versao_remota` do `indice.binarypb`.
2. Se houver defasagem, faz a requisição:
   `GET https://api.aresta.cc/sync?desde=118&ate=120`
3. O Worker consolida as mudanças (*squash* de histórico), gerando um JSON único de ~1.5 KB.
4. **Cache Imutável:** Como a rota possui intervalo fixo, a resposta é armazenada na CDN com `Cache-Control: public, max-age=31536000, immutable`.
5. **Fallback de Segurança:** Se a diferença for superior a 15 versões ou o payload passar de 200 KB, o Worker redireciona o app para baixar o snapshot completo `catalogo.db.gz`.

### 7.4 Verificação de Integridade
Devido à mecânica de alocação de páginas do SQLite, bancos com os mesmos dados podem ter SHA256 binário diferente. O app valida a integridade por:
1. `PRAGMA integrity_check;` (validação física de B-Trees).
2. Validação da contagem de linhas contra `total_itens_catalogo`.

---

## 8. Comparativo de Métricas

| Métrica | Abordagem Anterior (Carregar Protobufs) | Abordagem Proposta (SQLite + Delta Edge) | Impacto |
| :--- | :--- | :--- | :--- |
| **Consumo de RAM no Boot** | 150 MB a 300 MB | **0 MB** (paginado do disco sob demanda) | **-100%** |
| **Tempo de Cold Start** | 2 a 6 segundos de travamento | **0 ms** de impacto no boot | **Instantâneo** |
| **Resolução de QR Code** | Impossível offline sem carregar tudo | **< 1 ms** em qualquer cenário | **Viabilizado** |
| **Tamanho por Update** | ~250 KB (ou dezenas de MBs de croquis) | **~1.5 KB a 3 KB** (delta compactado) | **-99% de tráfego** |
| **Resiliência a Falhas** | Risco de crash por Out of Memory | Total (snapshot de 250 KB como garantia) | **Alta Robustez** |

---

## 9. Plano de Implementação em Fases

- **Fase 1: Preparação de Modelo e Pipeline (aresta_db)**
  - Adicionar NanoID Base62 de 14 caracteres no `croqui.proto` e gerador de IDs no editor.
  - Implementar geração de `catalogo.db` e `catalogo.db.gz` no `deploy_generated.py`.
- **Fase 2: Motor de Busca e Roteamento Local (aresta_app)**
  - Incluir dependência `sqlite3` / `sqflite` no Flutter.
  - Implementar extração de preload do `catalogo.db` no `ExtratorAssetsPreload`.
  - Integrar resolução de rotas na classe `AnalisadorRotasDeepLink` e refatorar `BuscaGlobal`.
- **Fase 3: Cloudflare Edge Worker & Pipeline de Deploy**
  - Implementar script de cálculo de delta SQL `EXCEPT` no GitHub Actions do `aresta_db`.
  - Publicar Worker com D1 na Cloudflare para servir `/sync?desde=X&ate=Y`.
  - Implementar rotina de aplicação atômica de deltas no `SyncService` do app.
