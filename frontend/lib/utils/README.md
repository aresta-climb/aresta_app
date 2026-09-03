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

### Pipeline de Renderização em Camadas e Fidelidade 1:1 com o Editor
A renderização dos traçados no `MarkerPainter` segue rigorosamente as especificações estéticas do editor de mapas desktop (`aresta_db`), mantendo fidelidade visual 1:1:
1. **Decomposição Métrica no Espaço do Viewport (`aplicarEstiloNoViewport`)**: O tracejado e o pontilhado são calculados diretamente após a projeção do caminho contínuo para o sistema métrico de tela em dp (ex: 8.0dp traço / 4.0dp vão para `TRACEJADO`), garantindo que os vãos nunca se fundam em linhas sólidas, independente da resolução da imagem original (2000px a 8000px).
2. **Espessura Proporcional (`espessuraVisual`)**: A espessura do traço e seus halos é escalada proporcionalmente em relação à tela via `(espessuraNominal * scaleX * 2.2).clamp(2.0, 4.0)`, evitando linhas excessivamente pesadas em celulares.
3. **Halo de Seleção (Difuso Moderado)**: Se a via estiver selecionada, um traço com desfoque gaussiano moderado (`espessuraVisual + 6.0dp`) na cor da via cria destaque orgânico no mapa.
4. **Halo de Pulso (Advertência)**: Ao tocar no vazio do mapa, todas as rotas recebem um pulso luminoso branco que pulsa e desvanece suavemente.
5. **Casing de Contraste**: Um contorno escuro semi-transparente (`espessuraVisual + 1.5dp`) garante legibilidade da linha sobre qualquer tipo de rocha (granito claro, calcário escuro, sombras e vegetação).
6. **Traço Principal**: O traço central é desenhado na cor da rota ou na cor padrão `rustIron`.
7. **Marcadores Tipados (Fidelidade Cromática e Dimensional)**: Círculos identificadores de base (`CIRCULO_IDENTIFICADOR` e `INICIO_AGACHADO`) utilizam fundo na cor da via (`corLinha`), texto do número centralizado em branco em negrito, borda intermediária branca e casing externo preto de alto contraste, com raio e tipografia adaptativos ao zoom do viewport.

