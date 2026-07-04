## 1. Mocks & Telemetry Service

- [x] 1.1 Adicionar `logNavegacaoHierarquica` no `TelemetryService`
- [x] 1.2 Adicionar `logResultadoSincronizacao` no `TelemetryService`
- [x] 1.3 Adicionar mocks correspondentes nas ferramentas de teste (ex: `mock_telemetry_service.dart` ou onde for apropriado)

## 2. Mapa Interativo (Up Navigation)

- [x] 2.1 TDD: Atualizar `mapa_interativo_test.dart` para esperar a chamada de `logNavegacaoHierarquica` no clique do botão "Subir"
- [x] 2.2 Implementação: Substituir o hack de `logAcaoEscalada` por `logNavegacaoHierarquica` em `mapa_interativo.dart`

## 3. Sync Service (Feedback Badge)

- [x] 3.1 TDD: Atualizar `sync_service_test.dart` para esperar a chamada de `logResultadoSincronizacao` nos diferentes cenários (sucesso, sem atualizações, erro)
- [x] 3.2 Implementação: Adicionar chamadas de `logResultadoSincronizacao` dentro de `syncAllLocalCrags` no `sync_service.dart` ao final do fluxo
