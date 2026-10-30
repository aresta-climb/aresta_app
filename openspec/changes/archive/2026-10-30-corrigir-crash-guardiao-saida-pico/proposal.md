# Proposal

## Why

No relatório de pré-lançamento (teste automatizado da Google Play) em modo *release*, ocorreu um crash `TypeError: Null check operator used on a null value` em `State.context` (`_PicoDetailsPageState._setupBackInterceptor`, `pico.dart:186`) ao tocar em "Sair sem Salvar" no `ModalConfirmacaoSaida` após excluir um croqui baixado e acionar o botão voltar da `AppBar`. Isso acontece porque `AppNav.back(context)` executa um `Navigator.of(context).pop()` imperativo sobre a rota declarativa `MaterialPage` do `PicoNode` antes de consultar o `TreeNavigationController.onBackInterceptor`, desmontando o `_PicoDetailsPageState` ao fim da animação de transição enquanto o modal permanece aberto no `RootNavigator` e estourando `_element!` quando o callback tenta avaliar `this.context.mounted`.

## What Changes

- **Distinção entre Rotas Declarativas e Imperativas em `AppNav.back`**: Atualizar `AppNav.back(context)` em `frontend/lib/navigation/funcoes_navegacao.dart` para verificar se a rota atual no `Navigator` é uma rota imperativa sobreposta (`ModalRoute.of(context)?.settings is! Page`) antes de acionar `Navigator.of(context).pop()`; quando a rota atual for uma página declarativa da árvore (`settings is Page`), delegar diretamente para `TreeNavigationController.goBack()`, garantindo que `onBackInterceptor` seja avaliado **antes** de qualquer remoção de página no `Navigator`.
- **Segurança de Ciclo de Vida (`State.mounted`) e Desacoplamento de Contexto em `PicoDetailsPage`**:
  - Substituir o uso inseguro de `context.mounted` (que invoca o getter `this.context` / `_element!` em `State`) por verificações explícitas de `mounted` (`State.mounted`) antes de qualquer acesso a `context` em `_setupBackInterceptor`, `_iniciarDownload` e callbacks assíncronos de `PicoDetailsPage`.
  - Nos callbacks `onSalvar` e `onSairSemSalvar` do Guardião de Saída, realizar o retorno diretamente via `tree.goBack()` após limpar `tree.onBackInterceptor = null`, preservando a transição declarativa limpa e unificando o comportamento sem depender de um `PopScope` redundante e divergente em `PicoDetailsPage`.
- **Testes Comportamentais e de Regressão 1:1**: Adicionar testes em `pico_test.dart` e nos testes de navegação cobrindo o fluxo completo do crash (excluir croqui baixado na `PicoDetailsPage` -> tocar no `BackButton` da `AppBar` -> exibir `ModalConfirmacaoSaida` mantendo a `PicoDetailsPage` montada -> confirmar "Sair sem Salvar" ou "Salvar Offline" sem erro de ciclo de vida).

## Capabilities

### New Capabilities

### Modified Capabilities
- `guardiao-navegacao-online`: Garantir que a interceptação do Guardião de Saída (via gesto/botão do sistema ou `BackButton` da `AppBar`, inclusive após exclusão local de croqui que transiciona a tela para modo online) preserve a `PicoDetailsPage` montada enquanto o modal estiver aberto e execute os callbacks de saída com segurança de ciclo de vida (`mounted`).
- `navigation`: Garantir que `AppNav.back(context)` respeite a arquitetura declarativa da árvore (`TreeNavigationController.goBack()`) para rotas baseadas em `Page`, utilizando `Navigator.pop()` apenas para rotas imperativas sobrepostas (`DialogRoute`, `ModalBottomSheetRoute`, `SearchPageRoute`, etc.).

## Impact

- `frontend/lib/navigation/funcoes_navegacao.dart` (`AppNav.back`)
- `frontend/lib/pages/pico.dart` (`_PicoDetailsPageState._setupBackInterceptor`, `_iniciarDownload`, `PopScope`)
- `frontend/test/pages/pico_test.dart` e `frontend/test/navigation/funcoes_navegacao_test.dart`
