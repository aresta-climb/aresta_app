# Tasks

## 1. Widget Modular `ModalSessaoExperimentalEncerrada` (Widget-First TDD)

- [ ] 1.1 Criar o teste de widget `frontend/test/widgets/modal_sessao_experimental_encerrada_test.dart` (Red) validando a renderização do título, da mensagem explicativa de retorno ao catálogo oficial, do botão `"ENTENDI"`, o fechamento do modal ao tocar no botão e a proteção contra empilhamento duplicado via `ModalSessaoExperimentalEncerrada.exibir(context)`, verificando que o teste falha antes da implementação.
- [ ] 1.2 Implementar `frontend/lib/widgets/modal_sessao_experimental_encerrada.dart` (Green) com docstrings detalhadas em português e identidade visual consistente com `ModalBetaAberto` (`caveShadow`, `graniteEdge`, `brandColor`), verificando que `flutter test test/widgets/modal_sessao_experimental_encerrada_test.dart` passa com 100% de cobertura.
- [ ] 1.3 Atualizar `frontend/lib/widgets/README.md` documentando o componente `ModalSessaoExperimentalEncerrada`.

## 2. Detecção de URL Experimental, Tipagem de `FetchIndiceResult` e Filtro do Crashlytics (TDD)

- [ ] 2.1 Atualizar `frontend/test/services/editor_croqui_test.dart` e `frontend/test/services/http/sync_rede_test.dart` (Red) para testar: (a) `EditorDeCroqui.isUrlExperimental(url)` e `notificadorSessaoExpirada`, (b) o retorno tipado `IndiceOffline` e `IndiceErroServidor(statusCode)` em `SyncNetwork.fetchIndiceWithRetries`, e (c) que respostas `404`/`500` em URLs experimentais (`previa.arestaclimb.com` ou LAN) chamam apenas `AppLogger.instance.logAviso` sem invocar `logError`, enquanto na CDN oficial (`serving.arestaclimb.com`) invocam `logError`, verificando que os novos testes falham.
- [ ] 2.2 Implementar `EditorDeCroqui.isUrlExperimental`, `notificadorSessaoExpirada` e `notificarSessaoExperimentalExpirada()` em `frontend/lib/services/editor_croqui.dart`, e implementar `IndiceOffline`, `IndiceErroServidor` e o filtro de log experimental em `frontend/lib/services/http/sync_rede.dart` (Green), verificando que `flutter test test/services/editor_croqui_test.dart test/services/http/sync_rede_test.dart` passa com 100% de cobertura.

## 3. Encerramento Automático da Sessão Experimental no `SyncService` e Feedback na UI (TDD)

- [ ] 3.1 Atualizar `frontend/test/services/http/sync_service_test.dart`, `frontend/test/view/function_library/biblioteca_funcoes_comuns_test.dart` e `frontend/test/main_test.dart` (Red) validando: (a) que `SyncService._executarSyncIndex` atribui `SyncStatus.offline` para `IndiceOffline` e `SyncStatus.error` para `IndiceErroServidor` no modo oficial, (b) que no modo experimental um `IndiceErroServidor(404)` executa `nukeExperimentalData()`, restaura o índice oficial em memória e dispara `notificarSessaoExperimentalExpirada()`, (c) que `handleManualSync` não exibe `SnackBar` quando a sessão experimental é encerrada durante o sync, e (d) que `MyApp` exibe o `ModalSessaoExperimentalEncerrada` e navega para a Home ao receber a notificação de sessão expirada.
- [ ] 3.2 Implementar o tratamento de `IndiceOffline` e `IndiceErroServidor` (incluindo o encerramento automático de sessão experimental expirada) em `frontend/lib/services/http/sync_service.dart`, a supressão de `SnackBar` em `frontend/lib/view/function_library/biblioteca_funcoes_comuns.dart` e o listener de exibição do modal em `frontend/lib/main.dart` (Green), verificando que todos os testes passam.
- [ ] 3.3 Atualizar `frontend/lib/services/README.md` documentando as variantes seladas `IndiceOffline`/`IndiceErroServidor` e o ciclo de encerramento automático de sessões experimentais expiradas.

## 4. Verificação Global de Qualidade

- [ ] 4.1 Executar `flutter analyze` e a suíte completa de testes (`flutter test`) no diretório `frontend/`, garantindo zero avisos de linter e 100% de aprovação nos testes unitários, de widget e de arquitetura.
