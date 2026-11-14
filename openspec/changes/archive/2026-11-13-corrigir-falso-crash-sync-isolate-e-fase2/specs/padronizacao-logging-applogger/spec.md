## ADDED Requirements

### Requirement: Resumos Agregados de Sincronização Não Devem Gerar Falsos Erros de Rede
Os logs agregados de resumo da Fase 2 de sincronização (`_executarAtualizacaoMidiasEmSegundoPlano`) e os tratadores de retorno nulo de `_downloadFileAtomic` DEVEM utilizar `logAviso` (e `logFalhaSyncOuDownload` em exceções capturadas), delegando a emissão de `logError`/`logCrash` exclusivamente aos pontos onde a falha individual é inspecionada (`tratarErroDownloadIsolate` e `SyncNetwork.downloadFile`).

#### Scenario: Queda de conexão durante a Fase 2 de atualização em segundo plano
- **WHEN** um ou mais picos ou miniaturas falharem durante `_executarAtualizacaoMidiasEmSegundoPlano` devido a queda de conexão ou bloqueio de rede em segundo plano pelo sistema operacional
- **THEN** os resumos `[SyncService] Falha na atualização de ...` e `[SyncService] Falha definitiva na sincronização...` são registrados via `AppLogger.instance.logAviso`, sem gerar eventos `level: error` ou `level: fatal` no Sentry
