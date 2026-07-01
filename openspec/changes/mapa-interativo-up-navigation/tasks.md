## 1. UI Updates

- [ ] 1.1 Replace the existing "Mapa Geral" button with a dynamic hierarchical navigation button in `MapaInterativoPage`.
- [ ] 1.2 Implement `ConstrainedBox` with a `maxWidth` to limit the button's width and prevent it from obscuring the map.
- [ ] 1.3 Apply `TextOverflow.ellipsis` to the button's text label to handle long group/crag names gracefully.
- [ ] 1.4 Use a compact button style (e.g., `ActionChip` or custom small button) to reduce the visual footprint.

## 2. Navigation Logic

- [ ] 2.1 Implement logic to check if `setorContext` belongs to a `grupoContext` that has map files.
- [ ] 2.2 Implement logic to navigate to the Group Map (pushing a new `MapaInterativoNode`) if condition 2.1 is met.
- [ ] 2.3 Implement logic to check if `Pico` has `mapasGerais` when there is no Group Map available.
- [ ] 2.4 Implement logic to navigate to the General Map (pushing a new `MapaInterativoNode`) if condition 2.3 is met.
- [ ] 2.5 Ensure the button is completely hidden if neither a Group Map nor a General Map is available to navigate up to.
- [ ] 2.6 Verify that using the system "Back" button correctly pops the navigation stack and returns the user to the previous map.
