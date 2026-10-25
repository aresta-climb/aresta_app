# Tasks

## 1. Remoção do Tratamento Especial de `thumbnail.webp` no `ProvedorImagemAresta`

- [x] 1.1 [Red] Atualizar `frontend/test/widgets/provedor_imagem_aresta_test.dart` para garantir que a resolução de `imagens/thumbnail.webp` (ou qualquer `croqui.caminhoThumbnail`) quando o croqui não está baixado localmente NÃO redirecione para `$downloadsRoot/thumbnails/<picoId>.webp`, mas siga o fluxo normal de cache volátil / CDN, executando o teste e confirmando a falha inicial.
- [x] 1.2 [Green/Refactor] Remover o bloco condicional de fallback de `imagens/thumbnail.webp` para `$downloadsRoot/thumbnails/$picoId.webp` em `frontend/lib/widgets/provedor_imagem_aresta.dart`, atualizar as docstrings (`///`) e verificar que `flutter test test/widgets/provedor_imagem_aresta_test.dart --coverage` passa com 100% de cobertura.

## 2. Priorização de `thumbnails/<picoId>.webp` com Fallback em `CardCroquiViewModel`

- [x] 2.1 [Red] Adicionar testes unitários em `frontend/test/view/view_models/card_croqui_view_model_test.dart` validando que `CardCroquiViewModel.deCroqui` retorna `'thumbnails/<id>.webp'` quando seu hash está indexado no repositório e faz fallback para `croqui.caminhoThumbnail` apenas quando a miniatura de catálogo não possui hash indexado, executando o teste e confirmando a falha inicial.
- [x] 2.2 [Green/Refactor] Atualizar `_CardCroquiCroqui.caminhoMiniatura` em `frontend/lib/view/view_models/card_croqui_view_model.dart` para priorizar `'thumbnails/${_croqui.id}.webp'` com fallback para `_croqui.caminhoThumbnail`, documentar com docstring (`///`) e verificar que `flutter test test/view/view_models/card_croqui_view_model_test.dart --coverage` passa com 100% de cobertura.

## 3. Borda Inteligente (Opção A) e Resolução Configurável em `buildCragBackground` e `PicoDetailsPage`

- [x] 3.1 [Red] Adicionar testes de widget em `frontend/test/widgets/card_pico_test.dart` e `frontend/test/pages/pico_test.dart` verificando: (a) que `buildCragBackground` com `usarBordaInteligente: false` mantém camada única `BoxFit.cover` e `larguraAlvo: 450`; (b) que `buildCragBackground` com `usarBordaInteligente: true` e `larguraAlvo: 1200` (usado na `SliverAppBar` de `300 dp` da `PicoDetailsPage`) resolve `croqui.caminhoThumbnail` com `ResizeImage` de largura `1200` e renderiza duas camadas (`ImageFiltered` + `BoxFit.cover` ao fundo e `BoxFit.contain` à frente ocupando 100% da área disponível sem cortes), incluindo o comportamento de erro (`Icons.broken_image` sem duplicação), executando os testes e confirmando a falha inicial.
- [x] 3.2 [Green/Refactor] Implementar os parâmetros `larguraAlvo` e `usarBordaInteligente` em `buildCragBackground` / `_CragBackgroundWidget` (`frontend/lib/widgets/card_pico.dart`) e configurar `PicoDetailsPage` (`frontend/lib/pages/pico.dart`) para invocar `buildCragBackground(widget.croqui.id, widget.croqui.caminhoThumbnail, larguraAlvo: 1200, usarBordaInteligente: true)`, verificando que `flutter test test/widgets/card_pico_test.dart test/pages/pico_test.dart --coverage` passa com 100% de cobertura nas linhas e arquivos tocados.
