## MODIFIED Requirements

### Requirement: Propagação de Erros de Isolates de Sincronização para o Logger Principal
O sistema DEVE capturar e registrar no `AppLogger` principal qualquer falha reportada pelos isolates de download (`DownloadIsolateResult.error`) ou de verificação de cache (`CacheCheckResponse`), preservando os detalhes da exceção subjacente (tanto no download do `compilado.binarypb` quanto no download das mídias) e classificando falhas de conectividade ou timeout como avisos (`logAviso`) e falhas de integridade ou corrupção como erros fatais (`logCrash`).

#### Scenario: Falha de rede ou timeout dentro do isolate de download de imagens ou de binarypb
- **WHEN** o isolate de download (`downloadIsolateMain`) retornar `DownloadIsolateResult` com `success: false` devido a timeout ou queda de conexão (`SocketException` / `ClientException` / `TimeoutException`), seja durante o download inicial do `compilado.binarypb` ou durante o download das imagens
- **THEN** o `DownloadIsolateResult.error` inclui o detalhe da exceção capturada em `errosDownloads` e o `SyncService` registra os detalhes via `AppLogger.instance.logAviso` sem reportar crash fatal (`fatal: true`)

#### Scenario: Falha de integridade ou parsing dentro do isolate de download
- **WHEN** o isolate de download (`downloadIsolateMain`) retornar `DownloadIsolateResult` com `success: false` devido a falha de decodificação Protobuf, tamanho inválido ou erro HTTP inesperado (ex: HTTP 404/500)
- **THEN** o `SyncService` DEVE registrar os detalhes do erro no `AppLogger.instance.logCrash` (`fatal: true`) antes de prosseguir com a limpeza de diretórios temporários

#### Scenario: Falha na leitura ou parsing no isolate de verificação de cache
- **WHEN** o isolate de verificação de cache (`verificarCacheIsolate`) encontrar uma exceção ao ler ou decodificar arquivos locais
- **THEN** o erro DEVE ser propagado na resposta do isolate e registrado via `AppLogger.instance.logError` na thread principal
