## ADDED Requirements

### Requirement: Indexing all maps in a Pico
The system SHALL create a global map index (`CroquiMapIndex`) when a Pico is loaded, scanning all maps across all hierarchy levels (Pico, Grupo, Setor).

#### Scenario: Global indexing
- **WHEN** the `Pico` is resolved and rendered in `PageListenableBuilder`
- **THEN** all map references are parsed and stored in an index keyed by `ReferenceKey` (Grupo, Setor, Escalada)

### Requirement: O(1) map resolution for escaladas
The system SHALL provide O(1) access to all maps that reference an escalada, returning the exact `IndexedMap` with its context of origin.

#### Scenario: Lookup by ReferenceKey
- **WHEN** `ViaPage` queries the index using its current Grupo, Setor, and Escalada names
- **THEN** the index returns all matching maps immediately, regardless of whether the map belongs to a Setor, Grupo, or Pico
