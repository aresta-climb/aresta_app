## Context

A versão v4 da `aresta_api` altera a nomenclatura de geometrias do `PontoDeInteresse` (`circular` -> `circulo`, `box` -> `retangulo`, `area_livre` -> `poligono`) e introduz a nova geometria `quadrado`.

## Goals / Non-Goals

**Goals:**
- Adaptar o parser do app Flutter para usar a nova enumeração e propriedades de geometria (`AreaHelper.getAreaInfo`).
- Suportar a geração de vértices poligonais para a nova geometria `quadrado`.

**Non-Goals:**
- Atualizar a UI do painel interativo ou do `MarkerPainter` (eles usam o resultado de `getAreaInfo`).

## Decisions

- **Implementação do Quadrado**: O `quadrado` no protobuf não tem ângulo (`x`, `y`, `lado`). A lógica para construir os vértices do polígono em `AreaHelper` será simples: o centro em `x, y` com os cantos definidos por offset de `lado / 2` (semelhante ao retângulo, mas mais simplificado e sem rotação).

## Risks / Trade-offs

- **Falha de Build**: Se os arquivos `.pb.dart` locais não estiverem gerados de acordo com a `v4`, a compilação vai quebrar.
- Mitigação: A proposta assume que o submódulo `aresta_api` já está atualizado no projeto e os arquivos gerados estão prontos para consumo.
