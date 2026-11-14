# Design: Corrigir Falso Crash no Download de Binarypb no Isolate e Falso Erro no Resumo da Fase 2

## Context
No Android 16 (e iOS/Android em geral), quando o usuário abre o aplicativo e imediatamente o envia para segundo plano (`AppLifecycleState.paused`/`hidden`), o sistema operacional suspende os sockets de rede da aplicação após ~5 segundos, lançando `ClientException with SocketException: Connection timed out` ou `Network is unreachable`.
O `AppLogger.isFalhaConexaoOuTimeout` já foi projetado para reconhecer essas exceções e classificá-las como `logAviso` (`⚠️ AVISO`), evitando falsos alertas de crash/erro no Sentry. Contudo, dois pontos no fluxo de sincronização (`SyncIsolate` e `SyncService`) impediam essa classificação:
1. No `downloadIsolateMain` (`sync_isolate.dart`), a falha no download do `compilado.binarypb` (linhas 215-225) retornava `error: 'Falha ao baixar binarypb de $url'` sem concatenar `errosDownloads`, descartando a `SocketException` capturada por `downloadBytesWithRetry`.
2. No `SyncService._executarAtualizacaoMidiasEmSegundoPlano` (`sync_service.dart`, linhas 698 e 714), o resumo agregado das falhas de picos/miniaturas chamava `AppLogger.instance.logError(...)` incondicionalmente, gerando um issue de erro no Sentry (`ARESTA-APP-J`) mesmo quando todas as falhas individuais eram meros avisos de rede. Além disso, `_downloadFileAtomic` (linhas 1272 e 1291) chamava `logError` quando `_network.downloadFile` retornava `null` ou lançava exceção de rede.

## Goals / Non-Goals
- **Goals:**
  - Preservar os detalhes de `errosDownloads` ao reportar falha de download do `compilado.binarypb` em `downloadIsolateMain`.
  - Substituir `logError` por `logAviso` nos dois logs de resumo de `_executarAtualizacaoMidiasEmSegundoPlano` e no retorno `null` de `_downloadFileAtomic`, e usar `logFalhaSyncOuDownload` no `catch` de `_downloadFileAtomic`.
  - Cobrir ambos os comportamentos com testes automatizados em `sync_isolate_test.dart` e `sync_service_test.dart`.
- **Non-Goals:**
  - Alterar a política de retentativas ou de preservação do `index.json` quando picos falham (o índice continua não sendo sobrescrito quando há falhas pendentes).

## Decisions
1. **Concatenação de `errosDownloads` no erro do `binarypb` (`sync_isolate.dart`)**:
   - Quando `pbBytes == null`, construir `final detalhe = errosDownloads.isNotEmpty ? ': ${errosDownloads.join("; ")}' : '';` e retornar `error: 'Falha ao baixar binarypb de $url$detalhe'`.
   - Dessa forma, `tratarErroDownloadIsolate` recebe a causa raiz (`SocketException`, `TimeoutException` ou `HTTP 404/500`) e `AppLogger.instance.logFalhaSyncOuDownload` classifica automaticamente:
     - Queda de rede / timeout -> `logAviso`
     - HTTP 404/500 ou erro inesperado -> `logCrash` (`fatal: true`)
2. **Rebaixamento dos logs agregados em `_executarAtualizacaoMidiasEmSegundoPlano` e `_downloadFileAtomic` (`sync_service.dart`)**:
   - Como cada falha individual de pico passa por `tratarErroDownloadIsolate` e cada falha de download de arquivo passa por `SyncNetwork.downloadFile` (que já chama `logFalhaSyncOuDownload`), os resumos de lote em `_executarAtualizacaoMidiasEmSegundoPlano` têm papel informativo/diagnóstico de fluxo e devem usar `logAviso`.
   - Em `_downloadFileAtomic`, quando `_network.downloadFile` retorna `null`, a requisição já foi logada dentro de `SyncNetwork.downloadFile`; portanto, o log de acompanhamento em `_downloadFileAtomic` usa `logAviso`, e o `catch` usa `logFalhaSyncOuDownload`.
