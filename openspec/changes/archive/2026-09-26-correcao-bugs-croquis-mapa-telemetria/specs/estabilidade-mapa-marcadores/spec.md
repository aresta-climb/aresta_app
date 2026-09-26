## MODIFIED Requirements

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
- **THEN** os marcadores DEVEM ser exibidos em tamanho completo (85px) acompanhados de balão de texto flutuante desacoplado contendo o nome do pico.

## ADDED Requirements

### Requirement: Desacoplamento de Hitbox e Rótulo Flutuante no Zoom Local
O sistema SHALL desacoplar o pino gráfico interativo do balão de texto flutuante na faixa de zoom local, restringindo a área de detecção de toque (hitbox) exclusivamente às dimensões do pino e garantindo que o rótulo textual não crie áreas transparentes laterais capazes de interceptar toques em picos vizinhos.

#### Scenario: Toque preciso em pino vizinho próximo
- **WHEN** o usuário toca em um pino que possui outro pino imediatamente adjacente na visualização local
- **THEN** o sistema ativa com precisão exclusivamente o pino tocado, sem interferência de áreas transparentes do pico vizinho.

#### Scenario: Rótulo flutuante sem bloqueio de eventos de toque
- **WHEN** o rótulo de texto flutuante for exibido acima do pino no zoom local
- **THEN** o marcador do rótulo possui prioridade inferior de renderização e repassa eventos de toque de forma transparente para não obstruir o mapa ou pinos circundantes.
