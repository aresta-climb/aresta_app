# Spec Delta: interactive-map

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
- **THEN** the map navigates to the target sector's map carousel opening the first map by default without relying on deprecated `indice_mapa_alvo`

### Requirement: Pre-computation of references
The interactive map SHALL index references upon initialization using `alvo_uid` and `pontos_uids` (or legacy fallbacks) to ensure 60fps performance during map interaction.

#### Scenario: Map initialization
- **WHEN** the map is loaded or the dataset changes
- **THEN** it resolves all references via `DatasetResolver` and populates the local `_poiToRefs` dictionary using the POI UIDs (or legacy IDs)

## ADDED Requirements

### Requirement: Resolução Local de Traçados e Rótulos no Escopo do Mapa
O sistema MUST resolver os traçados vetoriais e rótulos de identificação consultando os pontos de interesse estritamente dentro da coleção local `mapa.pontosDeInteresse`, priorizando o campo `rotulo` sobre `label` e os identificadores `pontos_uids` sobre `ids`.

#### Scenario: Extração de rótulo por rotulo e pontos_uids
- **WHEN** `extrairRotuloReferencia` processa uma referência que contém `pontos_uids` e o ponto de interesse possui `rotulo` preenchido
- **THEN** o rótulo retornado utiliza o valor de `rotulo` correspondente aos pontos daquele mapa

#### Scenario: Fallback para croquis com id e label legados
- **WHEN** uma referência contém `ids` e os pontos possuem apenas `label` preenchido
- **THEN** o rótulo é extraído com sucesso garantindo retrocompatibilidade
