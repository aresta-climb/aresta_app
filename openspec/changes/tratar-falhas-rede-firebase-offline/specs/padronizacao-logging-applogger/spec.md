# Spec Delta

## ADDED Requirements

### Requirement: Reconhecimento de Falhas de Rede Nativas de SDKs do Firebase
O método `AppLogger.isFalhaConexaoOuTimeout` SHALL reconhecer exceções e mensagens de erro originadas nos SDKs nativos do Firebase (`FirebaseException`, Firebase Installations, Firebase Remote Config e Firebase App Check) quando decorrentes de indisponibilidade de rede, falha ao obter token de instalação para busca ou falha de comunicação do cliente com o backend.

#### Scenario: Falha ao obter token do Firebase Installations durante fetch do Remote Config
- **WHEN** `AppLogger.isFalhaConexaoOuTimeout` for invocado com uma exceção contendo `[firebase_remote_config/internal] Firebase Installations failed to get installation auth token for fetch.`
- **THEN** o método DEVE retornar `true`.

#### Scenario: Falha de comunicação do cliente nativo do Firebase com o backend
- **WHEN** `AppLogger.isFalhaConexaoOuTimeout` for invocado com uma `FirebaseException` de código `unavailable` ou `network-request-failed`, ou mensagem contendo `the client had an error while calling the backend`, `unable to connect to the server` ou `fetch failed`
- **THEN** o método DEVE retornar `true`.

#### Scenario: Falha de rede ao obter token do App Check
- **WHEN** `AppCheckService.instance.getToken()` capturar uma exceção de rede ou indisponibilidade reconhecida por `AppLogger.isFalhaConexaoOuTimeout`
- **THEN** o serviço DEVE registrar a ocorrência via `AppLogger.instance.logAviso` (breadcrumb) em vez de `logError`, retornando `null` sem abrir issue não-fatal no Crashlytics.
