## 1. Testes de Widget em Primeiro Lugar (TDD - Fase Vermelha)

- [x] 1.1 Criar testes de widget em `frontend/test/pages/setor_test.dart` e `frontend/test/pages/pico_test.dart` validando que reconstruções via `didUpdateWidget` com novos dados do croqui preservam o deslocamento de rolagem anterior e utilizam `PageStorageKey` (Falha inicial - Red)
- [x] 1.2 Criar testes de widget em `frontend/test/navigation/page_listenable_builder_test.dart` garantindo que o builder retenha o último dado válido e não desmonte a página para `const Scaffold()` durante estados intermediários nulos do dataset (Falha inicial - Red)
- [x] 1.3 Criar testes de widget em `frontend/test/main_test.dart` simulando recebimento de notificação push de Live Reload via WebSocket e garantindo que o deslocamento de rolagem (`pixels`) permaneça estritamente inalterado (Falha inicial - Red)
- [x] 1.4 Atualizar testes unitários em `frontend/test/main_test.dart` validando que `registrarOuvintesLiveReload` invoca `imageCache.clear()` sem chamar `clearLiveImages()` e sem efetuar chamada redundante a `datasetRepo.init()` (Falha inicial - Red)
- [x] 1.5 Criar testes unitários em `frontend/test/services/http/sync_service_test.dart` espelhando `lib/services/http/` para validar a emissão de logs estruturados de depuração no `syncIndex` detalhando arquivos atualizados/renomeados e removidos (Falha inicial - Red)
- [x] 1.6 Criar teste de widget em `frontend/test/pages/grupo_test.dart` validando a presença de `PageStorageKey` no `CustomScrollView` de `GrupoPage` e a retenção de deslocamento de rolagem (Falha inicial - Red)

## 2. Resiliência do PageListenableBuilder e Retenção de Estado (Fase Verde)

- [x] 2.1 Refatorar `PageListenableBuilder` para `StatefulWidget` com retenção do último dado válido em memória (`_ultimoDadoCragValido`), prevenindo desmontagens transitórias para `const Scaffold()` durante I/O de disco
- [x] 2.2 Atualizar mensagens de log de erro para português brasileiro no `PageListenableBuilder` e assegurar que o retorno automático (`AppNav.back`) só ocorra caso a ausência do croqui seja confirmada fora de sincronização

## 3. Chaves Persistentes de Rolagem e Reatividade Local (Fase Verde)

- [x] 3.1 Adicionar `PageStorageKey('pico_${widget.cragId}')` ao `CustomScrollView` de `PicoDetailsPage`
- [x] 3.2 Adicionar `PageStorageKey('setor_${widget.cragId}${sufixoGrupo}_${widget.setor.nome}')` ao `CustomScrollView` de `SetorPage` contemplando grupo se presente
- [x] 3.3 Adicionar `PageStorageKey('via_${cragId}${sufixoGrupo}${sufixoSetor}_$nomeVia')` ao `SingleChildScrollView` de `ViaPage` (`buildViaBody`)
- [x] 3.4 Atualizar reativamente `_categories` em `PicoDetailsPage.didUpdateWidget` quando o objeto `widget.croqui` for modificado
- [x] 3.5 Adicionar `PageStorageKey('grupo_${widget.cragId}_${widget.grupo.nome}')` ao `CustomScrollView` de `GrupoPage`

## 4. Coalescência de Live Reload e Telemetria de Sincronização (Fase Verde)

- [x] 4.1 Remover a chamada duplicada a `datasetRepo.init()` no ouvinte de `eventoLiveReload` em `registrarOuvintesLiveReload` (`frontend/lib/main.dart`)
- [x] 4.2 Remover a purgação destrutiva de texturas ativas `cache.clearLiveImages()` em `registrarOuvintesLiveReload`, preservando a invalidação cirúrgica por SHA-256
- [x] 4.3 Implementar logs de depuração estruturados em `SyncService.syncIndex` listando expressamente no console a quantidade e os caminhos de arquivos atualizados/renomeados e removidos antes da execução de `applyAtomicFileUpdates`

## 5. Refatoração, Cobertura Integral e Documentação (PRINCIPIOS.md)

- [x] 5.1 Executar a suíte completa de testes (`flutter test`) assegurando 100% de aprovação e ausência de regressões (Fase Verde/Refactor)
- [x] 5.2 Validar 100% de cobertura de testes nos arquivos criados e modificados (`PageListenableBuilder`, `PicoDetailsPage`, `SetorPage`, `ViaPage`, `main.dart`, `SyncService`)
- [x] 5.3 Assegurar conformidade com Princípio I (100% em português brasileiro em identificadores, comentários, docstrings `///` e mensagens de log)
- [x] 5.4 Atualizar a documentação técnica nos arquivos pertinentes (`frontend/HOT_RELOAD.md`, `frontend/lib/navigation/README.md`, `frontend/lib/services/http/README.md`) refletindo a retenção de estado de nós, preservação de rolagem e diagnósticos de sincronização
