## MODIFIED Requirements

### Requirement: Borda Inteligente no Cabeçalho do Croqui e Separação de Miniatura de Catálogo
O cabeçalho da página de detalhes do croqui (`PicoDetailsPage`) MUST calcular sua altura visual total expandida dinamicamente baseada na proporção de aspecto real de `croqui.caminhoThumbnail` dentro da janela `[math.max(220.0, alturaColapsada), 300.0]` dp ($\text{alturaExpandida} = \text{clamp}(\text{larguraTela} / \text{proporcaoCapa}, \max(220.0, \text{alturaColapsada}), 300.0\text{ dp})$), passando `expandedHeight: alturaExpandida - topPadding` para a `SliverAppBar` de modo que a altura visual *edge-to-edge* na tela corresponda exatamente a `alturaExpandida` desde o topo físico (`y = 0`). A imagem DEVE ser exibida em alta resolução (`larguraAlvo: 1200`) em camada única com `BoxFit.cover`, sem nenhuma borda superior, inferior ou lateral, acompanhada de um sutil gradiente superior escuro (*scrim* de `Colors.black.withValues(alpha: 0.45)` em `0.0` até `Colors.transparent` em `0.22`) para preservar a legibilidade da barra de status e transição suave inferior para `deepBasalt`. Quando a altura natural da capa for inferior a `220.0 dp` (capas panorâmicas), a altura DEVE travar no mínimo de `220.0 dp` cortando suavemente as extremidades laterais com `BoxFit.cover`; quando a altura natural exceder `300.0 dp` (capas verticais ou quadradas), a altura DEVE travar em `300.0 dp` preenchendo 100% da largura da tela e cortando suavemente as extremidades superior e inferior com `BoxFit.cover`. Já os cartões de listagem (`CragCard` e `OfflineCragCard`) MUST priorizar `thumbnails/<picoId>.webp` com fallback para `croqui.caminhoThumbnail`.

#### Scenario: Renderização da capa edge-to-edge sem bordas na página de detalhes do croqui
- **WHEN** a página de detalhes do croqui (`PicoDetailsPage`) construir a `SliverAppBar` para um croqui com `caminhoThumbnail` definido
- **THEN** o sistema DEVE resolver `croqui.caminhoThumbnail` com `larguraAlvo: 1200` em camada única com `BoxFit.cover` e obter a proporção de aspecto da imagem
- **AND** a altura expandida da `SliverAppBar` DEVE descontar `MediaQuery.of(context).padding.top` (`alturaExpandida - topPadding`) para que a caixa renderizada tenha altura total *edge-to-edge* igual a `clamp(larguraTela / proporcaoCapa, math.max(220.0, alturaColapsada), 300.0)`
- **AND** a capa NÃO DEVE apresentar borda no topo, no rodapé nem nas laterais, exibindo 100% da foto quando a altura natural estiver entre `220.0 dp` e `300.0 dp`, cortando as laterais quando for mais larga que o piso de `220.0 dp`, e cortando topo/base quando for mais alta que o teto de `300.0 dp`.

#### Scenario: Priorização de miniatura de catálogo em cartões de listagem a partir de Croqui
- **WHEN** um `CardCroquiViewModel` for instanciado a partir de um objeto `Croqui` (`CardCroquiViewModel.deCroqui`) e existir hash indexado para `thumbnails/<picoId>.webp`
- **THEN** `caminhoMiniatura` DEVE retornar `'thumbnails/<picoId>.webp'`
- **AND** caso não exista hash indexado para `thumbnails/<picoId>.webp`, `caminhoMiniatura` DEVE retornar `croqui.caminhoThumbnail` (ou `null` se ambos estiverem ausentes).

#### Scenario: Renderização padrão com preenchimento em cartões de catálogo
- **WHEN** `buildCragBackground` for utilizado nos cartões de catálogo (`CragCard`)
- **THEN** a `larguraAlvo` padrão DEVE permanecer `450` e a imagem DEVE ser exibida em camada única com `BoxFit.cover`.
