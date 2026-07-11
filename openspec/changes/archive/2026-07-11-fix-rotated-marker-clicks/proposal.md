## Why

Ao clicar em marcadores no mapa interativo (como os rótulos 15 e 16 próximos ao rótulo rotacionado "Sentinela"), os cliques frequentemente são interceptados por formas rotacionadas maiores que estão próximas. Isso ocorre porque o sistema usa a Caixa Delimitadora Alinhada aos Eixos (Axis-Aligned Bounding Box - AABB) do elemento rotacionado para detecção de toques, o que cobre uma área muito maior do que o elemento visual em si, causando uma experiência ruim para o usuário e detecção imprecisa de cliques nos mapas interativos.

Para garantir que esse comportamento seja robusto e que não ocorram regressões no futuro, adotaremos uma abordagem de Desenvolvimento Orientado a Testes (TDD), buscando 100% de cobertura de testes unitários na lógica de detecção de toques (hit-testing), juntamente com docstrings abrangentes para explicar as nuances matemáticas e comportamentais dos cálculos de área.

## What Changes

- Escrever testes unitários para a lógica de hit-testing do `MarkerPainter` e para o cálculo de limites do `AreaHelper` antes de modificar a árvore de widgets.
- Documentar o `MarkerPainter`, o `AreaHelper` e o processo de hit-testing com docstrings claras no Dart.
- Modificar `_buildMarkers` no `mapa_interativo.dart` para alterar como o `GestureDetector` se comporta, delegando o hit test para o filho `MarkerPainter`, que implementa uma detecção de toque precisa baseada em polígonos.
- Inflar o caminho (path) no `MarkerPainter.hitTest` levemente para tornar linhas/polígonos finos mais fáceis de tocar (implementando o comentário que hoje existe no código).

## Capabilities

### New Capabilities
None

### Modified Capabilities
None

## Impact

- `frontend/lib/pages/mapa_interativo.dart`: A forma como os toques são tratados em todos os marcadores do mapa será atualizada para ser precisa em relação aos limites rotacionados, em vez da sua caixa delimitadora AABB.
- `frontend/test/`: Novos testes unitários serão introduzidos para cobrir a detecção de toques no mapa e os cálculos de área.
