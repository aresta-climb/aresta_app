# Proposal

## Why

Quando o usuário está no Modo Experimental conectado ao Editor Desktop (via Cloudflare Relay `previa.arestaclimb.com/<codigo>` ou rede local LAN) e a sessão no computador é fechada ou expira no retransmissor, qualquer sincronização subsequente recebe `HTTP 404` ao buscar `indice.binarypb`. Atualmente, isso causa três problemas: (1) `SyncNetwork` registra o `404` como uma exceção não-fatal no Firebase Crashlytics (`Server returned an error: 404`), poluindo o monitoramento de produção com o encerramento natural de uma sessão efêmera; (2) `SyncNetwork.fetchIndiceWithRetries` retorna `null` tanto para falta de internet quanto para erros HTTP, fazendo o `SyncService` atribuir sempre `SyncStatus.offline` e exibir um SnackBar enganoso ("Sem conexão com a internet.") mesmo com conectividade normal; e (3) o aplicativo permanece preso no Modo Experimental tentando reconectar o WebSocket a cada 4 segundos indefinidamente, em vez de encerrar a sessão efêmera e devolver o usuário ao catálogo oficial.

## What Changes

- **Tipagem Explícita de Falhas em `FetchIndiceResult` (`sync_rede.dart` e `sync_service.dart`)**:
  - Substituição do retorno `null` ambíguo em `SyncNetwork.fetchIndiceWithRetries` por variantes seladas explícitas de `FetchIndiceResult`: `IndiceOffline` (falha de conexão/timeout após esgotar retentativas) e `IndiceErroServidor(int statusCode)` (resposta HTTP com código de erro, como `404` ou `500`).
  - Atualização do `SyncService._executarSyncIndex` para diferenciar `IndiceOffline` (`SyncStatus.offline`) de `IndiceErroServidor` (`SyncStatus.error`), garantindo que a UI exiba a mensagem correta para cada caso.
- **Filtro de Crashlytics para Servidores Efêmeros do Modo Experimental (`sync_rede.dart` e `editor_croqui.dart`)**:
  - Identificação de URLs pertencentes ao Modo Experimental/Prévia (`previa.arestaclimb.com` ou endereços locais de LAN).
  - Respostas HTTP de erro (`404`, `5xx`, etc.) originadas de sessões efêmeras do Editor Desktop passam a ser registradas exclusivamente como aviso/breadcrumb contextual (`AppLogger.instance.logAviso`), deixando de gerar issues falsas no Firebase Crashlytics. Erros HTTP na CDN oficial (`serving.arestaclimb.com`) continuam sendo reportados via `AppLogger.instance.logError`.
- **Encerramento Automático da Sessão Experimental Expirada e Diálogo de Retorno ao Modo Oficial**:
  - Quando uma sincronização em Modo Experimental receber `IndiceErroServidor` (como `HTTP 404` indicando que a sessão de prévia foi encerrada no Editor Desktop ou expirou no Cloudflare Relay):
    - O sistema encerra automaticamente o Modo Experimental (`nukeExperimentalData()`), interrompe o timer de reconexão do WebSocket de Live Reload, restaura imediatamente o catálogo oficial em memória (`datasetRepo.init()`) e retorna a navegação para a tela inicial (`AppNav.home`).
    - O `EditorDeCroqui` aciona um notificador reativo (`notificadorSessaoExpirada`) escutado na camada global da aplicação para exibir um diálogo modal elegante informando que a conexão com o Editor Desktop foi encerrada e que o aplicativo voltou para o catálogo oficial do Aresta Climb, com um botão de confirmação (`"ENTENDI"`).
    - Caso o encerramento tenha sido detectado durante uma sincronização manual (`handleManualSync`), o SnackBar de erro é suprimido para evitar sobreposição visual com o modal informativo.

## Capabilities

### New Capabilities

*(Nenhuma nova capability independente; os requisitos estendem as capabilities existentes de experiência de Live Reload, feedback de sincronização e rastreamento de falhas de rede).*

### Modified Capabilities

- `hot-reload-experiencia-usuario`: Adiciona o encerramento automático do Modo Experimental quando a sessão remota do Editor Desktop expira ou retorna `HTTP 404`, limpando os dados efêmeros, restaurando o catálogo oficial de produção e exibindo um modal amigável de aviso ao usuário.
- `data-sync-feedback`: Diferencia falhas de conectividade (`SyncStatus.offline`) de erros HTTP do servidor (`SyncStatus.error`) a partir do resultado tipado de `fetchIndiceWithRetries` e suprime SnackBars redundantes quando ocorre transição automática de expiração do modo experimental.
- `rastreamento-falhas-isolates-rede`: Reclassifica erros HTTP (`404`, `5xx`) provenientes de URLs efêmeras do Modo Experimental (`previa.arestaclimb.com` ou LAN) como avisos contextuais (`logAviso`), preservando o disparo de erros no Crashlytics exclusivamente para a infraestrutura oficial de produção.

## Impact

- **Código Afetado (`frontend/lib/`)**:
  - `lib/services/http/sync_rede.dart` (`IndiceOffline`, `IndiceErroServidor`, filtro de logs em URLs experimentais)
  - `lib/services/http/sync_service.dart` (tratamento de `IndiceOffline` vs `IndiceErroServidor` e encerramento automático da sessão experimental em caso de `404`)
  - `lib/services/editor_croqui.dart` (helper `isUrlExperimental`, `notificadorSessaoExpirada`)
  - `lib/widgets/modal_sessao_experimental_encerrada.dart` (novo widget independente e testável para o diálogo de aviso de retorno ao modo oficial)
  - `lib/main.dart` (escuta do `notificadorSessaoExpirada` para apresentação do modal e retorno à Home oficial)
  - `lib/view/function_library/biblioteca_funcoes_comuns.dart` (supressão de SnackBar quando a sessão experimental foi encerrada durante o sync manual)
- **Testes Afetados (`frontend/test/`)**:
  - `test/widgets/modal_sessao_experimental_encerrada_test.dart` (novo)
  - `test/services/sync_rede_test.dart`
  - `test/services/sync_service_test.dart` e `test/services/http/sync_service_test.dart`
  - `test/services/editor_croqui_test.dart`
  - `test/view/function_library/biblioteca_funcoes_comuns_test.dart`
