# Tasks

## 1. Navegação Declarativa vs. Imperativa em `AppNav.back`

- [x] 1.1 Escrever testes de widget (Red) em `frontend/test/navigation/funcoes_navegacao_test.dart` validando que `AppNav.back(context)` chamado a partir de uma página declarativa da árvore (`ModalRoute.of(context)?.settings is Page`) delega a transição para `TreeNavigationController.goBack()` (respeitando `onBackInterceptor` antes de remover a página da pilha), enquanto `AppNav.back(context)` chamado de uma rota imperativa sobreposta (`showDialog` / `Navigator.push`) desempilha apenas a rota sobreposta.
- [x] 1.2 Atualizar `AppNav.back(context)` em `frontend/lib/navigation/funcoes_navegacao.dart` (Green/Refactor) para distinguir rotas declarativas (`settings is Page`) de rotas imperativas sobrepostas (`settings is! Page`), preservando o fallback para testes isolados sem `TreeNavigationController`, e verificar que `flutter test test/navigation/funcoes_navegacao_test.dart` passa com 100% de cobertura nas linhas alteradas.

## 2. Segurança de Ciclo de Vida e Guardião de Saída em `PicoDetailsPage`

- [x] 2.1 Escrever testes de widget (Red) em `frontend/test/pages/pico_test.dart` reproduzindo o fluxo completo do crash: abrir um pico baixado na `TreeNavigationWrapper`, excluir o guia local via botão de lixeira (transitando a tela para modo online), acionar o `BackButton` da `AppBar`, verificar que o `ModalConfirmacaoSaida` é exibido mantendo `PicoDetailsPage` montada e confirmar tanto "Sair sem Salvar" quanto "Salvar Offline" sem lançar `TypeError` em `State.context`.
- [x] 2.2 Atualizar `_PicoDetailsPageState` em `frontend/lib/pages/pico.dart` (Green/Refactor) para utilizar `mounted` (`State.mounted`) antes de qualquer acesso a `context`, acionar `tree.goBack()` diretamente nos callbacks `onSalvar` e `onSairSemSalvar`, proteger a limpeza de `tree.onBackInterceptor` por identidade de função no `dispose()` e unificar a interceptação de retorno, verificando que `flutter test test/pages/pico_test.dart` passa com 100% de cobertura.
