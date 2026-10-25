# Tasks

## 1. Desfoque Horizontal Puro e Notificação de Proporção em `_CragBackgroundWidget`

- [x] 1.1 [Red] Adicionar teste de widget em `frontend/test/widgets/card_pico_test.dart` verificando que `buildCragBackground` com `usarBordaInteligente: true` invoca o callback `aoResolverProporcao` com a proporção de aspecto decodificada da imagem e aplica desfoque horizontal puro (`sigmaX: 24.0, sigmaY: 0.0`) com `ClipRect`, executando o teste e confirmando a falha inicial.
- [x] 1.2 [Green/Refactor] Implementar o callback `aoResolverProporcao` e o `ImageFilter.blur(sigmaX: 24.0, sigmaY: 0.0, tileMode: TileMode.clamp)` envolto em `ClipRect` em `_CragBackgroundWidget` e `buildCragBackground` (`frontend/lib/widgets/card_pico.dart`), documentando com docstrings (`///`) e verificando que `flutter test test/widgets/card_pico_test.dart --coverage` passa com 100% de cobertura.

## 2. Altura Dinâmica da `SliverAppBar` na `PicoDetailsPage`

- [x] 2.1 [Red] Adicionar testes de widget em `frontend/test/pages/pico_test.dart` validando que: (a) para capa horizontal com altura natural menor que 300 dp, a `SliverAppBar` calcula `expandedHeight` igual à altura proporcional da tela sem sobras no topo e rodapé; (b) para capa vertical/quadrada com altura natural maior que 300 dp, `expandedHeight` limita-se ao teto de 300 dp com bordas inteligentes exclusivamente nas laterais; (c) o cálculo do fator de colapso `t` no `LayoutBuilder` acompanha a `alturaExpandida` dinâmica, executando os testes e confirmando a falha inicial.
- [x] 2.2 [Green/Refactor] Implementar o cálculo dinâmico de `alturaExpandida` e a resolução prévia de `_proporcaoCapa` em `_PicoDetailsPageState` (`frontend/lib/pages/pico.dart`), documentando com docstrings (`///`) e verificando que `flutter test test/pages/pico_test.dart test/widgets/card_pico_test.dart --coverage` passa com 100% de cobertura nas linhas e arquivos tocados.
