# Design

## Context

Veja `proposal.md` para a motivação completa. A solução abrange quatro repositórios acoplados pelo contrato central `aresta_api`:
1. **`aresta_api`**: define `NoMalhaEstrada` (`proto/croqui.proto`), as tabelas `catalogo_nos_estrada` e `catalogo_distancias_estrada` (`sql/catalogo.sql`) e o contrato de sincronização (`openapi/catalogo.yaml`).
2. **`aresta_db`**: gera a malha a partir do Overpass API (`scripts/gerar_malha_estrada_lib.py`), exibe o diálogo no Editor Desktop (`editor/views/widget_mensagem_coordenada.py`), expõe ferramentas MCP (`editor/mcp/`), avalia a qualidade do croqui (`editor/core/avaliador_nota_qualidade.py`, `scripts/medir_saude_croquis.py`), compila `catalogo.db` (`scripts/gerar_catalogo_sqlite_lib.py`) e publica deltas no Cloudflare D1 (`scripts/deploy_generated.py`, `scripts/gerar_deltas_catalogo.py`, `serving/sincronizar_d1_lib.py`).
3. **`aresta_backend`**: condensa os deltas de `catalogo_deltas` no Cloudflare Worker (`cloudflare/catalogo/src/index.ts`).
4. **`aresta_app`**: sincroniza `catalogo.db` (`RepositorioCatalogo`), indexa a malha em KD-Tree (`CalculadoraDistanciaEstrada`) e ordena/renderiza os cards na Home e na aba Explorar (`funcoes_home.dart`, `HomeViewModel`, `BrowseViewModel`, `CragCard`).

## Goals / Non-Goals

**Goals:**
- Otimizar o Dijkstra da malha viária pelo menor tempo de viagem sem trânsito (`duracao_minutos`), preservando também a `distancia_metros` desse caminho mais rápido.
- Exibir estimativa de tempo arredondada (`5 min` se `< 1h`, `10 min` se `>= 1h`) com `Tooltip` explicativo (`"Estimativa sem trânsito: ~X min (Y.Z km)"`) para picos alcançados pela malha local ($\le 200\text{ km}$) e ordenar os picos em duas faixas (1º por menor tempo; 2º por menor distância em km).
- Corrigir a sincronização incremental (`apply_delta`) no Cloudflare Worker e no `RepositorioCatalogo` para incluir `nos_estrada`, `distancias_estrada` (`duracao_minutos`) e `deletes.distancias_estrada`.
- Corrigir `verificar_malha_estrada_pico` no `deploy_generated.py`, adicionar progresso em streaming + botão `Concluir` no diálogo do Overpass, criar as ferramentas MCP `aresta_gerar_malha_estrada` e `aresta_avaliar_qualidade`, adicionar a 8ª tarefa essencial (1.000 pts) no Painel de Qualidade e refatorar `STATUS_CROQUIS.md`.

**Non-Goals:**
- Trânsito em tempo real (requer conexão online e APIs tarifadas).
- Roteamento curva-a-curva completo no dispositivo móvel.

## Decisions

### 1. Modelo de Velocidade Sem Trânsito e Dijkstra por Tempo (`gerar_malha_estrada_lib.py`)
- **Decisão**: Para cada `way` do OpenStreetMap:
  1. Se a superfície (`surface`) indicar via não pavimentada (`unpaved`, `compacted`, `gravel`, `fine_gravel`, `pebblestone`, `dirt`, `earth`, `ground`, `mud`, `sand`, `grass`, `woodchips`) ou `highway == "track"`, aplicar velocidade de estrada não pavimentada: `30 km/h` para `primary`/`secondary`/`tertiary`, `25 km/h` para `unclassified`/`residential`/`service` e `20 km/h` para `track`.
  2. Caso contrário, se houver tag `maxspeed` numérica válida (ex: `"80"`, `"100 km/h"`), aplicar fator de fluxo livre prático de `0.85` sobre `maxspeed` (limitado entre `15 km/h` e `110 km/h`).
  3. Caso não haja `maxspeed`, aplicar a velocidade padrão pavimentada por classe `highway`:
     - `motorway`: `95 km/h` (`motorway_link`: `60 km/h`)
     - `trunk`: `80 km/h` (`trunk_link`: `50 km/h`)
     - `primary`: `70 km/h` (`primary_link`: `45 km/h`)
     - `secondary`: `55 km/h` (`secondary_link`: `40 km/h`)
     - `tertiary`: `45 km/h` (`tertiary_link`: `35 km/h`)
     - `unclassified`: `35 km/h`
     - `residential` / `living_street` / `service`: `25 km/h`
