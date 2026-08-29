## ADDED Requirements

### Requirement: Auto-Zoom Monotônico para Pontos Únicos
The system SHALL centralizar a câmera no ponto de interesse selecionado sem jamais reduzir a escala de zoom atual caso o usuário já esteja com um nível de zoom superior à escala padrão.

#### Scenario: Seleção de ponto único quando o zoom atual é inferior ao alvo padrão
- **WHEN** o usuário está com o zoom do mapa em 1.0x (ou inferior a 2.5x)
- **AND** o usuário toca em um marcador de ponto único
- **THEN** a câmera amplia suavemente para a escala padrão de 2.5x (ou zoom customizado da referência)
- **AND** centraliza a área visível no ponto com o deslocamento vertical correspondente

#### Scenario: Seleção de ponto único quando o usuário já aplicou zoom manual elevado
- **WHEN** o usuário aplicou zoom manual para uma escala de 4.5x
- **AND** o usuário toca em um marcador de ponto único
- **THEN** a escala da câmera é mantida em 4.5x (sem redução de zoom)
- **AND** a câmera translada suavemente para centralizar o ponto selecionado

### Requirement: Enquadramento de Rotas com Múltiplos Pontos (Caixa Delimitadora)
The system SHALL calcular a escala necessária para enquadrar simultaneamente todos os marcadores associados (início e fim) no viewport visível com margens confortáveis ao selecionar uma via com múltiplos pontos.

#### Scenario: Seleção de via com múltiplos pontos distantes
- **WHEN** o usuário seleciona uma via composta por múltiplos marcadores (início e fim)
- **THEN** o sistema calcula a caixa delimitadora englobando todos os pontos
- **THEN** a câmera ajusta o zoom e a posição para que todos os pontos da via fiquem visíveis na tela

### Requirement: Zoom Dinâmico por Dimensão Confortável na Tela
The system SHALL calcular uma escala alvo proporcional ao tamanho do polígono do ponto na tela para garantir uma dimensão física mínima confortável (~40-48dp) em mapas de grandes dimensões ou alta resolução, sem nunca reduzir o zoom atual.

#### Scenario: Marcador de tamanho reduzido em croqui panorâmico
- **WHEN** o usuário toca em um marcador de dimensões físicas muito pequenas na escala 1.0
- **THEN** o sistema calcula a escala dinâmica para que o elemento atinja dimensão confortável de visualização e toque
- **THEN** o sistema aplica `max(escalaAtual, escalaDinamica)` para garantir que não ocorra redução de zoom

### Requirement: Limite de Zoom Expandido e Gesto de Duplo Toque
The interactive map SHALL suportar ampliações profundas de até 10.0x e permitir aproximação ágil via gesto de duplo toque.

#### Scenario: Ampliação máxima em imagem de alta resolução
- **WHEN** o usuário realiza o gesto de pinça para aproximar a imagem
- **THEN** o componente permite ampliação contínua até o limite máximo de 10.0x

#### Scenario: Duplo toque no mapa
- **WHEN** o usuário realiza um duplo toque em uma área do mapa
- **THEN** a câmera aproxima suavemente com foco nas coordenadas do toque
