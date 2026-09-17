## Purpose

Visualização interativa e navegação em croquis topográficos (mapas) offline com suporte a pan, zoom fluido, seleção de pontos de interesse e enquadramento automático de vias.
## Requirements
### Requirement: Cross-linking navigation in interactive map
The interactive map SHALL support tapping POIs that refer to sectors or groups, not just climbs.

#### Scenario: Tapping a sector reference
- **WHEN** the user taps a POI that resolves to a Sector entity
- **THEN** a Sector Card is displayed at the bottom with a "Go to Sector" button

#### Scenario: Navigating to another map from a sector reference
- **WHEN** the user clicks "View Sector Map" on a Sector Card triggered from a POI
- **THEN** the map navigates to the target sector's map using the specified `indice_mapa_alvo`

### Requirement: Pre-computation of references
The interactive map SHALL index references upon initialization to ensure 60fps performance during map interaction.

#### Scenario: Map initialization
- **WHEN** the map is loaded or the dataset changes
- **THEN** it resolves all references once and stores them in O(1) lookup dictionaries

### Requirement: Interactive Map context-free resolution
The interactive map SHALL support being rendered without an explicit Sector or Group context, using a global search across the Pico to resolve tapped POI references.

#### Scenario: Tapping a POI on a general map
- **WHEN** the user taps a POI on a Mapa Geral that references a Sector or Group
- **THEN** the system globally resolves the reference within the Pico
- **THEN** the corresponding Sector or Group card is shown

### Requirement: Render Mapas Gerais on Pico page
The Pico Details Page SHALL natively render thumbnails for all maps specified in its `mapasGerais` property.

#### Scenario: Pico has multiple general maps
- **WHEN** a Pico has general maps defined in the new v3 dataset
- **THEN** they are displayed sequentially above the list of Sectors
- **THEN** tapping a thumbnail opens the Interactive Map for that general map

### Requirement: Headless Interactive Map Rendering
The interactive map SHALL support being rendered without its own top App Bar (headless mode), delegating top-level navigation and actions to a parent container (such as a Map Carousel).

#### Scenario: Map rendered inside a Carousel
- **WHEN** the `MapaInterativoPage` is instantiated by `MapasCarrosselPage` with the headless/hideAppBar flag
- **THEN** it does not render the `Scaffold`'s `AppBar`
- **THEN** the map body occupies the entire available space (respecting Safe Area if delegated by parent)

### Requirement: Carousel Top Bar Integration
When presenting multiple maps, the Carousel SHALL manage its own fixed Top Bar to prevent UI clipping during swipe interactions.

#### Scenario: Swiping between maps in a carousel
- **WHEN** the user swipes left or right in a `MapasCarrosselPage`
- **THEN** the map image slides to the new page
- **THEN** the top navigation bar (AppBar) remains fixed on screen
- **THEN** the carousel pagination indicator (e.g., `< 01 de 02 >`) is rendered within the fixed Top Bar, avoiding overlap with map elements.

### Requirement: Estado Visual do Mapa Interativo
The system SHALL preservar o estado visual do mapa interativo (incluindo nível de zoom, posição de movimentação/pan e estado inicial de animação) quando o usuário navega entre múltiplos mapas em um carrossel.

#### Scenario: Deslizando de volta para um mapa visualizado anteriormente
- **WHEN** o usuário está visualizando múltiplos mapas interativos em um carrossel
- **AND** o usuário desliza para um novo mapa, e então desliza de volta para o mapa anterior
- **THEN** o mapa anterior retém sua posição exata de zoom e movimentação
- **AND** a animação inicial de zoom não é reproduzida novamente

### Requirement: O parser de áreas deve usar a nomenclatura da v4
The system SHALL parse PontoDeInteresse geometries using the v4 vocabulary: circulo, retangulo, poligono, quadrado, linha.

#### Scenario: Parsing circulo
- **WHEN** point type is circulo
- **THEN** it generates a circular polygon based on its x, y, and raio

