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


