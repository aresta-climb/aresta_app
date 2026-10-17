# Proposal

## Why

Quando um escalador sem conectividade (por exemplo, já na base da rocha sem sinal de dados móveis ou com falha de DNS `SocketException: Failed host lookup`) tenta abrir ou baixar um croqui que ainda não está salvo no aparelho, a camada de rede (`ServicoCroquiOnline.carregarCroquiRemoto` e `SyncService.tratarErroDownloadIsolate`) reconhece a falha transitória, registra um breadcrumb (`logAviso`) e retorna `null` ou `false`. Porém, os orquestradores superiores (`handlePicoSelection`, `SyncService.downloadCrag` e `ServicoDownloadSegundoPlano.executarDownload`) invocam novamente `AppLogger.instance.logFalhaSyncOuDownload` passando mensagens genéricas ou uma `Exception('Croqui nulo ou sem picos...')` sintética; como essas mensagens não contêm o objeto `SocketException` original, `AppLogger.isFalhaConexaoOuTimeout` retorna `false` e dispara falsos **Crashes Fatais (`fatal: true`)** no Firebase Crashlytics. Além disso, a interface atual exibe apenas uma mensagem genérica (`"Erro ao abrir o guia. Verifique sua conexão."`), sem esclarecer ao escalador que aquele croqui específico ainda não foi salvo offline no dispositivo e sem oferecer um atalho imediato para tentar novamente.

## What Changes

- **Eliminação de Falsos Crashes Fatais por Falta de Internet (`funcoes_home.dart`, `sync_service.dart`, `servico_download_segundo_plano.dart`, `servico_croqui_online.dart`)**:
  - Preservar a responsabilidade de invocar `logFalhaSyncOuDownload` exclusivamente onde o objeto de erro real (`SocketException`, `ClientException`, `HttpException`, erro de checksum ou protobuf corrompido) está presente.
  - Em `handlePicoSelection` (`funcoes_home.dart`), distinguir quando o croqui não pôde ser carregado por estar apenas online (`!isBaixado` — registrando `logAviso` contextual sem gerar issue/crash no Crashlytics) de quando o croqui constava como salvo localmente (`isBaixado`) mas falhou ao abrir (anomalia real de integridade, registrando erro rastreável no Crashlytics).
  - Em `SyncService.downloadCrag` e `ServicoDownloadSegundoPlano.executarDownload`, substituir as chamadas redundantes sem objeto `error` a `logFalhaSyncOuDownload` por `logAviso` (já que cada falha real ou transitória do isolate já é devidamente classificada e reportada com `stackTrace` original em `tratarErroDownloadIsolate`).
  - Em `ServicoCroquiOnline.recarregarCroquiOnline`, substituir `logError` por `logFalhaSyncOuDownload` para evitar abertura de issues não-fatais em quedas de rede durante recargas.
- **Melhoria de UX ao Tentar Abrir Croqui Não Baixado Offline (`funcoes_home.dart`)**:
  - Exibir uma `SnackBar` contextualizada e estilizada com a identidade visual do Aresta quando o escalador tentar abrir um croqui não salvo estando sem conexão:
    - Mensagem clara explicando que o croqui ainda não está salvo offline no aparelho e que é necessário sinal de internet para abri-lo ou baixá-lo;
    - Ação rápida (`SnackBarAction`) `"Tentar novamente"` que reexecuta `handlePicoSelection` para o mesmo pico sem exigir nova busca.

## Capabilities

### New Capabilities

### Modified Capabilities
- `transmissao-croqui-online`: Refina o requisito de fallback de falha de rede ao carregar croqui online para proibir o disparo de crashes fatais ou não-fatais no Crashlytics em falhas de conectividade (`SocketException`/`ClientException`/`TimeoutException`) e exigir feedback visual explicativo diferenciando croquis ainda não baixados (com opção de tentar novamente) de falhas em croquis locais.
- `padronizacao-logging-applogger`: Estabelece a regra de não-duplicação e vedação de exceções sintéticas em `logFalhaSyncOuDownload`, garantindo que orquestradores de UI e de download não convertam retornos `null`/`false` de falhas de rede já tratadas em crashes fatais no Firebase Crashlytics.

## Impact

- **Código Afetado (`frontend/lib/`)**:
  - `lib/view/function_library/funcoes_home.dart`
  - `lib/services/http/servico_croqui_online.dart`
  - `lib/services/http/sync_service.dart`
  - `lib/services/http/servico_download_segundo_plano.dart`
  - `lib/view/README.md` e `lib/services/README.md`
- **Testes Afetados (`frontend/test/`)**:
  - `test/view/function_library/funcoes_home_test.dart`
  - `test/services/http/servico_croqui_online_test.dart`
  - `test/services/http/sync_service_test.dart`
  - `test/services/http/servico_download_segundo_plano_test.dart`