#### Scenario: Parsing retangulo
- **WHEN** point type is retangulo
- **THEN** it generates a rectangular polygon with rotation

#### Scenario: Parsing poligono
- **WHEN** point type is poligono
- **THEN** it generates a freeform polygon

#### Scenario: Parsing quadrado
- **WHEN** point type is quadrado
- **THEN** it generates a square polygon based on x, y and lado without rotation

#### Scenario: Parsing linha
- **WHEN** o tipo do ponto de interesse for `linha`
- **THEN** o `AreaHelper.getAreaInfo` resolve os limites espaciais a partir da `caixa_delimitadora` pré-calculada ou das dimensões do próprio `Path`, gerando a caixa delimitadora envolvente (AABB) e a geometria correspondente

### Requirement: Auto-Zoom Monotônico para Pontos Únicos
The system SHALL centralizar a câmera no ponto de interesse selecionado sem jamais reduzir a escala de zoom atual caso o usuário já esteja com um nível de zoom superior à escala padrão.

#### Scenario: Seleção de ponto único quando o zoom atual é inferior ao alvo padrão
- **WHEN** o usuário está com o zoom do mapa em 1.0x (ou inferior a 2.5x)
- **AND** o usuário toca em um marcador de ponto único
- **THEN** a câmera amplia suavemente para a escala padrão de 2.5x (ou zoom customizado da referência)
- **AND** centraliza a área visível no ponto com o deslocamento vertical correspondente

#### Scenario: Seleção de ponto único quando o usuário já aplicou zoom manual elevado
- **WHEN** o usuário aplicou zoom manual para uma escala de 4.5x
- **AND** o usuário toca em um marcador de ponto único
- **THEN** a escala da câmera é mantida em 4.5x (sem redução de zoom)
- **AND** a câmera translada suavemente para centralizar o ponto selecionado

### Requirement: Enquadramento de Rotas com Múltiplos Pontos ou Linhas (Caixa Delimitadora)
The system SHALL calcular a escala necessária para enquadrar simultaneamente todos os marcadores associados (início e fim) ou o traçado vetorial completo da via no viewport visível com margens confortáveis ao selecionar uma via.

#### Scenario: Seleção de via com múltiplos pontos distantes
- **WHEN** o usuário seleciona uma via composta por múltiplos marcadores (início e fim)
- **THEN** o sistema calcula a caixa delimitadora englobando todos os pontos
- **THEN** a câmera ajusta o zoom e a posição para que todos os pontos da via fiquem visíveis na tela

#### Scenario: Seleção de via composta por linha vetorial
- **WHEN** o usuário seleciona uma via com traçado em linha vetorial (mesmo com um único elemento de linha no croqui)
- **THEN** o sistema aplica o enquadramento por caixa delimitadora cobrindo a altura e a largura completas do trajeto
- **THEN** a câmera preserva margens adequadas acima do card inferior de informações

### Requirement: Detecção Precisa de Toques ao Longo da Linha (Hit-Testing)
The `MarkerPainter` SHALL detectar toques do usuário em qualquer ponto ao longo de uma curva de traçado vetorial aberta, considerando uma tolerância ergonômica de proximidade física para toques com o dedo (~16dp).

#### Scenario: Toque próximo ao traçado da via
- **WHEN** o usuário toca a uma distância menor ou igual a 16dp de qualquer trecho da linha vetorial
- **THEN** o `hitTest` do pintor retorna `true`
- **THEN** a via correspondente é selecionada e recebe o foco do mapa

#### Scenario: Toque distante do traçado dentro da caixa delimitadora
- **WHEN** o usuário toca dentro da caixa delimitadora da linha, porém a uma distância superior a 16dp de qualquer trecho do traçado
- **THEN** o `hitTest` do pintor retorna `false`
- **THEN** o evento de toque não é consumido pelo marcador e propaga para o mapa de fundo, acionando o pulso de destaque

