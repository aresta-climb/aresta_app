# Tasks

## 1. Curto-Circuito Offline e Supressão de `syncIndex()` Pós-Falha em `DatasetRepository.getCroqui`

- [x] 1.1 Em ciclo TDD (*Red-Green-Refactor*), adicionar testes comportamentais em `frontend/test/services/repositorio_dataset_test.dart` e atualizar `DatasetRepository.getCroqui` em `frontend/lib/services/repositorio_dataset.dart` para: (a) retornar `null` imediatamente se o `syncIndex()` de fallback (quando o pico não consta no índice local) resultar em `SyncStatus.offline`, e (b) só disparar `unawaited(syncAtivo.syncIndex())` quando `carregarCroquiRemoto` retornar um croqui válido (`croquiRemoto != null`), atualizando `frontend/lib/services/README.md` e verificando 100% de cobertura LCOV em `repositorio_dataset.dart`.

## 2. Limiar Visual (`150 ms`) do Modal `"Abrindo..."` e Recarga Silenciosa na `GlobalSearch`

- [x] 2.1 Em ciclo TDD (*Red-Green-Refactor*), atualizar e expandir `frontend/test/widgets/busca_global_test.dart` e implementar em `frontend/lib/widgets/busca_global.dart`: (a) o limiar de `150 ms` para abertura visual do diálogo `"Abrindo <título>..."` mantendo a trava `_abrindoDestino = true` no milissegundo zero (`0 ms`), de modo que resoluções ou falhas rápidas (`< 150 ms`) não abram nem pisquem o diálogo intermediário; e (b) a recarga silenciosa em `_loadAllData()` (exibindo `_isLoading = true` apenas quando `_allData.isEmpty`), atualizando `frontend/lib/widgets/README.md` e validando 100% de cobertura LCOV em `busca_global.dart`.
