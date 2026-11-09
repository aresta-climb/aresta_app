# Proposal

## Why

Atualmente, a malha viária pré-computada de cada pico otimiza caminhos apenas pela menor distância física em metros, o que distorce a proximidade prática quando há rodovias expressas rápidas versus estradas secundárias lentas, além de não informar ao escalador o tempo estimado de direção (sem trânsito) para picos na sua região ($\le 200\text{ km}$). Adicionalmente, o fluxo de geração e sincronização da malha apresenta lacunas operacionais e duas regressões: (1) o Cloudflare Worker (`condensarDeltas`) descarta `nos_estrada` e `distancias_estrada` na sincronização incremental (`apply_delta`), fazendo o aplicativo continuar exibindo a distância geodésica em linha reta após publicações na nuvem; (2) o `deploy_generated.py` emite falso aviso de falta de malha ao ler a raiz do wrapper `ArquivoMalhaEstrada` em vez de `malha["conteudo"]`; e (3) no Editor Desktop, a consulta ao Overpass API não exibe progresso granular durante o download nem botão explícito de conclusão, falta ferramenta MCP dedicada para geração da malha e diagnóstico do Painel de Qualidade, e a geração da malha ainda não integra as tarefas essenciais de publicação nem o relatório `STATUS_CROQUIS.md`.

## What Changes

- **Cálculo de Tempo de Viagem (Sem Trânsito) via Dijkstra na Malha Viária (`aresta_api`, `aresta_db`)**:
  - Estimar a velocidade livre de trânsito de cada segmento (`way`) do OpenStreetMap combinando a tag `maxspeed` (quando presente e válida, com fator de fluxo livre de `0.85`) e uma tabela determinística por `(highway, surface)` para estradas pavimentadas, não pavimentadas (`unpaved`, `gravel`, `dirt`, `earth`, `ground`, `sand`, `track`) e urbanas.
  - Alterar o algoritmo de Dijkstra invertido em `gerar_malha_estrada_lib.py` para otimizar pelo **caminho de menor tempo** (`duracao_minutos`) a partir do estacionamento do pico, persistindo tanto `duracao_minutos` quanto a `distancia_metros` desse caminho mais rápido no Protobuf (`NoMalhaEstrada.duracao_minutos = 6`), no SQLite (`catalogo_distancias_estrada.duracao_minutos`), no OpenAPI (`CatalogoDistanciaEstrada.duracao_minutos`) e no Cloudflare D1.
- **Conexão Inicial $U \to K$, Ordenação em 2 Faixas, Arredondamento e Tooltip no App (`aresta_app`)**:
  - Ampliar em `CalculadoraDistanciaEstrada` o raio de captura da malha local para `25 km` (`25000.0 m`) e `quantidadeVizinhos = 6` na KD-Tree, garantindo cobertura contínua até o Anel 3 (`0.18°` $\approx 20\text{ km}$, cobrindo picos em até $\sim 200\text{ km}$).
  - Calcular o tempo de acesso do usuário até o nó vizinho $K$ sobre $d_{U \to K} = \text{dist\_geodésica}(U, K) \times 1{,}25$ assumindo `30 km/h` nos primeiros `3 km` (saída urbana/local) e `50 km/h` no trecho excedente, escolhendo o nó $K$ que minimiza $\text{TempoAcesso}(U \to K) + \text{duracao\_minutos}(K \to P)$.
  - Arredondar a estimativa de tempo exibida na UI para múltiplos de **5 minutos** quando `< 60 min` (mínimo `5 min`) e múltiplos de **10 minutos** quando `>= 60 min`.
  - Estruturar a ordenação por proximidade (carrossel "Picos Próximos" da Home e ordenação "Mais próximos" da aba Explorar) em **duas faixas**:
    1. **Faixa 1 (picos alcançados pela malha local, $\le 200\text{ km}$, com estimativa de tempo)**: exibidos primeiro, ordenados por menor tempo de viagem, apresentando o tempo arredondado no badge do card (ex: `~40 min`, `~1h 10min`).
    2. **Faixa 2 (picos fora do raio de 200 km ou sem malha)**: exibidos após a Faixa 1, ordenados por menor distância estimada em quilômetros, apresentando apenas a distância no badge (ex: `342.0 km`).
  - Adicionar `Tooltip` no badge de proximidade explicando que o tempo é uma estimativa sem trânsito acompanhada da quilometragem (ex: `"Estimativa sem trânsito: ~40 min (51.4 km)"`).
- **Correção da Sincronização Incremental (`apply_delta`) da Malha Viária (`aresta_backend`, `aresta_db`, `aresta_api`, `aresta_app`)**:
  - Corrigir `condensarDeltas()` no Cloudflare Worker (`aresta_backend/cloudflare/catalogo/src/index.ts`) para condensar e retornar `nos_estrada` (`upserts` por `no_osm_id` e `deletes`) e `distancias_estrada` (`upserts` por `${croqui_uid}:${no_osm_id}`, `duracao_minutos` e `deletes` por `croqui_uid`).
  - Incluir `distancias_estrada` (lista de `croqui_uid` cujas distâncias devem ser limpas) em `DeletesSyncCatalogo` no OpenAPI (`catalogo.yaml`), em `gerar_payload_d1` (`gerar_deltas_catalogo.py`) e em `RepositorioCatalogo.aplicarDelta` (`aresta_app`), além de migrar automaticamente `catalogo_distancias_estrada` caso não possua a coluna `duracao_minutos`.
