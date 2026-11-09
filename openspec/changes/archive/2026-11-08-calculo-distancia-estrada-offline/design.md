# Design

## Context

Conforme detalhado em `proposal.md`, o cálculo atual em `calcularPicosMaisProximos` (`frontend/lib/view/function_library/funcoes_home.dart`) utiliza `Geolocator.distanceBetween` (linha reta geodésica). O aplicativo já possui duas estruturas de dados globais sincronizadas:
1. `indice.binarypb` (~13 KB, mantido em RAM no `DatasetRepository`), que é re-baixado integralmente sempre que o hash SHA-256 de qualquer croqui muda.
2. `catalogo.db` (SQLite local gerenciado por `RepositorioCatalogo`), que conta com sincronização incremental via Delta Squash (`/sync` no Cloudflare Worker + D1) e substituição atômica em `full_download`.

Precisamos introduzir o cálculo de distância por estrada 100% offline mantendo:
- Compilação incremental rápida por croqui (sem obrigar a reprocessar todos os picos quando apenas 1 croqui muda).
- Zero tráfego de rede extra quando apenas metadados de vias/setores mudam.
- Consulta em tempo sub-milissegundo ($O(\log N)$) na UI thread do Flutter para ordenar os cards da Home e da aba Explorar.

## Goals / Non-Goals

**Goals:**
- Armazenar a malha rodoviária esparsa e os portais de borda no `catalogo.db` com paridade 1:1 no contrato `aresta_api` (`sql/catalogo.sql` e `openapi/catalogo.yaml`).
- Garantir deduplicação determinística de nós do OpenStreetMap entre picos distintos e entre anéis de diferentes resoluções usando grades globais encaixadas ($3 \times 3$) e função de prioridade intrínseca ao nó.
- Construir em memória uma árvore de busca espacial 2D (`ArvoreKdNosEstrada`) em Dart para localizar os $k=3$ nós rodoviários mais próximos do usuário em $O(\log N)$.
- Estimar a distância rodoviária combinando busca local na KD-Tree ($\le 180\text{ km}$), minimização sobre portais de borda para picos distantes ($> 180\text{ km}$) e fallback geodésico ($\times 1{,}25$) para croquis ainda sem malha.
- Cachear as distâncias calculadas por `(latitudeUsuario, longitudeUsuario, versaoMalha)` para evitar recomputação durante rolagens, trocas de aba e buscas textuais.

**Non-Goals:**
- Renderizar visualmente o traçado (polilinha curva) da rota rodoviária em um mapa ou fornecer navegação curva-a-curva (*turn-by-turn*).
- Estimar tempo de trânsito em tempo real (a métrica exibida e ordenada permanece em quilômetros/metros por sua invariância e estabilidade offline).
- Consultar APIs externas de roteamento em tempo de execução no dispositivo móvel.

## Decisions

### 1. Armazenamento no `catalogo.db` em vez do `indice.binarypb`
- **Decisão**: Criar duas tabelas relacionais em `sql/catalogo.sql` (`catalogo_nos_estrada` e `catalogo_distancias_estrada`) sincronizadas via `catalogo.db` e `/sync`.
- **Racional**:
  - O `indice.binarypb` muda de `ETag` e é baixado por inteiro a cada edição de texto ou grau de qualquer via. Embutir a malha no `indice.binarypb` inflaria todas as atualizações cotidianas.
  - No `catalogo.db`, a chave primária `no_osm_id` em `catalogo_nos_estrada` deduplica automaticamente nós compartilhados via `INSERT OR IGNORE`/`REPLACE`, e `catalogo_distancias_estrada` permite atualizar um único croqui isoladamente (`DELETE FROM catalogo_distancias_estrada WHERE croqui_uid = ?`).
  - Quando uma atualização altera apenas vias/setores, o diff SQL (`EXCEPT`) nas tabelas de estrada é vazio (0 bytes transmitidos no Delta Sync).
