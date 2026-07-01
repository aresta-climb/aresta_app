## Why

Atualmente, o app bloqueia a interface e mostra um ícone de carregamento na inicialização enquanto aguarda uma requisição síncrona de rede para buscar o `indice.binarypb` remoto. Em conexões lentas ou offline, isso leva a timeouts longos e uma péssima experiência para o usuário. Além disso, novas instalações não possuem dados locais e, portanto, apresentam um estado vazio se não houver internet. As thumbnails da aba Explorar também dependem estritamente de requisições de rede, quebrando a promessa de offline-first. Precisamos carregar os dados locais instantaneamente, adiar sincronizações de rede para o background, empacotar um conjunto inicial de dados com o app e fazer o cache das thumbnails localmente.

## What Changes

- Mudar a inicialização do app para carregar o `indice.binarypb` local imediatamente na memória antes de qualquer requisição de rede, removendo o carregamento inicial.
- Mover a chamada `SyncService.syncIndex()` para rodar em background sem bloquear a UI.
- Fornecer um mecanismo de pré-build (ex: `tool/sync_preload.dart`) para empacotar o último `indice.binarypb` e suas thumbnails em `frontend/assets/preload/`.
- Durante a inicialização, se o diretório local de documentos não tiver um `indice.binarypb`, copiar o índice e as thumbnails empacotadas para o diretório de documentos local do app. (Nenhuma comparação de versão é necessária em updates, conforme solicitação).
- Atualizar `SyncService.syncIndex` para baixar e sincronizar proativamente todas as thumbnails para os crags disponíveis no diretório de documentos local sempre que um novo índice for buscado.
- Atualizar `_buildCragIcon` para ler as thumbnails do sistema de arquivos local em vez de fazer requisições de rede.

## Capabilities

### New Capabilities
- `offline-first-initialization`: Garante que o app consiga inicializar instantaneamente a partir do cache local ou assets embutidos sem bloqueios de rede.
- `local-thumbnail-cache`: Baixa e serve thumbnails de crags diretamente do sistema de arquivos local.

### Modified Capabilities

## Impact

- **UI/UX**: O tempo de inicialização será quase instantâneo. A aba de exploração mostrará thumbnails mesmo quando totalmente offline.
- **App Bundle**: O tamanho do APK/AAB vai aumentar um pouco (~1MB) para incluir o índice preloaded e as thumbnails.
- **DatasetRepository**: Requer lógica para lidar com a descompactação na primeira inicialização.
- **SyncService**: Agora vai baixar thumbnails junto com as atualizações de índice.
