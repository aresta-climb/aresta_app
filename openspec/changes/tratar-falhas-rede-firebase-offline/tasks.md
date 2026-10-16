# Tasks

## 1. Reconhecimento de Exceções Nativas do Firebase no `AppLogger`

- [ ] 1.1 Escrever testes unitários (TDD Red) em `frontend/test/services/firebase/app_logger_test.dart` validando que `AppLogger.isFalhaConexaoOuTimeout` retorna `true` para `FirebaseException` com falha do Firebase Installations (`Firebase Installations failed to get installation auth token for fetch.`), falhas de cliente ao contatar o backend (`The client had an error while calling the backend!`, `Unable to connect to the server`, `Fetch failed`) e códigos `unavailable` / `network-request-failed`, verificando a falha inicial com `flutter test test/services/firebase/app_logger_test.dart`.
- [ ] 1.2 Atualizar `AppLogger.isFalhaConexaoOuTimeout` e suas docstrings em `frontend/lib/services/firebase/app_logger.dart` (TDD Green) para reconhecer códigos e mensagens de falha de conectividade dos SDKs nativos do Firebase, verificando que todos os testes passam com `flutter test test/services/firebase/app_logger_test.dart`.

## 2. Resiliência e Retentativa Futura no `RemoteConfigService` e `AppCheckService`

- [ ] 2.1 Escrever testes unitários (TDD Red) em `frontend/test/services/firebase/remote_config_test.dart` e `frontend/test/services/firebase/validador_app_test.dart` validando que: (a) a exceção `[firebase_remote_config/internal] Firebase Installations failed to get installation auth token for fetch.` é registrada como `logAviso` sem acionar `logError` e limpa `_initFuture` permitindo nova chamada a `initialize()`; e (b) falhas de rede em `AppCheckService.getToken()` registram `logAviso` em vez de `logError`, verificando a falha inicial com `flutter test test/services/firebase/remote_config_test.dart test/services/firebase/validador_app_test.dart`.
- [ ] 2.2 Atualizar `frontend/lib/services/firebase/remote_config.dart` e `frontend/lib/services/firebase/validador_app.dart` (TDD Green + Docstrings) para limpar `_initFuture` em falhas transitórias do `RemoteConfigService` e utilizar `AppLogger.isFalhaConexaoOuTimeout` com `logAviso` em `AppCheckService.getToken()`, verificando que os testes passam com `flutter test test/services/firebase/remote_config_test.dart test/services/firebase/validador_app_test.dart`.
- [ ] 2.3 Atualizar a seção de telemetria/logging em `frontend/README.md` documentando o tratamento de falhas transitórias dos SDKs nativos do Firebase (`RemoteConfigService` e `AppCheckService`) quando offline e verificar a integridade da documentação.

## 3. Verificação Integrada e Conformidade Arquitetural

- [ ] 3.1 Executar a suíte completa de testes de serviços Firebase e testes arquiteturais (`flutter test test/services/firebase/ test/architecture/`) e `flutter analyze` garantindo zero avisos e 100% de aprovação.
