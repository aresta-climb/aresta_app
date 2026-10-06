# Arquitetura Unificada: Identificadores Estáveis, Caderneta Pessoal e Comunidade Aberta

**Ecossistema Aresta Climb**  
*Consolidação Técnica Definitiva dos Documentos de Identificadores Estáveis (v2.0) e Arquitetura de Contas, Cadenas e Comunidade*  
**Data:** Outubro de 2026 • **Versão:** 3.0 (Unificada & Aprovada) • **Status:** Arquitetura Definitiva

---

## 1. Resumo Executivo e Princípios Basilares

Esta especificação consolida a fundação arquitetural definitiva do ecossistema **Aresta Climb**, harmonizando integralmente as decisões de **Identificadores Estáveis Universais (NanoID 14c)** com a **Arquitetura de Contas, Caderneta Pessoal e Sabedoria Comunitária Aberta**.

O projeto resolve simultaneamente a sustentabilidade perpétua no modelo de custos e a perenidade dos dados nas montanhas a partir de quatro pilares inegociáveis:

1. **Adoção Universal do NanoID 14c Base62:** Eliminação das tabelas intermediárias de mapeamento YAML e supressão de identificadores inteiros em múltiplos níveis. Toda entidade recebe um identificador imutável, único e universal.
2. **Sincronização Offline-First Full PowerSync:** Eliminação de qualquer gerenciamento manual ou avulso de SQLite no aplicativo móvel. O SDK do PowerSync gerencia de forma transparente a replicação bidirecional com o Supabase e a persistência reativa local.
3. **Harmonia entre Caderneta Pessoal e Comunidade Aberta:** Rollback das redes privadas de amigos (feeds, grafos relacionais N x N). Foco estrito em duas frentes: a **Caderneta Pessoal Esportiva** (privada com backup em nuvem) e a **Sabedoria Comunitária Coletiva** (alertas de segurança, comentários de betas e consenso democrático de graduação, preservados sob licença aberta ODbL no Git).
4. **Sustentabilidade Perpétua no Free Tier do Supabase:** O banco de dados PostgreSQL atua como backup pessoal estrito e como buffer transitório de ingestão (esvaziado de hora em hora pelo *Aresta Bot*), mantendo a ocupação abaixo de 45 MB (< 9% da cota gratuita) mesmo com 500.000 ascensões registradas.

```
┌────────────────────────────────────────────────────────────────────────┐
│                   ECOSSISTEMA ARESTA CLIMB UNIFICADO                  │
└────────────────────────────────────────────────────────────────────────┘
          │                                              │
          ▼                                              ▼
┌───────────────────────────────────┐    ┌───────────────────────────────────┐
│     CAMADA ESTÁTICA / OFICIAL     │    │     CAMADA DINÂMICA / ATLETA      │
│  - Vias, Setores, Croquis e Fotos │    │  - Caderneta Pessoal de Cadenas   │
│  - Traçados Vetoriais             │    │  - Notas Privadas (Crux/Costuras) │
│  - Consenso Comunitário Consolid. │    │  - Fila de Ingestão de Interações │
├───────────────────────────────────┤    ├───────────────────────────────────┤
│ Protobuf (.binarypb) via CDN      │    │ PowerSync SDK (Offline-First)     │
│ Custo: R$ 0,00                    │    │ + Supabase Postgres com RLS       │
└───────────────────────────────────┘    └───────────────────────────────────┘
          │                                              │
          │                   FUSÃO NA UI                │
          └───────────────────────┬──────────────────────┘
                                  ▼
                ┌──────────────────────────────────┐
                │   Chave Unívoca: escalada_uid    │
                │        (NanoID 14c)              │
                │      Ex: x8siJek3FiG3aB          │
                └──────────────────────────────────┘
```

---

## 2. Segregação de Verdade: As 4 Camadas de Dados

A arquitetura do Aresta divide os dados conforme a sua frequência de atualização, soberania jurídica e necessidade de funcionamento offline nas falésias:

