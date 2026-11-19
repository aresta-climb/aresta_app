# Spec Delta: padronizacao-logging-applogger

## ADDED Requirements

### Requirement: Inspeção de Códigos de Status HTTP na Classificação de Desconexão
O método `AppLogger.isFalhaConexaoOuTimeout` MUST inspecionar códigos de status HTTP presentes em exceções tipadas de resposta HTTP e em mensagens de `HttpException` antes de classificá-las como falha transitória de conectividade. Apenas códigos HTTP transitórios de gateway, timeout ou rate-limit (`408`, `429`, `502`, `503` e `504`) ou exceções puras de transporte sem código de status HTTP MUST retornar `true`; códigos definitivos de cliente, autenticação, autorização ou erro interno do servidor (como `400`, `401`, `403`, `404`, `422` e `500`) MUST retornar `false` para que sejam registrados como erros reais no Sentry e no Crashlytics.

#### Scenario: HttpException contendo erro HTTP 400 ou 500 não é rebaixada para aviso offline
- **WHEN** `AppLogger.isFalhaConexaoOuTimeout` recebe uma `HttpException` ou exceção de serviço contendo status HTTP `400`, `401`, `403`, `404`, `422` ou `500` (ex.: `HttpException: Falha ao autenticar no Supabase (400): provider_disabled`)
- **THEN** o método MUST retornar `false`, garantindo que a falha seja enviada como erro real com `StackTrace` ao Sentry e ao Crashlytics

#### Scenario: HttpException pura de transporte ou com código HTTP transitório retorna verdadeiro
- **WHEN** `AppLogger.isFalhaConexaoOuTimeout` recebe uma `HttpException('Connection closed before full header was received')` sem código HTTP ou com status transitório (`408`, `429`, `502`, `503`, `504`)
- **THEN** o método MUST retornar `true`, permitindo o rebaixamento para `logAviso`

## MODIFIED Requirements

### Requirement: Propagação Completa de Exceções e StackTrace em Blocos de Captura
Todos os blocos de captura de exceções (`catch`) da aplicação sob `lib/` que tratam falhas operacionais, de autenticação, de sincronização de perfil remoto, de renderização de marcadores de mapa ou de abertura de links externos SHALL capturar explicitamente a exceção e o rastreamento de pilha `catch (e, stackTrace)` e encaminhá-los ao `AppLogger` (respeitando o rebaixamento para `logAviso` apenas em desconexões transitórias e ignorando cancelamentos voluntários ou erros de validação de entrada do usuário).

#### Scenario: Tratamento de exceção em serviço de background ou sincronização
- **WHEN** uma exceção não esperada for interceptada em um bloco `catch` de um serviço
- **THEN** o bloco DEVE capturar o `stackTrace` do evento e invocar `AppLogger.instance.logError` passando o `error: e` e `stackTrace: stackTrace`.

#### Scenario: Falha operacional ou de configuração em autenticação e sincronização de perfil
- **WHEN** uma falha inesperada ou erro HTTP definitivo (`400`, `401`, `403`, `500`) ocorrer durante o login no `LoginViewModel` ou durante a sincronização de perfil/avatar no `SincronizadorPerfilSupabase`
- **THEN** o sistema MUST registrar a falha com seu `StackTrace` no `AppLogger.instance.logError` (ou `logAviso` caso seja falha transitória de conexão) em vez de descartá-la silenciosamente em `catch (_) {}`
