# Tasks

## 1. Minimização Não-Destrutiva da Tarefa ao Sair pela Raiz da Navegação

- [x] 1.1 Escrever testes comportamentais em `frontend/test/navigation/funcoes_navegacao_test.dart` e `frontend/test/navigation/wrapper_navegacao_arvore_test.dart` validando que o retorno na raiz da `HomeNode` invoca o canal `"app.escalada.croquis/ciclo_vida"` (`minimizarTarefa`) e realiza fallback para `SystemNavigator.pop()` quando o canal não está registrado ou retorna `false` (ciclo Red do TDD).
- [x] 1.2 Implementar o `MethodChannel("app.escalada.croquis/ciclo_vida")` em `frontend/android/app/src/main/kotlin/com/example/frontend/MainActivity.kt` chamando `moveTaskToBack(true)` e a função `minimizarAplicativo()` integrada ao `PopScope` de `frontend/lib/navigation/wrapper_navegacao_arvore.dart`, verificando que `flutter test test/navigation/funcoes_navegacao_test.dart test/navigation/wrapper_navegacao_arvore_test.dart` passa com 100% de cobertura.

## 2. Garantia de Saída da `TelaSplashInicial` e Preservação da `DatabaseMigrationScreen`

- [x] 2.1 Escrever testes em `frontend/test/services/inicializacao_app_test.dart` e `frontend/test/main_test.dart` para: (a) timeout e exceção em `resolverDestinoInicialColdStart` retornando `HomeNode` com log de aviso; (b) falha na `Future` `resolucaoInicialColdStart` em `MyApp` liberando `_aguardandoColdStart = false`; e (c) preservação integral do bloqueio da `DatabaseMigrationScreen` quando `needsMigration == true` (ciclo Red do TDD).
- [x] 2.2 Implementar o `timeoutResolucao` e tratamento de exceções em `resolverDestinoInicialColdStart` (`frontend/lib/services/inicializacao_app.dart`) e o `.catchError` defensivo em `_MyAppState.initState` (`frontend/lib/main.dart`), verificando que `flutter test test/services/inicializacao_app_test.dart test/main_test.dart` passa com 100% de cobertura comportamental.

## 3. Timeouts Defensivos nas Operações de Pré-Boot

- [x] 3.1 Escrever testes em `frontend/test/application_managers/migracao/migracao_background_orchestrator_test.dart` e `frontend/test/services/inicializacao_app_test.dart` cobrindo o limite de tempo defensivo no cancelamento da migração em segundo plano (`cancelarMigracaoSegundoPlano`) e nas etapas de pré-boot sem bloquear a inicialização (ciclo Red do TDD).
- [x] 3.2 Implementar o `timeout` defensivo em `MigracaoBackgroundOrchestrator.cancelarMigracaoSegundoPlano` (`frontend/lib/application_managers/migracao/migracao_background_orchestrator.dart`) e nas etapas de pré-boot em `frontend/lib/services/inicializacao_app.dart` / `frontend/lib/main.dart`, atualizando docstrings e verificando que todos os testes dos módulos afetados passam com 100% de cobertura.
