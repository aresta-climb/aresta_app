# Tasks

## 1. Contratos Unificados em `aresta_api` (Protobuf, SQL e OpenAPI)

- [x] 1.1 Escrever testes em `aresta_api/tests/` validando a presença do campo `duracao_minutos = 6` em `NoMalhaEstrada` (`proto/croqui.proto`), da coluna `duracao_minutos INTEGER NOT NULL DEFAULT 0` em `catalogo_distancias_estrada` (`sql/catalogo.sql`) e de `duracao_minutos` em `CatalogoDistanciaEstrada` + `distancias_estrada` em `DeletesSyncCatalogo` (`openapi/catalogo.yaml`), verificando a falha inicial (Red)
- [x] 1.2 Atualizar `proto/croqui.proto`, `sql/catalogo.sql` e `openapi/catalogo.yaml` em `aresta_api`, executar `python build.py` e verificar que `pytest` passa com 100% de sucesso (Green)
- [x] 1.3 Sincronizar o submódulo `aresta_api` atualizado em `aresta_db`, `aresta_backend` e `aresta_app`, regenerando os artefatos locais quando aplicável

## 2. Sincronização Incremental (`apply_delta`) no Cloudflare Worker (`aresta_backend`)

- [x] 2.1 Adicionar testes em `aresta_backend/cloudflare/catalogo/src/index_test.ts` cobrindo a condensação de `nos_estrada` (`upserts` por `no_osm_id` e `deletes`) e `distancias_estrada` (`upserts` por `croqui_uid:no_osm_id` com `duracao_minutos` e limpeza via `deletes.distancias_estrada` / `deletes.croquis`) em `condensarDeltas`, verificando a falha inicial (Red)
- [x] 2.2 Implementar a condensação de `nos_estrada` e `distancias_estrada` em `aresta_backend/cloudflare/catalogo/src/index.ts` e verificar que toda a suíte de testes do Worker passa (Green)

## 3. Dijkstra por Tempo, Progresso Overpass, Deploy e Catálogo SQLite/D1 (`aresta_db`)

- [x] 3.1 Escrever testes em `aresta_db/tests/test_deploy_generated.py` para `verificar_malha_estrada_pico` recebendo `malha_estrada` com wrapper `{"conteudo": {"latitude_referencia_e7": ..., "longitude_referencia_e7": ..., "nos": [...]}}` e corrigir `scripts/deploy_generated.py` usando `malha_estrada_pico_atualizada(pico)`, verificando que `pytest tests/test_deploy_generated.py` passa
- [x] 3.2 Escrever testes em `aresta_db/tests/test_gerar_malha_estrada_lib.py` para: (a) cálculo de velocidade sem trânsito por `(highway, surface, maxspeed)` e escolha do caminho mais rápido (`duracao_minutos` + `distancia_metros`) no Dijkstra invertido; e (b) leitura em streaming por blocos em `ClienteOverpass.consultar_malha` com emissão de progresso em MB (`15%` a `42%`) e cancelamento imediato entre blocos, verificando a falha inicial (Red)
- [x] 3.3 Implementar o cálculo de velocidade sem trânsito, o Dijkstra por menor tempo (`duracao_minutos`) e o streaming com progresso em `aresta_db/scripts/gerar_malha_estrada_lib.py`, verificando que `pytest tests/test_gerar_malha_estrada_lib.py` passa com 100% de cobertura (Green)
- [x] 3.4 Escrever teste em `aresta_db/tests/editor/views/test_widget_mensagem_coordenada.py` garantindo que `DialogoProgressoMalhaEstrada._ao_concluir` mantém a janela aberta ao atingir 100% e habilita o botão `Concluir` para fechamento manual pelo usuário, e implementar o comportamento em `editor/views/widget_mensagem_coordenada.py`
- [x] 3.5 Escrever testes e atualizar `aresta_db/scripts/gerar_catalogo_sqlite_lib.py`, `aresta_db/scripts/gerar_deltas_catalogo.py` e `aresta_db/serving/sincronizar_d1_lib.py` para persistir `duracao_minutos` em `catalogo_distancias_estrada` (com migração in-place se a coluna faltar), incluí-lo em `calcular_versao_catalogo` e no CSV, e emitir `deletes.distancias_estrada` em `gerar_payload_d1`, verificando com `pytest`

