# Proposta: Priorização da Thumbnail de Catálogo e Aumento de Resolução para 450px

## Por Que

Atualmente, ao abrir um croqui em modo online, a página de detalhes do pico (`PicoDetailsPage`) tenta carregar a imagem de capa através de `croqui.caminhoThumbnail` (`imagens/thumbnail.webp`). Como o croqui não está baixado offline, o aplicativo realiza uma requisição de rede para baixar a imagem da CDN, mesmo que o dispositivo já possua a miniatura do catálogo (`thumbnails/<picoId>.webp`) salva localmente desde o pré-carregamento (*preload*).

Aumentando a resolução da miniatura de catálogo para 450px no pipeline e atualizando o aplicativo para priorizar `thumbnails/<picoId>.webp` sobre `imagens/thumbnail.webp`, eliminamos totalmente o download redundante na abertura de croquis online, garantimos carregamento visual instantâneo (0 ms de rede) e elevamos a nitidez do cabeçalho sem quebrar a compatibilidade com clientes legados.

## O Que Muda

- **Priorização da Thumbnail de Catálogo no Aplicativo**: Ao resolver a imagem de capa de um pico (em `_CragBackgroundWidget` / `buildCragBackground` e `ProvedorImagemAresta`), o aplicativo deve verificar e priorizar a existência da miniatura do catálogo `thumbnails/<picoId>.webp` no armazenamento local (`$downloadsRoot/thumbnails/`) ou cache; apenas caso ela não exista, deve recorrer ao caminho `imagens/thumbnail.webp` (ou `caminhoThumbnail`).
- **Resolução Alvo de 450px no CardPico**: O `buildCragBackground` em `card_pico.dart` passa a requisitar `larguraAlvo: 450` ao `ProvedorImagemAresta` (em vez de 300px), aproveitando a resolução otimizada da nova thumbnail de 450px sem alterar o tamanho do widget nem o layout visual na tela.
- **Preservação de Compatibilidade Retroativa (*Backwards Compatibility*)**:
  - No pipeline de build do banco/servidor, o campo `caminho_thumbnail` do Protobuf continuará apontando para `imagens/thumbnail.webp` e o arquivo permanecerá listado em `arquivos_externos` para não quebrar versões antigas do aplicativo.
  - O aplicativo cliente passa a preferir ativamente `thumbnails/<picoId>.webp` quando disponível.

## Capabilities

### Modified Capabilities
- `invalidacao-reativa-cache-imagens`: Atualização do requisito de resolução de capas para priorizar a miniatura local de catálogo `thumbnails/<picoId>.webp` antes de recorrer a `imagens/thumbnail.webp`, e adoção da resolução alvo de 450px no cabeçalho do pico.

## Impacto

- **Frontend (`frontend/lib/widgets/card_pico.dart`, `frontend/lib/widgets/provedor_imagem_aresta.dart`)**:
  - `_CragBackgroundWidget` passa `larguraAlvo: 450` e verifica se existe miniatura local antes de acionar rede para imagem interna não baixada.
  - `ProvedorImagemAresta.resolver`: Suporte a fallback inteligente para `thumbnails/<picoId>.webp` quando uma capa interna do croqui não estiver presente no disco.
- **Testes**: Atualização e expansão dos testes unitários e de widget em `card_pico_test.dart` e `provedor_imagem_aresta_test.dart`.
- **Pipeline de Dados (`aresta_db`)**: Geração de miniaturas do catálogo na dimensão de 450px em WebP (mantendo `caminho_thumbnail` e `arquivos_externos` inalterados para legado).
