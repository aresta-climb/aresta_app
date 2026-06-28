## ADDED Requirements

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

## REMOVED Requirements

### Requirement: Legacy markdown-based Mapa Geral
**Reason**: Replaced by native `mapasGerais` support
**Migration**: Remove `mapa_geral_pico.dart` and any logic depending on text-matching buttons for maps.
