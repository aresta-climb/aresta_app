# Tasks

## 1. Reprodução do Bug via Testes Reais sem Mocks Internos (Fase Red - TDD)

- [x] 1.1 Refatorar `frontend/test/view/view_models/pico_view_model_test.dart` removendo `mocktail`, `_FakeSyncService` e `_FakeDatasetRepository` (Princípios V e VII do `AGENTS.md`), configurando `DatasetRepository` e `SyncService` reais sobre `Directory.systemTemp` e fronteira HTTP fake (`ClienteHttpAresta.paraTestes`), e adicionar os 2 testes unitários de descarte durante `baixarPico()` e `excluirPico()`, verificando via `flutter test test/view/view_models/pico_view_model_test.dart` que ambos reproduzem a falha `FlutterError: A PicoViewModel was used after being disposed`.
- [x] 1.2 Adicionar em `frontend/test/pages/pico_test.dart` o teste de integração de widget montando a tela via `construirPaginaParaNo` (`PageListenableBuilder` + `PicoDetailsPage`) com `SyncService` e `DatasetRepository` reais, exercitando o botão "Salvar Offline" (com rebuild reativo do `activeDataset` e novos dados do croqui durante a conclusão da notificação) e o fluxo "Salvar Offline" do `ModalConfirmacaoSaida`, verificando via `flutter test test/pages/pico_test.dart` que o teste reproduz o `FlutterError` antes da correção.

## 2. Segurança de Ciclo de Vida no `PicoViewModel` e Validação Integral (Fase Green & Refactor - TDD)

- [x] 2.1 Implementar o controle de ciclo de vida (`_disposed`) em `frontend/lib/view/view_models/pico_view_model.dart` com docstrings em português explicando o motivo arquitetural (reconstrução reativa pelo `PageListenableBuilder` e saída imediata pelo Guardião de Saída durante operações assíncronas), garantindo que `baixarPico()`, `excluirPico()` e `notifyListeners()` não notifiquem ouvintes após `dispose()`, e verificar que todos os testes em `pico_view_model_test.dart` e `pico_test.dart` passam com sucesso.
- [x] 2.2 Executar `flutter test --coverage` para `pico_view_model_test.dart` e `pico_test.dart` e `flutter analyze`, verificando 0 avisos de análise estática e 100% de cobertura comportamental em `frontend/lib/view/view_models/pico_view_model.dart`.