### Requirement: Zoom Dinâmico por Dimensão Confortável na Tela
The system SHALL calcular uma escala alvo proporcional ao tamanho do polígono do ponto na tela para garantir uma dimensão física mínima confortável (~20dp) em mapas de grandes dimensões ou alta resolução, sem nunca reduzir o zoom atual.

#### Scenario: Marcador de tamanho reduzido em croqui panorâmico
- **WHEN** o usuário toca em um marcador de dimensões físicas muito pequenas na escala 1.0
- **THEN** o sistema calcula a escala dinâmica para que o elemento atinja dimensão confortável de visualização e toque
- **THEN** o sistema aplica `max(escalaAtual, escalaDinamica)` para garantir que não ocorra redução de zoom

### Requirement: Limite de Zoom Expandido e Gesto de Duplo Toque
The interactive map SHALL suportar ampliações profundas de até 10.0x e permitir aproximação ágil via gesto de duplo toque.

#### Scenario: Ampliação máxima em imagem de alta resolução
- **WHEN** o usuário realiza o gesto de pinça para aproximar a imagem
- **THEN** o componente permite ampliação contínua até o limite máximo de 10.0x

#### Scenario: Duplo toque no mapa
- **WHEN** o usuário realiza um duplo toque em uma área do mapa
- **THEN** a câmera aproxima suavemente com foco nas coordenadas do toque

### Requirement: Renderização Incondicional de Traçados Vetoriais no Mapa
O `MapaInterativoPage` DEVE renderizar visualmente no mapa todos os pontos de interesse do tipo `linha`, independentemente de eles possuírem ou não uma entidade associada na lista `mapa.referencias`.

#### Scenario: Linha sem referência associada presente no croqui
- **WHEN** o croqui contém um ponto de interesse com geometria do tipo `linha` que não possui entrada correspondente em `mapa.referencias`
- **THEN** o componente não descarta o marcador com `SizedBox.shrink()`
- **THEN** o marcador é desenhado na rocha com seu traçado vetorial, estilo e marcadores correspondentes

#### Scenario: Toque em linha sem referência associada
- **WHEN** o usuário toca sobre uma linha vetorial que não possui referência cadastrada
- **THEN** a linha é selecionada visualmente (`isSelected == true`)
- **THEN** o sistema aplica o enquadramento de auto-zoom para a caixa delimitadora da linha

### Requirement: Prévia Textual da Descrição no Cartão Flutuante
O cartão flutuante do mapa interativo SHALL exibir uma prévia textual da descrição da via selecionada, formatada em texto simples (removendo marcações Markdown através de `stripMarkdownForSubtitle`), limitada a no máximo 2 linhas com reticências (`maxLines: 2, overflow: TextOverflow.ellipsis`), mantendo a altura compacta do cartão e preservando a visibilidade do croqui.

#### Scenario: Via selecionada no mapa com descrição cadastrada
- **WHEN** o usuário seleciona um ponto de interesse que resolve para uma via com `descricao` não vazia
- **THEN** o cartão flutuante exibe o texto da descrição limpo de marcações Markdown
- **AND** o texto é truncado com reticências após 2 linhas caso exceda o espaço
- **AND** o botão "Mais Info" continua disponível para abrir a visualização completa

#### Scenario: Via selecionada no mapa sem descrição cadastrada
- **WHEN** o usuário seleciona uma via cuja `descricao` é vazia
- **THEN** o cartão flutuante não exibe a área de texto de prévia, mantendo o espaçamento compacto original

### Requirement: Exibição de Proteções e Modalidade no Subtítulo do Cartão Flutuante
O subtítulo do cartão flutuante da via no mapa interativo SHALL incluir a quantidade de proteções na notação `<intermediárias>+<parada>` adjacente à modalidade e ao grau (ex: `Esportiva | 6°sup | 3+2` ou `Mista | 6°sup | 3+2`).

