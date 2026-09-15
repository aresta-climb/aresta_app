## Context

Ver `proposal.md` para motivação. Atualmente, `MarkerPainter` em `frontend/lib/pages/mapa_interativo.dart` calcula a espessura e o raio dos nós multiplicando a escala por 2.2 e aplicando clamps estáticos (`clamp(11.0, 15.0)` e `clamp(2.0, 4.0)`). Além disso, o `hitTest` utiliza uma tolerância fixa em coordenadas locais de 16.0 dp para linhas e 10.0 dp para polígonos, o que infla a área de toque excessivamente conforme o usuário aproxima o zoom.

## Goals / Non-Goals

**Goals:**
- Projeção visual estritamente 1:1 com as dimensões de pixels de imagem definidas no editor desktop.
- Hitbox de toque no aplicativo que garanta área mínima confortável para o polegar humano no panorama geral (~22 dp de raio para nós e ~16 dp para linhas), mas que colapse para zero quando o elemento visual cresce com o zoom, garantindo precisão cirúrgica.
- Manutenção do isolamento arquitetural, adesão rigorosa a `AGENTS.md` (Tudo em Português, TDD, 100% de cobertura) e integridade dos testes de widget.

**Non-Goals:**
- Não alterar o formato de persistência protobuf ou YAML.
- Não alterar as regras de renderização do editor desktop no `aresta_db`.
- Não criar simuladores ou modos adicionais de preview mobile no editor desktop.

## Decisions

### Decisão 1: Dimensionamento Visual Estrito em Pixels da Imagem
- **Abordagem**: 
  - `espessuraVisual = espessuraNominal * escalaX`
  - `raioVisual = raioNominal * escalaX`
  - `tamanhoFonteVisual = tamanhoFonteNominal * escalaX`
  - Casings e bordas proporcionais a `escalaX` (com piso mínimo de 1.0 dp para nitidez do traço em telas de alta densidade).
- **Racional**: Garante que a relação geométrica entre o desenho e a rocha seja rigorosamente a mesma que o autor visualizou e ajustou no editor de mapas.
- **Alternativas consideradas**: Manter clamps visuais ou multiplicadores intermediários. Rejeitado por distorcer a estética em fotos de diferentes resoluções.

### Decisão 2: Hitbox Adaptativa ao Tamanho Físico na Tela
- **Abordagem**:
  - No método `hitTest`, calcula-se o tamanho que o elemento ocupa na tela naquele momento:
    `tamanhoVisualNaTela = tamanhoVisualLocal * zoomAtual`
  - Define-se um raio ergonômico mínimo em tela (`raioMinimoToque = 22.0` dp para marcadores circulares e `16.0` dp para linhas).
  - A tolerância extra em tela é calculada como:
    `toleranciaTela = math.max(0.0, raioMinimoToque - tamanhoVisualNaTela)`
  - A tolerância convertida para o espaço de coordenadas do `hitTest` local torna-se:
    `toleranciaLocal = toleranciaTela / zoomAtual`
- **Racional**: Atende perfeitamente ao comportamento humano: no panorama geral, onde o círculo é pequeno, o toque é facilitado; ao aproximar com zoom, a tolerância extra colapsa para zero, permitindo selecionar nós ou linhas coladas com precisão milimétrica.
- **Alternativas consideradas**: Tolerância proporcional puramente ao fator numérico de zoom. Rejeitado pelo usuário porque não considerava a resolução variável das fotos.

## Risks / Trade-offs

- **[Risco] Marcadores muito pequenos em fotos de altíssima resolução (> 3.000 px) no panorama geral** 
  → *Mitigação*: A área de toque é garantida pela hitbox ergonômica mínima de 22 dp na tela, permitindo que o usuário clique e acione o auto-zoom ou dê pinch-to-zoom normalmente para visualizar os detalhes.
