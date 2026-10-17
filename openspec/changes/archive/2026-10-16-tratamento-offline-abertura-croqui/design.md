# Design

## Context

Veja `proposal.md` para a motivação completa. Atualmente, `AppLogger.instance.logFalhaSyncOuDownload(contextMessage, {error, required stackTrace})` decide entre registrar um simples breadcrumb (`logAviso`) ou um Crash Fatal (`logCrash(..., fatal: true)`) verificando `isFalhaConexaoOuTimeout(error) || isFalhaConexaoOuTimeout(contextMessage)`.

O problema arquitetural ocorre porque o tratamento está dividido em duas camadas que não compartilham a exceção capturada:
1. A camada inferior (`ServicoCroquiOnline.carregarCroquiRemoto` e `SyncService.tratarErroDownloadIsolate`) captura a `ClientException` / `SocketException` real, passa `error: e` para `logFalhaSyncOuDownload` (que corretamente emite `logAviso`) e retorna `null` ou `false`.
2. A camada superior (`handlePicoSelection` em `funcoes_home.dart`, `SyncService.downloadCrag` em `sync_service.dart` e `ServicoDownloadSegundoPlano.executarDownload` em `servico_download_segundo_plano.dart`) verifica `if (croqui == null)` ou `if (!success)` e chama `logFalhaSyncOuDownload` novamente — porém passando `error: null` ou `error: Exception('Croqui nulo ou sem picos após consulta ao repositório')`. Sem a `SocketException` original, `isFalhaConexaoOuTimeout` retorna `false` e dispara `logCrash(fatal: true)` no Firebase Crashlytics para um simples clique sem internet.

## Goals / Non-Goals

**Goals:**
- Garantir que 0 issues (nem não-fatais, nem fatais) sejam abertas no Firebase Crashlytics quando o usuário sem internet tentar abrir um croqui online, recarregar um croqui ou baixar um croqui.
- Preservar o reporte rigoroso no Crashlytics quando ocorrerem falhas reais de integridade (ex: HTTP 404/500, protobuf corrompido ou um croqui que consta como salvo offline mas retorna nulo/vazio ao ser lido do disco).
- Melhorar a UX em `handlePicoSelection` quando um croqui não puder ser aberto, diferenciando claramente croquis que requerem conexão (por ainda não estarem salvos offline) de erros inesperados em croquis já salvos, e oferecendo ação de `"Tentar novamente"`.

**Non-Goals:**
- Adicionar dependências externas de verificação de conectividade (como `connectivity_plus`), mantendo a arquitetura simples baseada no resultado real das operações e no estado local do repositório (`isPicoDownloaded`).

## Decisions

### 1. Responsabilidade Única de Classificação de Erro na Camada de Origem
- **Decisão**: Apenas o ponto que possui o objeto `error` real (ou que detecta uma violação de invariante local) deve invocar `logFalhaSyncOuDownload` ou `logError`. Orquestradores de nível superior que recebem apenas `null` ou `bool` devem usar `logAviso` para registrar o breadcrumb de fluxo.
- **Aplicação por módulo**:
  1. `ServicoCroquiOnline.carregarCroquiRemoto`: No bloco `catch`, mantém `logFalhaSyncOuDownload` com `error: e` (classifica `SocketException`/`ClientException`/`TimeoutException` como `logAviso`). Quando `response.statusCode != 200`, passa `error: response.statusCode` para `logFalhaSyncOuDownload` (em vez de `HttpException`, pois `AppLogger.isFalhaConexaoOuTimeout` trata qualquer `HttpException` como falha de socket, o que mascarava `HTTP 404/500`; passando o `int` `response.statusCode`, códigos transitórios `502/503/504/429` emitem `logAviso` e erros `404/500` são reportados ao Crashlytics).
  2. `ServicoCroquiOnline.recarregarCroquiOnline`: Troca `logError` por `logFalhaSyncOuDownload` no bloco `catch`.
  3. `handlePicoSelection` (`funcoes_home.dart`):
     - Se `isBaixado == true` e `croqui == null || croqui.picos.isEmpty`: trata-se de uma falha real de integridade em um croqui que deveria existir em `/downloads`. Registra `AppLogger.instance.logError` com contexto claro (`'Falha de integridade ao abrir croqui salvo offline: $id (origem: $source)'`).
     - Se `isBaixado == false` e `croqui == null || croqui.picos.isEmpty`: a falha de rede (ou HTTP) já foi registrada por `ServicoCroquiOnline.carregarCroquiRemoto`. `handlePicoSelection` registra apenas `AppLogger.instance.logAviso('Não foi possível abrir o croqui online $id (origem: $source): sem conexão ou indisponível.')`.
  4. `SyncService.downloadCrag` e `ServicoDownloadSegundoPlano.executarDownload`:
     - Quando `!success`, todas as falhas de rede ou de hash no isolate já foram registradas com o `error` e `stackTrace` reais via `tratarErroDownloadIsolate`. Portanto, o bloco `if (!success)` em `downloadCrag` e em `executarDownload` deve chamar `AppLogger.instance.logAviso(...)` em vez de `logFalhaSyncOuDownload` sem `error`.

### 2. UX Contextual com Ação de Retentativa ao Abrir Croqui Sem Conexão
- **Decisão**: Em `handlePicoSelection` (`funcoes_home.dart`), substituir a `SnackBar` estática por um feedback diferenciado conforme `isBaixado`:
  - **Quando `!isBaixado` (croqui não salvo offline)**:
    - Limpar eventuais `SnackBar`s anteriores (`ScaffoldMessenger.of(context).hideCurrentSnackBar()`) para evitar empilhamento se o usuário tocar várias vezes.
    - Exibir `SnackBar` flutuante (`SnackBarBehavior.floating`) com ícone `Icons.cloud_off_outlined`, texto explicativo `"Este croqui ainda não está salvo offline. Conecte-se à internet para abri-lo."` e `SnackBarAction(label: 'Tentar novamente', onPressed: ...)` que invoca novamente `handlePicoSelection` quando o contexto ainda estiver montado.
  - **Quando `isBaixado` (croqui salvo offline com falha de leitura)**:
    - Exibir `SnackBar` informando `"Erro ao abrir o croqui salvo. Tente sincronizar novamente."`.

## Risks / Trade-offs

- **[Risco] Ocultar acidentalmente um erro HTTP 404/500 ao abrir croqui online** → **Mitigação**: Passando `error: response.statusCode` em `ServicoCroquiOnline.carregarCroquiRemoto`, `AppLogger.isFalhaConexaoOuTimeout(int)` retorna `true` apenas para `502, 503, 504, 429`, garantindo que HTTP `404` ou `500` na CDN sejam reportados integralmente ao Crashlytics.
- **[Risco] Usuário clicar em "Tentar novamente" após sair da tela** → **Mitigação**: Verificar `if (context.mounted)` dentro do callback da `SnackBarAction` antes de reexecutar `handlePicoSelection`.
