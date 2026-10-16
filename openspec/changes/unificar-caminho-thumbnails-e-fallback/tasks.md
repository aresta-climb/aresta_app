## 1. Resolução de Imagens e Severidade de Logs (`ProvedorImagemAresta`)

- [ ] 1.1 (TDD - Red) Escrever testes unitários e de widget em `frontend/test/widgets/provedor_imagem_aresta_test.dart` validando:
  - Resolução de `thumbnails/<picoId>.webp` exclusivamente a partir de `$downloadsRoot/thumbnails/<picoId>.webp` (sem buscar em `$docsDir/thumbnails/`).
  - Não reescrita de `imagens/thumbnail.webp` para `thumbnails/<picoId>.webp` (preservando a imagem de capa interna do croqui em `$downloadsRoot/<picoId>/imagens/thumbnail.webp` ou sua URL remota com seu próprio hash SHA-256).
  - Emissão de `AppLogger.instance.logError` quando o SHA-256 estiver ausente em mídia remota de um croqui baixado offline (`isPicoDownloaded(picoId) == true`).
  - Emissão de `AppLogger.instance.logAviso` (sem disparar erro fatal/não-fatal no Crashlytics) quando o SHA-256 estiver ausente em mídia remota durante navegação online (`isPicoDownloaded(picoId) == false`).
- [ ] 1.2 (TDD - Green/Refactor) Implementar os ajustes em `frontend/lib/widgets/provedor_imagem_aresta.dart`:
  -Restringir `ehThumbnail` a caminhos iniciados por `thumbnails/`.
  - Remover a busca legada em `$docsDirPath/thumbnails/$picoId.webp`.
  - Condicionar a severidade do log de checksum ausente com base em `DatasetRepository.instance.isPicoDownloaded(picoId)`.
  - Atualizar docstrings (`///`) e `frontend/lib/widgets/README.md`.

## 2. Indexação de Hashes SHA-256 e Metadados (`DatasetRepository` e `CardCroquiViewModel`)

- [ ] 2.1 (TDD - Red) Escrever testes em `frontend/test/services/repositorio_dataset_test.dart` e `frontend/test/view/view_models/card_croqui_view_model_test.dart` validando:
  - `DatasetRepository.loadIndiceToMemory` não cria a chave ambígua `'thumbnail.webp'` no mapa de hashes (mantendo apenas `'thumbnails/$id.webp'`) e não preserva colisão com `imagens/thumbnail.webp` de `arquivosExternos`.
  - `DatasetRepository.loadIndiceToMemory` define `thumbnailUrl = null` em `CragMetadata` quando `resumo.checksumSha256Thumbnail` está vazio.
  - `DatasetRepository.obterSha256DaMidia` não faz fallback pelo nome `'thumbnail.webp'` quando o caminho for `imagens/thumbnail.webp`.
  - `CardCroquiViewModel.deMetadados` e `CardCroquiViewModel.deCroqui` retornam `caminhoMiniatura = ''` quando o croqui não possui thumbnail no catálogo (`thumbnailUrl == null`) nem `caminhoThumbnail` preenchido.
- [ ] 2.2 (TDD - Green/Refactor) Implementar as alterações em `frontend/lib/services/repositorio_dataset.dart` e `frontend/lib/view/view_models/card_croqui_view_model.dart`, atualizando docstrings (`///`) em português.

## 3. Fallback Visual nos Cards de UI (`OfflineCragCard` e `CardPico`)

- [ ] 3.1 (TDD - Red) Escrever testes de widget em `frontend/test/view/function_library/meus_croquis_functions_test.dart` e `frontend/test/widgets/card_pico_test.dart` validando:
  - Quando `caminhoMiniatura` (ou `caminhoThumbnail` / `thumbnailUrl`) for vazio, `OfflineCragCard` e `_CragBackgroundWidget` (`CardPico`) não invocam `ProvedorImagemAresta.resolver` e renderizam `Image.asset('assets/logo_splash.png', fit: BoxFit.contain)`.
  - Em estados de carregamento ou erro de resolução da imagem, o placeholder exibido utiliza `assets/logo_splash.png` em vez de `Icons.terrain`.
- [ ] 3.2 (TDD - Green/Refactor) Implementar o fallback visual com `assets/logo_splash.png` e a supressão de chamadas ao `ProvedorImagemAresta.resolver` para caminhos vazios em `frontend/lib/view/function_library/meus_croquis_functions.dart` e `frontend/lib/widgets/card_pico.dart`, atualizando docstrings (`///`).

## 4. Unificação do Armazenamento e Sincronização (`ExtratorAssetsPreload`, `SyncService` e `FeedbackMetadataCollector`)

- [ ] 4.1 (TDD - Red) Escrever testes unitários em `frontend/test/services/dataset/armazenamento/extrator_assets_preload_test.dart`, `frontend/test/services/http/sync_service_test.dart` e `frontend/test/services/feedback/feedback_metadata_collector_test.dart` validando:
  - Extração de thumbnails de preload em `$docsPath/downloads/thumbnails/`.
  - Sincronização `_syncThumbnails` salvando em `${downloadsDir.path}/thumbnails/`, executando também em modo experimental (no diretório isolado `$docsDir/editor/experimental/downloads/thumbnails/`) e removendo o diretório legado `$docsDir/thumbnails/` se existir.
  - Verificação de presença de thumbnail no coletor de diagnósticos (`FeedbackMetadataCollector`) apontando para `$downloadsPath/thumbnails/$croquiId.webp`.
- [ ] 4.2 (TDD - Green/Refactor) Implementar a unificação de diretórios em `frontend/lib/services/dataset/armazenamento/extrator_assets_preload.dart`, `frontend/lib/services/http/sync_service.dart` e `frontend/lib/services/feedback/feedback_metadata_collector.dart`.
- [ ] 4.3 Atualizar a documentação em `frontend/lib/aresta_api/proto/indice.proto`, `frontend/lib/services/README.md` e `frontend/lib/widgets/README.md` para refletir o caminho canônico `$downloadsRoot/thumbnails/<pico_id>.webp` e remover referências ao caminho legado.
- [ ] 4.4 Executar a suíte completa de testes automatizados e verificar 100% de cobertura nas unidades modificadas.