- **Esquema SQL (`sql/catalogo.sql`)**:
  ```sql
  CREATE TABLE IF NOT EXISTS catalogo_nos_estrada (
      no_osm_id INTEGER PRIMARY KEY,
      latitude_e7 INTEGER NOT NULL,
      longitude_e7 INTEGER NOT NULL
  );

  CREATE TABLE IF NOT EXISTS catalogo_distancias_estrada (
      croqui_uid TEXT NOT NULL,
      no_osm_id INTEGER NOT NULL,
      distancia_metros INTEGER NOT NULL,
      na_borda INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (croqui_uid, no_osm_id)
  );

  CREATE INDEX IF NOT EXISTS idx_catalogo_distancias_estrada_no
  ON catalogo_distancias_estrada(no_osm_id);
  ```

### 2. Geração Offline em 3 Anéis Concêntricos e Deduplicação Determinística Global
- **Decisão**: Amostrar a malha do OpenStreetMap num raio de até 180 km por coordenada de estacionamento usando 3 anéis concêntricos ancorados no `(0°, 0°)` da Terra com passos múltiplos exatos ($3 \times 3$):
  - **Anel 1 (0 a 15 km)**: todas as vias dirigíveis (`motorway` até `track`/`unclassified`), grade fina de `0.02° × 0.02°` ($\approx 2{,}2\text{ km}$).
  - **Anel 2 (15 a 60 km)**: vias principais a coletoras (`motorway` até `tertiary`), grade média de `0.06° × 0.06°` ($\approx 6{,}6\text{ km}$, exatamente $3 \times 3$ células do Anel 1).
  - **Anel 3 (60 a 180 km)**: apenas rodovias (`motorway`, `trunk`, `primary`, `secondary`), grade grossa de `0.18° × 0.18°` ($\approx 20\text{ km}$, exatamente $3 \times 3$ células do Anel 2).
- **Função de Prioridade Intrínseca do Nó**:
  Dentro de qualquer célula `(ix, iy) = (floor(lat / passo), floor(lon / passo))` (avaliando apenas células inteiras dentro do raio), o nó vencedor é escolhido minimizando a tupla:
  $$\text{prioridade}(\text{nó}) = \big(\text{rank\_rodovia},\; -\text{grau\_cruzamento},\; \text{crc32}(\text{no\_osm\_id})\big)$$
  - **Racional**: Como a prioridade depende exclusivamente do próprio nó (e nunca da distância ao centro da célula nem da coordenada do pico), o mínimo de uma célula pai $3 \times 3$ (Anel 3) é matematicamente garantido de coincidir com o vencedor de uma de suas 9 subcélulas (Anel 2), que por sua vez coincide com o vencedor de uma subcélula do Anel 1. Isso maximiza a colisão de `no_osm_id` entre picos vizinhos e distantes.
- **Nó do Estacionamento e Dijkstra Invertido**:
  - O grafo extraído via Overpass API é filtrado pelo seu maior componente fortemente/fracamente conexo antes de localizar o nó mais próximo do estacionamento (`no_pico`), evitando ilhas de trilhas desconectadas no OSM.
  - Um único Dijkstra invertido a partir de `no_pico` calcula simultaneamente a distância de estrada de todos os nós até o estacionamento, e o próprio `no_pico` é incluído com `distancia_metros = 0`.
  - Na borda externa da malha (8 octantes: N, NE, L, SE, S, SO, O, NO), o nó rodoviário principal mais externo de cada direção recebe `na_borda = 1`.

