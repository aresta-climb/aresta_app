# Design

## Context

Conforme detalhado em `proposal.md - Why`, três mecanismos combinados causam piscadas visuais quando o usuário toca em um item de croqui não baixado na Busca Global (`GlobalSearch`) sem internet:
1. Abertura imediata (`0 ms`) e fechamento quase instantâneo (`~5 ms` em Modo Avião) do `showDialog("Abrindo <título>...")` simultaneamente ao recolhimento do teclado antes de abrir o `ModalCroquiSemConexao`.
2. Disparo de `unawaited(syncAtivo.syncIndex())` em `DatasetRepository.getCroqui` antes de verificar se `carregarCroquiRemoto` obteve sucesso, fazendo com que 4 segundos depois (após 3 tentativas com `retryDelay = 2s`) o `SyncService` chame `_loadLocalIndiceAndNotify` e reemita `activeDataset.value`.
3. Em `GlobalSearch._loadAllData()`, a atribuição incondicional `_isLoading = true` desmonta a `ListView` de resultados já visível e exibe um `CircularProgressIndicator` temporário a cada notificação reativa de `activeDataset` ou `versaoNotificador`.

Todas as decisões seguem rigorosamente os 8 princípios do `AGENTS.md` (100% em português brasileiro, modularidade, TDD *Red-Green-Refactor*, espelhamento 1:1, 100% de cobertura comportamental e ausência de mocks internos).

## Goals / Non-Goals

**Goals:**
- Eliminar o "flash" de 1 frame do diálogo `"Abrindo <título>..."` em resoluções rápidas (`< 150 ms`, como croquis locais ou rejeição imediata de socket em Modo Avião), mantendo o bloqueio de toques repetidos desde o milissegundo zero (`0 ms`).
- Eliminar a recarga destrutiva (`_isLoading = true`) na `GlobalSearch` quando já houver dados carregados em `_allData`.
- Evitar disparos de `unawaited(syncAtivo.syncIndex())` e requisições redundantes em `DatasetRepository.getCroqui` quando a operação falhar offline.

**Non-Goals:**
- Alterar os tempos de timeout TCP/TLS (`10s`) do `ClienteHttpAresta`.

## Decisions

### 1. Limiar Visual (`150 ms`) para o Diálogo `"Abrindo <título>..."` com Trava Síncrona Imediata em `GlobalSearch`
- **Decisão**:
  - Manter `_abrindoDestino = true` síncrono na primeira linha de `_abrirDestinoPorUid`, garantindo que qualquer toque subsequente seja ignorado desde `0 ms`.
  - Agendar a abertura do `showDialog("Abrindo $titulo...")` através de um `Timer(const Duration(milliseconds: 150), ...)` que verifica `if (!mounted || !_abrindoDestino) return;` e marca `dialogoCarregamentoAberto = true`.
  - No bloco `finally` após `localizarComDiagnostico(uid)`:
    - Cancelar o `timerCarregamento`.
    - Se `dialogoCarregamentoAberto && mounted`, fechar o diálogo via `navegadorRaiz.pop()`.
    - Definir `_abrindoDestino = false`.
  - Recolher o foco do teclado (`_searchFocusNode.unfocus()`) apenas ao exibir o diálogo (após `150 ms`), ao navegar para o destino ou antes de exibir o `ModalCroquiSemConexao`, evitando duas transições visuais concorrentes no mesmo frame.
- **Alternativas consideradas**:
  - *Forçar o diálogo `"Abrindo..."` a ficar aberto por no mínimo 400 ms mesmo em Modo Avião*: Descartado porque adicionaria atraso artificial desnecessário à abertura de croquis salvos localmente e à resposta rápida em Modo Avião.

### 2. Recarga Silenciosa em `GlobalSearch._loadAllData()`
- **Decisão**:
  - Em `_loadAllData()`, só chamar `setState(() { _isLoading = true; })` quando `_allData.isEmpty`.
  - Quando `_allData.isNotEmpty` (recarga reativa disparada por `versaoNotificador` ou `activeDataset`), consultar o SQLite em segundo plano mantendo a `ListView` atual montada na árvore de widgets e atualizar `_allData` e `_filteredResults` atomicamente no bloco `finally`.
- **Alternativas consideradas**:
  - *Ignorar notificações de `activeDataset` na `GlobalSearch`*: Descartado porque violaria o requisito de reatividade automática quando novos picos ou sessões são atualizados.

### 3. Curto-Circuito Offline e `syncIndex()` Pós-Sucesso em `DatasetRepository.getCroqui`
- **Decisão**:
  - Na Etapa 4 de `DatasetRepository.getCroqui`:
    1. No fallback em que `caminhoRelativo` está ausente do índice local e `await syncAtivo.syncIndex()` é executado: se `syncAtivo.syncStatus.value == SyncStatus.offline`, retornar `null` imediatamente.
    2. Quando `caminhoRelativo` está presente: executar `servicoCroquiOnline.carregarCroquiRemoto(...)` primeiro e só disparar `unawaited(syncAtivo.syncIndex())` dentro do bloco `if (croquiRemoto != null)`. Se `carregarCroquiRemoto` retornar `null` (falha de conexão), nenhum `syncIndex()` em background é iniciado.

## Risks / Trade-offs

- **[Risco] Timer de `150 ms` pendente em testes de widget (`testWidgets`) se a resolução terminar antes** → **Mitigação**: O `timerCarregamento.cancel()` no bloco `finally` cancela imediatamente o timer assim que `localizarComDiagnostico` retorna, garantindo zero timers pendentes no `FakeAsync`.