## 4. Ferramentas MCP, 8ª Tarefa do Painel de Qualidade e `STATUS_CROQUIS.md` (`aresta_db`)

- [x] 4.1 Escrever testes em `aresta_db/tests/editor/core/test_avaliador_nota_qualidade.py` para a 8ª tarefa essencial da Etapa 1 (`etapa1_malha_estrada_picos`, valendo `1000` pontos, máximo da Etapa 1 = `8000`, nota máxima total = `8770`) e implementá-la em `editor/core/avaliador_nota_qualidade.py`, verificando com `pytest`
- [x] 4.2 Escrever testes e registrar as ferramentas MCP `aresta_gerar_malha_estrada` (em `editor/mcp/ferramentas_comandos.py`) e `aresta_avaliar_qualidade` (em `editor/mcp/ferramentas_conhecimento.py`), atualizando `.agents/skills/preencher_croqui_yaml/SKILL.md` e verificando os testes do servidor MCP
- [x] 4.3 Escrever testes em `aresta_db/tests/test_medir_saude_croquis.py` e refatorar `scripts/medir_saude_croquis.py` para gerar `STATUS_CROQUIS.md` diretamente a partir de `avaliar_nota_qualidade_croqui`, verificando que os testes passam
- [x] 4.4 Atualizar `database/br_mg_lagoa_santa_gruta_da_lapinha/malha_estrada.yaml` e os artefatos de catálogo (`catalogo.db` / CSVs) com `duracao_minutos` preenchido

## 5. `RepositorioCatalogo`, `CalculadoraDistanciaEstrada`, Ordenação em 2 Faixas e Tooltip (`aresta_app`)

- [x] 5.1 Escrever testes em `test/data/repositories/repositorio_catalogo_test.dart` cobrindo: (a) migração automática de `catalogo_distancias_estrada` quando não possui a coluna `duracao_minutos`; (b) limpeza de `deletes.distancias_estrada` e gravação de `duracao_minutos` em `aplicarDelta`; e (c) leitura de `duracaoMinutos` em `carregarMalhaEstrada`, e implementar em `lib/data/repositories/repositorio_catalogo.dart`
- [x] 5.2 Escrever testes em `test/util/calculadora_distancia_estrada_test.dart` cobrindo: (a) raio de captura de `25 km` com até `6` vizinhos na KD-Tree; (b) cálculo do tempo de acesso $U \to K$ (`30 km/h` até `3 km` + `50 km/h` acima de `3 km`) e seleção do nó que minimiza o tempo total; (c) retorno de `EstimativaViagemPico` com `duracaoMinutos` (quando alcançado pela malha local) e `distanciaMetros`; e (d) formatação arredondada de tempo (`5 min` se `< 60 min`, `10 min` se `>= 60 min`) e texto do tooltip (`"Estimativa sem trânsito: ~X min (Y.Z km)"`), implementando em `lib/util/calculadora_distancia_estrada.dart` com 100% de cobertura
- [x] 5.3 Escrever testes e atualizar `lib/ui/pages/home/pico_proximo_view_model.dart`, `lib/ui/pages/home/funcoes_home.dart`, `lib/ui/pages/home/home_view_model.dart`, `lib/ui/pages/browse/browse_view_model.dart` e `lib/ui/view_models/card_croqui_view_model.dart` para ordenar por proximidade em duas faixas (1º picos com estimativa de tempo ordenados por minutos; 2º demais picos ordenados por km) e propagar o texto do badge (`~40 min` ou `42.0 km`) e do tooltip
- [x] 5.4 Escrever testes de widget em `test/ui/widgets/crag_card_test.dart` e `test/ui/pages/home/secao_picos_proximos_test.dart` validando a exibição do badge de tempo arredondado e do `Tooltip` explicativo (`"Estimativa sem trânsito: ..."`), implementando nos widgets correspondentes e garantindo 100% de cobertura nas linhas alteradas
