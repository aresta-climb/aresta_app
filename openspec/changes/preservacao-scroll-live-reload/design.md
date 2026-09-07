## Context

O aplicativo Aresta Climb suporta Live Reload (Hot Reload do Editor Desktop) no Modo Experimental. Quando o autor salva uma alteração no editor visual, um evento de notificação remota push via WebSocket (`eventoLiveReload`) dispara a sincronização automática dos arquivos no dispositivo cliente.

Identificou-se uma regressão recente onde o aplicativo, em vez de aplicar as atualizações de texto e informações de forma suave e contínua (sem interrupções na interface), passou a recarregar a tela inteira e resetar a posição de rolagem para o topo (`offset = 0.0`).

A investigação técnica revelou cinco fatores concorrentes para a ocorrência do problema:
1. Queda transitória para `const Scaffold()` em `PageListenableBuilder` quando `cragData` é temporariamente nulo durante a troca atômica de binários em disco, desmontando a tela ativa e destruindo a instância de `ScrollController`.
2. Emissões múltiplas no `activeDataset.value` em um intervalo de milissegundos (`syncIndex()` seguido de `datasetRepo.init()`).
3. Ausência de `PageStorageKey` nos componentes `CustomScrollView` e `SingleChildScrollView` das páginas de detalhes.
4. Purgação agressiva de texturas na GPU via `PaintingBinding.instance.imageCache.clearLiveImages()`, forçando decodificação síncrona de todas as imagens em tela e causando cintilação.
5. Inércia de campos de estado local (como `_categories` em `PicoDetailsPage`) que só eram computados no `initState`.

Adicionalmente, solicitou-se diagnóstico explícito via terminal das ações de I/O em disco realizadas pelo `syncIndex()`, registrando quais arquivos foram efetivamente renomeados/atualizados e quais foram deletados.

## Goals / Non-Goals

**Goals:**
- Preservar estritamente a posição de rolagem (`scroll offset`) em `PicoDetailsPage`, `SetorPage` e `ViaPage` durante eventos de Live Reload.
- Garantir que `PageListenableBuilder` retenha a última versão válida em memória enquanto novos dados são consolidados, evitando desmontagens espúrias da árvore de widgets.
- Associar chaves `PageStorageKey` determinísticas a todos os componentes de rolagem principais de croqui.
- Eliminar chamadas redundantes a `datasetRepo.init()` em `registrarOuvintesLiveReload`.
- Remover a purgação destrutiva `clearLiveImages()`, confiando na invalidação reativa cirúrgica via SHA-256 já provida pelo `ImagemArquivoAresta`.
- Atualizar `_categories` reativamente no `didUpdateWidget` de `PicoDetailsPage`.
- Emitir logs de depuração detalhados em português brasileiro no `syncIndex()` listando os arquivos atualizados e removidos.
- Manter 100% de cobertura de testes unitários e de widget com TDD estrito.

**Non-Goals:**
- Alterar o design visual, tipografia ou disposição espacial das páginas de croqui.
- Alterar o protocolo de comunicação WebSocket ou a estrutura dos modelos Protobuf.
- Modificar o comportamento de rolagem intencional ao tocar em links específicos (ex: `scrollToMapaGeral` ou `scrollToEscalada`).

## Decisions

### Decisão 1: `PageListenableBuilder` Resiliente com Retenção de Último Estado Válido
Transformar `PageListenableBuilder` em um `StatefulWidget` que mantém uma referência local `_ultimoDadoCragValido`.
- **Racional:** Durante o processo de I/O em que o binário temporário (`.tmp`) é renomeado para `.binarypb` e o índice é regravado, a coleção `downloadedPicos` pode passar por um estado intermediário nulo ou incompleto. Se o builder retornar `const Scaffold()`, o Flutter desmonta imediatamente o `State` da página (e seu `ScrollController`), perdendo a posição de visualização. Retendo os dados anteriores até que uma nova versão válida chegue, a tela permanece montada e sofre apenas atualização diferencial via `didUpdateWidget`.
- **Tratamento de Exceções em Português:** Atualizar a mensagem enviada a `AppLogger.instance.logError` para português brasileiro (`'Exceção ao resolver nó no PageListenableBuilder: $e\nStacktrace:\n$st'`), em conformidade com o Princípio I.
- **Alternativas consideradas:** Usar `Future.delayed` antes de verificar nulo — descartado por ser não-determinístico e introduzir lentidão perceptível.

