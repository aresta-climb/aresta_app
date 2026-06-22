## ADDED Requirements

### Requirement: Map context resolution
The system SHALL resolve map references by merging the explicit reference data with the current navigation context.

#### Scenario: Implicit sector scope
- **WHEN** a map reference specifies a climb but omits the sector
- **THEN** the system injects the current map's sector context before resolving the target climb

### Requirement: Broken reference resilience
The system SHALL handle missing or renamed entities gracefully without crashing the map interface.

#### Scenario: Renamed climb in database
- **WHEN** a map reference points to a climb name that no longer exists in the active dataset
- **THEN** the resolver ignores the reference and the map renders its corresponding POI in a distinct 'broken' style (grey)
