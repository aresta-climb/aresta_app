# Design

## Context

Veja `proposal.md` para a motivação e a linha do tempo do crash.

Na arquitetura atual de navegação em árvore (`construirPaginaParaNo` em `construtor_view_arvore.dart`), a tela `PicoDetailsPage` é envolvida por um `PageListenableBuilder` que escuta `datasetRepo.activeDataset`. Esse desenho permite que qualquer atualização no dataset (como Hot Reload no modo experimental ou atualização de croqui via sincronização) reconstrua `PicoDetailsPage` passando um novo `PicoViewModel` com os protobufs `Pico` e `Croqui` atualizados, preservando o `_PicoDetailsPageState` (e a posição de rolagem). No `didUpdateWidget` de `_PicoDetailsPageState`, a instância anterior de `PicoViewModel` sofre `dispose()` e é substituída pela nova.

No entanto, durante `PicoViewModel.baixarPico()`, o `SyncService.downloadCrag()` invoca `await datasetRepository.updateDatasetAfterDownload(id)` antes de `ServicoDownloadSegundoPlano.executarDownload()` encerrar o `await gerenciadorNotificacao.notificarConclusao()`. Durante essa janela assíncrona, `PageListenableBuilder` reconstrói a página e descarta o `PicoViewModel` original que ainda está aguardando o `await executarDownload()`. O mesmo ocorre quando o usuário escolhe "Salvar" no `ModalConfirmacaoSaida` (que dispara `_iniciarDownload()` e imediatamente executa `AppNav.back(context)` desmontando a página) ou se `excluirPico()` sofrer rebuild/descarte antes do retorno de `deleteCrag()`.

## Goals / Non-Goals

**Goals:**
- Garantir que `PicoViewModel` nunca invoque `notifyListeners()` após `dispose()`, independentemente de quantos `await` existam em `baixarPico()`, `excluirPico()` ou callbacks assíncronos.
- Manter intacta a reatividade do `PageListenableBuilder` + `PicoDetailsPage` para Hot Reload e atualizações de croqui pós-sincronização.
- Eliminar os fakes de classes internas (`_FakeSyncService`, `_FakeDatasetRepository`) e o uso de `mocktail` nos testes de `PicoViewModel`, substituindo-os por testes de integração usando `SyncService` e `DatasetRepository` reais sobre diretório temporário real e fronteira HTTP fake (`ClienteHttpAresta.paraTestes`).

**Non-Goals:**
- Alterar o fluxo de `ServicoDownloadSegundoPlano` ou a ordem de chamadas dentro de `SyncService.downloadCrag`.
- Remover o `PageListenableBuilder` da árvore de navegação.

## Decisions

### 1. Controle explícito de ciclo de vida (`_disposed`) em `PicoViewModel`
- **Decisão**: Adicionar uma flag privada `bool _disposed = false;` em `PicoViewModel`, atualizada para `true` em `dispose()`, e sobrescrever/proteger `notifyListeners()` (além de checar `if (_disposed) return ...;` após pontos de suspensão `await` em `baixarPico()` e `excluirPico()`).
- **Por quê**: Mesmo que evitássemos recriar `PicoViewModel` quando o conteúdo de `Pico`/`Croqui` fosse idêntico, ainda existem dois casos legítimos em que o `PicoViewModel` é descartado enquanto `baixarPico()` está em andamento:
  1. O download trouxe uma versão mais nova do croqui (dados diferentes -> `PicoViewModel` precisa atualizar/trocar).
  2. O usuário clicou em "Salvar Offline" no modal Guardião de Saída (`ModalConfirmacaoSaida`), que inicia o download e sai da página imediatamente (`AppNav.back`).
  Portanto, tornar `PicoViewModel` resiliente ao descarte durante operações assíncronas resolve todos os vetores do bug sem quebrar o Hot Reload.
- **Alternativas consideradas**:
  - *Mover `updateDatasetAfterDownload` para depois da notificação nativa*: Não resolveria o caso do Guardião de Saída ("Salvar e Sair") nem o caso de um frame de UI ser agendado entre o fim de `executarDownload` e a continuação da microtask de `baixarPico`.

### 2. Testes de fronteira com `SyncService` e `DatasetRepository` reais (Princípio V do `AGENTS.md`)
- **Decisão**: Em `pico_view_model_test.dart` e `pico_test.dart`, substituir `_FakeSyncService` e `_FakeDatasetRepository` por instâncias reais de `DatasetRepository` (operando em `Directory.systemTemp`) e `SyncService` (injetado com `ClienteHttpAresta.paraTestes` simulando apenas as respostas HTTP de `/indice.binarypb` e `/<id>/compilado.binarypb`, e um `GerenciadorNotificacaoDownload` fake/controlado na fronteira do plugin nativo).
- **Por quê**: O bug só passou despercebido porque `_FakeSyncService.downloadCrag` retornava `true` sem executar `datasetRepository.updateDatasetAfterDownload(id)`. Usando o `SyncService` real com HTTP fake e montando a árvore com `construirPaginaParaNo` (`PageListenableBuilder`), o teste exercita exatamente a cadeia reativa de produção sob TDD (Red-Green-Refactor).

## Risks / Trade-offs

- **[Risco] Testes unitários com `SyncService` real exigem configuração de `Directory.systemTemp`, `PathProviderPlatform` e `SharedPreferences`** → **Mitigação**: Encapsular o setup do ambiente temporário e do cliente HTTP fake de respostas Protobuf no `setUp`/`tearDown` do arquivo de teste, mantendo cada `test()` enxuto, rápido e 100% determinístico em memória/disco temporário local.
