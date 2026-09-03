## 1. Gestão de Memória e Decodificação de Imagens no Flutter (TDD)

- [x] 1.1 [TDD] Criar testes unitários para configuração de teto de memória LRU (100 MB) e tratamento de ciclo de vida no `main.dart` (Fase Vermelha)
- [x] 1.2 Implementar configuração do `imageCache.maximumSizeBytes` (100 MB) e listener de ciclo de vida no `main.dart` com docstrings `///` em português (Fase Verde e Refatoração)
- [x] 1.3 [TDD] Criar testes unitários em `provedor_imagem_aresta_test.dart` para os parâmetros de downsampling `larguraAlvo` e `alturaAlvo` (Fase Vermelha)
- [x] 1.4 Implementar `ResizeImage.resizeIfNeeded` em `ProvedorImagemAresta.resolver` com docstrings `///` em português (Fase Verde e Refatoração)
- [x] 1.5 [TDD] Criar testes de widget para decodificação de miniaturas com `cacheWidth` em `browse_functions.dart` (`_CragBackgroundWidget`) (Fase Vermelha)
- [x] 1.6 Implementar `cacheWidth: 300` para carregamento local e remoto em `_CragBackgroundWidget` com docstrings `///` em português (Fase Verde e Refatoração)
- [x] 1.7 [TDD] Criar testes de widget para downsampling em `mapa_thumbnail.dart` passando `larguraAlvo` para o provedor (Fase Vermelha)
- [x] 1.8 Implementar passagem de `larguraAlvo` em `mapa_thumbnail.dart` com docstrings `///` em português (Fase Verde e Refatoração)

## 2. Otimização de Compilação Android (R8 & ProGuard)

- [x] 2.1 Criar `frontend/android/app/proguard-rules.pro` com regras de preservação para `WorkManager`, `Protobuf`, `Google Maps`, `Firebase` e `Flutter`
- [x] 2.2 Atualizar `frontend/android/app/build.gradle.kts` habilitando `isMinifyEnabled = true`, `isShrinkResources = true`, `proguard-android-optimize.txt` e `proguard-rules.pro`
- [x] 2.3 Adicionar o plugin Gradle do Firebase Crashlytics (`com.google.firebase.crashlytics`) para upload automático do `mapping.txt`

## 3. Otimizações do Projeto iOS (Xcode & Clang)

- [x] 3.1 Adicionar configurações de `LLVM_LTO = YES_THIN` e `DEAD_CODE_STRIPPING = YES` no `frontend/ios/Flutter/Release.xcconfig`

## 4. CI/CD e Upload de Símbolos no GitHub Actions

- [x] 4.1 Atualizar `.github/workflows/build_android.yml` com `--obfuscate --split-debug-info`, upload de `mappingFile` para Google Play e upload de símbolos para o Firebase Crashlytics
- [x] 4.2 Atualizar `.github/workflows/build_ios.yml` com `--obfuscate --split-debug-info`, upload de `dSYMs` e upload de símbolos para o Firebase Crashlytics

## 5. Documentação Contínua (PRINCIPIOS.md)

- [x] 5.1 Atualizar `frontend/README.md`, `frontend/lib/README.md` e `frontend/lib/services/README.md` documentando a arquitetura de gestão de memória, downsampling centralizado no `ProvedorImagemAresta` e pipeline de compilação release
- [x] 5.2 Validar que todas as classes, métodos e widgets novos ou alterados contenham docstrings `///` explicativas em português brasileiro

## 6. Verificação, Cobertura de Testes e Validação de Build

- [x] 6.1 Executar a suíte de testes automatizados com medição de cobertura (`flutter test --coverage`) e assegurar 100% de cobertura nos componentes alterados
- [x] 6.2 Executar compilação local de release do Android para validar execução do R8 sem quebras