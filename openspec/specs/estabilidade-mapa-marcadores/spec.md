# estabilidade-mapa-marcadores Specification

## Purpose
Garante estabilidade, renderização resiliente, escalonamento por zoom e precisão interativa dos marcadores e da barra superior nas telas de mapas do aplicativo.
## Requirements
### Requirement: Tratamento Seguro de Buffers Gráficos de Marcadores
O sistema SHALL criar marcadores de mapa de forma resiliente sem invocar operadores force-unwrap (`!`) sobre buffers nulos.

#### Scenario: Falha de alocação de ByteData para imagem de marcador
- **WHEN** `image.toByteData()` retornar `null` durante a conversão do canvas para ícone do mapa
- **THEN** a função DEVE retornar `BitmapDescriptor.defaultMarker` de fallback e não DEVE disparar `Null check operator used on a null value`.

### Requirement: Resiliência em Dicionário de Marcadores de Setores
O sistema SHALL resolver ícones de marcadores com verificação segura de nulidade.

#### Scenario: Setor sem ícone em cache de memória
- **WHEN** um setor com id inexistente no mapa `textIcons` for processado para exibição
- **THEN** o marcador DEVE utilizar fallback seguro para o ícone padrão ou genérico sem disparar exceção de `null check`.

### Requirement: Proteção de Streams de Câmera do Mapa
O sistema SHALL ignorar ou tratar defensivamente atualizações de câmera nativas com parâmetros nulos ou incompletos na inicialização.

#### Scenario: Disparo prematuro de eventos de câmera pelo SO
- **WHEN** o canal nativo do Google Maps emitir evento de câmera com elementos nulos antes da superfície estar pronta
- **THEN** o listener do Flutter DEVE descartar o evento graciosamente sem causar crash do aplicativo.

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

### Requirement: Desacoplamento de Hitbox e Rótulo Flutuante no Zoom Local
O sistema SHALL desacoplar o pino gráfico interativo do balão de texto flutuante na faixa de zoom local, restringindo a área de detecção de toque (hitbox) exclusivamente às dimensões do pino e garantindo que o rótulo textual não crie áreas transparentes laterais capazes de interceptar toques em picos vizinhos.

#### Scenario: Toque preciso em pino vizinho próximo
- **WHEN** o usuário toca em um pino que possui outro pino imediatamente adjacente na visualização local
- **THEN** o sistema ativa com precisão exclusivamente o pino tocado, sem interferência de áreas transparentes do pico vizinho.

#### Scenario: Rótulo flutuante sem bloqueio de eventos de toque
- **WHEN** o rótulo de texto flutuante for exibido acima do pino no zoom local
- **THEN** o marcador do rótulo possui prioridade inferior de renderização e repassa eventos de toque de forma transparente para não obstruir o mapa ou pinos circundantes.

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

### Requirement: Resolução Resiliente de Marcadores no Mapa Global
O sistema SHALL resolver os dados geográficos e renderizar os marcadores no Mapa Global a partir de identificadores em texto ou instâncias de apresentação, consultando o repositório de dados ativo para extrair as coordenadas geográficas quando necessário.

#### Scenario: Abertura do Mapa Global a partir da lista de cartões de exploração
- **WHEN** o usuário toca no botão de visualização em mapa a partir da lista de exploração
- **THEN** o sistema resolve os identificadores dos picos selecionados junto ao catálogo de dados ativo e plota os marcadores de todos os picos que possuem coordenadas geográficas válidas.

#### Scenario: Fallback automático para catálogo completo
- **WHEN** a navegação para o Mapa Global fornecer uma lista que não contenha coordenadas ou resulte em nenhum marcador válido
- **THEN** o sistema DEVE recorrer automaticamente a todos os picos com coordenadas válidas disponíveis no catálogo do dispositivo, garantindo que o mapa não seja exibido vazio.

### Requirement: Consistência de Ações e Feedback na Barra Superior
O sistema SHALL exibir exatamente um botão de envio de feedback ou relato de bug na barra superior da tela do Mapa Global.

#### Scenario: Visualização da barra superior no Mapa Global
- **WHEN** a tela do Mapa Global é apresentada ao usuário
- **THEN** a barra superior DEVE exibir exatamente uma ação para acionamento do fluxo de feedback, sem botões duplicados.


