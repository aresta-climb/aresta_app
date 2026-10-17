# Spec Delta

## ADDED Requirements

### Requirement: Prevenção de Falsos Crashes Fatais por Omissão da Exceção de Rede Original
Os serviços e orquestradores de UI (`handlePicoSelection`, `SyncService.downloadCrag`, `ServicoDownloadSegundoPlano.executarDownload` e `ServicoCroquiOnline.recarregarCroquiOnline`) SHALL preservar a classificação de falhas de conectividade realizada pela camada de transporte inferior, sendo proibido invocar `AppLogger.instance.logFalhaSyncOuDownload` ou `AppLogger.instance.logCrash` sem o objeto de erro original (`error: null`) ou com exceções sintéticas genéricas quando uma operação retornar `null` ou `false` em decorrência de falha de rede já registrada.

#### Scenario: Falha de download de croqui por ausência de conexão no SyncService
- **WHEN** `SyncService.downloadCrag` falha após as tentativas porque o isolate de download encontrou `SocketException`, `ClientException` ou `TimeoutException` (já registrado via `tratarErroDownloadIsolate`)
- **THEN** o encerramento de `downloadCrag` DEVE registrar o resumo de falha via `AppLogger.instance.logAviso`
- **AND** NÃO DEVE invocar `logFalhaSyncOuDownload` sem o erro original, evitando o disparo de `logCrash(fatal: true)`.

#### Scenario: Falha de download em segundo plano por ausência de conexão
- **WHEN** `ServicoDownloadSegundoPlano.executarDownload` recebe `sucesso == false` de `syncService.downloadCrag`
- **THEN** o serviço DEVE registrar o encerramento sem sucesso via `AppLogger.instance.logAviso` e exibir a notificação de falha ao usuário
- **AND** NÃO DEVE invocar `logFalhaSyncOuDownload` sem objeto `error`, evitando duplicação de crash fatal no Crashlytics.
