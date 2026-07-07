## Why

Atualmente, quando um mapa interativo é renderizado dentro de um carrossel de mapas (`MapasCarrosselPage`), a pílula de paginação (ex: `< 01 de 02 >`) flutua de forma absoluta na tela e frequentemente sofre "clipping" ou sobreposição com os elementos da `AppBar` do próprio mapa ou botões (como "Mapa Geral"). Além disso, quando o usuário dá um swipe para o lado, a `AppBar` inteira do mapa desliza junto, o que não proporciona uma experiência fluida e nativa. Esta refatoração move a responsabilidade da barra superior (AppBar) para o Carrossel, mantendo-a fixa durante o swipe e integrando a paginação de forma elegante no próprio título.

## What Changes

- Extrair o `AppBar` do `MapaInterativoPage` e gerenciar no `MapasCarrosselPage` quando o mapa for renderizado em um carrossel.
- O `MapaInterativoPage` vai passar a aceitar um parâmetro (ex: `hideAppBar`) para não desenhar o `AppBar` próprio quando estiver sendo usado internamente pelo carrossel.
- A pílula de navegação e as ações superiores agora serão renderizadas diretamente no `AppBar` do `MapasCarrosselPage`, eliminando sobreposições com os botões internos do mapa (como "Mapa Geral" ou "Auto Zoom").
- Apenas a imagem do mapa (conteúdo da `PageView`) fará parte da animação de *swipe*, garantindo uma navegação imersiva e consistente.

## Capabilities

### New Capabilities
Nenhuma. Esta é apenas uma refatoração arquitetural de UI.

### Modified Capabilities
- `interactive-map`: Mudança de comportamento arquitetural de UI onde a barra superior pode ser ocultada em favor da barra do carrossel em modo multi-mapas.

## Impact

- Modificações primárias no componente pai `MapasCarrosselPage` (que passa a ter o `Scaffold` e `AppBar`).
- Modificação no `MapaInterativoPage` para possibilitar exibição "headless" (sem `AppBar`).
- Apenas impactos positivos de usabilidade e layout. Nenhuma alteração nas dependências externas ou APIs de backend.
