# Tasks

## 1. Priorização da Thumbnail de Catálogo Local no Provedor de Imagem

- [x] 1.1 Escrever testes unitários (Red) em `frontend/test/widgets/provedor_imagem_aresta_test.dart` validando que: (a) ao resolver `imagens/thumbnail.webp` (ou `caminhoThumbnail`) para um croqui cujo arquivo local não existe, mas existe a miniatura `$downloadsRoot/thumbnails/<picoId>.webp`, o provedor retorna `ImagemArquivoAresta` apontando para a miniatura local sem disparar requisição HTTP; (b) quando nem a capa local nem a miniatura de catálogo existem, procede com download da CDN para `temp_cache`.
- [x] 1.2 Implementar a priorização da miniatura local de catálogo em `frontend/lib/widgets/provedor_imagem_aresta.dart` com docstrings em português brasileiro, verificando que os testes passam com sucesso (Green).

## 2. Configuração de Resolução Alvo de 450px no CardPico e Cabeçalho de Pico

- [x] 2.1 Escrever/atualizar testes de widget (Red) em `frontend/test/widgets/card_pico_test.dart` verificando que `buildCragBackground` solicita `larguraAlvo: 450` ao `ProvedorImagemAresta.resolver` e que as dimensões visuais na tela permanecem intactas.
- [x] 2.2 Atualizar `larguraAlvo: 450` no `_CragBackgroundWidgetState` em `frontend/lib/widgets/card_pico.dart` e validar que todos os testes de `card_pico_test.dart` e `pico_test.dart` passam (Green).
