## 1. Configuração e Script de Pré-build

- [x] 1.1 Escrever testes unitários falhos para a lógica de download e salvamento do script `sync_preload.dart`.
- [x] 1.2 Criar a implementação do script `tool/sync_preload.dart` garantindo que os testes passem, para baixar o `indice.binarypb` remoto e suas imagens associadas para `frontend/assets/preload/`.
- [x] 1.3 Atualizar `pubspec.yaml` para declarar `assets/preload/` de modo que os arquivos sejam embutidos com o app.
- [x] 1.4 Adicionar um README básico ou comentário no script explicando seu uso para o GitHub Actions.

## 2. Refatoração da Inicialização de Boot

- [x] 2.1 Escrever testes unitários falhos para `DatasetRepository.init()` garantindo que ele identifica corretamente a falta do índice local e descompacta o `indice.binarypb` e as thumbnails a partir de `assets/preload/`.
- [x] 2.2 Implementar a lógica de descompactação em `DatasetRepository.init()` para fazer os testes passarem.
- [x] 2.3 Escrever testes afirmando que a conclusão de `datasetRepo.init()` é aguardada (await) antes do `syncIndex` disparar.
- [x] 2.4 Modificar `main.dart` para aguardar explicitamente o `datasetRepo.init()` antes de prosseguir com `syncService.syncIndex()`.

## 3. Ajustes de Sincronização em Background

- [x] 3.1 Escrever testes unitários garantindo que `SyncService.syncIndex()` rode de forma assíncrona e atualize com sucesso o `activeDataset` sem bloquear a thread principal de execução.
- [x] 3.2 Atualizar `main.dart` para rodar `syncService.syncIndex()` sem usar await.
- [x] 3.3 Atualizar a implementação de `SyncService.syncIndex()` para garantir que o estado da UI continue reativo às atualizações de rede.

## 4. Thumbnails Offline na Aba Explorar

- [x] 4.1 Escrever testes unitários falhos para `SyncService.syncIndex()` afirmando que ele analisa o `indice.binarypb`, extrai as URLs de thumbnail e faz o download delas com sucesso para o diretório local de thumbnails.
- [x] 4.2 Implementar a lógica de extração e download de thumbnails em `SyncService.syncIndex()` para fazer os testes passarem.
- [x] 4.3 Escrever widget tests para `_buildCragIcon` em `frontend/lib/view_functions/browse_functions.dart` afirmando que ele tenta carregar através de `Image.file` (sistema de arquivos local) em vez de `Image.network`.
- [x] 4.4 Atualizar a implementação de `_buildCragIcon` para usar o sistema de arquivos local.
