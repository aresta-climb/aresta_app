## Why

Currently, the "Mapa Geral" button inside interactive maps navigates away from the map interface to the crag's text-heavy home page (`PicoPage`). This breaks visual context and spatial immersion. We need an intuitive, hierarchical "Up" navigation that keeps users inside the interactive map experience when moving between map levels (Sector -> Group -> General Map).

## What Changes

- Replaces the static "Mapa Geral" button in `MapaInterativoPage` with a dynamic hierarchical navigation button.
- Restricts map navigation exclusively to other maps: if a higher-level map does not exist, the button is not displayed.
- Implements navigation logic:
  - From Sector map -> Group map (if sector belongs to a group and group has maps).
  - From Group map (or Sector without group) -> General crag map (if available).
- The button text is dynamically generated (e.g., `⬆ Grupo Vale Oculto` or `⬆ Mapa Geral`) to indicate the destination clearly.
- Truncates long names and uses a compact button design to avoid obstructing the interactive map view.

## Capabilities

### New Capabilities
- `map-hierarchy-navigation`: Defines the hierarchical navigation rules for moving "Up" within the interactive maps (Sector -> Group -> Crag).

### Modified Capabilities
- `interactive-map`: Modifies the existing floating action button requirements to be dynamic and conditional based on hierarchy.

## Impact

- `MapaInterativoPage` UI and logic.
- `navigation_functions.dart` (if new navigation methods are needed to directly open Group Maps or General Maps).
- The Android back stack (pushing new map nodes instead of navigating to Pico).
