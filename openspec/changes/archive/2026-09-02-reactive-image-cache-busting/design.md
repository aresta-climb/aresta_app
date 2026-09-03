## Context

O Aresta Climb possui um mecanismo reativo de sincronização e modo experimental (Editor Desktop via WebSocket e sincronização atômica em segundo plano). Quando um novo pacote de croqui chega, o `DatasetRepository` atualiza o `activeDataset` e o `PageListenableBuilder` reconstrói a tela visível. Textos atualizam perfeitamente porque recebem novas instâncias de `String` dos objetos Protobuf, mas imagens locais e remotas permanecem congeladas na versão anterior.

Isso ocorre porque:
1. O Flutter utiliza `PaintingBinding.instance.imageCache` como cache global de texturas na RAM/GPU.
2. O `FileImage` padrão gera chaves baseadas unicamente em `file.path` e `scale`. Como o caminho do arquivo em disco permanece o mesmo (ex: `/downloads/pico_1/croqui_mapa.webp`), o Flutter considera que `oldImage == newImage`, ignorando a reconstrução e retornando a textura decodificada antiga.
3. Para imagens remotas via `NetworkImage`, os componentes de tela não forneciam o `checksumSha256`, resultando em URLs sem query string de versão que sofrem do mesmo problema de cache hit.
4. `SetorPage` e `GrupoPage` inicializam o futuro da imagem no `initState` e não o atualizam em `didUpdateWidget`.
5. `MapaInterativoPage` e `MapaThumbnail` tentavam chamar `provider?.evict()`, mas o código estava condicionado a `widget.mapa != oldWidget.mapa` (que avalia como falso quando apenas a imagem muda, já que o hash fica em `Croqui.arquivosExternos` e não em `Mapa`).

## Goals / Non-Goals

**Goals:**
- Prover atualização visual imediata de qualquer imagem modificada em disco ou na nuvem após eventos de recarregamento (*Live Reload*) ou download de atualizações.
- Eliminar a necessidade de chamadas manuais a `evict()` dispersas em componentes da interface.
- Preservar a posição de rolagem e evitar qualquer cintilação (*flicker*) em imagens que não sofreram alterações.
- Tratar mídias de croquis locais, mídias de croquis remotas e miniaturas (*thumbnails*) através de uma arquitetura centralizada e unificada baseada no `checksumSha256` autoritativo.
- Cumprir integralmente os princípios de engenharia de `PRINCIPIOS.md`: código 100% em português brasileiro, 100% de cobertura de testes, TDD rigoroso com testes de widget em primeiro lugar e documentação contínua.

**Non-Goals:**
- Não detectar edições manuais cruas em disco feitas fora do pipeline do compilador de croqui / Protobuf (o `checksumSha256` do catálogo é autoritativo).
- Não reiniciar árvores de estado ou componentes com novas `Key`s aleatórias (o que resetaria o scroll do usuário).

## Decisions

### Decisão 1: `ImagemArquivoAresta` com chave versionada por `checksumSha256` (Princípios I, II e VI)
- **Escolha**: Criar a classe `ImagemArquivoAresta` em `frontend/lib/widgets/imagem_arquivo_aresta.dart`, estendendo `ImageProvider<ChaveImagemArquivoAresta>`. A chave encapsula `(caminhoArquivo, escala, checksumSha256)`.
- **Racional**:
  - Quando a imagem é modificada no editor ou baixada, o hash muda. O método `operator ==` da chave avalia como diferente da versão anterior.
  - O widget `Image` nativo do Flutter detecta que `widget.image != oldWidget.image` e aciona `_updateImage()`.
  - O `ImageCache` não encontra a nova chave no mapa em memória $\implies$ executa nova decodificação atômica sem afetar outras imagens.
  - Implementação declarativa, simples e sem abstrações desnecessárias (~40 linhas de código limpo).
- **Alternativas consideradas**:
  - *Limpeza global via `imageCache.clear()`*: Ineficiente (força recarga de todas as imagens da tela) e ineficaz se o widget `Image` achar que o provider é idêntico (`old == new`).
  - *Checar `file.lastModifiedSync()` no disco*: Requereria I/O de disco síncrono no frame de build do Flutter, gerando perda de fluidez (*jank*). O hash do Protobuf já é calculado e determinístico.