### 3. Busca Espacial 2D via KD-Tree em Memória e Fórmula Híbrida de Distância
- **Decisão**: Implementar um módulo puro e independente em `frontend/lib/utils/calculadora_distancia_estrada.dart` contendo a `ArvoreKdNosEstrada` (2D KD-Tree alternando cortes em latitude e longitude pela mediana) e o cálculo híbrido de distância.
- **Fluxo de Execução para `(userLat, userLon)`**:
  1. **Busca na KD-Tree ($O(\log N)$)**: busca os até $k=3$ nós mais próximos do usuário dentro de um raio máximo de captura `kRaioMaxCapturaKm = 15.0`.
  2. **Para cada pico $P$**:
     - **Caso 1 — Pico presente em pelo menos um dos nós vizinhos ($\le 180\text{ km}$)**:
       $$\text{dist}(U, P) = \min_{K \in \text{vizinhos com } P} \Big(\text{dist\_geodesica}(U, K) \times 1{,}25 + \text{dist\_estrada}(K \to P)\Big)$$
     - **Caso 2 — Pico ausente nos nós vizinhos, mas possui Portais de Borda (`na_borda = 1`)**:
       $$\text{dist}(U, P) = \min_{B \in \text{Portais}(P)} \Big(\text{dist\_geodesica}(U, B) \times 1{,}25 + \text{dist\_estrada}(B \to P)\Big)$$
       *(Avalia os até 8 portais de borda em $O(1)$, preservando os quilômetros finais sinuosos da serra e descartando automaticamente portais bloqueados por barreiras cujo `dist_estrada(B -> P)` seja alto).*
     - **Caso 3 — Fallback (Croqui sem malha cadastrada ou catálogo ainda vazio)**:
       Quando a malha global já está ativa mas um croqui específico não tem nós (ex: croqui novo no Editor), usa $\text{dist\_geodesica}(U, P) \times 1{,}25$; se nenhuma malha rodoviária estiver carregada, preserva `dist_geodesica(U, P)`.

### 4. Reatividade e Cache nos ViewModels
- **Decisão**: O `RepositorioCatalogo` expõe um método `carregarMalhaEstrada()` que lê em uma única consulta as tabelas `catalogo_nos_estrada` e `catalogo_distancias_estrada` (associadas ao `id_slug` via `catalogo_croquis`) e constrói a instância imutável de `CalculadoraDistanciaEstrada`.
- O `DatasetRepository` atualiza a instância de `CalculadoraDistanciaEstrada` sempre que o `catalogo.db` é inicializado ou `RepositorioCatalogo.versaoNotificador` muda, e `calcularPicosMaisProximos` utiliza essa instância.

## Risks / Trade-offs

- **[Banco `catalogo.db` legado em dispositivos antes da migração DDL]** → Na abertura do banco em `RepositorioCatalogo._obterBanco`, `comandosDdlCatalogo` executa `CREATE TABLE IF NOT EXISTS` para `catalogo_nos_estrada` e `catalogo_distancias_estrada`, garantindo que bancos pré-existentes ganhem as tabelas sem erro de SQL e operem em fallback até receberem os dados.
- **[Croquis identificados por `id_slug` na UI vs `croqui_uid` no SQLite]** → Na query de carregamento da malha em `RepositorioCatalogo`, fazemos `JOIN catalogo_croquis` para indexar as distâncias tanto por `croqui_uid` quanto por `id_slug` (`ResumoCroqui.id`), permitindo lookup $O(1)$ independentemente de o objeto em memória usar `id` ou `croqui_uid`.
- **[Picos sem coordenada ou com coordenada `(0, 0)`]** → Picos sem `hasLocalizacao()` (ou com latitude e longitude iguais a zero) continuam sendo ignorados pelo cálculo de distância e listados ao final na ordem alfabética na aba Explorar.

## Migration Plan

1. Atualizar `sql/catalogo.sql` e `openapi/catalogo.yaml` no `aresta_api`, ajustar `validador_paridade.py` se necessário e regerar os bindings (`build.py`).
2. Implementar `CalculadoraDistanciaEstrada` e `ArvoreKdNosEstrada` seguindo TDD (Red-Green-Refactor) com 100% de cobertura comportamental.
3. Atualizar `RepositorioCatalogo` (aplicação de deltas e leitura da malha) e `DatasetRepository`.
4. Integrar `CalculadoraDistanciaEstrada` em `funcoes_home.dart`, `HomeViewModel` e `BrowseViewModel`.
