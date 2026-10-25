# Tasks

## 1. Simplificação de `buildCragBackground` em Camada Única (`BoxFit.cover`)

- [x] 1.1 [Red] Atualizar os testes de widget em `frontend/test/widgets/card_pico_test.dart` para verificar que `buildCragBackground` renderiza sempre uma única `Image` com `BoxFit.cover` (sem `ImageFiltered` nem `usarBordaInteligente`) e continua invocando `aoResolverProporcao` com a razão `largura / altura`, executando `flutter test test/widgets/card_pico_test.dart` e confirmando a falha inicial.
- [x] 1.2 [Green/Refactor] Remover `usarBordaInteligente` e o `ImageFiltered` de `buildCragBackground` em `frontend/lib/widgets/card_pico.dart`, mantendo camada única com `BoxFit.cover`, callback `aoResolverProporcao` e docstrings `///` atualizadas, verificando `flutter test test/widgets/card_pico_test.dart --coverage`.

## 2. Janela de Altura Dinâmica `[220.0, 300.0]` dp e Renderização sem Bordas em `PicoDetailsPage`

- [x] 2.1 [Red] Atualizar os testes de widget em `frontend/test/pages/pico_test.dart` para validar a janela de altura visual `[math.max(220.0, collapsedHeight), 300.0]` dp (incluindo o piso de `220.0 dp` para imagens muito largas/panorâmicas, altura exata entre `220.0` e `300.0 dp` para paisagem padrão e teto de `300.0 dp` para imagens verticais, descontando `topPadding` no `expandedHeight` e renderizando com `BoxFit.cover` sem `ImageFiltered`), executando `flutter test test/pages/pico_test.dart` e confirmando a falha inicial.
- [x] 2.2 [Green/Refactor] Atualizar `_calcularAlturaExpandida` em `frontend/lib/pages/pico.dart` para impor `minExpandedHeight = math.max(220.0, collapsedHeight)` e remover `usarBordaInteligente: true` na chamada de `buildCragBackground`, verificando aprovação e 100% de cobertura com `flutter test test/pages/pico_test.dart test/widgets/card_pico_test.dart --coverage`.
