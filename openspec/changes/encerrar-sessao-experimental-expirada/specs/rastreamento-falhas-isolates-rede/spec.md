# Spec Delta

## ADDED Requirements

### Requirement: Supressão de Erros no Crashlytics para Servidores Efêmeros do Modo Experimental
O sistema SHALL registrar falhas HTTP (`404`, `5xx`, etc.) originadas de URLs efêmeras do Modo Experimental/Prévia (`previa.arestaclimb.com` ou endereços privados de rede local LAN) exclusivamente como avisos contextuais (`AppLogger.instance.logAviso`), nunca reportando-as como exceções não-fatais ou crashes (`logError`/`logCrash`) no Firebase Crashlytics.

#### Scenario: Servidor de prévia experimental retorna HTTP 404 na busca do índice
- **WHEN** `SyncNetwork.fetchIndiceWithRetries` ou `SyncNetwork.downloadFile` recebe HTTP 404 (ou qualquer status diferente de 200/304) de uma URL pertencente ao domínio `previa.arestaclimb.com` ou rede local de editor
- **THEN** o sistema DEVE registrar o evento via `AppLogger.instance.logAviso` (apenas breadcrumb)
- **AND** NÃO DEVE invocar `AppLogger.instance.logError` ou `AppLogger.instance.logCrash`.

#### Scenario: Servidor oficial de produção retorna HTTP 404 na busca do índice
- **WHEN** `SyncNetwork.fetchIndiceWithRetries` recebe HTTP 404 da CDN oficial de produção (`serving.arestaclimb.com`)
- **THEN** o sistema DEVE invocar `AppLogger.instance.logError` com o `StackTrace` correspondente para alertar a equipe no Firebase Crashlytics.