- O peso da aresta no grafo invertido passa a ser `tempo_segundos = comprimento_metros / (velocidade_kmh / 3.6)`, mantendo junto o `comprimento_metros`. O Dijkstra relaxa pelo menor `tempo_segundos` acumulado e registra simultaneamente a `distancia_metros` acumulada daquele caminho ótimo. Ao final, `duracao_minutos = round(tempo_segundos / 60.0)`.
- **Racional**: Prioriza rodovias pavimentadas rápidas em vez de atalhos rurais lentos de terra, mantendo determinismo 100% reproduzível a partir dos dados OSM.

### 2. Conexão Inicial $U \to K$, Raio de Captura de 25 km e Duas Faixas de Ordenação (`aresta_app`)
- **Decisão**:
  - Na `CalculadoraDistanciaEstrada`:
    - `raioCapturaMalhaMetros = 25000.0` (`25 km`) e `quantidadeVizinhos = 6`. Como o Anel 3 (`60` a `180 km`) amostra 1 nó por célula de `0.18°` ($\approx 20\text{ km}$), um usuário dentro do raio de `~200 km` do pico pode estar a até `18–22 km` do nó amostrado da sua célula. O raio de `25 km` com `6` vizinhos garante que o usuário capture os nós do Anel 3 sem buracos.
    - Para cada nó vizinho $K$ que possui o pico $P$ registrado em `distanciasAtePicoPorNo`:
      - $d_{U \to K} = \text{dist\_geodésica}(U, K) \times 1{,}25$ (em metros).
      - $\text{TempoAcessoMinutos}(d_{U \to K})$: primeiros $\min(d_{U \to K}, 3000)$ metros a `30 km/h` ($500\text{ m/min}$) + metros excedentes $\max(0, d_{U \to K} - 3000)$ a `50 km/h` ($833{,}33\text{ m/min}$).
      - $\text{TempoTotal}(K) = \text{TempoAcessoMinutos}(d_{U \to K}) + \text{duracaoMinutos}(K \to P)$.
      - Seleciona-se o nó $K$ que minimiza $\text{TempoTotal}(K)$, produzindo `EstimativaViagemPico(distanciaMetros: d_total, duracaoMinutos: round(tempoTotal), PossuiEstimativaTempo: true)`.
    - Se o pico não estiver presente nos nós vizinhos a até `25 km` (usuário a $> 200\text{ km}$ do pico ou pico sem malha), calcula-se a distância via portais de borda (`na_borda = 1`) ou fallback geodésico ($\times 1{,}25$) e retorna-se `EstimativaViagemPico(distanciaMetros: d_total, duracaoMinutos: null)`.
  - Arredondamento para exibição (`formatarTempoEstimadoViagem`):
    - Se `duracaoMinutos < 60`: arredondar para múltiplo de `5` (`max(5, ((min + 2) ~/ 5) * 5)`), formatando como `"~40 min"`.
    - Se `duracaoMinutos >= 60`: arredondar para múltiplo de `10` (`((min + 5) ~/ 10) * 10`), formatando como `"~1h 10min"` (ou `"~2h"` quando `min % 60 == 0`).
  - Ordenação em duas faixas (`compararProximidadeViagem`):
    - Picos com `duracaoMinutos != null` (Faixa 1) vêm sempre antes de picos com `duracaoMinutos == null` (Faixa 2).
    - Dentro da Faixa 1, ordena-se por `duracaoMinutos` crescente (desempate por `distanciaMetros`).
    - Dentro da Faixa 2, ordena-se por `distanciaMetros` crescente.

