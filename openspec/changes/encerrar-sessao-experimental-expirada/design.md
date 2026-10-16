# Design

## Context

Veja `proposal.md` para a motivação completa. Atualmente:
1. `SyncNetwork.fetchIndiceWithRetries` retorna `Future<FetchIndiceResult?>`, onde `null` representa tanto a ausência de internet (`SocketException`/`TimeoutException`) quanto qualquer resposta HTTP diferente de `200` e `304` (como `404` ou `500`).
2. Quando o status HTTP não está na lista de falhas transitórias de gateway (`502, 503, 504, 429`), `SyncNetwork` chama `AppLogger.instance.logError('Server returned an error: ${response.statusCode}')` incondicionalmente — inclusive quando a URL alvo é uma sessão efêmera do Editor Desktop no Cloudflare Relay (`https://previa.arestaclimb.com/<codigo>`).
3. `SyncService._executarSyncIndex` trata `result == null` atribuindo sempre `syncStatus.value = SyncStatus.offline`, fazendo com que `SyncStatus.error` nunca seja atribuído no `syncIndex` e que o usuário veja `"Sem conexão com a internet."` mesmo quando a internet está perfeita e apenas a sessão do Editor Desktop foi fechada.

## Goals / Non-Goals

**Goals:**
- Eliminar 100% dos falsos positivos no Firebase Crashlytics causados pelo encerramento/expiração de sessões do Modo Experimental (`previa.arestaclimb.com` ou IPs locais de LAN).
- Tornar `FetchIndiceResult` exaustivo (sem retorno `null`), distinguindo claramente `IndiceOffline` de `IndiceErroServidor(int statusCode)`.
- Encerrar automaticamente o Modo Experimental quando uma sincronização na sessão experimental receber `HTTP 404` (ou quando a sessão não existir mais no servidor de prévia), limpando os dados efêmeros, voltando ao catálogo oficial de produção e apresentando o diálogo `ModalSessaoExperimentalEncerrada`.

**Non-Goals:**
- Alterar o comportamento do Cloudflare Worker (`previa.arestaclimb.com`) ou do Editor Desktop.
- Criar persistência de longo prazo para sessões experimentais (o modo experimental é intencionalmente efêmero).

## Decisions

### 1. Hierarquia Selada Completa para `FetchIndiceResult`
- **Decisão**: Expandir `sealed class FetchIndiceResult` em `lib/services/http/sync_rede.dart` com duas novas subclasses:
  - `class IndiceOffline extends FetchIndiceResult {}` — retornado quando todas as tentativas falham por exceção de rede/timeout (`response == null`) ou erro de parse.
  - `class IndiceErroServidor extends FetchIndiceResult { final int statusCode; IndiceErroServidor(this.statusCode); }` — retornado quando o servidor responde com status HTTP diferente de `200` e `304`.
- **Racional**: Permite que o `switch (result)` em `SyncService._executarSyncIndex` seja exaustivo em tempo de compilação, atribuindo `SyncStatus.offline` para `IndiceOffline` e `SyncStatus.error` para `IndiceErroServidor`.

### 2. Detecção de URL Efêmera (`EditorDeCroqui.isUrlExperimental`)
- **Decisão**: Adicionar o método utilitário estático `EditorDeCroqui.isUrlExperimental(String url)` que retorna `true` se o host da URL for `previa.arestaclimb.com` (ou esquema `aresta://previa`) ou um endereço de rede local privada (`localhost`, `127.x.x.x`, `192.168.x.x`, `10.x.x.x`, `172.16-31.x.x`).
- **Racional**: Desacopla o `SyncNetwork` de instâncias globais mutáveis: basta `SyncNetwork` verificar `EditorDeCroqui.isUrlExperimental(baseUrl)` (ou `url` em `downloadFile`). Se for `true`, qualquer status HTTP de erro (`404`, `500`, etc.) é registrado com `AppLogger.instance.logAviso(...)` em vez de `logError(...)`. Se for `false` (CDN oficial `serving.arestaclimb.com`), erros `404`/`500` continuam disparando `AppLogger.instance.logError(...)` para o Crashlytics.

