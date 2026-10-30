# padronizacao-logging-applogger Specification Delta

## ADDED Requirements

### Requirement: Acoplamento de Contextos Estruturados Extras no Escopo do Sentry
Os métodos `AppLogger.instance.logError`, `AppLogger.instance.logCrash` e `AppLogger.configurarEscopoSentry` SHALL aceitar um parâmetro opcional `Map<String, Map<String, dynamic>>? contextosExtras` para anexar objetos de diagnóstico estruturados (como `receita_robo_caotico` contendo a receita JSON de reprodução, `seed`, `dataset` e instruções de regressão) diretamente no `Scope` do evento enviado ao Sentry (`scope.setContexts(chave, valor)`), mantendo os breadcrumbs normais do aplicativo (`Sentry.addBreadcrumb`) estritamente restritos aos eventos reais de telemetria e ciclo de vida do app.

#### Scenario: Envio de crash fatal do robô caótico com receita acoplada no Sentry
- **WHEN** `AppLogger.instance.logCrash` é invocado pelo motor do robô caótico passando `contextosExtras: {'receita_robo_caotico': receita.toJson()}`
- **THEN** o `AppLogger` DEVE configurar o `Scope` do Sentry com `SentryLevel.fatal`, registrar o contexto padrão `contexto_erro` e registrar adicionalmente `scope.setContexts('receita_robo_caotico', ...)` sem poluir a trilha de breadcrumbs normais do aplicativo.
