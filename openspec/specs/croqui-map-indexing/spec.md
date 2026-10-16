# Capability: croqui-map-indexing

## Purpose

Global O(1) map index for resolving entities across pico hierarchies.

## Requirements

### Requirement: Indexing all maps in a Pico
The system SHALL catalog all map references and direct maps when a Pico is loaded or updated, associating references directly to their resolved entities via `DatasetResolver` in a single O(N) pass.

#### Scenario: Global indexing
- **WHEN** the `Pico` is resolved and rendered in `PageListenableBuilder`
- **THEN** all map references are parsed and linked to their target entities' `ResolvedDataset`
- **AND** all direct maps defined on `Escalada.mapas` remain accessible directly through the escalada instance

### Requirement: O(1) map resolution for escaladas
The system SHALL provide O(1) access to all maps that belong directly to or reference an escalada, returning the exact references with their contexts of origin in O(1) through the `ResolvedDataset`.

#### Scenario: Lookup by ReferenceKey
- **WHEN** `ViaPage` queries maps using its current Grupo, Setor, and Escalada context
- **THEN** it retrieves the matching maps immediately from `resolved.referencias` in O(1), prioritizing direct maps belonging to the escalada followed by maps from Setor, Grupo, or Pico where the escalada is referenced

#### Scenario: Lookup by Escalada UID or ResolvedDataset
- **WHEN** `ViaPage` queries maps where the escalada is referenced via its UID
- **THEN** it retrieves the matching maps immediately from `resolved.referencias` in O(1)
- **AND** displays direct maps from `escalada.mapas` followed by panoramic maps from Setor, Grupo, or Pico where the escalada is drawn