#### Scenario: Via com proteções cadastradas selecionada no mapa
- **WHEN** uma via esportiva ou móvel possui `quantidadeProtecoesIntermediarias > 0` ou `quantidadeProtecoesParada > 0`
- **THEN** o subtítulo do cartão exibe `[Modalidade] | [Grau] | <intermediárias>+<parada>`
- **AND** se a via for móvel com proteções intermediárias fixas, a modalidade exibida SHALL ser "Mista"

#### Scenario: Via sem proteções cadastradas selecionada no mapa
- **WHEN** a via selecionada não possui proteções intermediárias nem na parada (ex: boulder)
- **THEN** o subtítulo exibe apenas `[Modalidade] | [Grau]` sem o segmento de proteções

### Requirement: Renderização Imediata e Não-Bloqueante do Botão de Mapa no Setor
O componente de miniatura de mapa no setor SHALL renderizar imediatamente no primeiro frame o container com a proporção exata (`larguraMapa / alturaMapa`) e o botão de abertura do mapa interativo, permitindo toque e navegação instantânea para a tela cheia do mapa sem aguardar o download ou decodificação da imagem de fundo.

#### Scenario: Visualização do setor com mapa enquanto a imagem está baixando
- **WHEN** o usuário acessa um setor que possui mapas em um croqui online
- **AND** a imagem do mapa ainda não foi baixada ou está em processo de resolução
- **THEN** o card do mapa exibe imediatamente um container estilizado com cantos arredondados na proporção correta
- **AND** o botão "Abrir Mapa Interativo" é renderizado centralizado e habilitado para toque no primeiro frame
- **AND** o término do download da miniatura exibe a imagem em segundo plano com transição suave (fade-in) sem reconstruir ou piscar o botão

#### Scenario: Toque no botão de mapa antes do término do download da miniatura
- **WHEN** o usuário toca no botão "Abrir Mapa Interativo" no setor
- **AND** a miniatura do mapa ainda não completou seu download
- **THEN** o sistema aciona a navegação para a tela de mapas (`toMapas`) imediatamente sem reter o usuário no setor

### Requirement: Montagem Estrutural Imediata e Revelação Atômica no Mapa Interativo
A página do mapa interativo SHALL montar imediatamente sua estrutura visual (Scaffold, AppBar com título e controles de navegação, e tela de visualização com fundo escuro) no primeiro frame, mantendo um indicador de carregamento sutil enquanto a imagem em alta resolução é obtida, e revelando a imagem junto com os marcadores e traçados vetoriais de forma atômica e coordenada.

#### Scenario: Abertura da tela cheia do mapa interativo online
- **WHEN** a tela do mapa interativo é aberta e a imagem correspondente ainda está sendo obtida pela rede ou disco
- **AND** o modo headless não está ativo
- **THEN** a barra superior (AppBar) com botão de retorno e identificação do mapa/setor é exibida instantaneamente
- **AND** o canvas do mapa exibe um fundo escuro com indicador de carregamento centralizado
- **AND** os marcadores (POIs) e traçados vetoriais permanecem ocultos até que a imagem esteja pronta para exibição

#### Scenario: Revelação coordenada ao concluir o carregamento da imagem
- **WHEN** o carregamento e decodificação da imagem do mapa são concluídos
- **THEN** a imagem da rocha, os marcadores de interesse (POIs) e os traçados vetoriais são exibidos simultaneamente com transição suave de fade-in
- **AND** os controles de interação (zoom, pan, duplo toque) tornam-se plenamente operacionais

### Requirement: Pré-download Leve para Cache em Disco de Mapas de Setor e Carrossel
O sistema DEVE (MUST) disponibilizar o método `ProvedorImagemAresta.preCarregarNoDisco` com propriedades de idempotência, deduplicação e ausência de decodificação de imagem em RAM. O sistema DEVE disparar o pré-download assíncrono em segundo plano das páginas subsequentes de mapas tanto ao renderizar a miniatura do setor (`MapaThumbnail`) quanto ao abrir a visualização em carrossel (`MapasCarrosselPage`), garantindo disponibilidade local e navegação fluida mesmo sem conectividade na rocha.

