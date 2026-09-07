## ADDED Requirements

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
