## MODIFIED Requirements

### Requirement: Indexing all maps in a Pico
The system SHALL create a global map index (`CroquiMapIndex`) when a Pico is loaded, scanning all maps across all hierarchy levels (Pico, Grupo, Setor, and Escaladas).

#### Scenario: Global indexing
- **WHEN** the `Pico` is resolved and rendered in `PageListenableBuilder`
- **THEN** all map references are parsed and stored in an index keyed by `ReferenceKey` (Grupo, Setor, Escalada)
- **AND** all direct maps defined on `Escalada.mapas` are cataloged in the index associated with the respective escalada

### Requirement: O(1) map resolution for escaladas
The system SHALL provide O(1) access to all maps that belong directly to or reference an escalada, returning the exact `IndexedMap`s with their contexts of origin.

#### Scenario: Lookup by ReferenceKey
- **WHEN** `ViaPage` queries the index using its current Grupo, Setor, and Escalada names
- **THEN** the index returns all matching maps immediately, prioritizing direct maps belonging to the escalada followed by maps from Setor, Grupo, or Pico where the escalada is referenced
