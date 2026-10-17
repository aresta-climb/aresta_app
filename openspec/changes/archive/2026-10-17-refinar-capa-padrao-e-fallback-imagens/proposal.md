# Proposal

## Why

Atualmente, os componentes de cartão e cabeçalho de croqui (`CardPico`, `PicoPage` e `OfflineCragCard`) exibem a logo da splash screen (`assets/logo_splash.png`) tanto quando o croqui não possui capa declarada no Protobuf quanto quando a capa existe no Protobuf, mas ainda não foi baixada ou falhou ao carregar. Além disso, o asset `assets/logo_splash.png` possui grandes margens internas para o ícone adaptativo do Android 12 e era renderizado com `Padding`, fazendo a capa padrão parecer uma imagem encolhida em vez de preencher todo o espaço do cartão.

## What Changes

- **Separação entre "Sem capa no Protobuf" e "Imagem ainda não disponível"**:
  - Exibir a capa padrão do Aresta **exclusivamente** quando o croqui não tiver miniatura/capa declarada no Protobuf (`checksumSha256Thumbnail` vazio no `ResumoCroqui` ou `caminhoThumbnail` vazio no `Croqui`, resultando em `capaPath`/`thumbnailUrl`/`caminhoMiniatura` vazios).
  - Quando o croqui possuir capa declarada no Protobuf, mas ela ainda não estiver baixada localmente ou falhar ao carregar (`ProvedorImagemAresta.resolver` retornar `null` ou `Image.errorBuilder` for acionado), exibir o ícone padrão de imagem indisponível (`Icons.broken_image`, `color: Colors.grey`) centralizado sobre o fundo escuro, mantendo consistência com `OfflineMarkdown` e `MapaInterativoPage`.
  - Durante o estado `ConnectionState.waiting` de uma capa existente no Protobuf, exibir apenas o container de fundo escuro neutro sem exibir prematuramente a logo do Aresta.
- **Preenchimento de 100% da área na capa padrão com `assets/logo_in_app.jpg`**:
  - Substituir `assets/logo_splash.png` por `assets/logo_in_app.jpg` sem `Padding` interno, preenchendo 100% da área disponível com fundo preto (`Colors.black`) ao redor.

## Capabilities

### New Capabilities
<!-- Nenhuma nova capacidade introduzida -->

### Modified Capabilities
- `invalidacao-reativa-cache-imagens`: Refina o requisito de fallback visual de miniaturas e capas de croquis para distinguir entre ausência de capa no Protobuf (`assets/logo_in_app.jpg` cobrindo 100% da área com fundo preto ao redor) e capa declarada no Protobuf porém indisponível no momento (`Icons.broken_image` cinza).

## Impact

- `frontend/lib/widgets/card_pico.dart` (`_CragBackgroundWidget`)
- `frontend/lib/view/function_library/meus_croquis_functions.dart` (`OfflineCragCard`)
- Testes de widget correspondentes em `frontend/test/widgets/card_pico_test.dart`, `frontend/test/pages/pico_test.dart` e `frontend/test/view/function_library/meus_croquis_functions_test.dart`
- Especificação `openspec/specs/invalidacao-reativa-cache-imagens/spec.md`
