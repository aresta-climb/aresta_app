# Tasks

## 1. Configuração de Release do Android (`isShrinkResources = false`)

- [x] 1.1 Alterar `isShrinkResources = false` mantendo `isMinifyEnabled = true` no bloco `buildTypes.release` de `frontend/android/app/build.gradle.kts` e verificar a configuração da variante de release.

## 2. Inicialização Determinística, Paralelizada e Sem Timeouts Redundantes

- [x] 2.1 Escrever e atualizar os testes em `frontend/test/services/firebase/inicializar_firebase_test.dart`, `frontend/test/services/inicializacao_app_test.dart`, `frontend/test/application_managers/migracao/migracao_background_orchestrator_test.dart` e `frontend/test/main_test.dart` (ciclo Red) validando a execução paralela pós-`Firebase.initializeApp()` em `initFirebase()`, a espera determinística sem timeouts nas etapas locais de pré-boot e a preservação de `itemSemConexaoInicial` sem timeout redundante em `resolverDestinoInicialColdStart`.
- [x] 2.2 Paralelizar com `Future.wait` as chamadas `AppCheckService.instance.activate()`, `initCrashlytics()`, `initAnalytics()` e `initPerformance()` após `await (initializer ?? Firebase.initializeApp)()` em `frontend/lib/services/firebase/inicializar_firebase.dart` e verificar que `flutter test test/services/firebase/inicializar_firebase_test.dart --coverage` passa com 100% de cobertura.
- [x] 2.3 Remover `executarEtapaPreBootComTimeout` de `frontend/lib/services/inicializacao_app.dart` e `frontend/lib/main.dart`, remover o `.timeout` em `MigracaoBackgroundOrchestrator.cancelarMigracaoSegundoPlano` (`frontend/lib/application_managers/migracao/migracao_background_orchestrator.dart`) e remover `timeoutResolucao` de `resolverDestinoInicialColdStart`, e verificar que os testes de `inicializacao_app_test.dart`, `migracao_background_orchestrator_test.dart` e `main_test.dart` passam com 100% de cobertura.

## 3. Guarda Defensiva `AppLogger.firebaseInicializado` nos Serviços Firebase

- [x] 3.1 Escrever testes comportamentais (ciclo Red) em `frontend/test/services/firebase/remote_config_test.dart`, `frontend/test/services/firebase/performance_telemetria_test.dart` e `frontend/test/services/firebase/telemetria_test.dart` verificando que os serviços degradam silenciosamente sem lançar `[core/no-app]` nem reportar erro ao `AppLogger.logError` quando `AppLogger.firebaseInicializado` é `false` e nenhum override de teste foi injetado.
- [x] 3.2 Implementar a verificação defensiva de `AppLogger.firebaseInicializado` (quando a instância injetada for `null`) em `frontend/lib/services/firebase/remote_config.dart`, `frontend/lib/services/firebase/performance_telemetria.dart` e `frontend/lib/services/firebase/telemetria.dart` (ciclo Green/Refactor) e verificar que os três arquivos de teste passam com 100% de cobertura de linhas.
