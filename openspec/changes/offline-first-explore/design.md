## Context

O app atualmente experimenta estados de carregamento bloqueantes na inicialização quando a internet está lenta, aguardando o arquivo `indice.binarypb` remoto. Adicionalmente, instalações novas offline mostram uma aba Explorar completamente vazia, e as thumbnails na aba Explorar exigem acesso à internet pois dependem de `Image.network`. Esta proposta visa eliminar essas dependências de rede para a renderização inicial, tornando o app verdadeiramente offline-first.

## Goals / Non-Goals

**Goals:**
- Zero espera de rede durante a inicialização do app (startup).
- Enviar um banco de dados embutido inicial para que instalações novas funcionem offline.
- Baixar e fazer o cache das thumbnails da aba Explorar localmente.
- Lidar com as sincronizações de rede subsequentes completamente em background.
- Seguir o Desenvolvimento Orientado a Testes (TDD) para toda lógica nova, mantendo 100% de cobertura de testes unitários.

**Non-Goals:**
- Reescrever completamente o `SyncService`.
- Atualizar a UI para refletir o progresso do download de thumbnails em background (uma sincronização silenciosa é preferida).
- Comparação complexa de versionamento para atualizações do app (nós apenas checamos se o diretório local de documentos possui o arquivo, conforme pedido do usuário).

## Decisions

- **Immediate Local Initialization**: No `main.dart`, nós garantiremos que `datasetRepo.init()` seja explicitamente chamado (ou lógica similar) e resolvido completamente antes de tentar rodar o `syncIndex`.
- **Pre-bundling via Script**: Vamos fornecer um script (`tool/sync_preload.dart`) que busca o `indice.binarypb` e as thumbnails em `frontend/assets/preload/`. O CI vai rodar isso durante os version bumps.
- **Boot Unpacking**: `DatasetRepository.init()` vai checar se `indice.binarypb` existe em `getApplicationDocumentsDirectory()`. Se não, ele copia esse arquivo e todo o conteúdo de `assets/preload/` para o diretório de documentos. Já que isso só acontece se o diretório de documentos não possuir o arquivo, as atualizações do app não vão sobrescrever o índice potencialmente mais recente do usuário.
- **Thumbnail Sync in SyncService**: `SyncService.syncIndex()` vai ser modificado para analisar o índice recém-baixado, extrair as URLs de thumbnails, e baixá-las (usando cache ETag/hash se possível ou apenas download atômico padrão) para o diretório local de thumbnails.
- **Local Thumbnail UI**: `_buildCragIcon` vai usar `Image.file` apontando para o diretório de cache local ao invés de `Image.network`.

## Risks / Trade-offs

- **Risk**: Aumento no tamanho do pacote do app. → Mitigação: O índice tem ~7KB e as thumbnails comprimidas ~50KB. O aumento total de tamanho é de ~1MB, o que é aceitável.
- **Risk**: Dados preloaded defasados em uma instalação nova de uma versão antiga do app. → Mitigação: O `syncIndex` em background vai atualizar imediatamente os dados para a versão mais recente.
