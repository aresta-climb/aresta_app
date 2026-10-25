## MODIFIED Requirements

### Requirement: Borda Inteligente no Cabeçalho do Croqui e Separação de Miniatura de Catálogo
O cabeçalho da página de detalhes do croqui (`PicoDetailsPage`) MUST calcular sua altura expandida dinamicamente baseada na proporção de aspecto real de `croqui.caminhoThumbnail` até o limite máximo de `300.0 dp` ($\text{alturaExpandida} = \text{clamp}(\text{larguraTela} / \text{proporcaoCapa}, \text{alturaColapsada}, 300.0\text{ dp})$). A imagem DEVE ser exibida em alta resolução (`larguraAlvo: 1200`) sem nenhuma borda superior ou inferior. Quando a altura natural da capa exceder `300.0 dp` (capas verticais ou quadradas), a altura DEVE travar em `300.0 dp`, a foto DEVE tocar o topo e a base, e bordas inteligentes DEVEM ser exibidas exclusivamente nas laterais (esquerda e direita) com desfoque horizontal puro (`sigmaX: 24.0, sigmaY: 0.0`) e `ClipRect`. Já os cartões de listagem (`CragCard` e `OfflineCragCard`) MUST priorizar `thumbnails/<picoId>.webp` com fallback para `croqui.caminhoThumbnail`.

#### Scenario: Renderização da capa sem cortes com borda inteligente na página de detalhes do croqui
- **WHEN** a página de detalhes do croqui (`PicoDetailsPage`) construir a `SliverAppBar` para um croqui com `caminhoThumbnail` definido
- **THEN** o sistema DEVE resolver `croqui.caminhoThumbnail` com `larguraAlvo: 1200` e obter a proporção de aspecto da imagem
- **AND** a altura expandida da `SliverAppBar` DEVE ser ajustada proporcionalmente até o teto de `300.0 dp`
- **AND** a capa NÃO DEVE apresentar borda no topo nem no rodapé, terminando rente ao fim do cabeçalho
- **AND** caso a proporção da imagem exija preenchimento lateral (altura natural superior a `300.0 dp`), as bordas inteligentes DEVEM ser exibidas exclusivamente na esquerda e na direita com desfoque horizontal (`sigmaX: 24, sigmaY: 0`) e recorte estrito (`ClipRect`).

#### Scenario: Priorização de miniatura de catálogo em cartões de listagem a partir de Croqui
- **WHEN** um `CardCroquiViewModel` for instanciado a partir de um objeto `Croqui` (`CardCroquiViewModel.deCroqui`) e existir hash indexado para `thumbnails/<picoId>.webp`
- **THEN** `caminhoMiniatura` DEVE retornar `'thumbnails/<picoId>.webp'`
- **AND** caso não exista hash indexado para `thumbnails/<picoId>.webp`, `caminhoMiniatura` DEVE retornar `croqui.caminhoThumbnail` (ou `null` se ambos estiverem ausentes).

#### Scenario: Renderização padrão com preenchimento em cartões de catálogo
- **WHEN** `buildCragBackground` for utilizado nos cartões de catálogo (`CragCard`) sem borda inteligente ativada
- **THEN** a `larguraAlvo` padrão DEVE permanecer `450` e a imagem DEVE ser exibida em camada única com `BoxFit.cover`.