| Camada / Destino | Responsabilidade & Conteúdo | Armazenamento Físico | Custo Operacional |
| :--- | :--- | :--- | :--- |
| **1. Protobuf (`.binarypb`)**<br>*CDN Cloudflare / GitHub* | Grau Oficial do Conquistador, traçados vetoriais, fotos WebP, coordenadas e consenso comunitário compilado em lote. | Armazenamento local do dispositivo (`/downloads`) via CDN estática. | **R$ 0,00**<br>(Tráfego e CDN gratuitos) |
| **2. PowerSync Client**<br>*PowerSync SDK Reativo* | Caderneta pessoal do atleta, notas técnicas privadas, cache reativo instantâneo e fila local de mutações offline. | Persistência local gerenciada 100% pelo PowerSync SDK. | **R$ 0,00**<br>(Execução local no cliente) |
| **3. Supabase PostgreSQL**<br>*Backend + RLS + Buffer* | Backup criptografado de cadenas pessoais (`auth.uid() = user_id`) e fila temporária de interações (`fila_interacoes`), esvaziada a cada hora. | Tabelas enxutas com tipos compactos (< 45 MB total). | **R$ 0,00**<br>(Free Tier perpétuo < 9%) |
| **4. Repositório Git (`aresta_db`)**<br>*Diretório `interacoes/`* | Acervo histórico, transparente e auditável de avaliações de grau e comentários, protegido por `CODEOWNERS` (apenas Aresta Bot e mantenedores). | Repositório Git público em YAML estruturado (licença ODbL). | **R$ 0,00**<br>(Open Data permanente) |

---

## 3. Espaço de Identificadores: NanoID 14c Universal

### 3.1. A Racionalidade Técnica e Matemática
Todas as entidades do ecossistema (`Croqui`, `Grupo`, `Setor`, `Escalada`, `PontoDeInteresse` e registros de `Cadena`) recebem nativamente um identificador **NanoID com 14 caracteres contínuos em Base62** (`[0-9a-zA-Z]`, ex: `x8siJek3FiG3aB`).

A tentativa preliminar de utilizar mapeamentos intermediários de inteiros de 4 bytes e arquivos YAML centrais (`ids_entidades.yaml`, `ids_pontos.yaml`) foi oficialmente revogada pelos seguintes motivos:
* **Peso irrisório no acervo:** Todos os 42 croquis do país (637 setores, 4.318 vias, 4.811 POIs) somam apenas 1,16 MB de dados brutos Protobuf (475 KB comprimidos), enquanto as fotos WebP representam 353 MB (99,7% do volume). A diferença entre armazenar 4 bytes ou 14 caracteres é matematicamente desprezível em escala nacional.
* **Eliminação de conflitos de merge no Git:** Dispensa algoritmos de *split* de visões e parsers para marcadores `<<<<<<< HEAD` durante contribuições simultâneas de guias de escalada.
* **Resistência absoluta a colisões:** O espaço amostral de 14 caracteres Base62 é de:
  $$62^{14} \approx 1{,}24 \times 10^{25} \text{ combinações}$$
  Mesmo considerando um acervo global acumulado de 1.000.000 de vias em forks descentralizados, a probabilidade de colisão é de:
  $$P \approx \frac{(10^6)^2}{2 \times 62^{14}} \approx 4 \times 10^{-14} \quad (\text{1 chance em 25 trilhões})$$

### 3.2. Formato e Geração Criptográfica
O NanoID 14c não utiliza hífens ou sublinhados, sendo restrito estritamente ao alfabeto Base62:
```python
# scripts/gerenciar_uids_lib.py
import secrets

ALFABETO_BASE62 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

def gerar_uid() -> str:
    """Gera um NanoID puro de 14 caracteres Base62 criptograficamente seguro."""
    return "".join(secrets.choice(ALFABETO_BASE62) for _ in range(14))

def validar_uid(uid: str) -> bool:
    """Valida se o identificador atende rigorosamente ao padrão NanoID 14c."""
    return isinstance(uid, str) and len(uid) == 14 and all(c in ALFABETO_BASE62 for c in uid)
```

---

