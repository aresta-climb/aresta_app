## MODIFIED Requirements

### Requirement: View entity on map with target context
The system SHALL open the interactive map using explicit target contexts rather than legacy map IDs, sequencing local direct maps before sector-level maps when available.

#### Scenario: View entity on map
- **WHEN** the user taps "View on map" from an entity's detail page (climb, sector or group)
- **THEN** the system navigates to the map passing the explicit `TargetContext` (grupo, setor, escalada) of that entity
- **AND** if the entity is an escalada with direct maps, those maps are presented as the initial items in the carousel

### Requirement: Default map selection
The system SHALL determine which map to open by prioritizing direct climb maps when they exist, falling back to the default map index or the first map in the context where the entity is referenced.

#### Scenario: Entity has explicit default map
- **WHEN** an entity has `indice_mapa_padrao` set and "View on map" is clicked
- **THEN** the map corresponding to that index in the hierarchy is opened, provided it contains the entity

#### Scenario: Fallback map selection
- **WHEN** an entity does not have `indice_mapa_padrao` set or the specified map does not contain the entity
- **THEN** the system iterates through the context's maps and opens the first one that contains a reference to the entity, or the first direct map of the escalada if present
