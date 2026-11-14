# Proposal: Corrigir Falso Crash no Download de Binarypb no Isolate e Falso Erro no Resumo da Fase 2 de Sincronização

## Why
Na versão `0.6.2+102` em produção, foram reportados dois alertas falsos no Sentry e no GitHub (`aresta_app#33` / `ARESTA-APP-H` e `aresta_app#34` / `ARESTA-APP-J`) quando o aplicativo foi enviado para segundo plano (`background`) logo após o início de `syncIndex()` e o Android 16 bloqueou os sockets de rede:
1. **Perda da Causa Raiz de Rede na Falha do `binarypb` (`ARESTA-APP-H`)**: Em `downloadIsolateMain` (`sync_isolate.dart`), quando o download inicial do `compilado.binarypb` falha por queda de rede (`ClientException with SocketException`), a exceção é registrada em `errosDownloads`, porém o `DownloadIsolateResult` retornado omitia esses detalhes (`error: 'Falha ao baixar binarypb de $url'`). Sem a string da `SocketException`, `tratarErroDownloadIsolate` -> `AppLogger.logFalhaSyncOuDownload` não reconhecia a falha como queda de conexão/timeout (`isFalhaConexaoOuTimeout == false`) e reportava um crash fatal (`fatal: true`) para cada pico em fila.
2. **Duplicação de Erro Agrupado na Fase 2 e no Download Atômico (`ARESTA-APP-J`)**: Em `SyncService._executarAtualizacaoMidiasEmSegundoPlano`, mesmo quando todas as falhas individuais de picos e miniaturas já foram devidamente classificadas como `logAviso` (por queda de conexão em segundo plano), o resumo da Fase 2 chamava incondicionalmente `AppLogger.instance.logError('[SyncService] Falha na atualização de X picos ou nas thumbnails...')` e `logError('[SyncService] Falha definitiva na sincronização...')`. De forma análoga, `_downloadFileAtomic` chamava `logError` redundante quando `_network.downloadFile` retornava `null` (já logado por `SyncNetwork`) ou no `catch` de I/O/rede.

## What Changes
- **Preservação dos Detalhes de Erro no `compilado.binarypb` (`sync_isolate.dart`)**: Incluir os detalhes acumulados em `errosDownloads` na mensagem `DownloadIsolateResult.error` quando o download do `compilado.binarypb` retornar `null` (`'Falha ao baixar binarypb de $url$detalhe'`), espelhando o que já ocorre no bloco de imagens.
- **Rebaixamento de Logs de Resumo de Sincronização para Aviso (`sync_service.dart`)**:
  - Alterar os dois logs agregados de resumo em `_executarAtualizacaoMidiasEmSegundoPlano` (`Falha na atualização de X picos ou nas thumbnails...` e `Falha definitiva na sincronização após tentativa de bypass de cache.`) de `logError` para `logAviso`, uma vez que cada pico (`tratarErroDownloadIsolate`) e cada arquivo (`SyncNetwork.downloadFile`) já reporta individualmente `logError`/`logCrash` em caso de corrupção ou erro HTTP inesperado, ou `logAviso` em caso de queda de rede.
  - Em `_downloadFileAtomic`, usar `logAviso` quando `_network.downloadFile` retornar `null` (pois `SyncNetwork.downloadFile` já registrou o erro/aviso específico da requisição) e `logFalhaSyncOuDownload` no bloco `catch`.

## Capabilities

### New Capabilities
*(Nenhuma nova capability)*

### Modified Capabilities
- `rastreamento-falhas-isolates-rede`: Garantir que a falha de download do arquivo `compilado.binarypb` em `downloadIsolateMain` inclua o detalhe da exceção capturada em `errosDownloads`, permitindo que `tratarErroDownloadIsolate` classifique quedas de conexão/timeout como `logAviso`.
- `padronizacao-logging-applogger`: Garantir que resumos agregados de falha de sincronização na Fase 2 (`_executarAtualizacaoMidiasEmSegundoPlano`) e retornos nulos já tratados por `SyncNetwork` em `_downloadFileAtomic` utilizem `logAviso` / `logFalhaSyncOuDownload`, evitando falsos eventos de `level: error` no Sentry quando o sistema operacional corta a rede em segundo plano.

## Impact
- `frontend/lib/services/http/sync_isolate.dart`
- `frontend/lib/services/http/sync_service.dart`
- `frontend/test/services/http/sync_isolate_test.dart`
- `frontend/test/services/http/sync_service_test.dart`