## 4. Física e Engenharia das Placas nas Falésias (Aço Inox & QR Code)

As placas físicas instaladas nas bases das vias de escalada devem resistir por mais de três décadas a intempéries extremas, raios ultravioleta, água, poeira de rocha e impregnação de carbonato de magnésio (pó de escalada).

```
┌─────────────────────────────────────────────────────────────┐
│  PLACA DE AÇO INOXIDÁVEL AISI 316L (50mm x 30mm)            │
│                                                             │
│   ▄▄▄▄▄▄▄  ▄ ▄▄   ▄▄▄▄▄▄▄   Pedra Rachada                   │
│   █ ▄▄▄ █  ▄▀▄ ▄  █ ▄▄▄ █   Setor Deslize                   │
│   █ ███ █ ▀█▄ ▄▀  █ ███ █   Via Deslize (7a / V8)           │
│   █▄▄▄▄▄█ █ ▄ █▀  █▄▄▄▄▄█                                   │
│   ▄▄▄▄  ▄ ▄▄▄▀▄ ▄   ▄  ▄▄   https://aresta.cc/x8siJek3FiG3aB │
│   █ ▄▄▄▄▄ ▀▀▀█ ▄▀ ▄ ▄▀ ▄█                                   │
│   █▄▄▄▄▄█ █ ▀█ ▄▀ █▄▄█▄██   QR Code V3 (29x29) Nível H (30%)│
└─────────────────────────────────────────────────────────────┘
```

### 4.1. Especificação de Engenharia do Link Físico
* **Domínio Encurtador Canônico:** `https://aresta.cc/` (18 caracteres).
* **URL Canônica Completa:** `https://aresta.cc/<escalada_uid>` (exatamente 32 caracteres, ex: `https://aresta.cc/x8siJek3FiG3aB`).
* **Versão do QR Code:** **Versão 3** (29 × 29 módulos). Garante módulos amplos e legíveis mesmo quando gravados por laser de fibra óptica em chapas escovadas de 50 mm × 30 mm.
* **Nível de Correção de Erros:** **Nível H (High — 30%)**.
  * *Racionalidade:* Em montanhas, placas sofrem atrito de mosquetões, fezes de pássaros, deposição de magnésio nas reentrâncias da gravação e oxidação salina. O Nível H permite que até 30% da área do código seja destruída sem perda de leitura óptica por celulares.
* **Capacidade de Dados:** A Versão 3 com Nível H comporta até 35 caracteres binários de 8 bits. A URL canônica de 32 caracteres consome 32 bytes, garantindo folga de 3 bytes.
* **Substrato Físico:** Aço Inoxidável **AISI 316L** (grau marítimo, alta resistência à corrosão por cloretos e acidez de rochas calcárias e graníticas).

---

## 5. Desacoplamento Relacional e Regras de Nomenclatura

Em cumprimento estrito ao **Princípio I ("Tudo em Português")** e ao **Princípio VI ("Simplicidade e Anti-Abstração")**:

1. **Eliminação de Cadeias de Nomes nos Mapas:**
   * Removem-se as referências textuais legadas (`setor: "Gruta"`, `escalada: "Sombra Fresca"`).
   * Mapas e croquis na pasta `database/` referenciam diretamente o `alvo_uid` e a lista `pontos_uids` (ambos NanoID 14c).
   * Renomear uma via torna-se uma operação atômica de alteração de 1 linha no atributo `nome` da via, sem varredura em mapas ou nos comandos do editor.
2. **Substituição de `label` por `rotulo`:**
   * O atributo visual de identificação em `PontoDeInteresse` é padronizado como `rotulo`.
   * No arquivo Protobuf, o campo anterior `label` recebe `[deprecated = true]` e o compilador popula ambos os campos em tempo de build para assegurar retrocompatibilidade com clientes legados.

---

## 6. Arquitetura Full PowerSync & Modelagem de Dados

A persistência reativa local do aplicativo no dispositivo é implementada **exclusivamente via PowerSync SDK**. 

