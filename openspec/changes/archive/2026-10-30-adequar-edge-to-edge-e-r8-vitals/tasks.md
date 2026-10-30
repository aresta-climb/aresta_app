# Tasks

## 1. Configuração de Redução de Recursos Otimizada do R8 (Android)

- [x] 1.1 Declarar explicitamente `android.r8.optimizedResourceShrinking=true` em `frontend/android/gradle.properties` (mantendo `isShrinkResources = true` em `frontend/android/app/build.gradle.kts`) e verificar que o arquivo `gradle.properties` contém a propriedade documentada em português.

## 2. Inicialização em Modo Ponta a Ponta (`SystemUiMode.edgeToEdge`)

- [x] 2.1 Escrever testes de comportamento em `frontend/test/services/inicializacao_app_test.dart` validando que `configurarExibicaoPontaAPonta()` envia ao canal de plataforma `flutter/platform` os comandos `SystemChrome.setEnabledSystemUIMode` (`SystemUiMode.edgeToEdge`) e `SystemChrome.setSystemUIOverlayStyle` com barras transparentes e sem contraste forçado, confirmando a falha inicial (*Red*).
- [x] 2.2 Implementar `configurarExibicaoPontaAPonta()` em `frontend/lib/services/inicializacao_app.dart`, re-exportá-la e invocá-la na inicialização em `frontend/lib/main.dart`, verificando que os testes em `frontend/test/services/inicializacao_app_test.dart` e `frontend/test/main_test.dart` passam com 100% de cobertura nas linhas adicionadas (*Green*).
- [x] 2.3 Atualizar a documentação em `frontend/lib/services/README.md` descrevendo a rotina `configurarExibicaoPontaAPonta()`.

## 3. Adequação de Recuos Inferiores (*Window Insets*) nas Telas de UI

- [x] 3.1 Escrever teste de widget em `frontend/test/pages/qr_scanner_test.dart` simulando um `MediaQuery` com recuo inferior (`padding: EdgeInsets.only(bottom: 48)`) e verificando que o `Positioned` da instrução inferior soma o `padding.bottom` aos `40` dp base (`bottom == 88`), confirmando a falha inicial (*Red*), e em seguida implementar o ajuste em `frontend/lib/pages/qr_scanner.dart` até o teste passar (*Green*).
- [x] 3.2 Escrever teste de widget em `frontend/test/pages/configuracoes_test.dart` simulando um `MediaQuery` com recuo inferior (`padding: EdgeInsets.only(bottom: 48)`) e verificando que o `ListView` aplica preenchimento inferior de `64` dp (`16 + 48`), confirmando a falha inicial (*Red*), e em seguida implementar o ajuste em `frontend/lib/pages/configuracoes.dart` até o teste passar (*Green*).
- [x] 3.3 Escrever teste de widget em `frontend/test/pages/mapa_global_test.dart` simulando um `MediaQuery` com recuo inferior (`padding: EdgeInsets.only(bottom: 34)`) e verificando que o widget `GoogleMap` recebe `padding: EdgeInsets.only(bottom: 34)`, confirmando a falha inicial (*Red*), e em seguida implementar o ajuste em `frontend/lib/pages/mapa_global.dart` até o teste passar (*Green*).
- [x] 3.4 Atualizar `frontend/lib/pages/README.md` documentando o tratamento de recuos inferiores (*edge-to-edge*) nas páginas afetadas e validar 100% de cobertura nos arquivos alterados com `flutter test --coverage`.
