# Proposal

## Why

Atualmente, a descoberta e a ordenação de picos por proximidade na página inicial e na aba Explorar utilizam exclusivamente a distância geodésica em linha reta (`Geolocator.distanceBetween`). Como locais de escalada situam-se em acidentes geográficos (serras, vales, rios sem ponte e maciços rochosos), a distância em linha reta distorce severamente a realidade — exibindo picos do outro lado de uma serra (ex: Sabará ou Caeté vistos da Zona Sul de BH a 14 km em linha reta, mas a mais de 40–55 km por estrada) como mais próximos do que picos de acesso rodoviário rápido e direto. Precisamos calcular e ordenar a distância levando em conta a malha viária real de forma **100% offline desde o preload**, leve em armazenamento e instantânea na interface.

## What Changes

- **Extensão do Esquema SQLite e Delta Sync do Catálogo (`aresta_api` e `RepositorioCatalogo`)**:
  - Adição das tabelas `catalogo_nos_estrada` (nós únicos compartilhados da malha viária do OpenStreetMap com `no_osm_id`, `latitude_e7` e `longitude_e7`) e `catalogo_distancias_estrada` (lista esparsa associando `(croqui_uid, no_osm_id)` à `distancia_metros` pré-computada via Dijkstra e flag `e_portal_borda` indicando os portais cardeais/colaterais de entrada na borda da malha do pico).
  - Atualização do contrato OpenAPI (`catalogo.yaml`) e da sincronização incremental (`apply_delta` no `RepositorioCatalogo`) para suportar `upserts` e `deletes` das novas tabelas sem invalidar nem retransmitir a malha quando apenas vias ou textos de um croqui forem editados.
- **Geração Pré-Computada em 3 Anéis Concêntricos com Deduplicação Determinística**:
  - Definição do contrato de geração da malha por coordenada de estacionamento num raio de até 180 km dividido em 3 anéis concêntricos sobre o OpenStreetMap (Anel 1 de 0–15 km com todas as vias dirigíveis e grade global de `0.02°`; Anel 2 de 15–60 km com vias até `tertiary` e grade global de `0.06°`; Anel 3 de 60–180 km com rodovias `motorway`/`trunk`/`primary`/`secondary` e grade global de `0.18°`, mais até 8 portais de borda).
  - Deduplicação determinística entre picos distintos através de grades globais encaixadas ($3 \times 3$, ancoradas em `(0°, 0°)`) e função de prioridade intrínseca do nó `(rank_rodovia, -grau_cruzamento, hash_deterministico(no_osm_id))`, garantindo que diferentes picos e diferentes anéis elejam exatamente o mesmo `no_osm_id`, além de incluir o próprio estacionamento do pico como nó de distância `0`.
- **Motor Offline de Busca Espacial 2D (KD-Tree) e Cálculo de Distância Rodoviária (`aresta_app`)**:
  - Criação de estrutura de busca espacial 2D (`ArvoreKdNosEstrada` / `CalculadoraDistanciaEstrada`) construída em memória a partir do `catalogo.db` em tempo $O(N \log N)$ na inicialização/atualização do catálogo e consultada em $O(\log N)$ para encontrar os $k=3$ nós mais próximos do usuário num raio de captura de até 15 km.
  - Cálculo híbrido determinístico:
    1. **Dentro da malha regional ($\le 180\text{ km}$)**: quando o pico consta na lista esparsa dos nós vizinhos do usuário, calcula $\min_{K} \big(\text{dist\_reta}(U, K) \times 1{,}25 + \text{dist\_estrada}(K \to P)\big)$.
    2. **Fora da malha regional ($> 180\text{ km}$) com Portais de Borda**: quando o pico possui portais de borda cadastrados, calcula $\min_{B \in \text{Portais}(P)} \big(\text{dist\_reta}(U, B) \times 1{,}25 + \text{dist\_estrada}(B \to P)\big)$, preservando a sinuosidade real dos quilômetros finais na serra e evitando escolher pontos bloqueados por barreiras geográficas.
    3. **Fallback geodésico com fator rodoviário**: para croquis recém-criados no modo Editor/Live Reload ainda sem malha compilada, utiliza $\text{dist\_reta}(U, P) \times 1{,}25$ (ou geodésica direta caso não haja malha carregada).
- **Integração Reativa nos ViewModels da Home e Explorar**:
  - Atualização de `HomeViewModel`, `BrowseViewModel` e `calcularPicosMaisProximos` para utilizar o calculador de distância rodoviária com cache em memória indexado pela última coordenada do usuário e versão do catálogo, mantendo ordenação e *badges* (`m` / `km`) instantâneas sem bloquear a UI thread.

## Capabilities

### New Capabilities
- `malha-distancia-estrada-offline`: Indexação espacial 2D (KD-Tree), estrutura relacional esparsa de nós rodoviários e portais de borda no catálogo SQLite, e cálculo offline de distância por estrada até os picos de escalada.

### Modified Capabilities
- `descoberta-picos-proximidade`: Substituição do cálculo puramente geodésico em linha reta pelo cálculo de distância rodoviária estimada (via malha pré-computada de pontos-chave e portais de borda, com fallback geodésico ajustado) na ordenação e exibição de quilometragem do carrossel da Home e da aba Explorar.
- `catalogo-sqlite-sync`: Inclusão das tabelas `catalogo_nos_estrada` e `catalogo_distancias_estrada` no esquema do `catalogo.db`, na aplicação transacional de deltas (`apply_delta`) e na notificação reativa de atualização da malha.

## Impact

- **Contratos e Geração de Código (`frontend/lib/aresta_api/`)**:
  - `sql/catalogo.sql` e `openapi/catalogo.yaml` (e artefatos gerados em Dart, Python e TypeScript via `build.py`).
- **Camada de Dados e Serviços (`frontend/lib/services/` e `frontend/lib/utils/`)**:
  - `RepositorioCatalogo` (`frontend/lib/services/catalogo/repositorio_catalogo.dart`) para leitura dos nós/distâncias e aplicação de deltas.
  - Nova biblioteca modular de KD-Tree 2D e cálculo de distância por estrada em `frontend/lib/utils/` (com espelhamento 1:1 de testes em `frontend/test/utils/`).
  - `DatasetRepository` (`frontend/lib/services/repositorio_dataset.dart`) expondo a malha rodoviária carregada reativamente a partir do `RepositorioCatalogo`.
- **Camada de Apresentação (`frontend/lib/view/`)**:
  - `funcoes_home.dart`, `HomeViewModel` e `BrowseViewModel` consumindo a malha rodoviária com cache por coordenada do usuário.