### 3. Condensação de `nos_estrada` e `distancias_estrada` no Cloudflare Worker e `RepositorioCatalogo`
- **Decisão**:
  - Adicionar `distancias_estrada: list[str]` (lista de `croqui_uid` cujas distâncias de estrada foram substituídas ou removidas no delta) ao objeto `deletes` de `catalogo_deltas` (`gerar_deltas_catalogo.py`, `openapi/catalogo.yaml`, `cloudflare/catalogo/src/index.ts`).
  - Em `condensarDeltas()` (`aresta_backend/cloudflare/catalogo/src/index.ts`):
    - Manter `nosEstradaUpsert = new Map<number, Record<string, unknown>>()`, `nosEstradaDelete = new Set<number>()`, `distanciasEstradaUpsert = new Map<string, Record<string, unknown>>()` (chave `${croqui_uid}:${no_osm_id}`) e `distanciasEstradaDelete = new Set<string>()` (`croqui_uid`).
    - Quando um delta trouxer `deletes.distancias_estrada` ou `deletes.croquis` para um `croqui_uid`, adicionar `croqui_uid` em `distanciasEstradaDelete` e limpar de `distanciasEstradaUpsert` entradas anteriores daquele `croqui_uid` antes de aplicar os novos `upserts.distancias_estrada` do mesmo passo.
  - Em `RepositorioCatalogo.aplicarDelta` (`aresta_app`):
    - Executar `DELETE FROM catalogo_distancias_estrada WHERE croqui_uid = ?` para cada `croqui_uid` em `deletes.distanciasEstrada` (além de `deletes.croquis`).
    - Inserir `duracao_minutos` em `INSERT OR REPLACE INTO catalogo_distancias_estrada (croqui_uid, no_osm_id, distancia_metros, na_borda, duracao_minutos)`.
    - Em `_garantirTabelaMalhaEstrada`, verificar via `PRAGMA table_info(catalogo_distancias_estrada)` se a coluna `duracao_minutos` existe; caso não exista, migrar in-place preservando os dados existentes.

### 4. Streaming no Overpass, Confirmação Manual no Diálogo, MCP e Painel de Qualidade (`aresta_db`)
- **Decisão**:
  - `ClienteOverpass.consultar_malha`: ler `resposta.read(65536)` em loop, verificando `verificador_cancelamento` a cada bloco e reportando `progresso(pct, f"Recebendo malha viária de {nome_espelho} ({mb_recebidos:.1f} MB)...")` mapeando o progresso de `15%` a `42%`.
  - `DialogoProgressoMalhaEstrada._ao_concluir`: não chamar `self.accept()` automaticamente; alterar o texto do botão para `"Concluir"`, habilitá-lo, desconectar do cancelamento e conectá-lo a `self.accept()`.
  - `avaliador_nota_qualidade.py`: adicionar a 8ª tarefa essencial `etapa1_malha_estrada_picos` (1.000 pts) na Etapa 1, validando `malha_estrada_pico_atualizada(pico)` para cada pico do croqui.
  - `ferramentas_comandos.py` / `ferramentas_conhecimento.py`: expor `aresta_gerar_malha_estrada` e `aresta_avaliar_qualidade`.
  - `medir_saude_croquis.py`: gerar `STATUS_CROQUIS.md` diretamente a partir de `avaliar_nota_qualidade_croqui(croqui)`.

## Risks / Trade-offs

- **[ Clientes que sincronizaram com o Worker antigo ficaram com `catalogo_nos_estrada` vazia ]** → **Mitigação**: A inclusão de `duracao_minutos` em `calcular_versao_catalogo` e a regeneração da malha de `br_mg_lagoa_santa_gruta_da_lapinha` geram um novo hash `versao_catalogo`, disparando automaticamente uma nova sincronização com a malha completa.
- **[ Testes existentes do Painel de Qualidade esperam pontuação máxima 7000 na Etapa 1 / 7770 total ]** → **Mitigação**: Atualizar os testes unitários e de integração do avaliador de qualidade e do `medir_saude_croquis.py` seguindo TDD para refletir a 8ª tarefa essencial (`8000` na Etapa 1 / `8770` total).
