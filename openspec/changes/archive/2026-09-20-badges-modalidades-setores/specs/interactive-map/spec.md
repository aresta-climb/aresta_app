## MODIFIED Requirements

### Requirement: Cross-linking navigation in interactive map
The interactive map SHALL support tapping POIs that refer to sectors or groups, not just climbs, displaying bottom cards with navigation actions and informative modality badges.

#### Scenario: Tapping a sector reference
- **WHEN** the user taps a POI that resolves to a Sector entity
- **THEN** a Sector Card is displayed at the bottom with a "Go to Sector" button and modality badges indicating the climb types and counts for that sector

#### Scenario: Tapping a group reference
- **WHEN** the user taps a POI that resolves to a Group entity
- **THEN** a Group Card is displayed at the bottom with a "Go to Group" button, a quantitative summary of sectors and climbs, and aggregated modality badges

#### Scenario: Navigating to another map from a sector reference
- **WHEN** the user clicks "View Sector Map" on a Sector Card triggered from a POI
- **THEN** the map navigates to the target sector's map using the specified `indice_mapa_alvo`
