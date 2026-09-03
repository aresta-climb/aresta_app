# Design Técnico: Renderização, Interatividade e Destaque de Traçados Vetoriais SVG no App

## Context

O Aresta DB introduziu o suporte à criação de linhas vetoriais de vias de escalada através da mudança `tracados-vetoriais-vias-mapas`. Nesse novo formato, as rotas desenhadas sobre fotos em alta definição são pré-compiladas pela biblioteca matemática do backend em strings de caminho SVG contendo curvas cúbicas de Bézier (`caminho_svg`), uma caixa delimitadora calculada (`caixa_delimitadora`), lista de marcadores semânticos com rotação angular (`marcadores`), estilos de traço (tracejado, sólido) e cores personalizadas (`cor`).

No aplicativo móvel (`aresta_app`), o componente `MapaInterativoPage` e seu auxiliar `MarkerPainter` foram projetados originalmente para áreas fechadas delimitadas (`circulo`, `quadrado`, `retangulo`, `poligono`), onde o hit-test utiliza `path.contains(touchPoint)` e o zoom de pontos individuais assume um elemento pontual de ~20dp. 

Este design técnico estabelece a arquitetura para consumir o SVG compilado acelerado por GPU, garantir isolamento estrito de bibliotecas externas de terceiros (`path_drawing`) validado por testes automatizados, fornecer detecção ergonômica de toques ao longo de toda a extensão do traçado, enquadrar a via inteira no auto-zoom e renderizar os efeitos visuais de highlight persistente e pulso luminoso.

## Goals / Non-Goals

**Goals:**
- Atualizar a compilação Protobuf no aplicativo (`croqui.pb.dart`) para sincronizar a mensagem `LinhaTrajeto` e os novos campos de `PontoDeInteresse`.
- Criar a biblioteca utilitária `TrajetoPathHelper` (`lib/utils/trajeto_path_helper.dart`) encapsulando o uso do `path_drawing`, com 100% de cobertura de testes.
- Implementar um teste de barreira arquitetural (`test/architecture/dependencias_externas_test.dart`) garantindo que nenhum arquivo de view ou lógica do app importe diretamente `path_drawing`.
- Expandir o `AreaHelper.getAreaInfo` para suportar `Mapa_PontoDeInteresse_TipoArea.linha`, calculando os limites a partir de `caixa_delimitadora` e do próprio `Path`.
- Implementar detecção de toques contínua ao longo de curvas abertas no `MarkerPainter.hitTest` com tolerância ergonômica de 16dp.
- Implementar renderização em 4 camadas no `MarkerPainter`: halo de destaque difuso (`MaskFilter.blur`), casing de alto contraste, traço principal estilizado e marcadores rotacionados.
- Adaptar o cálculo de auto-zoom em `_zoomToPoints` para tratar vias com traçados vetoriais através de Bounding Box, enquadrando toda a extensão da via (base ao topo) mesmo quando composta por um único elemento de linha.
- Assegurar compatibilidade total e sem regressões com todos os croquis legados.

**Non-Goals:**
- Não recalcular curvas de Catmull-Rom nem realizar cálculos matemáticos pesados de interpolação no aplicativo: o celular consome estritamente o SVG já compilado pelo backend.
- Não alterar a lógica de apresentação e navegação dos cartões inferiores de vias, setores e grupos.

## Decisions

### Decisão 1: Encapsulamento Estrito do `path_drawing` e Teste de Barreira Arquitetural
- **Escolha:** Todo acesso à biblioteca `path_drawing` (para `parseSvgPathData` e `dashPath`) fica restrito exclusivamente ao arquivo `lib/utils/trajeto_path_helper.dart`. Um teste automatizado de análise de código-fonte em Dart verifica que nenhuma outra parte do app importa esse pacote.
- **Justificativa:** Atende ao Princípio II (Componentes Independentes) e Princípio VI (Simplicidade). O pacote `path_drawing` está estável na versão 1.0.1, mas possui manutenção infrequentemente atualizada. O encapsulamento garante que, caso no futuro seja necessário migrar para um parser interno ou outra solução, o impacto no código seja restrito a um único arquivo de 30 linhas.

