## ADDED Requirements

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