#### Scenario: Execução de ProvedorImagemAresta.preCarregarNoDisco sem carregar em RAM
- **QUANDO** o método `ProvedorImagemAresta.preCarregarNoDisco` é invocado para uma imagem remota com checksum SHA-256 válido
- **THEN** o sistema baixa os bytes compactados da CDN e grava atomicamente em disco sob `temp_cache`
- **AND** a imagem NÃO DEVE ser decodificada na GPU nem inserida no `ImageCache` da memória RAM
- **AND** o método retorna a referência ao `File` salvo no disco

#### Scenario: Idempotência de pré-download para arquivos já presentes no disco
- **QUANDO** o método `preCarregarNoDisco` for chamado para uma imagem que já exista em `/downloads` ou `/temp_cache`
- **THEN** nenhuma requisição de rede HTTP deve ser realizada
- **AND** o arquivo local existente é retornado imediatamente

#### Scenario: Pré-download das páginas subsequentes ao exibir o Setor
- **QUANDO** o usuário visualiza a página de um setor (`SetorPage`) cujo `MapaThumbnail` possui múltiplos mapas (`mapas.length > 1`)
- **THEN** a miniatura renderiza o primeiro mapa normalmente
- **AND** o sistema agenda em segundo plano o download de todas as páginas subsequentes (índice 1 em diante) para o disco via `preCarregarNoDisco`

#### Scenario: Pré-download complementar de garantia ao abrir o carrossel
- **QUANDO** o usuário abre a visualização em carrossel (`MapasCarrosselPage`)
- **THEN** a página ativa é exibida na tela
- **AND** o sistema aciona em segundo plano a verificação e o pré-download das demais páginas para assegurar que estejam disponíveis em disco mesmo em acessos diretos

### Requirement: Salvaguarda Visual contra Falhas de Carregamento em Miniaturas e Capas
Os widgets `MapaThumbnail`, bem como as capas de `SetorPage` e `GrupoPage`, MUST fornecer salvaguarda visual defensiva com `errorBuilder` em seus componentes `Image`, prevenindo que falhas assíncronas de rede ou decodificação de imagem resultem na renderização do `ErrorWidget` do Flutter (caixa preta com linhas cruzadas vermelhas e texto cru de `SocketException`). Em caso de falha no carregamento do stream da imagem, o widget DEVE degradar graciosamente para o fundo sólido escuro do tema (`deepBasalt`), mantendo a legibilidade, o botão central de abertura de mapas e os elementos de interface totalmente operacionais.

#### Scenario: Falha de rede durante exibição do thumbnail do mapa
- **WHEN** o `MapaThumbnail` receber um provedor de imagem que falha ao carregar pela rede (offline)
- **THEN** o `errorBuilder` DEVE interceptar o erro silenciosamente
- **AND** renderizar `const SizedBox.shrink()` sobre a camada de fundo sólido do tema
- **AND** o botão de ação (ex: "Mapas Interativos") DEVE permanecer visível e interativo.

#### Scenario: Resolução nula de imagem de mapa quando offline
- **WHEN** o futuro de resolução de imagem retornar `null` devido à ausência de mídia baixada e falta de internet
- **THEN** o `MapaThumbnail` DEVE exibir a camada de fundo sólido (`deepBasalt`) e o botão central de ação sem instanciar o widget `Image`.

#### Scenario: Falha de rede na imagem de capa de setor ou grupo
- **WHEN** a imagem de capa de um setor ou grupo falhar ao carregar via streaming remoto
- **THEN** a tela DEVE manter a cor de fundo do tema e o gradiente escuro de cabeçalho sem exibir caixas de erro do framework.
