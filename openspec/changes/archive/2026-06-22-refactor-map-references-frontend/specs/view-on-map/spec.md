## ADDED Requirements

### Requirement: View entity on map with target context
The system SHALL open the interactive map using explicit target contexts rather than legacy map IDs.

#### Scenario: View entity on map
- **WHEN** the user taps "View on map" from an entity's detail page (climb, sector or group)
- **THEN** the system navigates to the map passing the explicit `TargetContext` (grupo, setor, escalada) of that entity

### Requirement: Default map selection
The system SHALL respect the `indice_mapa_padrao` property of entities (climbs, sectors, groups) when determining which map to open.

#### Scenario: Entity has explicit default map
- **WHEN** an entity has `indice_mapa_padrao` set and "View on map" is clicked
- **THEN** the map corresponding to that index in the hierarchy is opened, provided it contains the entity

#### Scenario: Fallback map selection
- **WHEN** an entity does not have `indice_mapa_padrao` set or the specified map does not contain the entity
- **THEN** the system iterates through the context's maps and opens the first one that contains a reference to the entity
