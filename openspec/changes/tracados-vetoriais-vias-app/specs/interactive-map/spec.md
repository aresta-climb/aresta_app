## Purpose

Adaptação dos comportamentos de parser geométrico, enquadramento de câmera e detecção de toques do mapa interativo para suporte completo a geometrias de linha vetorial aberta.

## MODIFIED Requirements

### Requirement: O parser de áreas deve usar a nomenclatura da v4
O sistema DEVE processar geometrias de `PontoDeInteresse` utilizando o vocabulário: circulo, retangulo, poligono, quadrado, linha.

#### Scenario: Parsing circulo
- **WHEN** point type is circulo
- **THEN** it generates a circular polygon based on its x, y, and raio

#### Scenario: Parsing retangulo
- **WHEN** point type is retangulo
- **THEN** it generates a rectangular polygon with rotation

#### Scenario: Parsing poligono
- **WHEN** point type is poligono
- **THEN** it generates a freeform polygon

#### Scenario: Parsing quadrado
- **WHEN** point type is quadrado
- **THEN** it generates a square polygon based on x, y and lado without rotation

#### Scenario: Parsing linha
- **WHEN** o tipo do ponto de interesse for `linha`
- **THEN** o `AreaHelper.getAreaInfo` resolve os limites espaciais a partir da `caixa_delimitadora` pré-calculada ou das dimensões do próprio `Path`, gerando a caixa delimitadora envolvente (AABB) e a geometria correspondente

### Requirement: Enquadramento de Rotas com Múltiplos Pontos (Caixa Delimitadora)
O sistema DEVE calcular a escala e a translação necessárias para enquadrar simultaneamente toda a extensão da via no viewport visível com margens confortáveis ao selecionar uma via, quer ela seja composta por múltiplos marcadores pontuais ou por uma ou mais linhas vetoriais.

#### Scenario: Seleção de via com múltiplos pontos distantes
- **WHEN** o usuário seleciona uma via composta por múltiplos marcadores (início e fim)
- **THEN** o sistema calcula a caixa delimitadora englobando todos os pontos
- **THEN** a câmera ajusta o zoom e a posição para que todos os pontos da via fiquem visíveis na tela

#### Scenario: Seleção de via composta por linha vetorial
- **WHEN** o usuário seleciona uma via com traçado em linha vetorial (mesmo com um único elemento de linha no croqui)
- **THEN** o sistema aplica o enquadramento por caixa delimitadora cobrindo a altura e a largura completas do trajeto
- **THEN** a câmera preserva margens adequadas acima do card inferior de informações

## ADDED Requirements

### Requirement: Detecção Precisa de Toques ao Longo da Linha (Hit-Testing)
O `MarkerPainter` DEVE detectar toques do usuário em qualquer ponto ao longo de uma curva de traçado vetorial aberta, considerando uma tolerância ergonômica de proximidade física para toques com o dedo (~16dp).

#### Scenario: Toque próximo ao traçado da via
- **WHEN** o usuário toca a uma distância menor ou igual a 16dp de qualquer trecho da linha vetorial
- **THEN** o `hitTest` do pintor retorna `true`
- **THEN** a via correspondente é selecionada e recebe o foco do mapa

#### Scenario: Toque distante do traçado dentro da caixa delimitadora
- **WHEN** o usuário toca dentro da caixa delimitadora da linha, porém a uma distância superior a 16dp de qualquer trecho do traçado
- **THEN** o `hitTest` do pintor retorna `false`
- **THEN** o evento de toque não é consumido pelo marcador e propaga para o mapa de fundo, acionando o pulso de destaque
