## Context

A `MapaInterativoPage` renderiza um mapa interativo onde pontos de interesse (POIs) e áreas interativas são desenhados e podem ser clicados. Cada área interativa é envolvida por um `GestureDetector`. Atualmente, o `GestureDetector` está configurado com `behavior: HitTestBehavior.opaque`. Isso faz com que o detector de gestos registre toques em qualquer lugar dentro de sua caixa delimitadora (que é uma Caixa Delimitadora Alinhada aos Eixos, AABB). Para rótulos retangulares rotacionados ou áreas finas, essa AABB inclui muito espaço vazio, levando a uma detecção de toque imprecisa.

O `MarkerPainter` já implementa um teste de toque preciso baseado em polígonos (`path.contains`), mas está sendo ignorado pelo `HitTestBehavior.opaque` no `GestureDetector`.

Para garantir alta qualidade e evitar regressões, essa correção será implementada usando o Desenvolvimento Orientado a Testes (TDD). Primeiro, escreveremos testes afirmando que os testes de toque dentro dos limites rotacionados são bem-sucedidos e fora falham, e então aplicaremos a correção.

## Goals / Non-Goals

**Goals:**
- Abordagem TDD: Escrever testes unitários para `MarkerPainter.hitTest` antes de aplicar a correção.
- Alcançar 100% de cobertura de testes na lógica de hit-testing no `MarkerPainter` e no cálculo de limites no `AreaHelper`.
- Garantir que a detecção de toques siga estritamente os limites rotacionados reais dos marcadores desenhados no mapa interativo.
- Tornar linhas ou caminhos finos levemente mais fáceis de tocar implementando inflação de caminho (ex: alargamento do traço).
- Adicionar docstrings claras em Dart ao `MarkerPainter`, `AreaHelper` e seus métodos de hit-testing.

**Non-Goals:**
- Não estamos alterando como os limites dos marcadores ou polígonos são calculados ou desenhados (exceto para inflação no hit-test).
- Nenhuma alteração em outros elementos interativos fora do mapa interativo.

## Decisions

**1. TDD e Testes Unitários**
- **Rationale**: Ao escrever testes para o `AreaHelper` (verificando polígonos gerados e limites) e para o `MarkerPainter.hitTest` (verificando a detecção de toque dentro/fora com diferentes preenchimentos/inflações), garantimos que a matemática esteja correta e intocável por regressões futuras. Os testes ficarão em `frontend/test/`.

**2. Adicionar Docstrings**
- **Rationale**: Sistemas de coordenadas (locais vs globais, relativos vs absolutos) em mapas podem ser confusos. Documentar parâmetros como `mapWidth`, `constraints.maxWidth` e `minX/minY` ajudará futuros mantenedores a entender a matemática de escala usada no `MarkerPainter.hitTest`.

**3. Remover `HitTestBehavior.opaque` do GestureDetector**
- **Rationale**: `HitTestBehavior.deferToChild` é o comportamento padrão quando `behavior` não é especificado. Ele faz com que o teste de toque passe para o filho (`CustomPaint`), que o encaminha para `MarkerPainter.hitTest`. Isso ativa naturalmente o teste de toque preciso que estamos testando.

**4. Inflar caminhos (paths) finos**
- **Rationale**: O `MarkerPainter` atualmente usa um `path.contains(position)` restrito. Modificaremos o hit test para traçar o caminho com uma largura razoável (ex: usando uma tolerância testável) ou usar `path.shift`/inflação de polígono para tornar mais fácil tocar em áreas finas, conforme o comentário TODO existente no código.

## Risks / Trade-offs

- **[Risk] Cálculo de inflação de caminho pode ser custoso** → Mitigation: Como só inflamos durante um `hitTest` (que acontece apenas no toque do usuário, não durante o `paint`), o impacto no desempenho é insignificante. Usaremos inflação geométrica simples ou a lógica `PathMetric` / `contains` do Flutter.
