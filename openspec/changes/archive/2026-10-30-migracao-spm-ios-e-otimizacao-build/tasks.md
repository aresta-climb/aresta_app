# Tasks

## 1. Migração da Implementação iOS do Google Maps para SPM (`sdk9`)

- [x] 1.1 Atualizar `frontend/pubspec.yaml` declarando `google_maps_flutter: ^2.19.0` e `google_maps_flutter_ios_sdk9: ^2.19.0`, executar `flutter pub get` e verificar em `frontend/pubspec.lock` e `frontend/.flutter-plugins-dependencies` que `google_maps_flutter_ios_sdk9` substituiu `google_maps_flutter_ios` como implementação iOS mantendo compatibilidade com iOS 15.0+

## 2. Persistência da Integração Swift Package Manager no Projeto Xcode

- [x] 2.1 Atualizar `frontend/.gitignore` adicionando `.build/` e `.swiftpm/` conforme exigido por `SwiftPackageManagerGitignoreMigration` e verificar que as entradas constam no arquivo
- [x] 2.2 Atualizar `frontend/ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme` adicionando o bloco `<PreActions>` com `"Run Prepare Flutter Framework Script"` (`xcode_backend.sh prepare`) e verificar que o XML permanece bem-formado
- [x] 2.3 Atualizar `frontend/ios/Runner.xcodeproj/project.pbxproj` adicionando as referências determinísticas ao `FlutterGeneratedPluginSwiftPackage` (`PBXBuildFile`, `PBXFileReference`, `PBXFrameworksBuildPhase`, `PBXGroup`, `PBXNativeTarget`, `PBXProject`, `XCLocalSwiftPackageReference` e `XCSwiftPackageProductDependency`) e verificar que todos os identificadores exigidos por `SwiftPackageManagerIntegrationMigration` estão presentes

## 3. Otimização do Cache de CI/CD no GitHub Actions e Validação

- [x] 3.1 Atualizar `.github/workflows/build_ios.yml` substituindo o passo `Cache CocoaPods` (`actions/cache@v5`) pelo passo `Cache Swift Package Manager` com `actions/cache@v6`, armazenando `~/Library/Caches/org.swift.swiftpm` e `~/Library/org.swift.swiftpm` com chave baseada em `hashFiles('frontend/pubspec.lock')`
- [x] 3.2 Executar `flutter analyze` e a suíte de testes de mapas em `frontend/` para verificar que não há regressões de análise estática ou de testes após a substituição da implementação federada de iOS