> **Diretriz Arquitetural:** O aplicativo móvel não instancia, não conecta e não gerencia bancos SQLite manuais (`sqflite` ou conexões avulsas). A base de dados SQLite subjacente ao dispositivo é gerenciada pelo motor interno em C do PowerSync SDK, que abstrai criptografia, replicação de stream WAL e consistência eventual com o Supabase.

```
┌────────────────────────────────────────────────────────┐
│           APLICATIVO FLUTTER (aresta_app)              │
│                                                        │
│   db.watch("SELECT * FROM cadenas WHERE...")          │
│   db.execute("INSERT INTO cadenas (...) VALUES...")    │
└──────────────────────────┬─────────────────────────────┘
                           │ (API Reativa de Alto Nível)
                           ▼
┌────────────────────────────────────────────────────────┐
│                    PowerSync SDK                       │
│  - Replicação de Stream e Sincronização em Segundo Plano│
│  - Resolução Automática de Conflitos                   │
│  - Fila de Mutação Transacional para Falésias Offline  │
│  - Motor SQLite C Interno (Totalmente Abstraído)       │
└──────────────────────────┬─────────────────────────────┘
                           │ (Sync Seguro via HTTPS / SHA-256)
                           ▼
┌────────────────────────────────────────────────────────┐
│            SUPABASE (PostgreSQL + RLS)                 │
│  - Autenticação e Row Level Security (RLS)             │
│  - Tabela cadenas (Backup Pessoal do Atleta)          │
│  - Tabela fila_interacoes (Buffer Horário do Bot)      │
└────────────────────────────────────────────────────────┘
```

### 6.1. Regras de Sincronização do PowerSync (`sync_rules.yaml`)
A sincronização do usuário rejeita redes sociais e foca apenas no titular autenticado:

```yaml
bucket_definitions:
  bucket_usuario:
    parameters:
      - select request.user_id() as usuario_id
    data:
      - select * from cadenas where user_id = usuario_id
```
Isso elimina muito do processamento de replicação lógica (WAL) e reduz o tráfego do Supabase a valores próximos de zero.

### 6.2. Esquema Físico DDL no Supabase (PostgreSQL)
Em conformidade com a disciplina estrita de bytes, cada coluna e índice foi pensado para manter o consumo de armazenamento mínimo e suportar até 500.000 ascensões dentro do Free Tier:

```sql
-- ============================================================================
-- TABELA: cadenas (Backup Seguro e Privado da Caderneta do Escalador)
-- ============================================================================
CREATE TABLE public.cadenas (
    id VARCHAR(14) PRIMARY KEY,                   -- NanoID 14c gerado no cliente
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    croqui_uid VARCHAR(14) NOT NULL,              -- NanoID 14c do Croqui
    escalada_uid VARCHAR(14) NOT NULL,            -- NanoID 14c da Via
    data_ascensao DATE NOT NULL,                  -- Data da realização esportiva
    tipo_ascensao SMALLINT NOT NULL,              -- 1: À Vista, 2: Flash, 3: Trabalhado, 4: Tentativa
    tipo_escalada SMALLINT NOT NULL,              -- 1: Guiado, 2: Top Rope, 3: Boulder, 4: Solo
    tentativas SMALLINT DEFAULT 1,                -- Número de pegas / tentativas
    grau_sugerido SMALLINT,                       -- Sugestão de grau (Enum Protobuf, 2 bytes)
    notas_privadas VARCHAR(200)                   -- Notas do atleta (crux, métodos, costuras)
);

-- Habilitação obrigatória de RLS
ALTER TABLE public.cadenas ENABLE ROW LEVEL SECURITY;

-- Política RLS: O atleta tem acesso exclusivo às suas próprias cadenas
CREATE POLICY "cadenas_proprio_usuario" ON public.cadenas
    FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Índices de consulta otimizados
CREATE INDEX idx_cadenas_usuario ON public.cadenas(user_id);
CREATE INDEX idx_cadenas_escalada ON public.cadenas(escalada_uid);

-- ============================================================================
-- TABELA: fila_interacoes (Buffer Transitório Coletivo - Esvaziado de Hora em Hora)
-- ============================================================================
CREATE TABLE public.fila_interacoes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    autor_id_publico VARCHAR(8) NOT NULL,          -- Hash Base36 (8 chars)
    autor_nome_publico TEXT NOT NULL,              -- Nickname público ou "Anônimo"
    croqui_uid VARCHAR(14) NOT NULL,               -- NanoID 14c do Croqui
    escalada_uid VARCHAR(14) NOT NULL,             -- NanoID 14c da Via
    tipo TEXT NOT NULL,                            -- 'VOTO_GRAU' | 'COMENTARIO'
    grau_sugerido SMALLINT,                        -- Código numérico do grau sugerido
    texto_comentario VARCHAR(1000),                -- Beta, métodos ou aviso de segurança
    status TEXT NOT NULL DEFAULT 'PENDENTE',       -- 'PENDENTE' | 'PROCESSADO'
    criado_em TIMESTAMPTZ DEFAULT now()
);

-- Habilitação obrigatória de RLS
ALTER TABLE public.fila_interacoes ENABLE ROW LEVEL SECURITY;

-- Políticas RLS: Leitura livre (transparência) e inserção restrita ao usuário logado
CREATE POLICY "fila_interacoes_leitura" ON public.fila_interacoes
    FOR SELECT
    USING (true);

CREATE POLICY "fila_interacoes_insercao" ON public.fila_interacoes
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE INDEX idx_fila_pendentes ON public.fila_interacoes(status) WHERE status = 'PENDENTE';
```

