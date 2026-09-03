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


