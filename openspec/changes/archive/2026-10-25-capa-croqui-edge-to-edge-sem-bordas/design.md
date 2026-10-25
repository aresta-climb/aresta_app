# Design

## Context

Veja `proposal.md` para motivação. Atualmente:
1. Em `frontend/lib/widgets/card_pico.dart`, `buildCragBackground` aceita `usarBordaInteligente: true`, empilhando um fundo `ImageFiltered` (`ImageFilter.blur(sigmaX: 24, sigmaY: 0)`) sob a imagem principal com `BoxFit.contain`.
2. Em `frontend/lib/pages/pico.dart`, `_calcularAlturaExpandida` limita a altura da `SliverAppBar` no intervalo `[collapsedHeight, 300.0]`, fazendo com que capas panorâmicas encolham até ~160 dp e capas verticais exibam grandes faixas laterais borradas.

## Goals / Non-Goals

**Goals:**
- Eliminar completamente bordas laterais, superiores e inferiores na capa do croqui utilizando `BoxFit.cover` em camada única combinado com uma janela de altura dinâmica `[math.max(220.0, collapsedHeight), 300.0]` dp.
- Garantir que croquis muito largos (`< 220.0 dp` de altura natural) mantenham pelo menos `220.0 dp` de altura visual com *crop* lateral suave, croquis em paisagem padrão (`220.0` a `300.0 dp`) apareçam 100% inteiros sem *crop*, e croquis quadrados/verticais (`> 300.0 dp`) preencham 100% da largura com *crop* suave no topo/base.
- Simplificar `buildCragBackground` removendo `usarBordaInteligente` e o custo de GPU do `ImageFilter.blur`.
- Seguir estritamente TDD (Red-Green-Refactor) e manter 100% de cobertura comportamental.

**Non-Goals:**
- Alterar o comportamento dos cartões de listagem (`CragCard` e `OfflineCragCard`), que continuam usando `larguraAlvo: 450` e `BoxFit.cover`.

## Decisions

### 1. Janela de Altura Visual `[math.max(220.0, collapsedHeight), 300.0]` dp + `BoxFit.cover`
- **Decisão**: Em `PicoDetailsPage._calcularAlturaExpandida(BuildContext context)`, o piso mínimo passa a ser `final minExpandedHeight = math.max(220.0, collapsedHeight);` e o teto máximo `const maxExpandedHeight = 300.0;`:
  $$\text{alturaExpandida} = \text{clamp}\left(\frac{\text{larguraTela}}{\text{proporcaoCapa}},\; \max(220.0, \text{collapsedHeight}),\; 300.0\right)$$
  A `SliverAppBar` continua recebendo `expandedHeight: alturaExpandida - topPadding` para compensar a soma interna `topPadding + expandedHeight` do `_SliverAppBarDelegate` do Flutter.
- **Racional**:
  - Quando `220.0 <= naturalHeight <= 300.0`, a caixa da `FlexibleSpaceBar` tem exatamente a mesma proporção da imagem (`larguraTela / naturalHeight == proporcaoCapa`), portanto `BoxFit.cover` não corta absolutamente nenhum pixel e não deixa nenhuma borda.
  - Quando `naturalHeight < 220.0` (ex: Pico da Vó Gusta), a caixa mantém `220.0 dp` de altura e `BoxFit.cover` corta suavemente apenas as extremidades laterais.
  - Quando `naturalHeight > 300.0` (ex: retrato/quadrado), a caixa mantém `300.0 dp` de altura e `BoxFit.cover` preenche 100% da largura da tela, cortando suavemente apenas as extremidades superior e inferior.

### 2. Simplificação de `buildCragBackground` (Camada Única com `BoxFit.cover`)
- **Decisão**: Remover o parâmetro `usarBordaInteligente` e o widget `_ImagemComNotificacaoProporcao` / `ImageFiltered` com camada dupla, mantendo apenas a notificação de proporção (`aoResolverProporcao` via `ImageStreamListener`) sobre a `Image` única com `BoxFit.cover`.
- **Racional**: Com `BoxFit.cover` preenchendo 100% da caixa em todos os cenários, nenhuma região de fundo jamais fica exposta ao redor da foto, tornando a camada desfocada código morto e desperdício de GPU.

## Risks / Trade-offs

- **[Risk] Capas muito verticais (ex: `9:16`) sofrerem corte no topo e na base** → **Mitigation**: O alinhamento central (`BoxFit.cover`) preserva a faixa central onde normalmente está a parede principal do pico, garantindo um visual limpo *edge-to-edge* sem barras laterais.
