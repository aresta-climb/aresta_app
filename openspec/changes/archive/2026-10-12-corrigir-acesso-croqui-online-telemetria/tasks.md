# Tasks

## 1. Ciclo de Vida do PicoViewModel e Preservação do Cliente HTTP

- [x] 1.1 [RED] Escrever teste unitário em `frontend/test/view/view_models/pico_view_model_test.dart` verificando que após chamar `dispose()` no `PicoViewModel`, o `ServicoCroquiOnline` compartilhado não é encerrado e permanece apto a executar requisições HTTP subsequentes.
- [x] 1.2 [GREEN] Remover a invocação `_servicoCroquiOnline.dispose()` do método `dispose()` em `frontend/lib/view/view_models/pico_view_model.dart`, mantendo estritamente `_servicoCroquiOnline.cancelarPolling(cragId)`.

## 2. Resolução Centralizada de Croqui no DatasetRepository

- [x] 2.1 [RED] Escrever testes unitários em `frontend/test/services/repositorio_dataset_test.dart` validando que `getCroqui` consulta como salvaguarda os `metadadosDisponiveis` de `activeDataset.value` quando o resumo não estiver em `indiceData.value`, e monta a URL absoluta utilizando `activeBaseUrl`.
- [x] 2.2 [GREEN] Atualizar `DatasetRepository.getCroqui` em `frontend/lib/services/repositorio_dataset.dart` para incorporar a consulta defensiva aos `metadadosDisponiveis` e garantir montagem consistente da URL remota.

## 3. Saneamento e Reporte de Erro no Firebase Crashlytics

- [x] 3.1 [RED] Escrever testes em `frontend/test/view/function_library/funcoes_home_test.dart` validando disparo de `AppLogger.instance.logFalhaSyncOuDownload` e abertura consecutiva de múltiplos croquis online sem erro.
- [x] 3.2 [GREEN] Sanear `handlePicoSelection` em `frontend/lib/view/function_library/funcoes_home.dart`, removendo a lógica duplicada de fallback com URI relativa e adicionando reporte explícito com `AppLogger.instance.logFalhaSyncOuDownload` caso o croqui venha nulo.
- [x] 3.3 [GREEN] Atualizar `ServicoCroquiOnline.carregarCroquiRemoto` em `frontend/lib/services/http/servico_croqui_online.dart` para registrar falhas de rede e HTTP status != 200 com `AppLogger.instance.logFalhaSyncOuDownload`.

## 4. Validação Geral e Cobertura de Testes

- [x] 4.1 Executar os testes afetados (`pico_view_model_test.dart`, `funcoes_home_test.dart`, `servico_croqui_online_test.dart` e `repositorio_dataset_test.dart`) e validar ausência de regressões com 100% de cobertura nos trechos alterados.