---

## 7. Experiência de Consumo e Contribuição (UX/UI)

### 7.1. Tela da Via: Coexistência do Conquistador com a Comunidade
A interface do `aresta_app` apresenta o grau oficial do conquistador em harmonia com a percepção coletiva da comunidade:

```
┌─────────────────────────────────────────────────────────────┐
│ Via Deslize  •  Setor Deslize  •  28m  •  11 costuras       │
├──────────────────────────────┬──────────────────────────────┤
│ 🍅 GRAU OFICIAL (CONQUISTADOR│ 🍿 CONSENSO DA COMUNIDADE    │
│    7a                        │    7b (nível sugerido)        │
│    Guia Oficial / Protobuf   │78% sugerem +1 (gráfico de pizza)│
├──────────────────────────────┴──────────────────────────────┤
│ ✓ Você encadenou esta via em 14/09 (Flash)   ★ No seu Perfil │
├─────────────────────────────────────────────────────────────┤
│ 💬 Notas da Comunidade & Alertas de Segurança (2)           │
│                                                             │
│ Mariana Silva • há 2 min [ FLASH ★ ]                        │
│ "Difícil de ler à vista; chapeleta 3 está com folga."       │
│                                                             │
│ Carlos "Lagartixa" • há 3 dias [ TRABALHADO ]               │
│ "Costura 4 fica tranquila se clipar da orelha à esquerda."  │
└─────────────────────────────────────────────────────────────┘
```

### 7.2. Modal de Registro de Cadena: Fluxo Unificado de Baixa Fricção
Para eliminar o abandono de formulários comunitários (onde até 80% dos usuários anotam a cadena mas ignoram a avaliação da via), o formulário consolida os dados pessoais e coletivos em uma tela única:

