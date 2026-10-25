# Proposal

## Why

Ao exibir capas de croquis verticais/quadradas na página de detalhes (`PicoDetailsPage`) com `BoxFit.contain`, as bordas laterais desfocadas ocupam grande parte da largura da tela (~44% a ~58%), poluindo o visual. Por outro lado, capas muito panorâmicas (ex: Pico da Vó Gusta) encolhem demais a altura do cabeçalho (~160 dp), espremendo o botão de voltar contra o título do croqui.

## What Changes

- **Janela de Altura Dinâmica (`220 dp` a `300 dp`)**: `PicoDetailsPage` calculará a altura visual total expandida da `SliverAppBar` (`alturaExpandida`) aplicando `clamp(larguraTela / proporcaoCapa, math.max(220.0, collapsedHeight), 300.0)` e descontando `topPadding` em `expandedHeight` para manter o visual *edge-to-edge* desde o topo físico da tela (`y = 0`).
- **Renderização Limpa com `BoxFit.cover` em Camada Única (Zero Bordas)**:
  - Croquis panorâmicos (`alturaNatural < 220 dp`): travam na altura mínima confortável de `220 dp`, com `BoxFit.cover` cortando suavemente apenas as extremidades esquerda e direita.
  - Croquis em paisagem padrão (`220 dp <= alturaNatural <= 300 dp`): a caixa adapta sua altura exatamente à proporção da foto, exibindo 100% da imagem sem corte e sem borda.
  - Croquis quadrados ou verticais (`alturaNatural > 300 dp`): travam na altura máxima de `300 dp`, com `BoxFit.cover` preenchendo 100% da largura da tela (*edge-to-edge*) e cortando suavemente apenas as extremidades do topo e da base.
- **Remoção de `usarBordaInteligente` e do `ImageFilter.blur` em `buildCragBackground`**: Elimina a camada dupla desfocada de `frontend/lib/widgets/card_pico.dart`, mantendo apenas a imagem em camada única com `BoxFit.cover` e o callback opcional `aoResolverProporcao`, preservando o gradiente superior (*scrim* da barra de status) e inferior (transição para `deepBasalt`) no `FlexibleSpaceBar`.

## Capabilities

### New Capabilities
<!-- Nenhuma nova capability -->

### Modified Capabilities
- `invalidacao-reativa-cache-imagens`: Atualiza o requisito de cabeçalho do croqui para substituir a borda inteligente desfocada por `BoxFit.cover` em camada única combinado à janela de altura dinâmica `[math.max(220.0, collapsedHeight), 300.0]` *edge-to-edge*.

## Impact

- `frontend/lib/widgets/card_pico.dart`: Remoção do parâmetro `usarBordaInteligente` e da camada `ImageFiltered` com `ImageFilter.blur`, mantendo camada única com `BoxFit.cover` e notificação via `aoResolverProporcao`.
- `frontend/lib/pages/pico.dart`: Atualização de `_calcularAlturaExpandida` para impor o piso mínimo de `220.0 dp` (`math.max(220.0, collapsedHeight)`) e remoção do argumento `usarBordaInteligente: true`.
- `frontend/test/widgets/card_pico_test.dart` e `frontend/test/pages/pico_test.dart`: Atualização dos testes orientados a comportamento (TDD) para validar a janela `[220.0, 300.0]` dp e a renderização em camada única com `BoxFit.cover`.
