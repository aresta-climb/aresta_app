# Design

## Context

Conforme descrito em `proposal.md`, a `PicoDetailsPage` mantinha uma altura fixa de `300 dp` para a `SliverAppBar`. Isso causava dois problemas em capas de formato paisagem/panorâmico:
1. Uma faixa esbranquiçada/clara indesejada no rodapé do cabeçalho, resultante do desfoque Gaussiano vertical espalhando os tons da foto sobre o espaço vazio entre a base da imagem e o fim do cabeçalho.
2. Desperdício de espaço vertical na tela por manter `300 dp` mesmo quando a foto precisava de apenas `190–290 dp`.

## Goals / Non-Goals

**Goals:**
- Ajustar dinamicamente a altura expandida da `SliverAppBar` na `PicoDetailsPage` à proporção de aspecto real da imagem de capa: $\text{alturaExpandida} = \text{clamp}(\text{larguraTela} / \text{proporcaoCapa}, \text{alturaColapsada}, 300\text{ dp})$.
- Garantir que fotos horizontais preencham 100% da largura e 100% da altura da `SliverAppBar`, eliminando por completo qualquer borda superior ou inferior.
- Exibir bordas inteligentes **exclusivamente nas laterais (esquerda e direita)** e apenas quando a foto for vertical ou quadrada e bater no teto de `300 dp`.
- Configurar o filtro de desfoque inteligente com `sigmaX: 24.0, sigmaY: 0.0` e `ClipRect` para impedir vazamento de desfoque ou esbranquiçado no rodapé.
- Suportar o callback `aoResolverProporcao` em `buildCragBackground` e a pré-resolução imediata na página de detalhes.

**Non-Goals:**
- Permitir que o cabeçalho ultrapasse o teto máximo de `300 dp`.
- Alterar o comportamento dos cartões de catálogo (`CragCard`), que continuam com `BoxFit.cover` padrão e `larguraAlvo: 450`.

## Decisions

### 1. Cálculo da Altura Expandida da `SliverAppBar`
- **Decisão**: Em `_PicoDetailsPageState`, manter o estado `double? _proporcaoCapa`. No método de construção, calcular:
  ```dart
  final screenWidth = MediaQuery.of(context).size.width;
  final collapsedHeight = MediaQuery.of(context).padding.top + kToolbarHeight;
  const maxExpandedHeight = 300.0;
  final alturaExpandida = (_proporcaoCapa != null && _proporcaoCapa! > 0)
      ? (screenWidth / _proporcaoCapa!).clamp(collapsedHeight, maxExpandedHeight)
      : maxExpandedHeight;
  ```
  Passar `alturaExpandida` para `SliverAppBar(expandedHeight: alturaExpandida, ...)` e utilizá-la no `LayoutBuilder` para o cálculo proporcional de colapso `t`.
- **Racional**: Capas em proporção paisagem (como *Ouroboulder* 4:3 com ~292 dp ou *Pilastras* 16:9 com ~220 dp) adaptam o cabeçalho com precisão de pixel à altura da imagem. A foto preenche a caixa inteira sem bordas superior/inferior e o conteúdo do pico sobe, aproveitando melhor a tela.

### 2. Desfoque Horizontal Puro (`sigmaX: 24, sigmaY: 0`) e `ClipRect`
- **Decisão**: No `_CragBackgroundWidget`, quando `usarBordaInteligente: true`, envolver a `Stack` em `ClipRect` e configurar `ImageFiltered` com `ImageFilter.blur(sigmaX: 24.0, sigmaY: 0.0, tileMode: TileMode.clamp)`.
- **Racional**: Como bordas inteligentes são necessárias apenas nas laterais (quando a foto toca o topo e o fundo em 300 dp), zerar o desfoque no eixo Y (`sigmaY: 0.0`) elimina qualquer sangramento vertical para cima ou para baixo, garantindo que o rodapé da foto seja nítido e termine rente ao cabeçalho.

### 3. Comunicação de Proporção via Callback e Pré-Resolução
- **Decisão**: `buildCragBackground` e `_CragBackgroundWidget` recebem o callback opcional `void Function(double proporcao)? aoResolverProporcao`. Ao obter o `ImageProvider`, o widget escuta o `ImageStream` e invoca o callback com `info.image.width / info.image.height`. Em paralelo, `_PicoDetailsPageState` inicializa a resolução no `initState` para que imagens em cache local definam a proporção antes do primeiro render.

## Risks / Trade-offs

- **[Risco] Transição visual de altura se a proporção for resolvida após o primeiro quadro** → Mitigação: Em croquis baixados offline ou em cache volátil, a resolução do `ImageProvider` local e leitura do header de imagem ocorre de forma síncrona/imediata nos primeiros milissegundos durante a própria transição de tela do Flutter, sem saltos visíveis.
- **[Risco] Imagens com proporção extrema (muito panorâmicas)** → Mitigação: O `.clamp(collapsedHeight, maxExpandedHeight)` assegura que a altura expandida nunca fique menor que a barra colapsada com a status bar e botão voltar (`collapsedHeight ~80–90 dp`).
