# Design

## Context

Conforme detalhado em `proposal.md`, o aplicativo possuía uma divergência histórica no armazenamento e resolução de miniaturas:
1. O pipeline de build (`deploy_generated.py` no `aresta_db`) gera duas imagens distintas quando o croqui possui `caminho_thumbnail`:
   - A **imagem de capa interna do croqui** (até 1200x1200), mantida em `<picoId>/imagens/thumbnail.webp` (ou outro nome configurado em `caminho_thumbnail`), listada em `Croqui.arquivos_externos` e baixada em `$downloadsRoot/<picoId>/imagens/...`.
   - A **miniatura global do catálogo** (600x600 com borda borrada), gerada em `thumbnails/<picoId>.webp`, cujo hash é registrado em `ResumoCroqui.checksum_sha256_thumbnail` no `indice.binarypb`.
2. No aplicativo, `ExtratorAssetsPreload` e `SyncService._syncThumbnails` gravavam as miniaturas em `$docsDir/thumbnails/<picoId>.webp` em vez de `$downloadsRoot/thumbnails/<picoId>.webp`. Isso exigia desabilitar `_syncThumbnails` durante o Modo Experimental para não contaminar os arquivos oficiais.
3. Além disso, `ProvedorImagemAresta.resolver` tratava qualquer caminho terminado em `/thumbnail.webp` como sendo a miniatura global `thumbnails/<picoId>.webp`, e os ViewModels/widgets forçavam o caminho `'thumbnails/<picoId>.webp'` mesmo quando o croqui não tinha thumbnail definida (`checksum_sha256_thumbnail` ou `caminho_thumbnail` vazios), resultando em chamadas de rede sem hash SHA-256 e falsos positivos de `logError` no Crashlytics.

## Goals / Non-Goals

**Goals:**
- Unificar 100% da leitura, escrita, preload e auditoria de miniaturas permanentes em `$downloadsRoot/thumbnails/<picoId>.webp` (`editorDeCroqui.downloadsPath(docsPath)/thumbnails/<picoId>.webp`), permitindo sincronização nativa de thumbnails inclusive no Modo Experimental.
- Separar sem ambiguidades a miniatura global do catálogo (`thumbnails/<picoId>.webp`, indexada via `Indice`) da imagem interna de capa do croqui (`Croqui.caminho_thumbnail`, ex: `imagens/thumbnail.webp`, indexada via `Croqui.arquivos_externos`).
- Exibir `assets/logo_splash.png` como fallback visual elegante nos cards (`OfflineCragCard`, `CardPico`) e cabeçalho (`PicoPage` / `_CragBackgroundWidget`) quando o croqui não tiver thumbnail/capa ou enquanto carrega, sem disparar requisições HTTP para miniaturas inexistentes.
- Ajustar a severidade de log em `ProvedorImagemAresta.resolver` quando `hashEfetivo` for nulo/vazio em mídias remotas: `logError` apenas se o croqui estiver salvo offline (`isPicoDownloaded(picoId) == true`), e `logAviso` caso contrário.
- Atualizar toda a documentação técnica e comentários de `.proto` para eliminar referências ao caminho antigo.

**Non-Goals:**
- Alterar o formato de `Croqui.arquivos_externos` ou o pipeline Python do `aresta_db` (que já gera corretamente `thumbnails/<id>.webp` e `arquivos_externos`).

## Decisions

### 1. Caminho Canônico Único em `$downloadsRoot/thumbnails/<picoId>.webp`
- **Escolha**: Substituir todas as ocorrências de `$docsPath/thumbnails` por `${editorDeCroqui.downloadsPath(docsPath)}/thumbnails` (`$downloadsRoot/thumbnails`):
  - `ExtratorAssetsPreload.desempacotarAssetsPreload`: extrai `assets/preload/thumbnails/<cragId>.webp` para `$docsPath/downloads/thumbnails/<cragId>.webp` (ou recebe `downloadsPath`).
  - `SyncService._syncThumbnails`: grava e remove miniaturas em `${downloadsDir.path}/thumbnails/<id>.webp` e passa a ser executado tanto no Modo Oficial quanto no Modo Experimental (removendo a guarda `if (!editorDeCroqui.isExperimentalMode.value)` de `syncIndex`).
  - `ProvedorImagemAresta.resolver`: verifica apenas `File('$downloadsRoot/thumbnails/$picoId.webp')` na Etapa 1 para miniaturas (`ehThumbnail`).
  - `FeedbackMetadataCollector`: verifica `$downloadsPath/thumbnails/$croquiId.webp` (onde `downloadsPath = EditorDeCroqui.instance.downloadsPath(docsPath)`), seguido do cache volátil em `$tempCachePath/thumbnails/$croquiId.webp.<hash>`.
- **Limpeza do diretório legado**: Durante `ExtratorAssetsPreload` e `SyncService._syncThumbnails`, caso o diretório legado `$docsPath/thumbnails` ainda exista no dispositivo, ele é removido silenciosamente para liberar espaço e evitar estados fantasmas.
- **Alternativas consideradas**: Manter `$docsDir/thumbnails` para o modo oficial e criar apenas uma exceção para o modo experimental. Rejeitado por manter duplicidade de regras e violar o princípio de simplicidade (Princípio VI).

