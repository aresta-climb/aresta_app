## 1. Preparação

- [x] 1.1 Revisar e mapear a lógica atual da função `_buildCurrentNode` (em `main.dart`) e entender bem a filosofia principal do `TreeNavigationController`.
- [x] 1.2 Extrair a lógica de mapeamento Nó-Para-Página (Node-to-Page) para um componente ou função totalmente testável e isolada (desacoplada da raiz do `main.dart`).

## 2. Refatorando o `AppRouter` com TDD

- [x] 2.1 Escrever **testes unitários** (unit tests) voltados a atestar que o helper independente `buildPagesFromNode(NavNode currentNode)` vai corretamente atravessar a propriedade `currentNode.parent` e gerar a exata `List<NavNode>` encadeada, provendo chaves unívocas (`ValueKey`) imunes à instabilidade do Flutter.
- [x] 2.2 Implementar a tal função utilitária `buildPagesFromNode(NavNode)` satisfazendo, assim, os testes elaborados do item acima, exigindo **100% de cobertura (coverage)**.
- [x] 2.3 Escrever **testes de widget** focados no novo core do `AppRouter` de modo a validar matematicamente que ao se navegar num nó profundo, um widget `Navigator(pages: ...)` brota na raiz e não de forma alguma aquele velho e engessado `Scaffold` isolado.
- [x] 2.4 Fazer o hard-code implementando em definitivo esse modelo Declarativo `Navigator(pages: pages, onPopPage: ...)` na renderização da árvore real.

## 3. Retorno Sistêmico Impecável com TDD

- [x] 3.1 Desenvolver **testes de widget** que verifiquem a estrita interceptação do mecanismo natural de Pop. Seja emulação da AppBar ou BackButton de OS, seu acionamento DEVE acionar forçadamente o `treeController.goBack()`.
- [x] 3.2 Prover um método `onPopPage` perfeito para o Navigator acatar os testes escritos outrora. 

## 4. Auditoria Final de QA (Quality Assurance)

- [x] 4.1 Rodar a suite global com `flutter test --coverage` para conferir a métrica de 100% sobre as novas rotinas de navegação em árvore.
- [x] 4.2 **Manual:** Testar se ao entrar num Pico (ScrollView) e, em seguida, Setor, e dar 'Back', a exata posição do scroll no Pico foi magicamente mantida por conta da persistência de página do novo Navigator.
- [x] 4.3 **Manual:** Conferir que alternar entre as 3 abas raízes (Home, Settings, Browse) não gera repintura do zero. O estado segue preservado via `IndexedStack`.