```
┌─────────────────────────────────────────────────────────────┐
│ 🧗 Registrar Ascensão • Via Deslize (Oficial: 7a)           │
├─────────────────────────────────────────────────────────────┤
│ 🔒 SEUS DADOS PESSOAIS (Salvo no PowerSync • Só você vê)    │
│ Estilo: [ À Vista ] [ Flash ★ ] [ Trabalhado ] [ Tentativa ]│
│ Data: 14/10/2026   •   Tentativas: [ 1 ]                    │
│ Notas: "Crux de pé direito alto no reglete, costura 3 longa"│
├─────────────────────────────────────────────────────────────┤
│ 🌍 CONTRIBUIÇÃO PÚBLICA (Consolidada no guia para a falésia)│
│ Avaliação do grau técnico da via (considerando trabalhada): │
│ [ -2 níveis ] [ -1 nível ] [ Grau Justo (0) ] [ +1 nível ★ ]│
│                              (Pré-selecionado)              │
│ Comentário (opcional): "Chapeleta 3 bamba, levar chave 13." │
├─────────────────────────────────────────────────────────────┤
│       [ ✓ Salvar Cadena Pessoal & Contribuir com Pico ]     │
└─────────────────────────────────────────────────────────────┘
```
* **Skin in the Game:** Votos de graduação só podem ser submetidos mediante registro real de ascensão/tentativa.
* **Baixa Fricção:** Como o botão "Grau Justo (0)" vem pré-marcado por padrão, os escaladores que salvam a cadeia alimentam a estatística democrática sem esforço adicional.

---

## 8. Contratos Git no `aresta_db` e Pipeline CI/CD Autônomo

### 8.1. Estrutura Canônica: `interacoes/{croqui_slug}.yaml`
Os arquivos de interação histórica no repositório `aresta_db` são indexados diretamente pelo `escalada_uid` (NanoID 14c) da via:

```yaml
# aresta_db/interacoes/br_mg_sabara_pedra_rachada.yaml
croqui_slug: br_mg_sabara_pedra_rachada
croqui_uid: "pQ9mRt2Kx1Vw8L"
escaladas:
  x8siJek3FiG3aB: # escalada_uid (NanoID 14c)
    consenso_grau:
      grau_consenso: "7b"
      grau_oficial_base: "7a"
      total_votos: 28
      distribuicao_deltas:
        "-1": 2
        "0": 4
        "+1": 22
    comentarios:
      - id: "m8Kq2L1x"
        autor_id_publico: "k7x9m2p1" # Base36 (8 chars)
        autor_nome: "Mariana Silva"
        data: "2026-10-06T11:20:00Z"
        estilo_cadena: "FLASH"
        texto: "Difícil de ler à vista; chapeleta 3 está com folga."
```

### 8.2. Ciclo de Execução Horária do Aresta Bot
O robô de automação roda a cada 60 minutos como cron job seguro:
1. **Consulta Segura:** O bot consome a tabela `fila_interacoes` com credencial administrativa (`service_role`).
2. **Consolidação dos YAMLs:** Agrupa votos e comentários por `croqui_slug` e `escalada_uid`, recalculando as medianas e modas estatísticas de grau.
3. **Commit & Push Atômico no Git:** Grava alterações diretamente na branch `main` do `aresta_db`. Se ocorrer qualquer instabilidade de conexão ou conflito no Git, o bot aborta o processo e preserva intactas as linhas no Supabase (risco zero de perda de dados).
4. **Purga do Buffer no Supabase:** Com o commit confirmado no GitHub, executa:
   ```sql
   DELETE FROM public.fila_interacoes WHERE id = ANY(ids_processados);
   ```
   Isso restabelece a tabela para praticamente 0 MB de ocupação.
5. **Geração do Binário Protobuf:** O push no Git dispara a GitHub Action com `deploy_generated.py`, que funde a pasta `database/` com `interacoes/` gerando o novo `compilado.binarypb`.

---

## 9. Privacidade por Design, LGPD e Exclusão sem Rebase

1. **Anonimização Pública por Design:**
   * Nenhum dado de cadastro pessoal (e-mail, telefone, CPF ou UUID interno do Supabase) é exportado para os arquivos YAML públicos.
   * Autores de comentários são identificados estritamente pelo `autor_id_publico` (hash determinístico de 8 caracteres em Base36) e pelo apelido esportivo informado.
2. **Consentimento Explícito para Acervo Aberto:**
   * Nos termos de uso do aplicativo, ao submeter sugestões de graduação e alertas de rocha, o titular consente expressamente que esses dados integram o patrimônio coletivo do montanhismo sob licença internacional ODbL (Art. 7º, I e § 4º da Lei Geral de Proteção de Dados - LGPD).