### Decisão 2: Chaves Persistentes de Rolagem (`PageStorageKey`)
Adicionar chaves determinísticas de armazenamento de página aos componentes com rolagem:
- `PicoDetailsPage`: `CustomScrollView(key: PageStorageKey('pico_${widget.cragId}'))`
- `GrupoPage`: `CustomScrollView(key: PageStorageKey('grupo_${widget.cragId}_${widget.grupo.nome}'))`
- `SetorPage`: `CustomScrollView(key: PageStorageKey('setor_${widget.cragId}_${widget.setor.nome}'))`
- `ViaPage` (`buildViaBody`): `SingleChildScrollView(key: PageStorageKey('via_${cragId}${sufixoGrupo}${sufixoSetor}_$nomeVia'))`
- **Racional:** O `PageStorage` do Flutter retém e restaura o deslocamento de rolagem do usuário no `PageStorageBucket` mesmo que ocorra reconstrução do widget ancestral ou substituição parcial na árvore de nós.

### Decisão 3: Coalescência de Notificações em `registrarOuvintesLiveReload`
Remover a chamada redundante `await datasetRepo.init()` em `registrarOuvintesLiveReload`.
- **Racional:** O método `syncService.syncIndex()` já executa `_storage.applyAtomicFileUpdates()`, atualiza os metadados do aplicativo e persiste o novo índice local. Invocar `datasetRepo.init()` imediatamente após gera uma segunda onda concorrente de decodificação de arquivo e emissão no `activeDataset`, causando corrida de renderização e desperdício de ciclos de CPU.

### Decisão 4: Purgação Cirúrgica sem `clearLiveImages()`
Remover `cache.clearLiveImages()` de `registrarOuvintesLiveReload`, mantendo apenas `cache.clear()`.
- **Racional:** `clearLiveImages()` descarta referências a imagens ativas na memória de renderização, forçando cabeçalhos e miniaturas a piscarem enquanto o arquivo é redecodificado. Como o `ImagemArquivoAresta` já incorpora o `checksumSha256` na chave `ChaveImagemArquivoAresta`, imagens com conteúdo modificado adquirem chave nova automaticamente. Imagens inalteradas continuam na memória sem cintilação.

### Decisão 5: Atualização Reativa de `_categories` em `PicoDetailsPage`
No método `didUpdateWidget(PicoDetailsPage oldWidget)` de `_PicoDetailsPageState`:
```dart
if (oldWidget.croqui != widget.croqui) {
  _categories = PicoCategorizedData(widget.croqui);
}
```
- **Racional:** Garante que textos de avisos, regras e créditos atualizem reativamente sem exigir que a tela inteira seja remontada do zero.

### Decisão 6: Logs Estruturados de Depuração de Arquivos no `syncIndex`
No método `syncIndex()` de `SyncService`, logo antes da efetivação em `_storage.applyAtomicFileUpdates()`:
- Emitir mensagens formatadas via `debugPrint` destacando nominalmente:
  - Quantidade e lista de arquivos atualizados/renomeados (`globalUpdates.filesToRename`).
  - Quantidade e lista de arquivos excluídos (`globalUpdates.filesToDelete`).
