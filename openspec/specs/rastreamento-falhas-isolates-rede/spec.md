# rastreamento-falhas-isolates-rede Specification

## Purpose
Padroniza a resiliência de rede, a propagação de stack traces entre isolates de download e a classificação de erros HTTP para o Firebase Crashlytics, evitando falsos alertas em falhas transitórias ou sessões efêmeras do editor.

## Requirements
### Requirement: Retentativa Resiliente para Erros Transitórios de Download
O sistema SHALL realizar até 3 tentativas automáticas com espera progressiva ao encontrar erros transitórios de rede ou gateway antes de considerar um download atômico como falho.

#### Scenario: Recuperação bem-sucedida após erro HTTP 504 transitório
- **WHEN** uma requisição de download no `sync_isolate` receber HTTP 504 (ou 502, 503, timeout) na primeira tentativa e responder HTTP 200 na tentativa subsequente
- **THEN** o download DEVE ser concluído com sucesso e o arquivo salvo sem propagar erro ou interromper a sincronização.

#### Scenario: Esgotamento de tentativas em falha persistente
- **WHEN** uma requisição de download falhar persistentemente com erro transitório após 3 tentativas
- **THEN** o sistema DEVE registrar a falha definitiva capturando o `rastreamentoPilha` e enviando-o via `DownloadIsolateResult`.

### Requirement: Propagação de Rastreamento de Pilha em Isolates de Download
O sistema SHALL capturar e transportar o rastreamento de pilha original de falhas geradas dentro do background isolate de download para o processo principal.

#### Scenario: Download de arquivo com falha no isolate
- **WHEN** ocorre uma falha definitiva de download no `sync_isolate`
- **THEN** o `DownloadIsolateResult` retornado DEVE conter o campo `rastreamentoPilha` preenchido com os frames exatos de execução do isolate e o `SyncService` DEVE reconstruí-lo e repassá-lo ao `AppLogger`.

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

### Requirement: Classificação de Erros HTTP Transitórios como Não-Fatais
O `AppLogger` SHALL identificar códigos de erro HTTP transitórios (502, 503, 504) e expressões de timeout de gateway como falhas transitórias de conexão.

#### Scenario: Registro de erro com HTTP 504 Gateway Timeout
- **WHEN** o método `isFalhaConexaoOuTimeout` for invocado com uma mensagem contendo "HTTP 504", "504 Gateway Timeout", "502" ou "503"
- **THEN** ele DEVE retornar `true` e o método `logFalhaSyncOuDownload` DEVE registrar o evento no Crashlytics com `fatal: false`.

### Requirement: Supressão de Erros no Crashlytics para Servidores Efêmeros do Modo Experimental
O sistema SHALL registrar falhas HTTP (`404`, `5xx`, etc.) originadas de URLs efêmeras do Modo Experimental/Prévia (`previa.arestaclimb.com` ou endereços privados de rede local LAN) exclusivamente como avisos contextuais (`AppLogger.instance.logAviso`), nunca reportando-as como exceções não-fatais ou crashes (`logError`/`logCrash`) no Firebase Crashlytics.

#### Scenario: Servidor de prévia experimental retorna HTTP 404 na busca do índice
- **WHEN** `SyncNetwork.fetchIndiceWithRetries` ou `SyncNetwork.downloadFile` recebe HTTP 404 (ou qualquer status diferente de 200/304) de uma URL pertencente ao domínio `previa.arestaclimb.com` ou rede local de editor
- **THEN** o sistema DEVE registrar o evento via `AppLogger.instance.logAviso` (apenas breadcrumb)
- **AND** NÃO DEVE invocar `AppLogger.instance.logError` ou `AppLogger.instance.logCrash`.

#### Scenario: Servidor oficial de produção retorna HTTP 404 na busca do índice
- **WHEN** `SyncNetwork.fetchIndiceWithRetries` recebe HTTP 404 da CDN oficial de produção (`serving.arestaclimb.com`)
- **THEN** o sistema DEVE invocar `AppLogger.instance.logError` com o `StackTrace` correspondente para alertar a equipe no Firebase Crashlytics.
