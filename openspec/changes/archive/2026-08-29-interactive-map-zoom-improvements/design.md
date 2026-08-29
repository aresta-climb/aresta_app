## Contexto

No aplicativo Aresta Climb, a visualização e interação com croquis topográficos ocorre na página de mapa interativo (`MapaInterativoPage`), utilizando o componente `InteractiveViewer` do Flutter controlado por um `TransformationController`.

Ao tocar em um marcador no mapa, a função `_onMarkerTap` executa o método `_zoomToPoints`. Para pontos de interesse individuais (pontos únicos ou sem múltiplos marcadores de traçado), o código aplica um valor fixo de escala alvo `targetScale = 2.5`.

Quando o usuário está explorando uma imagem de alta resolução ou paredão extenso e aplica zoom manual (ex: 4.5x a 6.0x) para enxergar detalhes e tocar em um ponto, o mapa reduz a escala de volta para 2.5x ("zoom out"), quebrando a experiência de navegação do usuário.

## Objetivos e Não-Objetivos

**Objetivos:**
- **Fase 1 (Zoom Monotônico)**:
  - Garantir que a seleção de um marcador de ponto único nunca reduza a escala de zoom atual.
  - Se a escala atual for maior ou igual à escala padrão (`escalaAtual >= 2.5`), o mapa deve preservar a escala atual e apenas transladar a câmera para centralizar o marcador selecionado na área visível com seus devidos deslocamentos verticais (35%, 60% e 15%).
  - Manter intacta a lógica de enquadramento (caixa delimitadora) para rotas com múltiplos pontos (início, meio e cume/parada), onde afastar a câmera é indispensável para que o usuário veja a rota completa.
- **Fase 2 (Zoom Dinâmico e Recursos Avançados para Mapas Gigantes)**:
  - Calcular uma escala alvo dinâmica para pontos únicos com base no tamanho físico/lógico do elemento na tela (~40-48dp), com a garantia de que a escala resultante nunca reduzirá o zoom atual (`max(escalaAtual, escalaDinamica)`).
  - Aumentar o `maxScale` do `InteractiveViewer` de 6.0 para 10.0.
  - Rastrear ajustes manuais de zoom do usuário ("Memória de Zoom") para priorizar a escala escolhida pelo usuário durante a exploração contínua.
  - Adicionar suporte a gesto de duplo toque para aproximação rápida centrada na coordenada tocada.

**Não-Objetivos:**
- Alterar estruturas Protobuf de mapas ou esquemas de dados.
- Alterar o algoritmo de desenho dos polígonos ou de teste de toque nos marcadores.
- Forçar redução de zoom em rotas de ponto único.

## Decisões Técnicas e Arquitetura

### Decisão 1: Cálculo de Zoom Monotônico para Ponto Único (100% em Português)
- **Fórmula**: Para `pontos.length <= 1` (ou referências sem múltiplos marcadores):
  ```dart
  // Obtém a escala atual aplicada na matriz de transformação
  final double escalaAtual = _transformationController.value.getMaxScaleOnAxis();
  
  double escalaAlvoPadrao = 2.5;
  if (ref != null && ref.hasAjusteDeCamera() && ref.ajusteDeCamera.hasZoom()) {
    escalaAlvoPadrao = ref.ajusteDeCamera.zoom;
  }
  
  // Regra monotônica: nunca reduz o zoom ao focar em ponto único
  final double escalaAlvo = math.max(escalaAtual, escalaAlvoPadrao);
  ```
- **Justificativa**: Permite que o mapa amplie a visão se o usuário estiver na visão geral (ex: 1.0x -> 2.5x), mas realize apenas translação (pan) se o usuário já estiver em zoom elevado (ex: 4.5x -> 4.5x), preservando os detalhes visuais.

### Decisão 2: Preservação da Lógica de Enquadramento para Múltiplos Pontos
- **Justificativa**: Quando uma via possui início e fim (ou paradas intermediárias), o objetivo é apresentar a linha completa da via na parede. Nesses casos, o cálculo de caixa delimitadora (`math.min(escalaX, escalaY)`) deve continuar podendo afastar o zoom para que toda a rota caiba confortavelmente no viewport.

### Decisão 3: Zoom Dinâmico Baseado em Dimensão Confortável na Tela (~44dp) (Fase 2)
- **Cálculo Proposto**:
  ```dart
  final double larguraElementoDp = larguraRelativaCaixa * tamanhoFilho.width;
  final double alturaElementoDp = alturaRelativaCaixa * tamanhoFilho.height;
  final double maiorDimensaoDp = math.max(larguraElementoDp, alturaElementoDp);
  
  // Alvo: garantir que o elemento atinja dimensão confortável de ~44dp na tela física
  final double escalaConfortavel = maiorDimensaoDp > 0 
      ? (44.0 / maiorDimensaoDp).clamp(2.5, 10.0) 
      : 2.5;
      
  // Aplicação da regra monotônica estrita: nunca reduz a escala atual
  final double escalaAlvo = math.max(escalaAtual, escalaConfortavel);
  ```

### Decisão 4: Expansão do Limite Máximo de Zoom para 10.0x (Fase 2)
- Configuração de `maxScale: 10.0` no `InteractiveViewer`.
- **Justificativa**: Paredões e falésias de grande porte fotografados em alta resolução requerem aproximações superiores a 6.0x para seleção de ancoragens e agarras minúsculas.

### Decisão 5: Gesto de Duplo Toque para Zoom (Fase 2)
- Utilização de detector de gestos para alternar entre visão geral (1.0x) e zoom ótimo de leitura centrado no ponto tocado, com transição suave via `Matrix4Tween`.

## Conformidade com os Princípios de Engenharia (PRINCIPIOS.md)

1. **Tudo em Português**:
   - Todas as variáveis, métodos, comentários e testes serão estritamente em português brasileiro.
   - Nomes como `escalaAtual`, `escalaAlvoPadrao`, `escalaAlvoDinamica`, `obterEscalaMonotonica`, `usuarioAjustouZoomManualmente`.
2. **Componentes Independentes e Simplicidade (Anti-Abstração)**:
   - A lógica de cálculo de zoom é simples, direta e colocada junto às funções de câmera de forma declarativa, sem criar camadas de abstração desnecessárias.
3. **Imperativo do Teste em Primeiro Lugar (TDD) e 100% de Cobertura**:
   - Cada cenário de teste de widget será escrito e executado antes de alterar a implementação.
   - Cobertura total de testes para ponto único, múltiplos pontos, zoom customizado e transições de câmera.
4. **Documentação Contínua e Abrangente**:
   - Todo método e cálculo terá docstrings `///` em português explicando a motivação física e visual do cálculo.

## Riscos e Mitigações

- **[Risco: Movimentação abrupta de câmera em escalas altas]** → Ao transladar em escala 8.0x ou 10.0x entre pontos distantes, o deslocamento pode parecer rápido.
  *Mitigação*: A interpolação com `Matrix4Tween` utilizando a curva `Curves.easeInOut` na duração padrão de 300ms garante transição suave.
- **[Risco: Conflito de latência entre toque simples e duplo toque]** → 
  *Mitigação*: Na Fase 2, o duplo toque será implementado garantindo que o clique simples nos marcadores (`_onMarkerTap`) não sofra atraso perceptível de resposta.
