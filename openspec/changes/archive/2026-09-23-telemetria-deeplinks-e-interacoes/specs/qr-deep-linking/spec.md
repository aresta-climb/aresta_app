## ADDED Requirements

### Requirement: Captura de Parâmetros UTM e Metadados de Deep Links
O sistema DEVE (MUST) extrair e preservar os parâmetros de consulta (query parameters) de URLs de deep links recebidas, incluindo especificamente `utm_source`, `utm_medium`, `utm_campaign`, `utm_term`, `utm_content` e quaisquer parâmetros de origem.

#### Scenario: Deep link contendo parâmetros UTM de campanha
- **WHEN** o sistema intercepta uma URL como `https://app.arestaclimb.com/br_mg_igarape_pedra_grande/setor_estacionamento?utm_source=placa_pedra&utm_medium=qrcode`
- **THEN** o sistema analisa a rota preservando `utm_source` e `utm_medium` associados à resolução da rota.

#### Scenario: Deep link sem parâmetros de consulta
- **WHEN** o sistema intercepta uma URL simples como `https://app.arestaclimb.com/br_mg_igarape_pedra_grande`
- **THEN** o sistema normaliza a rota com mapa de parâmetros vazio sem falhar ou abortar a navegação.

### Requirement: Telemetria de Abertura via Deep Link e QR Code
O sistema DEVE (MUST) registrar um evento estruturado de telemetria sempre que um deep link for interceptado e processado pelo aplicativo, identificando o tipo de inicialização (Cold Start vs Warm Start), o nível hierárquico alcançado, os parâmetros UTM e o resultado do carregamento (sucesso ou falha).

#### Scenario: Registro bem-sucedido de abertura de via via QR code físico
- **WHEN** o usuário escaneia um QR code físico na rocha que abre uma via com o aplicativo previamente fechado (Cold Start)
- **THEN** o sistema despacha evento de telemetria contendo `tipo_start: cold_start`, `destino: via`, `sucesso: true`, `utm_medium: qrcode` e identificadores do pico e da via.

#### Scenario: Registro de falha no carregamento de deep link sem internet
- **WHEN** um link externo é acionado para um pico não baixado previamente e o dispositivo está sem conexão com a internet
- **THEN** o sistema despacha evento de telemetria registrando `sucesso: false` e o motivo do erro antes de notificar o usuário na interface.
