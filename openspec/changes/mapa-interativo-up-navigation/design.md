## Context
Currently, the `MapaInterativoPage` contains a static "Mapa Geral" button that calls `AppNav.toPico` to open the `PicoPage`. Users reported that this breaks the immersion of exploring maps, as they expect a map navigation button to take them to another map, not a text-based overview page.

## Goals / Non-Goals

**Goals:**
- Provide smooth hierarchical navigation (Sector Map -> Group Map -> General Map).
- Maintain the user within the `MapaInterativoPage` environment for map-to-map navigation.
- Ensure the button does not obstruct the interactive map view by using a compact design and truncating long texts.

**Non-Goals:**
- Changing the underlying Protobuf data structures of maps (`Pico`, `SetorOuGrupo`, `Mapa`).
- Removing the `PicoPage` general map section (this remains as-is for users browsing from the crag page).

## Decisions

- **Dynamic Button Text**: The button text will indicate the destination (e.g., `^ Grupo Oculto` ou `^ Mapa Geral`) to provide immediate context. We will use a compact widget like `ActionChip` or a custom small button instead of the large `FloatingActionButton.extended`.
- **Text Truncation**: A `ConstrainedBox` with a reasonable `maxWidth` (e.g., ~150-200px or 40% of screen width) will be used along with `TextOverflow.ellipsis` to ensure the map isn't obscured by long group names.
- **Hierarchical Fallback Logic**:
  1. Check if `setorContext` belongs to a `grupoContext` that has maps. If so, destination is the Group Map.
  2. Else, check if the `pico` has `mapasGerais`. If so, destination is the General Map.
  3. Else, do not show the button at all.
- **Navigation Stack**: Navigating up will call `AppNav.toMapaInterativo(...)`, pushing a new `MapaInterativoNode` to the navigation stack. This allows the user to intuitively use the system "Back" button to return down the hierarchy.

## Risks / Trade-offs

- **Risk**: Pushing new `MapaInterativoPage` instances onto the stack instead of replacing could consume memory.
  - **Mitigation**: The hierarchy is strictly shallow (Sector -> Group -> Crag), meaning the stack will be at most 2-3 levels deep for maps, which Flutter can handle effortlessly.
- **Risk**: Determining if a `Setor` belongs to a `Grupo` might require scanning the `pico.setoresOuGrupos` if the `grupoContext` is not provided to the page.
  - **Mitigation**: `MapaInterativoPage` already accepts `grupoContext`. We will ensure it is reliably populated, or we can look it up from the `pico` if missing.