3. **Exclusão de Conta sem Rebase:**
   * Caso o usuário decida encerrar sua conta, os dados pessoais e a caderneta de cadenas no Supabase são imediatamente destruídos (`ON DELETE CASCADE`).
   * No repositório público Git, o *Aresta Bot* realiza um commit no `HEAD` alterando o nome de exibição do autor nos comentários históricos para `"Anônimo"`.
   * Preserva-se integralmente a árvore de commits anteriores do Git (sem necessidade de `git rebase -i` ou `git push --force`), evitando corrupção de clones de colaboradores e respeitando as práticas consolidadas de conformidade de plataformas abertas como GitHub e Wikipedia.

---

## 10. Governança de Migrações e Testes de Contrato Arquitetural

### 10.1. Isolamento do Serving de Produção
Para que refatorações de código e reorganizações de banco de dados não invalidem desnecessariamente caches locais de atletas isolados em falésias, a migração declara expressamente:
```python
# migracoes/0005_migrar_uids_e_rotulos.py
AFETA_VERSAO_SERVING: bool = False
```
O utilitário `serving/update_serving.py` não incrementa a versão pública da CDN (`kDataVersion = 4`), atualizando apenas os croquis locais com `ultima_migracao: 5`.

### 10.2. Testes de Contrato Automatizados (TDD com 100% de Cobertura)
1. **Biblioteca `scripts/gerenciar_uids_lib.py`:** Módulo independente de funções criptográficas com cobertura de testes unitários em `scripts/gerenciar_uids_lib_test.py`.
2. **Contrato do Banco de Dados (`tests/contrato_database_uids_test.py`):** Suíte de testes que audita todo o repositório e reprova o build se:
   * Existir qualquer referência textual legada (`escalada:`, `setor:`, `grupo:`).
   * Existir o campo depreciado `label:` ao invés de `rotulo:`.
   * Qualquer via, setor, POI ou croqui não possuir um `uid:` válido de 14 caracteres Base62.
   * Existirem arquivos residuais `ids_*.yaml`.
3. **Contrato de Serialização do Editor (`tests/contrato_editor_serializacao_test.py`):** Garante que o editor de vias nunca volte a emitir identificadores numéricos ou estruturas legadas.

---

## 11. Quadro Comparativo: Evolução das Abordagens

| Critério Arquitetural | Abordagem Preliminar (Descartada)                                                                  | Arquitetura Unificada Aprovada (v3.0)                                                                                     |
| :--- |:---------------------------------------------------------------------------------------------------|:--------------------------------------------------------------------------------------------------------------------------|
| **Identificadores de Entidades** | IDs inteiros em 2 níveis (`croqui_id`, `escalada_id`) + 3 tabelas YAML por croqui (~130 arquivos). | **NanoID 14c Universal** atribuído diretamente em cada entidade; sem tabelas extras.                                      |
| **Risco de Conflitos de Merge** | Alto; exigia ferramentas de split de visões e resolução de conflitos de IDs no Git.                | **Sem conflito prático** ($1{,}24 \times 10^{25}$ combinações Base62; 1 em 25 trilhões de chance de colisão).             |
| **Placas na Rocha e QR Code** | URLs longas (`app.arestaclimb.com/12/35`), QR Code frágil com baixa tolerância a danos.            | **`https://aresta.cc/<uid>`** (32 caracteres exatos), QR V3 (29 × 29 módulos), Nível H (30% de correção) em Aço Inox 316L. |
| **Camada Móvel de Dados** | Sugestão de banco SQLite avulso com lógicas manuais de sincronização.                              | **PowerSync SDK** reativo; abstração integral do motor local e sync automático com Postgres.                              |
| **Armazenamento no Supabase** | Risco de estouro de cota e tabelas sobrecarregadas com histórico social.                           | **Consumo < 45 MB (< 9% do Free Tier)** com buffer transitório esvaziado de hora em hora pelo bot.                        |
| **Aderência aos Princípios** | Alta complexidade, duplicação e quebra de idioma (termos em inglês).                               | **Simplicidade em português (Regra VI && Regra I)**.                                                                      |