- **Formato das mensagens (100% em português brasileiro):**
```dart
if (globalUpdates.filesToRename.isNotEmpty) {
  debugPrint('🔄 [SyncService] Arquivos atualizados/renomeados no syncIndex (${globalUpdates.filesToRename.length}):');
  for (final entrada in globalUpdates.filesToRename.entries) {
    debugPrint('   • ${entrada.key} -> ${entrada.value}');
  }
}
if (globalUpdates.filesToDelete.isNotEmpty) {
  debugPrint('🗑️ [SyncService] Arquivos removidos no syncIndex (${globalUpdates.filesToDelete.length}):');
  for (final arquivo in globalUpdates.filesToDelete) {
    debugPrint('   • $arquivo');
  }
}
```
- **Racional:** Permite que desenvolvedores e operadores compreendam com exatidão o que foi transferido durante um Live Reload ou sincronização manual, eliminando incertezas operacionais.

## Conformidade com os Princípios de Engenharia (PRINCIPIOS.md)

1. **I. Tudo em Português**:
   - Todo o código novo e refatorado, nomes de variáveis (`_ultimoDadoCragValido`, `entrada`, `arquivo`), nomes de métodos, mensagens de log no console, mensagens de erro no `AppLogger` e documentação técnica estão integralmente em português brasileiro.
2. **II. Componentes Independentes (Feature-First)**:
   - `PageListenableBuilder` é independente e modular, atuando como um adaptador desacoplado de ciclo de vida. As chaves de rolagem são declaradas diretamente nas respectivas páginas (`PicoDetailsPage`, `SetorPage`, `ViaPage`), preservando a autonomia dos componentes.
3. **III. 100% de Test Coverage**:
   - Todas as modificações e fluxos condicionais possuem cobertura estrita de testes unitários e de widget, garantindo que nenhum caminho de execução fique sem verificação automatizada.
4. **IV. Imperativo do Teste em Primeiro Lugar (TDD)**:
   - O desenvolvimento segue estritamente o ciclo Vermelho-Verde-Refatorar. Cada teste de widget e de unidade é escrito e executado previamente para comprovar sua falha (Red) antes de receber o código de produção (Green). A estrutura de diretórios em `test/` espelha perfeitamente `lib/` (ex: `test/services/http/sync_service_test.dart` espelhando `lib/services/http/sync_service.dart`).
5. **V. Testes de Widget em Primeiro Lugar**:
   - O plano de testes prioriza testes de widget com renderização real da árvore (`PicoDetailsPage`, `SetorPage`, `PageListenableBuilder` e `main.dart`) para assegurar que o deslocamento de rolagem (`scroll offset`) seja mantido do ponto de vista do usuário final antes de descer para unidades de serviço.
6. **VI. Simplicidade e Anti-Abstração**:
   - Rejeição de soluções complexas ou middlewares artificiais. Uso direto dos mecanismos nativos do Flutter (`StatefulWidget`, `PageStorageKey`, `didUpdateWidget`), priorizando clareza e manutenibilidade.
7. **VII. Documentação Contínua e Abrangente**:
   - Todo código novo ou ajustado é documentado com docstrings completas em formato `///` explicando a intenção das rotinas. Os arquivos de documentação pertinentes (`frontend/HOT_RELOAD.md`, `frontend/lib/navigation/README.md`, `frontend/lib/services/http/README.md`) são atualizados de forma sincronizada com as entregas.

## Risks / Trade-offs

- **[Pico genuinamente excluído no editor desktop]** → Se o usuário deletar o pico no editor, reter o último estado válido poderia manter a visualização indefinidamente.  
  *Mitigação:* Se o dataset estiver consolidado fora de sincronização ativa e o identificador do pico não constar nem nos baixados nem na sessão online, dispara-se `AppNav.back(context)` e desmonta-se a página.
- **[Conflito de chave de rolagem se houver setores homônimos em picos distintos]** →  
  *Mitigação:* O identificador do pico (`cragId`) faz parte obrigatória da `PageStorageKey` (`'setor_${widget.cragId}_${widget.setor.nome}'`).
