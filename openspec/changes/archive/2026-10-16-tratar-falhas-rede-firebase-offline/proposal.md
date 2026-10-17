# Proposal

## Why

Quando o aplicativo é aberto sem conexão com a internet (ou sem resolução de DNS, situação frequente em áreas de escalada), a chamada assíncrona `_remoteConfig.fetchAndActivate()` em `RemoteConfigService._initializeInternal` falha no SDK nativo do Android/iOS ao tentar obter o token de autenticação do Firebase Installations (`Firebase Installations failed to get installation auth token for fetch.`) ou ao contatar o backend do Remote Config (`The client had an error while calling the backend!`, `Unable to connect to the server`). Como o canal nativo (Pigeon/PlatformChannel) descarta a `IOException` subjacente e entrega ao Dart apenas uma `FirebaseException` com código `internal` ou `unavailable`, o método `AppLogger.isFalhaConexaoOuTimeout` não reconhece a exceção como falha transitória de rede, gerando falsos positivos de *Non-fatal Exception* no Firebase Crashlytics (tanto no `RemoteConfigService` quanto potencialmente no `AppCheckService.getToken`).

## What Changes

- **Expansão de `AppLogger.isFalhaConexaoOuTimeout` (`lib/services/firebase/app_logger.dart`)**:
  - Reconhecimento explícito de exceções nativas de conectividade e indisponibilidade oriundas dos SDKs do Firebase (`FirebaseException` e mensagens correlatas), incluindo falhas de obtenção de token do Firebase Installations (`firebase installations failed to get installation auth token`), falhas de cliente ao contatar o backend (`error while calling the backend`, `unable to connect to the server`, `fetch failed`), códigos/mensagens de serviço indisponível (`unavailable`, `network_error`, `network error`) e falhas de rede no App Check.
- **Resiliência no `RemoteConfigService` (`lib/services/firebase/remote_config.dart`)**:
  - Isolamento da etapa de rede (`fetchAndActivate`) após a definição garantida de `setDefaults` e `setConfigSettings`, assegurando que `FirebaseException` ou falhas transitórias de conectividade durante o `fetchAndActivate` sejam registradas exclusivamente como `logAviso` (breadcrumb no Crashlytics) e limpem `_initFuture` em caso de falha transitória para permitir nova tentativa futura na sessão caso `initialize()` volte a ser invocado.
- **Tratamento de falhas de rede no `AppCheckService.getToken` (`lib/services/firebase/validador_app.dart`)**:
  - Verificação via `AppLogger.isFalhaConexaoOuTimeout(e)` no bloco `catch` de `getToken()`, registrando falhas de conectividade como `logAviso` (breadcrumb) em vez de `logError` quando o dispositivo tentar despachar feedbacks pendentes sem conexão.
- **Atualização de Documentação (`frontend/README.md`)**:
  - Documentação do comportamento de degradação graciosa e silenciamento de alertas falsos do Firebase (Remote Config e App Check) em operação offline.

## Capabilities

### New Capabilities

### Modified Capabilities
- `padronizacao-logging-applogger`: Ampliação da classificação de falhas transitórias de conexão (`isFalhaConexaoOuTimeout`) para abranger erros de rede encapsulados por SDKs nativos do Firebase (`FirebaseException` de Installations, Remote Config e App Check) e uso de `logAviso` no `AppCheckService.getToken` quando offline.
- `offline-first-initialization`: Garantia de que a sincronização em segundo plano do `RemoteConfigService` degrade silenciosamente via breadcrumb (`logAviso`) sem registrar erros não-fatais no Crashlytics quando o dispositivo iniciar sem internet e permita nova tentativa posterior se a inicialização falhar por ausência de rede.

## Impact

- **Código Afetado (`frontend/lib/`)**:
  - `lib/services/firebase/app_logger.dart`
  - `lib/services/firebase/remote_config.dart`
  - `lib/services/firebase/validador_app.dart`
- **Testes Afetados (`frontend/test/`)**:
  - `test/services/firebase/app_logger_test.dart`
  - `test/services/firebase/remote_config_test.dart`
  - `test/services/firebase/validador_app_test.dart`
- **Documentação Afetada**:
  - `frontend/README.md`
