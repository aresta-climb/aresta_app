# Tasks

## 1. Curto-Circuito de Rede Após Falha Offline de Sincronização

- [x] 1.1 Em ciclo TDD (*Red-Green-Refactor*), adicionar teste comportamental em `frontend/test/services/repositorio_dataset_test.dart` e atualizar `DatasetRepository.getCroqui` em `frontend/lib/services/repositorio_dataset.dart` para abortar imediatamente retornando `null` sem chamar `servicoCroquiOnline.carregarCroquiRemoto` quando `syncAtivo.syncIndex()` resultar em `SyncStatus.offline`, verificando que os testes passam e `repositorio_dataset.dart` mantém 100% de cobertura.
- [x] 1.2 Em ciclo TDD (*Red-Green-Refactor*), adicionar teste comportamental em `frontend/test/navigation/localizador_destino_uid_test.dart` e atualizar `LocalizadorDestinoUid.localizarComDiagnostico` em `frontend/lib/navigation/localizador_destino_uid.dart` para retornar imediatamente `ResultadoBuscaDestinoUid()` quando o `uid` não existir localmente e `sync.syncIndex()` resultar em `SyncStatus.offline`, verificando 100% de cobertura em `localizador_destino_uid.dart`.

## 2. Overlay Modal Bloqueante de Carregamento e Trava Contra Múltiplos Toques na Busca Global

- [x] 2.1 Em ciclo TDD (*Red-Green-Refactor*), adicionar testes de widget em `frontend/test/widgets/busca_global_test.dart` e implementar a trava `_abrindoDestino` e o diálogo modal bloqueante de carregamento (`"Abrindo <título>..."`) em `frontend/lib/widgets/busca_global.dart`, garantindo que toques repetidos durante o carregamento não empilhem resoluções nem múltiplos `ModalCroquiSemConexao`, atualizando `frontend/lib/widgets/README.md` e validando 100% de cobertura em `busca_global.dart`.