### Decisão 2: Hit-Testing Baseado em Proximidade a Segmentos Amostrados da Curva
- **Escolha:** Como caminhos abertos não possuem área interna para `path.contains()`, o `MarkerPainter.hitTest(Offset position)` aproxima a curva por uma sequência de pontos locais (via `path.computeMetrics()` com amostragem a cada ~15dp) e calcula a distância euclidiana do ponto de toque aos segmentos de reta consecutivos.
- **Tolerância Ergonômica:** Raio de 16dp (~32px em telas retina). Se a menor distância for $\le 16\text{dp}$, o clique é aceito.
- **Delegação para Clique Fora:** Como o `GestureDetector` que envolve o marcador utiliza `HitTestBehavior.deferToChild`, qualquer clique fora do raio de 16dp faz o `hitTest` retornar `false`. O evento de toque vaza automaticamente para o `GestureDetector` de fundo da tela, que cancela seleções ou dispara o pulso de destaque (`highlightIntensity`).

### Decisão 3: Cache em Memória dos Caminhos Vetoriais Processados
- **Escolha:** Os objetos `ui.Path` gerados e tracejados não devem ser recriados a cada chamada de `paint()` (que roda a 60/120 FPS em gestos de pan/zoom).
- **Justificativa:** Criação de `Path` via `dashPath` gera alocações de memória significativas. Mantendo uma estrutura simples de cache indexada pelo ID do ponto de interesse e estilo de traço, evitamos pressão desnecessária sobre o Garbage Collector do Flutter.

### Decisão 4: Estrutura Visual em Camadas (Layering) do Traçado
- **Escolha:** O `MarkerPainter` desenha o traçado vetorial na seguinte ordem:
  1. *Halo de Seleção* (quando `isSelected == true`): `strokeWidth = espessura + 12`, cor viva com `MaskFilter.blur(BlurStyle.normal, 5.0)`.
  2. *Halo de Pulso* (quando não selecionado e `highlightIntensity > 0`): `strokeWidth = espessura + 8 * highlightIntensity`, cor branca com opacidade proporcional.
  3. *Casing de Contraste*: Traço escuro sutil de base (`strokeWidth = espessura + 2`) para garantir legibilidade contra rochas claras ou escuras.
  4. *Traço Principal*: Traço com a cor do ponto (`ponto.cor` ou cor padrão), pontas arredondadas (`StrokeCap.round`).
  5. *Marcadores*: Ícones e rótulos de nós desenhados sobre as posições compiladas.

### Decisão 5: Enquadramento Adaptativo de Zoom por Bounding Box da Linha
- **Escolha:** Vias com traçado vetorial acionam a lógica de Bounding Box em `_zoomToPoints`, calculando `scaleX` e `scaleY` a partir dos limites totais do traçado (`minX, minY, maxX, maxY`), em vez de tratar como ponto único.
- **Justificativa:** Garante que o usuário veja a via completa (da base ao topo) confortavelmente enquadrada acima do card inferior, com um teto de zoom automático agradável (ex: 2.5x).

## Risks / Trade-offs

- **[Risco: String SVG inválida ou malformada vinda de croquis legados ou em desenvolvimento]** → *Mitigação:* `TrajetoPathHelper` envolve a interpretação em bloco `try/catch` defensivo, retornando `Path()` vazio em caso de falha sem quebrar a renderização do mapa.
- **[Risco: Vias paralelas muito próximas confundindo o clique do usuário]** → *Mitigação:* O `hitTest` calcula a distância euclidiana exata até a curva; caso duas vias estejam sob o raio de tolerância do toque, a seleção prioriza o traçado com menor distância absoluta até o ponto de contato.
- **[Risco: Sobrecarga de rebuilds com muitas linhas animando o pulso]** → *Mitigação:* O pulso reutiliza o `_highlightAnimation` existente e apenas recalcula o valor escalar de alfa/largura na pintura sem recriar os caminhos da memória.

## Migration Plan

1. Sincronizar o schema Protobuf executando a compilação dos protos Dart para atualizar `croqui.pb.dart`.
2. Adicionar a dependência `path_drawing: ^1.0.1` ao `frontend/pubspec.yaml` e executar `flutter pub get`.
3. Escrever o teste de barreira arquitetural e o teste unitário de `TrajetoPathHelper` (TDD).
4. Implementar `lib/utils/trajeto_path_helper.dart`.
5. Atualizar `AreaHelper` e `MarkerPainter` para suportar `linha`, hit-testing e camadas de highlight.
6. Atualizar `_zoomToPoints` para enquadramento completo de vias vetoriais.
7. Executar a suíte completa de testes unitários e de widget com `flutter test`.
