# Spec Delta

## MODIFIED Requirements

### Requirement: Rastreamento Obrigatório de Pilha (StackTrace) no Registro de Erros
O `AppLogger` SHALL exigir obrigatoriamente um parâmetro de rastreamento de pilha (`required StackTrace stackTrace`) nos métodos de registro de falhas `logError`, `logCrash` e `logFalhaSyncOuDownload`, garantindo que nenhuma falha seja registrada no Firebase Crashlytics ou no Sentry sem as informações de rastreamento da linha e arquivo de origem.

#### Scenario: Registro de erro não-fatal com rastreamento de pilha obrigatório
- **WHEN** o método `AppLogger.instance.logError` for invocado com uma mensagem de contexto, um objeto de erro e o respectivo `stackTrace` obrigatório
- **THEN** o sistema DEVE repassar o erro e o `stackTrace` tanto ao Firebase Crashlytics quanto ao Sentry (`Sentry.captureException`) e, em modo debug, imprimir a pilha de execução formatada no console.

#### Scenario: Registro de falha crítica ou de sincronização com rastreamento de pilha
- **WHEN** `logCrash` ou `logFalhaSyncOuDownload` (para erro que não seja falha de conexão/timeout) for invocado com erro e `stackTrace` obrigatório
- **THEN** o sistema DEVE encaminhar o `stackTrace` intacto para a chamada subjacente do Crashlytics e do Sentry (marcando o nível como `SentryLevel.fatal` quando `fatal == true`).

### Requirement: Suporte a Mensagens Informativas e Breadcrumbs
O `AppLogger` SHALL fornecer os métodos `logInfo` e `logAviso` com nomes e parâmetros em português brasileiro para rastreamento de ciclo de vida e eventos operacionais. Em modo de desenvolvimento (`kDebugMode`), os métodos DEVEM imprimir mensagens formatadas no console. Em modo de produção/release, os métodos DEVEM registrar breadcrumbs de diagnóstico simultaneamente no Firebase Crashlytics (`FirebaseCrashlytics.instance.log`) e no Sentry (`Sentry.addBreadcrumb`) sem poluir a lista de erros não-fatais.

#### Scenario: Registro de log informativo em modo debug
- **WHEN** `AppLogger.instance.logInfo("Mensagem informativa")` for chamado em ambiente com debug ativado
- **THEN** o sistema DEVE emitir a mensagem formatada para o console local utilizando o prefixo informativo.

#### Scenario: Registro de breadcrumbs em modo release
- **WHEN** `AppLogger.instance.logInfo("Sincronização iniciada")` ou `AppLogger.instance.logAviso("Cache expirado")` for chamado em ambiente de produção (release)
- **THEN** o sistema DEVE registrar a mensagem no Firebase Crashlytics através de `FirebaseCrashlytics.instance.log` e adicionar um `Breadcrumb` correspondente no Sentry (`SentryLevel.info` para `logInfo` e `SentryLevel.warning` para `logAviso`).
