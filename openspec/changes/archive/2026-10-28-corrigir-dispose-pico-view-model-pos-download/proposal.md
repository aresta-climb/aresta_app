# Proposal

## Why

Ao iniciar o download de um croqui na página de detalhes do pico (`PicoDetailsPage`) — seja pelo botão "Salvar Offline" no `BannerModoOnline` ou pela opção "Salvar Offline" no modal Guardião de Saída — o `SyncService` atualiza `datasetRepo.activeDataset` assim que os arquivos são persistidos no disco, **antes** do retorno final de `ServicoDownloadSegundoPlano.executarDownload` (que aguarda a notificação nativa de conclusão). Essa atualização de `activeDataset` faz o `PageListenableBuilder` reconstruir a `PicoDetailsPage` com uma nova instância de `PicoViewModel`, descartando (`dispose()`) a instância anterior no `didUpdateWidget` enquanto `baixarPico()` (ou `excluirPico()`) ainda está suspenso no `await`; quando a chamada assíncrona retorna, a instância descartada invoca `notifyListeners()` e lança `FlutterError: A PicoViewModel was used after being disposed`.

## What Changes

- Tornar o ciclo de vida de `PicoViewModel` seguro contra invocações pós-descarte (`_disposed`), garantindo que operações assíncronas (`baixarPico`, `excluirPico` e callbacks de atualização/polling) não invoquem `notifyListeners()` caso a instância já tenha sofrido `dispose()` (por rebuild do `PageListenableBuilder` ou saída da página no Guardião de Saída).
- Preservar o suporte integral a Hot Reload / Live Reload e sincronizações de croqui em `PicoDetailsPage` via `PageListenableBuilder`, garantindo que a substituição de `PicoViewModel` no `didUpdateWidget` descarte a instância anterior com segurança sem interromper downloads em andamento nem lançar exceções.
- Refatorar os testes de `PicoViewModel` (`pico_view_model_test.dart`) e adicionar testes de integração de widget em `pico_test.dart` eliminando mocks/fakes de classes internas (`_FakeSyncService`, `_FakeDatasetRepository` e `mocktail`) em favor de instâncias reais (`SyncService`, `DatasetRepository`, `PageListenableBuilder` / `construirPaginaParaNo`) com fake apenas nas fronteiras externas (HTTP e canal de notificações), reproduzindo fielmente o cenário de produção sob TDD (Red-Green-Refactor).

## Capabilities

### New Capabilities
<!-- Nenhuma nova capability necessária -->

### Modified Capabilities
- `transmissao-croqui-online`: Adicionar requisito de segurança de ciclo de vida do `PicoViewModel` durante transições assíncronas (download offline, exclusão de guia e reconstrução reativa via `PageListenableBuilder`), impedindo notificações em instâncias descartadas.

## Impact

- `frontend/lib/view/view_models/pico_view_model.dart`: Controle de estado `_disposed` e proteção pós-`await` em `baixarPico`, `excluirPico` e listeners.
- `frontend/test/view/view_models/pico_view_model_test.dart`: Remoção de `mocktail`, `_FakeSyncService` e `_FakeDatasetRepository`; uso de `SyncService` e `DatasetRepository` reais com fronteira HTTP fake e testes reproduzindo o descarte durante `baixarPico` e `excluirPico`.
- `frontend/test/pages/pico_test.dart`: Adição de teste de widget integrando `construirPaginaParaNo` (`PageListenableBuilder` + `PicoDetailsPage`), `SyncService` real e atualização de `activeDataset` durante o download offline e no fluxo "Salvar e Sair".
