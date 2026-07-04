## ADDED Requirements

### Requirement: Telemetria de Navegação Hierárquica no Mapa
O sistema MUST disparar um evento de telemetria específico quando o usuário utilizar o botão de subir nível hierárquico no mapa.

#### Scenario: Subida de Nível Registrada
- **WHEN** o usuário toca no botão de navegação "Subir"
- **THEN** o sistema dispara o evento `logNavegacaoHierarquica` contendo o ID do pico/croqui e o rótulo do destino
