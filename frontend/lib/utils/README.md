# Utilitários de Domínio - Aresta Climb

Este diretório (`lib/utils/`) reúne utilitários e serviços de suporte de domínio para manipulação de dados, geometria e navegação no Aresta Climb.

## 1. ConstrutorCaminhoTrajeto (`construtor_caminho_trajeto.dart`)

O `ConstrutorCaminhoTrajeto` é o componente central responsável por converter traçados vetoriais de escalada compilados em formato SVG Path Data (`M ... C ...`) para caminhos gráficos nativos (`ui.Path`) e viabilizar interações ergonômicas de toque no mapa interativo.

### Isolamento Arquitetural de Pacotes
Seguindo as diretrizes de engenharia do repositório (`PRINCIPIOS.md`), o uso de bibliotecas externas de parsing de caminhos vetoriais é estritamente isolado:
- **Barreira Exclusiva**: Apenas o arquivo `lib/utils/construtor_caminho_trajeto.dart` tem autorização para importar o pacote `package:path_drawing/`.
- **Garantia por Teste**: O teste arquitetural `test/architecture/path_drawing_isolation_test.dart` varre todos os arquivos do projeto em `lib/` e falha automaticamente o CI se qualquer outro arquivo violar este isolamento.

### Política de Cache em Memória
Durante operações de pan e zoom com `InteractiveViewer`, o método de pintura `MarkerPainter.paint` é chamado a taxas elevadas (60 a 120 FPS). Reconstruir curvas Bézier ou aplicar tracejados dinâmicos repetidamente gera pressão extrema no Garbage Collector.
- As instâncias compiladas de `ui.Path` são armazenadas em um cache estático `Map<String, Path>` indexado por `"$chaveCache-$estilo"`.
- A invalidação ou descarte pode ser acionada via `ConstrutorCaminhoTrajeto.limparCache()`.

### Algoritmo de Hit-Testing e Distância Euclidiana
Diferente de polígonos fechados onde `Path.contains` determina se um ponto está dentro da área, linhas de vias são curvas abertas unidimensionais.
- A curva é amostrada regularmente a cada ~15 unidades através de `Path.computeMetrics()` e `getTangentForOffset()`.
- O método `calcularDistanciaAoCaminho` projeta a coordenada do toque sobre cada segmento consecutivo da polilinha amostrada (sem fechar o laço entre início e fim da via).
- Se a menor distância euclidiana for inferior ou igual a 16.0dp, o toque é considerado válido, proporcionando excelente usabilidade em telas sensíveis ao toque.

### Pipeline de Renderização em Camadas
A renderização dos traçados no `MarkerPainter` segue uma ordem estrita de camadas visuais:
1. **Halo de Seleção (Difuso)**: Se a via estiver selecionada, um traço largo com desfoque gaussiano (`MaskFilter.blur`) na cor da via é desenhado na base para criar destaque orgânico no mapa.
2. **Halo de Pulso (Advertência)**: Quando o usuário toca em uma área vazia do mapa, todas as rotas e áreas clicáveis recebem um pulso luminoso branco que pulsa e desvanece suavemente.
3. **Casing de Contraste**: Um contorno escuro semi-transparente ligeiramente mais largo que o traço principal é desenhado, garantindo legibilidade da linha sobre qualquer tipo de rocha (granito claro, calcário escuro, sombras e vegetação).
4. **Traço Principal**: O caminho estilizado (sólido, tracejado ou pontilhado conforme convenções FEMEMG) na cor da via ou cor padrão `rustIron`.
5. **Marcadores Tipados**: Pontos semânticos compilados desenhados na escala exata da tela (círculos numerados de início de base/agachado, "X" para proteções fixas, "XX" para paradas e losangos para lances crux).
