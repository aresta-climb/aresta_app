## Why

Adicionamos recentemente novas funcionalidades (botão de subir no mapa interativo e feedback de sincronização sem atualizações) mas a telemetria existente não cobre essas interações de forma precisa ou dedicada. Precisamos instrumentar esses novos fluxos para entender o engajamento dos usuários e a efetividade das mudanças.

## What Changes

- Criação de novos eventos de telemetria no `TelemetryService` (`logNavegacaoHierarquica` e `logResultadoSincronizacao`).
- Substituição do "hack" atual no botão de navegação hierárquica do mapa interativo, que usava uma telemetria genérica de escalada, por uma telemetria específica de navegação.
- Inclusão do disparo de telemetria baseada no resultado final do fluxo de sincronização.

## Capabilities

### New Capabilities
None

### Modified Capabilities
- `map-hierarchy-navigation`: Inclusão de requisito técnico de telemetria no uso da navegação hierárquica.
- `data-sync-feedback`: Inclusão de requisito técnico de registro do resultado final do processo de sincronização na telemetria.

## Impact

- `TelemetryService` e seus Mocks
- `MapaInterativoPage`
- `SyncService`
- Testes associados (testes de widget do mapa interativo e testes unitários do sync service)