- **Correção da Verificação de Malha no Deploy (`aresta_db`)**:
  - Corrigir `verificar_malha_estrada_pico` em `scripts/deploy_generated.py` reutilizando `malha_estrada_pico_atualizada(pico)` para inspecionar `malha["conteudo"]` nos dados compilados do `ArquivoMalhaEstrada`, eliminando o falso aviso quando a malha já está gerada e atualizada.
- **Progresso Granular no Overpass e Botão `Concluir` no Wizard do Editor (`aresta_db`)**:
  - Em `ClienteOverpass.consultar_malha`, realizar leitura em *streaming* por blocos (`64 KB`), emitindo progresso contínuo durante a espera e o download (espelho consultado, segundos decorridos, MB baixados de `15%` a `42%`) e checando `verificador_cancelamento` a cada bloco para cancelamento imediato.
  - Em `DialogoProgressoMalhaEstrada`, ao concluir (`100%`), manter a janela aberta com o log completo e transformar o botão de ação em **`Concluir`** (habilitado e com foco padrão) para inspeção antes do fechamento.
- **Ferramentas MCP, 8ª Tarefa Essencial do Painel de Qualidade e `STATUS_CROQUIS.md` (`aresta_db`)**:
  - Adicionar a 8ª tarefa essencial da Etapa 1 no `avaliador_nota_qualidade.py` (`id_tarefa="etapa1_malha_estrada_picos"`, valendo `1000` pontos, elevando o máximo da Etapa 1 para `8000` e a nota máxima total de `7770` para `8770`).
  - Registrar as ferramentas MCP `aresta_gerar_malha_estrada` (para gerar a malha de estrada dos picos via MCP) e `aresta_avaliar_qualidade` (para inspecionar a nota de qualidade, pendências de publicação e ações recomendadas do croqui), documentando-as na skill `preencher_croqui_yaml`.
  - Refatorar `scripts/medir_saude_croquis.py` para que o `STATUS_CROQUIS.md` seja gerado diretamente como um dump estruturado do `avaliar_nota_qualidade_croqui`.

## Capabilities

### New Capabilities
- `geracao-e-qualidade-malha-estrada-editor`: Geração de malha viária no Editor Desktop e via MCP (`aresta_gerar_malha_estrada`), progresso em streaming do Overpass com confirmação manual (`Concluir`), validação no deploy (`verificar_malha_estrada_pico`), 8ª tarefa essencial de 1.000 pontos no Painel de Qualidade, ferramenta MCP `aresta_avaliar_qualidade` e relatório `STATUS_CROQUIS.md` baseado no avaliador de qualidade.

### Modified Capabilities
- `malha-distancia-estrada-offline`: Otimização do Dijkstra por menor tempo de viagem sem trânsito (`duracao_minutos`), armazenamento de `duracao_minutos` junto com `distancia_metros`, ampliação do raio de captura na KD-Tree para `25 km` (`6` vizinhos) e estimativa de tempo de acesso inicial $U \to K$ (`30 km/h` até `3 km` + `50 km/h` acima de `3 km`).
- `descoberta-picos-proximidade`: Ordenação por proximidade em duas faixas (1º picos alcançados pela malha local em até ~200 km ordenados por menor tempo estimado; 2º demais picos ordenados por menor distância em km), arredondamento da estimativa de tempo (`5 min` se `< 1h`, `10 min` se `>= 1h`) e `Tooltip` explicativo de estimativa sem trânsito com tempo e quilometragem.
- `catalogo-sqlite-sync`: Condensação e aplicação atômica de `nos_estrada` e `distancias_estrada` (incluindo `duracao_minutos` e `deletes.distancias_estrada` por `croqui_uid`) no endpoint `/sync` do Cloudflare Worker e no `RepositorioCatalogo.aplicarDelta`, além de migração in-place da tabela `catalogo_distancias_estrada`.

## Impact

- **`aresta_api`**: `proto/croqui.proto`, `sql/catalogo.sql`, `openapi/catalogo.yaml` e código gerado em Python, TypeScript e Dart.
- **`aresta_backend`**: `cloudflare/catalogo/src/index.ts` e `cloudflare/catalogo/src/index_test.ts`.
- **`aresta_db`**: `scripts/gerar_malha_estrada_lib.py`, `scripts/deploy_generated.py`, `scripts/gerar_catalogo_sqlite_lib.py`, `scripts/gerar_deltas_catalogo.py`, `serving/sincronizar_d1_lib.py`, `editor/views/widget_mensagem_coordenada.py`, `editor/core/avaliador_nota_qualidade.py`, `editor/mcp/ferramentas_comandos.py`, `editor/mcp/ferramentas_conhecimento.py`, `scripts/medir_saude_croquis.py`, `.agents/skills/preencher_croqui_yaml/SKILL.md` e `database/br_mg_lagoa_santa_gruta_da_lapinha/malha_estrada.yaml`.
- **`aresta_app`**: `lib/data/repositories/repositorio_catalogo.dart`, `lib/util/calculadora_distancia_estrada.dart`, `lib/ui/pages/home/funcoes_home.dart`, `lib/ui/pages/home/pico_proximo_view_model.dart`, `lib/ui/pages/home/home_view_model.dart`, `lib/ui/pages/browse/browse_view_model.dart`, `lib/ui/view_models/card_croqui_view_model.dart`, `lib/ui/widgets/crag_card.dart` e seus respectivos arquivos `_test.dart` espelhados 1:1.
