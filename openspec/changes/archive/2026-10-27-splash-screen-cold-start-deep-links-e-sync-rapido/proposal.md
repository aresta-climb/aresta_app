# Proposal

## Why

Ao abrir um link externo (`https://aresta.cc/...`) com o aplicativo fechado (*Cold Start*), o usuário enfrenta vários segundos de tela completamente branca (sem a logo da splash screen), seguidos de um "pulo" visual em que a tela inicial (Home) aparece brevemente antes de navegar para a via, setor ou pico do link. Isso ocorre porque: (1) o Android 12+ suprime por padrão o ícone da splash nativa em intents `ACTION_VIEW` se `windowSplashScreenBehavior` não estiver configurado; (2) o `main()` executa uma longa fila sequencial de inicializações antes de chamar `runApp()`; (3) o link inicial só é lido após a montagem da Home; e (4) o acesso online a croquis (`getCroqui`) e a resolução de UIDs novos não garantem um sync rápido prévio de `indice.binarypb` e `catalogo.db` desacoplado do download pesado de mídias em segundo plano.

## What Changes

- **Exibição garantida do ícone na Splash Nativa em Deep Links (Android 13+)**: Configuração de `android:windowSplashScreenBehavior="icon_preferred"` no manifesto/temas nativos do Android (`values-v33`) mantendo o fundo `#ffffff` atual compatível com `assets/logo_splash.png`, para que o sistema operacional exiba a logo desde o instante zero mesmo quando iniciado via `ACTION_VIEW`.
- **Inicialização Rápida (`runApp` imediato) com `TelaSplashInicial` no Flutter e Bootstrap Paralelo**: Exibição imediata da tela de splash do próprio Flutter (com `assets/logo_splash.png` centralizada sobre `#ffffff` e indicador de progresso discreto quando necessário) enquanto as rotinas independentes de inicialização (Firebase, SharedPreferences, `DatasetRepository.init()` e leitura de `getInitialLink()`) executam em paralelo, preservando integralmente o bloqueio de `DatabaseMigrationScreen` quando `needsMigration == true`.
- **Resolução de Deep Link no *Cold Start* Antes da Home (Sem "Pulo" de Tela)**: Se o aplicativo for iniciado por um Deep Link, o destino é resolvido ainda durante a `TelaSplashInicial` e o `TreeNavigationController` já é inicializado diretamente no nó de destino (`ViaNode`, `SetorNode`, `PicoNode`, `MapasCarrosselNode`, etc., com `HomeNode` na base da pilha para retorno), abrindo diretamente na tela final sem piscar a Home antes.
- **Abertura Instantânea para Croquis Offline ou em `temp_cache` e Sync Rápido Antes de Buscar na Rede**:
  - Se o `uid` do link pertencer a um croqui já presente em `/downloads` (offline) ou no cache volátil (`/temp_cache`), o destino é resolvido localmente em `0ms` de rede e aberto imediatamente, disparando o `syncService.syncIndex()` em segundo plano.
  - Se o `uid` não existir no `catalogo.db` local (ex: via ou croqui recém-lançado) ou se o `DatasetRepository.getCroqui(id)` precisar baixar o `compilado.binarypb` da CDN (etapa 4 — tanto via Deep Link quanto ao clicar em um pico online na Home/Explorar), o sistema aguarda `await syncService.syncIndex()` antes de baixar o `.binarypb`.
- **`syncService.syncIndex()` Não-Bloqueante para Mídias e Atualização Reativa de Sessão Online Ativa**:
  - `syncService.syncIndex()` passa a aguardar apenas a sincronização rápida de metadados (`GET /indice.binarypb` com ETag + `sincronizarCatalogoSeNecessario` via delta no `catalogo.db`) e retorna imediatamente para destravar o chamador em ~100–250ms, disparando a etapa pesada (`_syncThumbnails` e `_checkForUpdates` de picos baixados) em segundo plano.
  - O `activeDataset` só é atualizado após o commit atômico dos arquivos `.tmp` das thumbnails/croquis no disco, evitando leituras intermediárias de imagens ainda não renomeadas.
  - Caso a sincronização em segundo plano detecte que o croqui atualmente aberto na tela (`picoAbertoId`) em sessão online/cache volátil sofreu atualização de hash no novo índice, o `SyncService` recarrega automaticamente o novo `.binarypb` em segundo plano, atualiza a sessão online, reconstrói a página reativamente via `PageListenableBuilder` e emite o aviso amigável na UI (*"O guia de `<Nome>` foi atualizado!"*).

## Capabilities

### New Capabilities

*(Nenhuma nova capacidade isolada; os comportamentos evoluem capacidades existentes do sistema).*

### Modified Capabilities
- `offline-first-initialization`: Exibição garantida da splash nativa com ícone em deep links (`windowSplashScreenBehavior="icon_preferred"`), renderização imediata da `TelaSplashInicial` no Flutter durante o bootstrap paralelo e preservação do bloqueio de `DatabaseMigrationScreen`.
- `qr-deep-linking`: Resolução antecipada de deep links no *Cold Start* durante a splash (eliminando o flash da Home) e fallback automático com `await syncService.syncIndex()` quando o UID não consta no catálogo local.
- `sincronizacao-cache-croquis`: Retorno rápido de `syncService.syncIndex()` após atualizar `indice.binarypb` e `catalogo.db` (delegando downloads pesados de thumbnails e picos para segundo plano) e garantia de índice sincronizado antes da etapa 4 (download remoto da CDN) em `DatasetRepository.getCroqui`.
- `invalidador-cache-croquis-obsoletos`: Recarregamento automático em segundo plano e notificação reativa na UI quando o croqui atualmente aberto em sessão online (`picoAbertoId`) recebe nova versão durante o `syncIndex`.

## Impact

- **Android Nativo**: `frontend/android/app/src/main/AndroidManifest.xml`, `frontend/android/app/src/main/res/values-v33/styles.xml` e `frontend/android/app/src/main/res/values-night-v33/styles.xml`.
- **Inicialização e UI de Splash**: `frontend/lib/main.dart`, `frontend/lib/services/inicializacao_app.dart` e novo widget modular `frontend/lib/pages/tela_splash_inicial.dart` (com respectivo teste espelhado `frontend/test/pages/tela_splash_inicial_test.dart`).
- **Navegação e Deep Links**: `frontend/lib/navigation/wrapper_navegacao_arvore.dart`, `frontend/lib/navigation/gerenciador_deep_links.dart`, `frontend/lib/navigation/servico_navegacao_deep_link.dart` e `frontend/lib/navigation/localizador_destino_uid.dart`.
- **Sincronização e Repositório de Dados**: `frontend/lib/services/http/sync_service.dart` e `frontend/lib/services/repositorio_dataset.dart`.