### Decisão 2: Tabela de dispersão centralizada $O(1)$ no `DatasetRepository` (Princípios II e VI)
- **Escolha**: O `DatasetRepository` manterá o método `String? obterSha256DaMidia(String picoId, String caminho)` apoiado em uma tabela de dispersão em memória `Map<String, String>` por pico ativo (`caminhoNormalizado -> checksumSha256`). Esse mapa é populado ao carregar o `Croqui` (`croqui.arquivosExternos`) e enriquecido com as miniaturas do índice (`'thumbnails/<picoId>.webp' -> resumo.checksumSha256Thumbnail`).
- **Racional**:
  - Unifica a busca de hashes para qualquer tipo de imagem sob a mesma chave de caminho canônico.
  - Desacopla as telas (`OfflineMarkdown`, `MapaInterativoPage`, etc.) da responsabilidade de rastrear onde o hash reside no Protobuf.
  - Custo de consulta $O(1)$ puro em tempo de frame.
- **Alternativas consideradas**:
  - *Obrigar os chamadores a passar o hash*: Impossível para `OfflineMarkdown` sem duplicar código, pois tags Markdown (`![foto](foto.webp)`) só possuem o caminho relativo.

### Decisão 3: Cache-busting automático para URLs remotas no `ProvedorImagemAresta`
- **Escolha**: O `ProvedorImagemAresta` consultará a tabela de dispersão do `DatasetRepository` e injetará automaticamente `?v=<checksumSha256>` na URL antes de instanciar `NetworkImage`.
- **Racional**:
  - Fura instantaneamente caches de borda da CDN (Cloudflare/edge) e caches locais em memória do Flutter quando o croqui remoto for atualizado.

### Decisão 4: Alinhamento do ciclo de vida em telas com estado
- **Escolha**: Em `SetorPage`, `GrupoPage`, `MapaInterativoPage` e `MapaThumbnail`:
  - No `didUpdateWidget`, re-executar a atribuição do `Future` de resolução de imagem envolvida em `setState()`.
  - Remover a condição `if (widget.mapa != oldWidget.mapa)` e as chamadas assíncronas a `provider?.evict()`.
- **Racional**:
  - O `didUpdateWidget` só roda quando a página é reconstruída com novos dados pelo `PageListenableBuilder`.
  - Como o novo provider usará a chave com hash, se o hash for igual, o Flutter mantém a textura existente na GPU sem re-decodificar. Se o hash mudou, o Flutter recarrega suavemente.

### Decisão 5: Testes de Widget em Primeiro Lugar e TDD Rigoroso (Princípios III, IV e V)
- **Escolha**: Priorizar testes de widget que simulam o fluxo real do usuário (recebimento de hot reload na tela aberta com preservação de scroll e atualização da imagem) antes de descer para os testes unitários da chave.
- **Racional**:
  - Garante a integridade visual da interface de ponta a ponta e assegura que não haja regressão na experiência do usuário.
  - Exigência estrita de 100% de cobertura nos arquivos modificados e criados.

## Risks / Trade-offs

- **[Risco] Mídia não encontrada na tabela de dispersão de hashes**:
  - *Mitigação*: Se o caminho não tiver hash correspondente no `Croqui` (ex: arquivo legado ou rascunho), o provedor faz fallback para a chave padrão sem hash (comportamento atual), emitindo log de aviso em debug sem quebrar o app.
- **[Risco] Re-resolução do Future causar reinício de carregamento em frames de animação**:
  - *Mitigação*: `didUpdateWidget` não é chamado em animações internas ou gestos de zoom do usuário (`InteractiveViewer`), apenas quando o `PageListenableBuilder` dispara reconstrução externa de novos dados.

## Migration Plan

1. Escrever testes de widget falhando (Red) para o fluxo de recarregamento de imagem em telas com estado.
2. Implementar `ImagemArquivoAresta` e seus testes com 100% de cobertura.
3. Implementar a tabela de dispersão no `DatasetRepository` com 100% de cobertura.
4. Integrar o `ProvedorImagemAresta` com a tabela de dispersão e suporte remoto `?v=hash`.
5. Atualizar os métodos `didUpdateWidget` em `SetorPage`, `GrupoPage`, `MapaInterativoPage` e `MapaThumbnail`.
6. Atualizar a documentação técnica (`HOT_RELOAD.md` e `README.md` pertinentes) com docstrings completas em português brasileiro.
