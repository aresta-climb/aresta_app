# Proposal

## Why

O aplicativo ainda registra exceções não-fatais no Firebase Crashlytics (`Checksum SHA-256 ausente ou nulo para mídia remota <picoId> em thumbnails/<picoId>.webp`) quando um croqui sem thumbnail (especialmente em modo experimental/Live Reload no Editor) é aberto ou listado. Essa falha ocorre por uma soma de três fatores: (1) uma regressão que fragmentou o armazenamento local de miniaturas entre `$docsDir/thumbnails/` e `$downloadsRoot/thumbnails/`, impedindo a sincronização isolada de miniaturas no Modo Experimental; (2) heurísticas legadas que confundem a imagem interna de capa do croqui (`imagens/thumbnail.webp` em `arquivos_externos`) com a miniatura global do catálogo (`thumbnails/<picoId>.webp` no `Indice`) e forçam a requisição de `thumbnails/<picoId>.webp` mesmo quando o croqui não possui thumbnail; e (3) a emissão incondicional de `logError` para mídias remotas sem hash mesmo em croquis que não estão salvos offline.

## What Changes

- **Unificação do Armazenamento de Miniaturas em `$downloadsRoot/thumbnails/<picoId>.webp`**:
  - Padronizar `ExtratorAssetsPreload`, `SyncService._syncThumbnails`, `FeedbackMetadataCollector` e `ProvedorImagemAresta` para ler e gravar miniaturas exclusivamente em `$downloadsRoot/thumbnails/<picoId>.webp` (onde `downloadsRoot = editorDeCroqui.downloadsPath(docsPath)`), garantindo isolamento automático entre o modo oficial (`$docsDir/downloads/thumbnails/`) e o modo experimental (`$docsDir/editor/experimental/downloads/thumbnails/`).
  - Habilitar a execução de `_syncThumbnails` também no Modo Experimental em `SyncService.syncIndex`, já que o diretório de destino agora é isolado e expurgado pelo `nukeExperimentalData()`.
  - Migrar/limpar de forma transparente a pasta antiga `$docsDir/thumbnails/` caso exista no dispositivo.
- **Remoção do Tratamento Legado de `imagens/thumbnail.webp` e de Fallbacks Forçados**:
  - **BREAKING (Interno)**: Remover de `ProvedorImagemAresta.resolver` e `DatasetRepository` o mapeamento legado que tratava `imagens/thumbnail.webp` ou `thumbnail.webp` como sinônimo da rota global `thumbnails/<picoId>.webp`. A rota `thumbnails/<picoId>.webp` passa a representar exclusivamente a miniatura global do catálogo (`ResumoCroqui.checksum_sha256_thumbnail`), enquanto `imagens/thumbnail.webp` (definida em `Croqui.caminho_thumbnail`) é resolvida como arquivo normal de `Croqui.arquivos_externos` em `$downloadsRoot/<picoId>/imagens/thumbnail.webp`.
  - Remover dos ViewModels (`CardCroquiViewModel`) e widgets (`_CragBackgroundWidget` em `card_pico.dart`) o fallback que forçava a rota `'thumbnails/$id.webp'` quando `checksumSha256Thumbnail` ou `caminhoThumbnail` estivessem vazios.
- **Fallback Visual com a Logo da Splash Screen (`assets/logo_splash.png`)**:
  - Substituir o placeholder genérico (`Icons.terrain`) em `OfflineCragCard` (`meus_croquis_functions.dart`) e `_CragBackgroundWidget` (`card_pico.dart` / `pico.dart`) pela logo oficial `assets/logo_splash.png` (com `BoxFit.contain` sobre o fundo escuro do card/header) quando o croqui não possuir thumbnail/capa definida ou enquanto a imagem estiver sendo carregada/falhar, preservando o layout da UI sem disparar requisições HTTP para miniaturas inexistentes.
- **Severidade Condicional de Log para Ausência de Checksum SHA-256 em Mídia Remota**:
  - Em `ProvedorImagemAresta.resolver`, quando `hashEfetivo` for nulo ou vazio ao recorrer ao `NetworkImage`, emitir `AppLogger.instance.logError` apenas se o croqui estiver baixado offline (`isPicoDownloaded(picoId) == true`); caso contrário (exploração online), registrar apenas `AppLogger.instance.logAviso`.
- **Atualização de Documentação e Especificações**:
  - Atualizar `indice.proto`, `frontend/lib/services/README.md`, `frontend/lib/widgets/README.md`, docstrings e especificações OpenSpec para refletir o caminho canônico `$downloadsRoot/thumbnails/<picoId>.webp` e eliminar menções aos caminhos antigos `$docsDir/thumbnails/` e `imagens/thumbnail.webp` no índice.

## Capabilities

### New Capabilities

*(Nenhuma nova capability — os comportamentos pertencem às capabilities existentes abaixo).*

### Modified Capabilities

- `invalidacao-reativa-cache-imagens`: Atualiza o caminho permanente de miniaturas para `$downloadsRoot/thumbnails/<picoId>.webp`, remove o mapeamento legado de `thumbnail.webp` na tabela de dispersão do índice, define o fallback visual com `assets/logo_splash.png` quando não houver thumbnail e ajusta a severidade do log de ausência de SHA-256 em mídia remota (erro para croqui baixado offline, aviso para croqui online).
- `transmissao-croqui-online`: Atualiza a referência de armazenamento permanente de miniaturas de `$docsDir/thumbnails/` para `$downloadsRoot/thumbnails/`.
- `discord-feedback-security`: Atualiza a auditoria criptográfica de integridade no `FeedbackMetadataCollector` para verificar a miniatura no caminho unificado `$downloadsRoot/thumbnails/<croquiId>.webp`.

## Impact

- **Código Afetado**:
  - `frontend/lib/widgets/provedor_imagem_aresta.dart`
  - `frontend/lib/services/repositorio_dataset.dart`
  - `frontend/lib/services/http/sync_service.dart`
  - `frontend/lib/services/dataset/armazenamento/extrator_assets_preload.dart`
  - `frontend/lib/services/feedback/feedback_metadata_collector.dart`
  - `frontend/lib/view/view_models/card_croqui_view_model.dart`
  - `frontend/lib/view/function_library/meus_croquis_functions.dart`
  - `frontend/lib/widgets/card_pico.dart`
- **Schemas e Documentação**:
  - `frontend/lib/aresta_api/proto/indice.proto`
  - `frontend/lib/services/README.md`
  - `frontend/lib/widgets/README.md`
- **Testes**:
  - Atualização e adição de testes unitários e de widget correspondentes em `frontend/test/` seguindo TDD e 100% de cobertura.