### 3. Encerramento Automático do Modo Experimental e Notificação para a UI
- **Decisão**:
  - Adicionar em `EditorDeCroqui` o notificador `final ValueNotifier<int> notificadorSessaoExpirada = ValueNotifier(0);` e o método `void notificarSessaoExperimentalExpirada() => notificadorSessaoExpirada.value++;`.
  - Em `SyncService._executarSyncIndex`, ao receber `IndiceErroServidor(statusCode: 404)` enquanto `editorDeCroqui.isExperimentalMode.value == true`:
    1. Registrar aviso informativo via `AppLogger.instance.logAviso('[SyncService] Sessão experimental expirada (HTTP 404). Encerrando modo experimental e retornando ao catálogo oficial.')`.
    2. Executar `await editorDeCroqui.nukeExperimentalData()`, que apaga os dados efêmeros, encerra o WebSocket de Live Reload e define `isExperimentalMode.value = false` (o que aciona o listener `onModeChange` em `main.dart` para recarregar o `datasetRepo.init()` e sincronizar o catálogo oficial).
    3. Recarregar imediatamente o índice oficial local (`await datasetRepository.init()`) e definir `syncStatus.value = SyncStatus.updated`.
    4. Acionar `editorDeCroqui.notificarSessaoExperimentalExpirada()`.
- **Racional**: Centraliza a detecção no `SyncService` (seja via sync manual, pull-to-refresh ou live reload), garantindo que o estado de dados volte para produção imediatamente sem deixar telas vazias.

### 4. Widget Modular `ModalSessaoExperimentalEncerrada`
- **Decisão**: Criar `lib/widgets/modal_sessao_experimental_encerrada.dart` seguindo o padrão visual de `ModalBetaAberto` (`caveShadow`, borda `graniteEdge`, ícone em destaque com `brandColor` `0xFFC04F34`).
  - **Título**: `'Sessão de Prévia Encerrada'`
  - **Mensagem**: `'A conexão com o Editor Desktop foi finalizada. Como o modo de prévia é temporário, restauramos automaticamente o catálogo oficial do Aresta Climb para você continuar navegando.'`
  - **Botão primário**: `'ENTENDI'` (fecha o modal via `Navigator.of(context).pop()`).
- Em `MyApp` (`lib/main.dart`), escutar `widget.datasetRepo.editorDeCroqui.notificadorSessaoExpirada`: quando acionado, redirecionar a árvore de navegação para `AppNav.home` e exibir `ModalSessaoExperimentalEncerrada.exibir(navContext)` com proteção contra empilhamento duplicado.
- Em `handleManualSync` (`biblioteca_funcoes_comuns.dart`), verificar se o modo experimental estava ativo antes do `syncIndex` e foi desativado ao final: nesse caso, retornar sem exibir `SnackBar`, pois o `ModalSessaoExperimentalEncerrada` já comunicará a transição com muito mais clareza.

## Risks / Trade-offs

- **[Risco] Disparo concorrente de múltiplos syncs ao expirar a sessão abrir múltiplos modais** → **Mitigação**: `SyncService.syncIndex` já possui coalescência via `_activeSyncFuture`, e `ModalSessaoExperimentalEncerrada` controlará uma flag `_estaExibindo` para nunca abrir duas instâncias sobrepostas.
- **[Risco] Transição de volta ao modo oficial deixar a tela com dataset vazio antes do `init()` concluir** → **Mitigação**: Executar `await datasetRepository.init()` dentro de `_executarSyncIndex` logo após `await editorDeCroqui.nukeExperimentalData()`, garantindo que o catálogo oficial já esteja em memória antes do futuro de `syncIndex` completar.
