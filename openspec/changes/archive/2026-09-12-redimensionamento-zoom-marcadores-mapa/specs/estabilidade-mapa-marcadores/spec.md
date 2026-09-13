## ADDED Requirements

### Requirement: Escalonamento de Marcadores por Faixas de Zoom
O sistema SHALL ajustar a representação e dimensões visuais dos marcadores no Mapa Global de acordo com faixas discretas de zoom da câmera.

#### Scenario: Visualização em nível macro (país)
- **WHEN** o nível de zoom da câmera for inferior a 6.0
- **THEN** os marcadores DEVEM ser exibidos em tamanho compacto reduzido (40px) e sem rótulos de texto com o nome do pico.

#### Scenario: Visualização em nível regional (estado)
- **WHEN** o nível de zoom da câmera estiver entre 6.0 (inclusive) e 9.0 (exclusive)
- **THEN** os marcadores DEVEM ser exibidos em tamanho intermediário (65px) e sem rótulos de texto com o nome do pico.

#### Scenario: Visualização em nível local (cidade ou aproximação do pico)
- **WHEN** o nível de zoom da câmera for igual ou superior a 9.0
- **THEN** os marcadores DEVEM ser exibidos em tamanho completo (85px) acompanhados de balão de texto contendo o nome do pico.

### Requirement: Formatação Compacta e Truncamento de Rótulos de Texto
O sistema SHALL formatar os rótulos de texto dos marcadores com largura contida e truncamento por reticências para prevenir poluição visual e sobreposição excessiva.

#### Scenario: Nome longo de pico de escalada
- **WHEN** o nome do pico exceder a largura máxima configurada para o balão (~220px)
- **THEN** o texto DEVE ser truncado com reticências (`...`) mantendo o balão contido dentro dos limites de largura estipulados.

#### Scenario: Nome curto de pico de escalada
- **WHEN** o nome do pico couber na largura máxima estipulada
- **THEN** o texto DEVE ser exibido centralizado sem truncamento no balão.

### Requirement: Transição Otimizada de Faixas de Zoom
O sistema SHALL disparar atualização dos marcadores apenas quando a câmera do mapa transicionar entre diferentes faixas de zoom.

#### Scenario: Movimentação da câmera dentro da mesma faixa
- **WHEN** o zoom da câmera variar mantendo-se dentro da mesma faixa (por exemplo, de 6.5 para 8.5)
- **THEN** o conjunto de marcadores NÃO DEVE ser reconstruído, preservando a taxa de quadros e a fluidez do mapa.

#### Scenario: Movimentação da câmera cruzando faixas de zoom
- **WHEN** o zoom da câmera cruzar os limites de 6.0 ou 9.0
- **THEN** o estado do widget DEVE ser atualizado para exibir os marcadores correspondentes à nova faixa.
