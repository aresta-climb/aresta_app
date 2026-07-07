## ADDED Requirements

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
