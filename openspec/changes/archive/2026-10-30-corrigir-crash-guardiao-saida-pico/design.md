# Design

## Context

Conforme detalhado em `proposal.md`, o crash em produção/pré-lançamento (`TypeError: Null check operator used on a null value` em `State.context` -> `_PicoDetailsPageState._setupBackInterceptor`, `pico.dart:186`) ocorre devido à interação entre dois fatores:
1. `AppNav.back(context)` (`funcoes_navegacao.dart:353`) chama `Navigator.of(context).canPop()` e, se verdadeiro, executa `Navigator.of(context).pop()`. Desde que `TreeNavigationWrapper` adotou o `Navigator(pages: ...)` declarativo, todas as páginas da árvore (`PicoNode`, `SetorNode`, `ViaNode`, etc.) são `MaterialPage`s empilhadas sobre a `TabsPage`. Assim, `Navigator.of(context).canPop()` é sempre `true` em qualquer página da árvore, e `Navigator.of(context).pop()` força a remoção imperativa da `MaterialPage` ignorando `PopScope(canPop: false)`. O `onDidRemovePage` do `Navigator` aciona `treeController.goBack()`, que executa `tree.onBackInterceptor` e abre o `ModalConfirmacaoSaida` no `RootNavigator` retornando `true` (cancelando a mudança de nó na árvore). Porém, como a `MaterialPage` já foi removida imperativamente do `Navigator`, a transição de saída termina ~300ms depois e chama `_PicoDetailsPageState.dispose()`, tornando `_element = null` enquanto o modal segue aberto.
2. Dentro de `_PicoDetailsPageState`, os callbacks do modal (`onSairSemSalvar` e `onSalvar`) avaliam `if (context.mounted && ...)`. Em uma subclasse de `State`, `context` (sem variável local sombreando) invoca o getter `State.context` (`return _element!;` em `framework.dart:959`), que lança `TypeError` em builds de *release* antes mesmo de ler `.mounted`.

## Goals / Non-Goals

**Goals:**
- Garantir que `AppNav.back(context)` nunca execute `Navigator.of(context).pop()` sobre rotas declarativas gerenciadas pela lista `pages` do `TreeNavigationWrapper` (`ModalRoute.of(context)?.settings is Page`), delegando a volta para `TreeNavigationController.goBack()`.
- Preservar o fechamento de rotas imperativas reais (`DialogRoute`, `ModalBottomSheetRoute`, `_SearchPageRoute`, ou `MaterialPageRoute` empilhadas via `Navigator.push`) quando `AppNav.back(context)` for chamado a partir do `context` de uma rota imperativa (`settings is! Page`).
- Eliminar qualquer acesso ao getter `State.context` sem verificação prévia de `State.mounted` em `_PicoDetailsPageState` e simplificar os callbacks de saída para utilizarem `tree.goBack()` diretamente.
- Unificar a interceptação de retorno em `PicoDetailsPage` no `tree.onBackInterceptor`, eliminando a duplicação divergente no `PopScope` interno de `PicoDetailsPage`.

**Non-Goals:**
- Alterar a regra de negócio de quando o `ModalConfirmacaoSaida` deve ou não ser exibido (`PicoViewModel.deveInterceptarSaida` e controle de sessão `ModalConfirmacaoSaida.exibiuNestaSessao`).
- Modificar a estrutura de nós de `ArvoreNavegacao`.

## Decisions

### 1. Verificação de Rota Declarativa vs. Imperativa em `AppNav.back(context)`
- **Decisão**: Em `AppNav.back(context)`, inspecionar `final rotaAtual = ModalRoute.of(context);` e só executar `Navigator.of(context).pop()` quando `rotaAtual != null && rotaAtual.settings is! Page && Navigator.of(context).canPop()`. Caso contrário (quando `rotaAtual?.settings is Page` ou quando não há rota imperativa empilhada), acionar `ctrl.goBack()`.
- **Racional**: No Flutter, toda rota criada pela API declarativa `Navigator.pages` possui `route.settings` como uma subclasse de `Page<dynamic>` (`MaterialPage`, `ModalBottomSheetPage`), enquanto rotas imperativas empilhadas com `Navigator.push`, `showDialog`, `showModalBottomSheet` ou `showSearch` possuem `RouteSettings` comuns (`settings is! Page`). Essa verificação em tempo O(1) separa com precisão cirúrgica overlays imperativos de páginas declarativas da árvore.
- **Alternativas consideradas**:
  - *Substituir `Navigator.pop()` por `Navigator.maybePop()` em `AppNav.back`*: Rejeitado porque `maybePop()` é assíncrono e, para páginas sem `PopScope(canPop: false)` (como `SetorPage` e `ViaPage`), ainda removeria a `MaterialPage` imperativamente antes de atualizar o `treeController`, dependendo do efeito colateral de `onDidRemovePage` em vez do fluxo reativo unidirecional.

### 2. Uso Estrito de `State.mounted` e `tree.goBack()` em `_PicoDetailsPageState`
- **Decisão**:
  1. No início do callback `tree.onBackInterceptor`, verificar `if (!mounted) { tree.onBackInterceptor = null; return false; }`.
  2. Em `_iniciarDownload()`, verificar `if (!mounted) return;` logo na entrada antes de acessar `context`.
  3. Nos callbacks `onSalvar` e `onSairSemSalvar` passados ao `ModalConfirmacaoSaida.mostrar` em `_setupBackInterceptor`:
     ```dart
     onSalvar: () {
       if (mounted) {
         _iniciarDownload();
       }
       tree.onBackInterceptor = null;
       tree.goBack();
     },
     onSairSemSalvar: () {
       tree.onBackInterceptor = null;
       tree.goBack();
     },
     ```
  4. Remover o `PopScope` redundante em `PicoDetailsPage.build` (ou delegá-lo diretamente a `treeController.goBack()`), já que o `TreeNavigationWrapper` intercepta o gesto/botão voltar do sistema operacional no nível superior e invoca `treeController.goBack()`.
- **Racional**: Evita completamente o acesso ao getter `State.context` (`_element!`) após um potencial desmonte e garante que a confirmação de saída no modal sempre retroceda o nó no `TreeNavigationController` mesmo que a árvore de widgets tenha sofrido reconstrução.

## Risks / Trade-offs

- **[Risco] Algum teste ou componente chamar `AppNav.back(context)` dentro de um `MaterialApp` de teste isolado sem `TreeNavigationWrapper`** → **Mitigação**: Se `_ctrl(context)` for `null` (ambiente de teste isolado sem `TreeNavigationWrapper`) e `Navigator.of(context).canPop()` for `true`, manter o fallback `Navigator.of(context).pop()`, garantindo 100% de compatibilidade com testes de widget isolados.
- **[Risco] Limpeza indevida de `tree.onBackInterceptor` no `dispose()` de uma instância antiga de `_PicoDetailsPageState`** → **Mitigação**: Guardar a referência da closure `_backInterceptor` no `_PicoDetailsPageState` e, no `dispose()`, limpar `if (tree.onBackInterceptor == _backInterceptor) { tree.onBackInterceptor = null; }` (mesmo padrão seguro já utilizado em `SobreTimePage`).
