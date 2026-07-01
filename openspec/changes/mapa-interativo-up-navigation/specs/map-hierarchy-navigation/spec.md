## ADDED Requirements

### Requirement: Hierarchical "Up" Map Navigation Button
The interactive map SHALL provide a hierarchical "Up" navigation button when a higher-level map is available in the crag structure.

#### Scenario: Sector map with a parent group
- **WHEN** the user views a Sector map and the sector belongs to a Group that has maps
- **THEN** the system displays a button to navigate up to the Group map
- **THEN** the button text indicates the destination (e.g., `^ Grupo Oculto`)

#### Scenario: Sector map without a parent group, or Group map
- **WHEN** the user views a Group map, or a Sector map with no parent Group
- **THEN** the system checks if the Crag (Pico) has general maps
- **THEN** if a general map exists, the system displays a button to navigate up to the General map (e.g., `^ Mapa Geral`)

#### Scenario: No higher-level map available
- **WHEN** the user is viewing the Crag's general map, or there are no higher-level maps available
- **THEN** the "Up" navigation button SHALL NOT be displayed

#### Scenario: Display Constraints
- **WHEN** the "Up" navigation button is displayed
- **THEN** the text SHALL be truncated with an ellipsis if it exceeds the maximum safe width to prevent obscuring the map interface

#### Scenario: Navigation Stack
- **WHEN** the user taps the "Up" navigation button
- **THEN** the system SHALL push a new interactive map node to the navigation stack
- **THEN** the user can use the system "Back" button to return to the previous map
