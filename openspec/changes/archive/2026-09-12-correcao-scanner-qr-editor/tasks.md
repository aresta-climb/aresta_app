## 1. Testes de Widget em Primeiro Lugar (Fase Vermelha / Red TDD)

- [x] 1.1 Criar teste de widget em `settings_functions_test.dart` verificando que a tela do scanner abre no Root Navigator cobrindo o diálogo (`isCurrent == false` na rota do diálogo)
- [x] 1.2 Criar teste de widget para o cancelamento do scanner (retorno `null`), garantindo que o diálogo permanece ativo e o texto anterior inalterado
- [x] 1.3 Criar teste de widget para auto-conexão bem-sucedida (retorno de URL pelo scanner dispara conexão e navegação automática para o croqui)
- [x] 1.4 Criar teste de widget para auto-conexão com falha de rede/HTTP (servidor 404/500), garantindo que o diálogo permanece aberto e a URL permanece no campo de texto
- [x] 1.5 Executar os testes criados via `flutter test` e confirmar que falham na implementação atual (confirmação do estado Vermelho)

## 2. Implementação da Correção e Injetabilidade (Fase Verde / Green TDD)

- [x] 2.1 Adicionar parâmetro opcional em português `WidgetBuilder? construtorScannerQr` em `mostrarDialogConexao` (Princípio I e VI)
- [x] 2.2 Alterar a abertura da tela do scanner para utilizar `Navigator.of(dialogContext).push` no `Navigator` raiz, garantindo sobreposição opaca total
- [x] 2.3 Implementar a rotina de auto-conexão imediata ao retornar URL não vazia do scanner, reutilizando o fluxo de `conectarEditor` com indicador de carregamento
- [x] 2.4 Assegurar verificação estrita de `if (dialogContext.mounted)` antes de qualquer mutação de estado ou navegação
- [x] 2.5 Executar `flutter test test/view_functions/settings_functions_test.dart` e garantir que todos os testes passem (estado Verde)

## 3. Refatoração, Documentação e Cobertura (Fase de Refatoração & PRINCIPIOS.md)

- [x] 3.1 Documentar todas as novas rotinas e parâmetros com docstrings em português (`///`) detalhando as razões arquiteturais (Princípio VII)
- [x] 3.2 Executar a suíte completa de testes de `settings_functions_test.dart` garantindo 100% de cobertura dos ramos adicionados/modificados (Princípio III)
- [x] 3.3 Executar análise estática com `flutter analyze` para certificar ausência de advertências ou violações de regras de lint
