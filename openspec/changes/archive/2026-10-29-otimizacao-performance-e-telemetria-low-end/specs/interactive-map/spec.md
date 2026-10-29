## MODIFIED Requirements

### Requirement: Pre-computation of references
The interactive map SHALL index references upon initialization using `alvo_uid` and `pontos_uids` (or legacy fallbacks) by querying a single shared `DatasetResolver` instance in O(1) per reference to ensure 60fps performance during map transitions and interaction.

#### Scenario: Map initialization
- **WHEN** the map is loaded or the dataset changes
- **THEN** it obtains the shared `DatasetResolver` for the current `Pico` once and resolves all references in O(M) total time (where M is the number of map references) without re-indexing or re-normalizing the `Pico` per reference

## ADDED Requirements

### Requirement: Repintura Reativa sem Rebuild de Widgets no Destaque do Mapa
O `MapaInterativoPage` DEVE (MUST) acionar a animação de pulso de destaque (`highlightIntensity`) e atualizações de escala diretamente na camada de pintura (`CustomPainter` via `repaint` `Listenable`), sem invocar `setState` na página inteira a cada quadro da animação.

#### Scenario: Animação de pulso ao tocar em área vazia do mapa
- **WHEN** o usuário toca em uma área sem marcador no mapa interativo e dispara a animação de pulso de destaque
- **THEN** os `MarkerPainter` repintam os marcadores diretamente via notificação do `Listenable` de animação
- **AND** o `State` de `MapaInterativoPage` não executa `setState` nem reconstrói a árvore de widgets a cada frame da animação

### Requirement: Cache de Layout de Texto e Isolamento de Repintura nos Marcadores
O sistema DEVE (MUST) reutilizar instâncias cacheadas de `TextPainter` já medidas (`.layout()`) para os rótulos de marcadores de traçados vetoriais quando o texto e o tamanho da fonte não mudarem, e isolar a superfície do mapa com `RepaintBoundary`.

#### Scenario: Redesenho de marcadores numerados durante animação ou seleção
- **WHEN** o `MarkerPainter` desenha marcadores do tipo `CIRCULO_IDENTIFICADOR`, `INICIO_AGACHADO` ou `FIM_TOP` com rótulo textual
- **THEN** o pintor reutiliza o `TextPainter` previamente calculado para aquela combinação de rótulo e dimensão de fonte sem recalcular `layout()` a cada frame
