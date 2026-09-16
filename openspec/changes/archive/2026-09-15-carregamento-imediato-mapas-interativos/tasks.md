## 1. Testes de Widget em Primeiro Lugar (TDD) para `MapaThumbnail`

- [x] 1.1 [TDD] Escrever teste de widget em `frontend/test/widgets/mapa_thumbnail_test.dart` verificando que a moldura com aspect ratio correto e o botão "Abrir Mapa Interativo" são renderizados imediatamente no primeiro frame mesmo enquanto a imagem de fundo ainda está pendente (`ConnectionState.waiting`).
- [x] 1.2 [TDD] Escrever teste de widget em `frontend/test/widgets/mapa_thumbnail_test.dart` verificando que tocar no botão durante o carregamento assíncrono da imagem navega com sucesso para `AppNav.toMapas` sem esperar o download terminar.
- [x] 1.3 [TDD] Escrever teste de widget verificando que a imagem de fundo é apresentada suavemente por trás do botão quando a resolução do provedor de imagem for concluída com sucesso.

## 2. Refatoração e Renderização Imediata em `MapaThumbnail`

- [x] 2.1 Refatorar `MapaThumbnail` em `frontend/lib/widgets/mapa_thumbnail.dart` para desacoplar a camada de imagem do `Stack` principal, tornando o container base, o overlay e o botão translúcido centralizados presentes desde o frame inicial.
- [x] 2.2 Executar `flutter test test/widgets/mapa_thumbnail_test.dart` e verificar que todos os testes de widget do componente passam com sucesso.

## 3. Testes de Widget em Primeiro Lugar (TDD) para `MapaInterativoPage`

- [x] 3.1 [TDD] Escrever teste de widget em `frontend/test/pages/mapa_interativo_test.dart` verificando que o `Scaffold`, a `AppBar` e o canvas com fundo escuro são montados imediatamente no primeiro frame enquanto a imagem em alta resolução ainda está carregando, exibindo indicador central sutil de progresso.
- [x] 3.2 [TDD] Escrever teste de widget verificando que marcadores e traçados vetoriais permanecem ocultos durante o carregamento e são revelados de forma coordenada juntamente com a imagem assim que ela estiver pronta.

## 4. Refatoração Estrutural e Revelação Atômica em `MapaInterativoPage`

- [x] 4.1 Refatorar `MapaInterativoPage` em `frontend/lib/pages/mapa_interativo.dart` para manter a casca estrutural (Scaffold e AppBar) montada a 0ms, restringindo o estado de espera ao canvas do `InteractiveViewer` e revelando a imagem com marcadores/traçados vetoriais de forma atômica.
- [x] 4.2 Executar `flutter test test/pages/mapa_interativo_test.dart test/pages/mapas_carrossel_test.dart` e verificar que todos os testes de tela cheia passam com sucesso.

## 5. Verificação Integrada e Regressão

- [x] 5.1 Executar a bateria de testes integrados de mapas (`flutter test test/widgets/mapa_thumbnail_test.dart test/pages/mapa_interativo_test.dart test/pages/mapas_carrossel_test.dart test/navigation/navigation_routing_test.dart`) e verificar 100% de aprovação e integridade visual.
