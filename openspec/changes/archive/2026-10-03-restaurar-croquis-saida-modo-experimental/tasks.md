## 1. Testes Automatizados em Primeiro Lugar (TDD - Red Phase)

- [x] 1.1 Escrever teste unitário em `test/services/sync_service_test.dart` verificando que respostas HTTP 304 Not Modified recarregam o índice local quando `activeDataset.value` estiver vazio (`isEmpty`), e validar falha inicial (Red)
- [x] 1.2 Escrever teste unitário em `test/services/experimental_mode_test.dart` validando que `nukeExperimentalData()` encerra o modo experimental de forma coordenada sem disparar leituras em caminhos experimentais já excluídos, e validar falha inicial (Red)
- [x] 1.3 Escrever teste de widget em `test/main_test.dart` simulando a transição de saída do modo experimental via `BannerModoExperimental`, assegurando que `activeDataset` e os croquis oficiais de produção permaneçam populados e visíveis na interface, e validar falha inicial (Red)

## 2. Ajustes no SyncService e no EditorDeCroqui (Green Phase)

- [x] 2.1 Modificar `SyncService.syncIndex()` no caso `IndiceUnchanged` para recarregar o índice do disco quando `activeDataset.value == null || activeDataset.value!.isEmpty`, e validar aprovação do teste de sync (Green)
- [x] 2.2 Reordenar a limpeza em `EditorDeCroqui.nukeExperimentalData()` para garantir que `isExperimentalMode.value = false` e a URL sejam limpos de forma atômica e coordenada, prevenindo leituras no diretório experimental apagado, e validar aprovação dos testes unitários (Green)

## 3. Orquestração da Transição em main.dart (Green Phase)

- [x] 3.1 Ajustar o manipulador de transição de modo e a ação `onSairModoExperimental` em `main.dart` para que `datasetRepo.init()` restaure os dados oficiais de produção antes da navegação e sem colisões com `loadEmpty()`, e validar aprovação dos testes de widget (Green)
- [x] 3.2 Executar `flutter test test/main_test.dart` e validar que o retorno à tela inicial mantém os croquis de produção carregados na memória e renderizados em tela (Green)

## 4. Validação Geral, Documentação e Cobertura (Refactor & 100% Coverage)

- [x] 4.1 Executar a suíte de testes relevante via `flutter test` e assegurar que não haja regressões nem warnings
- [x] 4.2 Documentar métodos alterados com docstrings `///` em português brasileiro e atualizar `README.md` pertinentes em `frontend/lib/services/`