### 2. Separação Estrita entre `thumbnails/<picoId>.webp` e `imagens/thumbnail.webp`
- **Escolha**:
  - Em `ProvedorImagemAresta.resolver`: `ehThumbnail` passa a ser verdadeiro **somente** quando o caminho normalizado começa com `thumbnails/`, contém `/thumbnails/` ou é exatamente `$picoId.webp` / termina com `/$picoId.webp`. As cláusulas legadas `pathSemQuery.endsWith('/thumbnail.webp')`, `pathSemQuery == 'thumbnail.webp'` e `pathSemQuery.contains('thumbnail')` são removidas.
  - Em `DatasetRepository.loadIndiceToMemory` e `DatasetRepository.obterSha256DaMidia`: o hash `resumo.checksumSha256Thumbnail` é indexado apenas nas chaves `'thumbnails/${resumo.id}.webp'` e `'${resumo.id}.webp'`, removendo a gravação em `'thumbnail.webp'`. Assim, quando `indexarMidiasDoCroqui` indexa `imagens/thumbnail.webp` a partir de `croqui.arquivosExternos`, a chave `'imagens/thumbnail.webp'` (e `'thumbnail.webp'`) mantém intacto o hash da imagem de capa de 1200x1200.
  - Em `DatasetRepository.loadIndiceToMemory`: `thumbnailUrl` no `ResumoPico` só é preenchida com `'$baseUrl/thumbnails/$picoId.webp'` se `resumo.hasChecksumSha256Thumbnail() && resumo.checksumSha256Thumbnail.isNotEmpty`; caso contrário, recebe `''` (string vazia).
  - Em `CardCroquiViewModel`:
    - `_CardCroquiMetadados.caminhoMiniatura`: retorna `'thumbnails/${_metadados.id}.webp'` apenas se `_metadados.hasChecksumSha256Thumbnail() && _metadados.checksumSha256Thumbnail.isNotEmpty`; caso contrário, `''`.
    - `_CardCroquiCroqui.caminhoMiniatura`: retorna `_croqui.caminhoThumbnail` se `_croqui.hasCaminhoThumbnail() && _croqui.caminhoThumbnail.trim().isNotEmpty`; caso contrário, se o croqui possuir hash de miniatura registrado no `Indice` do `DatasetRepository`, retorna `'thumbnails/${_croqui.id}.webp'`; se não tiver nenhum dos dois, retorna `''`.

### 3. Fallback Visual com `assets/logo_splash.png`
- **Escolha**:
  - Em `_CragBackgroundWidget` (`frontend/lib/widgets/card_pico.dart`):
    - Remover o ramo `else if (cragId != null && cragId.isNotEmpty) { caminhoFinal = 'thumbnails/$cragId.webp'; }`. Se `capaPath` e `thumbnailUrl` forem vazios, `_provedorImagemFuture` permanece `null` (nenhuma chamada a `ProvedorImagemAresta.resolver` é feita).
    - Substituir o conteúdo de `_buildPlaceholder()` para renderizar `Image.asset('assets/logo_splash.png', fit: BoxFit.contain)` centralizado dentro do container de fundo escuro (`const Color(0xFF2C332A)`), com padding sutil para boa respiração visual.
  - Em `OfflineCragCard` (`frontend/lib/view/function_library/meus_croquis_functions.dart`):
    - Se `dados.caminhoMiniatura.trim().isEmpty`, não invoca `ProvedorImagemAresta.resolver` e renderiza diretamente o asset `Image.asset('assets/logo_splash.png', fit: BoxFit.contain)` dentro do container `60x60` (`context.colors.graniteEdge`).
    - Se `dados.caminhoMiniatura` não for vazio, usa o `FutureBuilder` e, em caso de erro ou retorno `null`, exibe o mesmo fallback com `assets/logo_splash.png`.

### 4. Severidade de Log Baseada no Estado Offline do Croqui
- **Escolha**:
  - Em `ProvedorImagemAresta.resolver` (quando `hashEfetivo == null || hashEfetivo.isEmpty` na etapa 3 de streaming remoto):
    - Consulta `(datasetRepository ?? DatasetRepository.instance)?.isPicoDownloaded(picoId) ?? false`.
    - Se `true` (croqui baixado offline): chama `AppLogger.instance.logError(...)` com `StackTrace.current` (pois um croqui salvo offline nunca deveria precisar buscar uma mídia remota sem hash).
    - Se `false` (croqui não baixado): chama `AppLogger.instance.logAviso(...)`.

## Risks / Trade-offs

- **[Risco] Dispositivos atualizando de versões anteriores com thumbnails salvas em `$docsDir/thumbnails/`** → **Mitigação**: Na inicialização/migração (`ExtratorAssetsPreload` e `SyncService._syncThumbnails`), caso um arquivo não esteja ainda em `$downloadsRoot/thumbnails/<id>.webp` mas exista em `$docsDir/thumbnails/<id>.webp` (ou no bundle de assets), `_syncThumbnails` ou o extrator popula `$downloadsRoot/thumbnails/` e remove a pasta legada `$docsDir/thumbnails/`.
- **[Risco] Testes existentes que mockavam `$docsDir/thumbnails` ou esperavam `Icons.terrain` / reescrita de `imagens/thumbnail.webp`** → **Mitigação**: Atualizar os testes unitários, de widget e de integração correspondentes seguindo TDD (Red-Green-Refactor) para validar a nova estrutura canônica e o fallback com `assets/logo_splash.png`.
