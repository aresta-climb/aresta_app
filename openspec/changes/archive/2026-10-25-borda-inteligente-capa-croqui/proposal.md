## Why

Ao abrir a página de detalhes de um croqui (`PicoDetailsPage`), a imagem de capa configurada em `croqui.caminho_thumbnail` estava sendo cortada nas bordas (ex.: em capas `4:3` como *Ouroboulder* cortava as laterais no celular, e em capas verticais `A4` ou em tablets cortava o topo e a base) por ser renderizada com `BoxFit.cover` dentro do `SliverAppBar` (`expandedHeight: 300.0`). Além disso, uma tentativa anterior de reutilizar a miniatura quadrada de catálogo (`thumbnails/<picoId>.webp` de `600x600`) na tela de detalhes dependia de uma verificação acoplada ao nome literal `'imagens/thumbnail.webp'` em `ProvedorImagemAresta.resolver` — que não contemplava 41 dos 43 croquis do banco — e limitava a nitidez da capa em telas de alta densidade e tablets por conta do redimensionamento para `450px`.

## What Changes

- **Remoção de tratamento especial para `thumbnail.webp`**: Remover do `ProvedorImagemAresta.resolver` a heurística que redirecionava caminhos terminados em `'thumbnail.webp'` para `$downloadsRoot/thumbnails/$picoId.webp`. Qualquer caminho passado em `croqui.caminhoThumbnail` será resolvido uniformemente como uma mídia normal do croqui.
- **Separação clara entre miniatura de catálogo e capa de alta resolução**:
  - Nos cards de listagem (`CragCard` e `OfflineCragCard` via `CardCroquiViewModel`), priorizar a miniatura pré-gerada do catálogo (`thumbnails/<picoId>.webp`) e usar `croqui.caminhoThumbnail` como fallback caso a miniatura de catálogo não exista no índice.
  - No cabeçalho de `PicoDetailsPage`, carregar diretamente `croqui.caminhoThumbnail` (imagem de capa em alta resolução) decodificada com `larguraAlvo: 1200` para garantir nitidez em celulares e tablets.
- **Borda inteligente desfocada no cabeçalho do croqui (`expandedHeight: 300.0`)**: Atualizar `buildCragBackground` / `_CragBackgroundWidget` para suportar o modo de borda inteligente (Opção A) na `PicoDetailsPage`: manter a altura de `300 dp` e renderizar uma `Stack` com duas camadas compartilhando o mesmo `ImageProvider` — ao fundo, a imagem com `BoxFit.cover` + `ImageFiltered` (`ImageFilter.blur` com `TileMode.clamp`) e leve escurecimento preenchendo 100% da `SliverAppBar`; à frente, a imagem completa com `BoxFit.contain` ocupando 100% da área disponível sem cortar nenhum pixel em qualquer proporção de tela.

## Capabilities

### New Capabilities
<!-- Nenhuma nova capability isolada introduzida -->

### Modified Capabilities
- `invalidacao-reativa-cache-imagens`: Remove a regra especial de redirecionamento de `'imagens/thumbnail.webp'` no `ProvedorImagemAresta`, define a priorização de `thumbnails/<picoId>.webp` (com fallback para `croqui.caminhoThumbnail`) no `CardCroquiViewModel` para cards de listagem, e atualiza a renderização de `buildCragBackground` na `PicoDetailsPage` para usar `croqui.caminhoThumbnail` em alta resolução (`larguraAlvo: 1200`) com borda inteligente desfocada (`BoxFit.cover` com blur ao fundo + `BoxFit.contain` à frente).

## Impact

- `frontend/lib/widgets/provedor_imagem_aresta.dart`: Remoção do desvio condicional para `'imagens/thumbnail.webp'`.
- `frontend/lib/view/view_models/card_croqui_view_model.dart`: Priorização de `thumbnails/<id>.webp` em `_CardCroquiCroqui` com fallback para `croqui.caminhoThumbnail`.
- `frontend/lib/widgets/card_pico.dart`: Suporte a `larguraAlvo` configurável e modo de borda inteligente (`BoxFit.cover` desfocado ao fundo + `BoxFit.contain` à frente usando o mesmo `ImageProvider`) em `buildCragBackground` / `_CragBackgroundWidget`.
- `frontend/lib/pages/pico.dart`: Uso do modo de borda inteligente e `larguraAlvo: 1200` ao invocar `buildCragBackground` na `SliverAppBar` (`expandedHeight: 300.0`).
- `frontend/test/`: Atualização e adição dos testes espelhados em `provedor_imagem_aresta_test.dart`, `card_croqui_view_model_test.dart`, `card_pico_test.dart` e `pico_test.dart`.
