# Proposal

## Why

Os relatórios de pré-lançamento do Google Play Console (Robo Tests) têm identificado crashes sutis causados por sequências não-óbvias de navegação, exclusão de estado local e cliques durante animações de transição de tela (como a desmontagem de `State` com modais abertos) que não são alcançados por testes unitários e de widget de caminho feliz. Além disso, com a depreciação oficial do Firebase Test Lab e a ausência de um crawler automático equivalente no novo Google Cloud Developer Device Platform (`gcloud beta device-run`, especialmente para iOS), precisamos de uma infraestrutura própria de testes exploratórios caóticos determinísticos que encontre falhas automaticamente, encolha o caminho até a menor sequência reproduzível, anexe a receita no Sentry (abrindo issue no GitHub via nosso worker de alertas) e converta cada crash em teste de regressão permanente.

## What Changes

- **Motor de Robô Caótico Determinístico (`MotorRoboCaotico`)**: Criar uma biblioteca modular em `frontend/test/caos/` baseada na interface `WidgetTester` (compatível tanto com `flutter test` em memória quanto com `integration_test` em dispositivos Android e iOS reais no Google Cloud Developer Device Platform). O robô descobre dinamicamente widgets interativos (`hitTestable`), sorteia ações guiadas por `Random(seed)` (toques, rolagem, entrada de texto fuzz, botão voltar do sistema/`AppNav.back`, eventos assíncronos de `SyncService` e transições de conectividade) e alterna entre `pumpAndSettle()` e avanços parciais de relógio (`pump(50ms..350ms)`) para capturar falhas no meio de transições e ciclos de `dispose()`.
- **Fábrica de Datasets Normal e Tóxico (`FabricaDatasetCaos`)**: Criar geradores determinísticos de estado inicial para alimentar o robô tanto com um catálogo realista quanto com um **Dataset Tóxico de Estresse** (picos sem setores, setores sem vias/imagens, textos de 300+ caracteres sem espaços/com emojis e Markdown extremo, graus de escalada exóticos/vazios, picos com alto volume de vias/traçados vetoriais e cadenas órfãs na Caderneta).
- **Encolhedor de Caminhos por Busca Binária (`EncolhedorCaminhoCrash`) e Receita JSON (`ReceitaCrashRobo`)**: Implementar o algoritmo *Delta Debugging* (`ddmin`) que, ao detectar uma exceção ou violação de invariante durante a exploração caótica, poda iterativamente blocos de passos usando busca binária até isolar a sequência mínima (`passosMinimos`) que reproduz o mesmo erro, salvando tanto os passos mínimos quanto os passos originais em `frontend/test/caos/caminhos_regressao/`.
- **Suíte Permanente de Regressão de Caminhos (`regressao_caminhos_test.dart`), Campanha por Tempo (`CampanhaRoboCaotico`) e Gate de Release (`release_new_app_version.yml`)**:
  - Criar o executor de regressão que lê automaticamente todos os arquivos `.json` em `frontend/test/caos/caminhos_regressao/` e reexecuta cada receita em `< 1s` durante o `flutter test`.
  - Implementar o modo de **Campanha por Orçamento de Tempo** (ex: 5 minutos ininterruptos via `--dart-define=DURACAO_CAMPANHA_CAOS_SEGUNDOS=300`) que executa seeds continuamente até esgotar o tempo, deduplica falhas pela assinatura (`tipoExcecao + framePrincipal`), realiza o shrinking e o envio ao Sentry para cada falha inédita e, ao final do período, consolida todas as falhas encontradas e falha o teste para bloquear o deploy.
  - Integrar no job `prepare_release` de `.github/workflows/release_new_app_version.yml` (antes do commit/tag da versão) a execução da suíte de testes e da campanha de 5 minutos do robô caótico (com upload das receitas JSON como artefato em caso de falha), além do entrypoint `frontend/integration_test/robo_caotico_dispositivo_test.dart`.
- **Acoplamento da Receita de Reprodução no Sentry (`AppLogger`) e Skill de Diagnóstico via MCP (`diagnosticar-issue-sentry`)**: Estender `AppLogger` para permitir acoplar o contexto estruturado `receita_robo_caotico` no `Scope` do Sentry ao reportar um crash fatal (preservando integralmente os breadcrumbs normais do aplicativo gerados por `TelemetryService` e `AppLogger`), permitindo que o `aresta-alertas-worker` abra a Issue no GitHub com o link do Sentry, e adicionar a skill `diagnosticar-issue-sentry` nos repositórios do ecossistema (`aresta_app`, `aresta_db`, `aresta_backend`, `arestaclimb.com`) instruindo o agente a consultar o Sentry via MCP a partir da Issue do GitHub e promover a receita JSON a teste de regressão.

## Capabilities

### New Capabilities
- `robo-caotico-testes-exploratorios`: Infraestrutura de testes exploratórios caóticos determinísticos em UI (`flutter_test` e `integration_test`), geração de Dataset Normal e Dataset Tóxico, encolhimento de caminhos de crash por busca binária (`ddmin`), campanhas por orçamento de tempo com deduplicação de falhas no pipeline de release e execução automática de regressão.

### Modified Capabilities
- `padronizacao-logging-applogger`: Permitir anexar contextos adicionais estruturados no `Scope` do Sentry (`contextosExtras`, como `receita_robo_caotico`) em `AppLogger.logError` e `AppLogger.logCrash`, mantendo os breadcrumbs normais do aplicativo inalterados.

## Impact

- `frontend/lib/services/firebase/app_logger.dart` e `frontend/test/services/firebase/app_logger_test.dart`
- `frontend/test/caos/` (`motor_robo_caotico.dart`, `fabrica_dataset_caos.dart`, `encolhedor_caminho_crash.dart`, `receita_crash_robo.dart`, `robo_caotico_exploratorio_test.dart`, `regressao_caminhos_test.dart` e pasta `caminhos_regressao/`)
- `frontend/integration_test/robo_caotico_dispositivo_test.dart`
- `.github/workflows/release_new_app_version.yml`
- `.agent/skills/diagnosticar-issue-sentry/SKILL.md` e `.agents/skills/diagnosticar-issue-sentry/SKILL.md` (em `aresta_app`, `aresta_db`, `aresta_backend` e `arestaclimb.com`)
