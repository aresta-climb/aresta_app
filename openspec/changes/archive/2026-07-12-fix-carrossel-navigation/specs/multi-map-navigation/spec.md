## MODIFIED Requirements

### Requirement: Carrossel de Mapas Interativos
O sistema DEVE prover uma interface para navegar de forma sequencial entre múltiplos mapas interativos (`MapasCarrosselPage`), garantindo que o mapa ativo seja trocado apenas via controles explícitos para não conflitar com a navegação do `InteractiveViewer`. O carrossel DEVE instanciar seus mapas explicitamente instruindo-os a não fazer "pop" da navegação ao acionar o botão principal de informações (Mais Info).

#### Scenario: Visualizando a via em múltiplos mapas
- **WHEN** o usuário toca no botão "Ver nos mapas (N)" na tela da Via
- **THEN** a tela de Carrossel de Mapas se abre, focando no primeiro mapa com a rota correspondente focada e animada no centro.
- **AND** a barra superior de controle exibe "< 01 de N >".

#### Scenario: Trocando de mapa no carrossel
- **WHEN** o usuário toca no botão ">" na barra superior
- **THEN** o mapa ativo muda para o próximo mapa do carrossel.
- **AND** o novo mapa automaticamente executa o autozoom para focar e destacar a exata rota referenciada, correspondendo ao seu `referencedId` específico daquele mapa.

#### Scenario: Várias vias no mesmo mapa durante a navegação
- **WHEN** o usuário está num carrossel focado na Rota A, mas toca no SVG da Rota B no mesmo mapa
- **THEN** o cartão flutuante da Rota B aparece no rodapé normalmente.
- **AND** o carrossel continua gerindo as configurações da Rota A no topo da tela, mas se a Rota B possui múltiplos mapas, um botão extra surge no cartão flutuante para "Ver nos mapas".

#### Scenario: Acessando Detalhes da Via através do Carrossel
- **WHEN** o usuário toca no botão "Mais Info" no cartão flutuante de uma rota exibida dentro do carrossel, mesmo que seja a rota originalmente focada ao abrir a tela
- **THEN** o sistema DEVE abrir a tela de Detalhes da Via (PUSH) em vez de fechar o carrossel (POP).
