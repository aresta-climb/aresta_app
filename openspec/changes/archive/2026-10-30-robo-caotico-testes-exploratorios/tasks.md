# Tasks

## 1. Acoplamento de Contextos Extras no Sentry (`AppLogger`)

- [x] 1.1 Escrever testes comportamentais em `frontend/test/services/firebase/app_logger_test.dart` verificando que `AppLogger.configurarEscopoSentry`, `logError` e `logCrash` anexam `contextosExtras` (como `receita_robo_caotico`) no `Scope` do Sentry mantendo `contexto_erro` e os breadcrumbs normais intactos, e confirmar que falham antes da implementação (*Red*).
- [x] 1.2 Atualizar `frontend/lib/services/firebase/app_logger.dart` adicionando o parâmetro opcional `Map<String, Map<String, dynamic>>? contextosExtras` em `configurarEscopoSentry`, `_registrarExcecaoSentry`, `logError` e `logCrash` com docstrings em português, e validar com `flutter test test/services/firebase/app_logger_test.dart --coverage` atingindo 100% de cobertura (*Green*).

## 2. Modelos de Receita, Seletores e Encolhedor por Busca Binária (`ddmin`)

- [x] 2.1 Criar os testes espelhados em `frontend/test/caos/receita_crash_robo_test.dart` e `frontend/test/caos/encolhedor_caminho_crash_test.dart` validando a serialização/desserialização JSON de `PassoRobo`, `SeletorAlvoRobo` e `ReceitaCrashRobo`, bem como a redução por busca binária (`EncolhedorCaminhoCrash.encolher`) de sequências longas para `passosMinimos`, confirmando a falha inicial (*Red*).
- [x] 2.2 Implementar `frontend/test/caos/receita_crash_robo.dart` e `frontend/test/caos/encolhedor_caminho_crash.dart` em português com docstrings explicativas, e executar `flutter test test/caos/receita_crash_robo_test.dart test/caos/encolhedor_caminho_crash_test.dart` confirmando 100% de aprovação (*Green*).

## 3. Fábrica de Datasets Normal e Tóxico (`FabricaDatasetCaos`)

- [x] 3.1 Criar o teste `frontend/test/caos/fabrica_dataset_caos_test.dart` verificando que `FabricaDatasetCaos` constrói instâncias determinísticas de `ConjuntoDadosCroqui` e registros de Caderneta nos perfis `TipoDatasetCaos.normal` e `TipoDatasetCaos.toxico` (incluindo picos sem setores, setores sem vias/imagens, textos de 300+ caracteres com emojis/Markdown limite, graus exóticos/vazios, alto volume de vias e cadenas órfãs) (*Red*).
- [x] 3.2 Implementar `frontend/test/caos/fabrica_dataset_caos.dart` gerando os modelos Protobuf (`Indice`, `Croqui`, `Pico`, `Setor`, `Escalada`) e dados de Caderneta para ambos os perfis, e validar com `flutter test test/caos/fabrica_dataset_caos_test.dart` (*Green*).

## 4. Motor do Robô Caótico (`MotorRoboCaotico`) e Suíte de Regressão

- [x] 4.1 Criar o teste `frontend/test/caos/motor_robo_caotico_test.dart` verificando: (a) determinismo de caminhada para a mesma `seed`, (b) descoberta e execução de ações (`tap`, `scroll`, `digitarTexto`, `voltarSistema`, `voltarAppNav`, eventos de `SyncService`/conectividade) com alternância temporal (`pump` parcial vs `pumpAndSettle`), (c) captura de crash com geração da `ReceitaCrashRobo` encolhida e envio opcional ao `AppLogger.logCrash`, e (d) execução de campanha por orçamento de tempo (`executarCampanhaPorTempo`) que percorre o período completo, deduplica falhas pela assinatura e reporta todas as falhas encontradas ao final (*Red*).
- [x] 4.2 Implementar `frontend/test/caos/motor_robo_caotico.dart` sobre `WidgetTester` e validar todos os cenários executando `flutter test test/caos/motor_robo_caotico_test.dart` (*Green*).
- [x] 4.3 Criar a suíte exploratória `frontend/test/caos/robo_caotico_exploratorio_test.dart` (suportando `--dart-define=DURACAO_CAMPANHA_CAOS_SEGUNDOS`), a suíte permanente de regressão `frontend/test/caos/regressao_caminhos_test.dart` (com uma receita inaugural em `frontend/test/caos/caminhos_regressao/`) e o entrypoint de dispositivo `frontend/integration_test/robo_caotico_dispositivo_test.dart`, verificando a execução com `flutter test test/caos/`.
- [x] 4.4 Atualizar `.github/workflows/release_new_app_version.yml` no job `prepare_release` (antes do commit e criação da tag) para executar a suíte de testes de regressão e a campanha de 5 minutos (`DURACAO_CAMPANHA_CAOS_SEGUNDOS=300` e `REPORTAR_SENTRY_CAOS=true`) do robô caótico, publicando eventuais receitas `.json` geradas como artefato do workflow e bloqueando o deploy caso qualquer falha seja encontrada.

## 5. Skill `diagnosticar-issue-sentry` e Documentação

- [x] 5.1 Garantir que a skill `.agent/skills/diagnosticar-issue-sentry/SKILL.md` (e `.agents/skills/diagnosticar-issue-sentry/SKILL.md`) esteja presente e atualizada nos quatro repositórios conectados ao Sentry (`aresta_app`, `aresta_db`, `aresta_backend`, `arestaclimb.com`), documentando a configuração e uso do MCP do Sentry a partir de Issues do GitHub e o fluxo de conversão de `receita_robo_caotico` em teste de regressão, e atualizar o `README.md` de testes com os comandos de execução do robô caótico.
