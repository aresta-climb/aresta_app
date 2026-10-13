# Spec Delta: estabilidade-mapa-marcadores

## ADDED Requirements

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
