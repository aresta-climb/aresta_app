# Proposal

## Why

Ao abrir a página de detalhes de um croqui (`PicoDetailsPage`), o cabeçalho possuía altura fixa de `300 dp`. Como a grande maioria das capas de croquis são fotos horizontais (16:9, 4:3, 2:1), a renderização com `BoxFit.contain` gerava sobras no topo e na base que eram preenchidas por um fundo desfocado. Esse desfoque vertical gerava uma faixa esbranquiçada/clara indesejada no rodapé do cabeçalho em vez de a imagem simplesmente terminar, além de consumir espaço desnecessário na tela que poderia ser aproveitado pelo conteúdo de setores e vias.

## What Changes

- **Altura Dinâmica do Cabeçalho até o Limite Máximo de 300 dp**: A `SliverAppBar` da `PicoDetailsPage` passa a calcular sua altura expandida dinamicamente baseada na proporção de aspecto real da imagem de capa: $\text{alturaExpandida} = \text{clamp}(\text{larguraTela} / \text{proporcaoCapa}, \text{alturaColapsada}, 300\text{ dp})$.
- **Eliminação de Bordas no Topo e Rodapé**: Para capas horizontais (onde a altura natural é menor ou igual a `300 dp`), a imagem preenche exatamente 100% da largura e 100% da altura do cabeçalho, terminando perfeitamente rente no rodapé sem nenhuma borda superior ou inferior.
- **Bordas Laterais Exclusivas para Capas Altas**: Para imagens verticais (A4 / 3:4) ou quadradas (1:1), a altura do cabeçalho trava no teto de `300 dp`. A imagem toca o topo e o rodapé (zero bordas verticais), e o fundo inteligente desfocado é exibido exclusivamente nas laterais (esquerda e direita) com desfoque horizontal puro (`sigmaX: 24.0, sigmaY: 0.0`) e `ClipRect`, impedindo qualquer vazamento ou faixa clara vertical.
- **Callback de Resolução de Proporção em `buildCragBackground`**: Adição de callback `aoResolverProporcao` em `buildCragBackground` e `_CragBackgroundWidget` para notificar a página de detalhes sobre as dimensões da textura decodificada.

## Capabilities

### New Capabilities
<!-- Nenhuma nova capability isolada introduzida -->

### Modified Capabilities
- `invalidacao-reativa-cache-imagens`: Atualiza os requisitos de exibição da capa do croqui no cabeçalho da página de detalhes para definir o cálculo da altura dinâmica proporcional da `SliverAppBar` até o teto de 300 dp, a eliminação total de bordas no topo e na base, e o isolamento das bordas inteligentes exclusivamente nas laterais com desfoque horizontal.

## Impact

- `frontend/lib/pages/pico.dart`: Cálculo da `alturaExpandida` da `SliverAppBar` baseado na proporção da capa do croqui e ajuste do cálculo do fator de colapso `t`.
- `frontend/lib/widgets/card_pico.dart`: Callback `aoResolverProporcao` e isolamento do desfoque no eixo horizontal (`sigmaX: 24, sigmaY: 0`) com `ClipRect` no `_CragBackgroundWidget`.
- `frontend/test/pages/pico_test.dart` e `frontend/test/widgets/card_pico_test.dart`: Testes de widget atualizados para validar o cálculo dinâmico da altura, a ausência de bordas verticais e a presença exclusiva de bordas laterais para imagens verticais.
