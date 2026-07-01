## ADDED Requirements

### Requirement: Map interaction passing resolved context
The system SHALL pass the internally resolved Setor and Grupo from the clicked map marker to the `AppNav` router, instead of passing a potentially null context when on a global map.

#### Scenario: Navigation from global map
- **WHEN** a user clicks "Mais Info" on a route from the Mapão Geral (where sector context is null)
- **THEN** the app extracts the resolved sector and grupo from the marker and navigates to the via page seamlessly

### Requirement: Route to map navigation passing origin context
The system SHALL pass the correct context (Setor or Grupo) to the map viewer when navigating from a via to the map where it is referenced.

#### Scenario: Opening a group map from ViaPage
- **WHEN** a user clicks "Ver no mapa" for a map that was indexed as belonging to a Grupo
- **THEN** the map viewer opens with the correct `grupoContext` instead of failing
