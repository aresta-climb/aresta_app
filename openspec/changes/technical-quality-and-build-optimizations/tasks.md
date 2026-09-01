## 1. Gestão de Memória e Decodificação de Imagens no Flutter (TDD)

- [ ] 1.1 [TDD] Criar testes unitários e de widget para configuração de teto de memória e tratamento de ciclo de vida no `main.dart` (Fase Vermelha)
- [ ] 1.2 Implementar configuração do `imageCache.maximumSizeBytes` (100 MB) e listener de ciclo de vida no `main.dart` com docstrings `///` em português (Fase Verde e Refatoração)
- [ ] 1.3 [TDD] Criar testes de widget para decodificação de miniaturas com `cacheWidth` em `browse_functions.dart` (Fase Vermelha)
- [ ] 1.4 Implementar downsampling (`cacheWidth` / `ResizeImage`) em `browse_functions.dart` com docstrings `///` em português (Fase Verde e Refatoração)
- [ ] 1.5 [TDD] Criar testes de widget para downsampling em `mapa_thumbnail.dart` (Fase Vermelha)
- [ ] 1.6 Implementar downsampling em `mapa_thumbnail.dart` e `resolveImagePathProvider` com docstrings `///` em português (Fase Verde e Refatoração)
- [ ] 1.7 [TDD] Criar testes de widget para capas em `grupo.dart` e `setor.dart` (Fase Vermelha)
- [ ] 1.8 Implementar downsampling nas capas de `grupo.dart` e `setor.dart` com docstrings `///` em português (Fase Verde e Refatoração)

## 2. Otimização de Compilação Android (R8 & ProGuard)

- [ ] 2.1 Criar `frontend/android/app/proguard-rules.pro` com regras de preservação para `WorkManager`, `Protobuf`, `Google Maps`, `Firebase` e `Flutter`
- [ ] 2.2 Atualizar `frontend/android/app/build.gradle.kts` habilitando `isMinifyEnabled = true`, `isShrinkResources = true`, `proguard-android-optimize.txt` e `proguard-rules.pro`
- [ ] 2.3 Adicionar o plugin Gradle do Firebase Crashlytics (`com.google.firebase.crashlytics`) para upload automático do `mapping.txt`

## 3. Otimizações do Projeto iOS (Xcode & Clang)

- [ ] 3.1 Adicionar configurações de `LLVM_LTO = YES_THIN` e `DEAD_CODE_STRIPPING = YES` no `frontend/ios/Flutter/Release.xcconfig`

## 4. CI/CD e Upload de Símbolos no GitHub Actions

- [ ] 4.1 Atualizar `.github/workflows/build_android.yml` com `--obfuscate --split-debug-info`, upload de `mappingFile` para Google Play e upload de símbolos para o Firebase Crashlytics
- [ ] 4.2 Atualizar `.github/workflows/build_ios.yml` com `--obfuscate --split-debug-info`, upload de `dSYMs` e upload de símbolos para o Firebase Crashlytics

## 5. Documentação Contínua (PRINCIPIOS.md)

- [ ] 5.1 Atualizar `frontend/README.md` e `frontend/lib/README.md` documentando a arquitetura de gestão de memória, teto de cache LRU e pipeline de compilação release
- [ ] 5.2 Validar que todas as classes, métodos e widgets novos ou alterados contenham docstrings `///` explicativas em português brasileiro

## 6. Verificação, Cobertura de Testes e Validação de Build

- [ ] 6.1 Executar a suíte de testes automatizados com medição de cobertura (`flutter test --coverage`) e assegurar 100% de cobertura nos componentes alterados
- [ ] 6.2 Executar compilação local de release do Android para validar execução do R8 sem quebras