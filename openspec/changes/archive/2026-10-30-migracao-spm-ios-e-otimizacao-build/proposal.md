# Proposal

## Why

O Flutter migrou o gerenciamento de dependências nativas no iOS para o **Swift Package Manager (SPM)**, mas o pacote padrão `google_maps_flutter_ios` é legado e não suporta SPM, emitindo um aviso de descontinuação (`The following plugins do not support Swift Package Manager for ios: google_maps_flutter_ios`) que se tornará um erro fatal em versões futuras do Flutter e forçando o build de CI a executar o CocoaPods em paralelo ao SPM. Além disso, os arquivos `project.pbxproj`, `Runner.xcscheme` e `.gitignore` no repositório ainda não possuem a integração determinística do SPM persistida, fazendo com que toda execução do GitHub Actions gaste cerca de 3 minutos (`173.1s`) reexecutando a migração do projeto Xcode do zero e tentando utilizar um cache obsoleto de CocoaPods (`Podfile.lock`) com `actions/cache@v5`.

## What Changes

- **Substituição da implementação iOS do Google Maps pelo pacote compatível com SPM (`google_maps_flutter_ios_sdk9`)**: Declarar explicitamente `google_maps_flutter_ios_sdk9: ^2.19.0` no `frontend/pubspec.yaml` (mantendo `google_maps_flutter: ^2.19.0`), preservando 100% de compatibilidade com o target mínimo atual **iOS 15.0+** (incluindo dispositivos como iPhone 7 Plus) e eliminando o pacote legado `google_maps_flutter_ios` e a necessidade do CocoaPods.
- **Persistência da integração do Swift Package Manager no projeto Xcode (`Runner.xcodeproj`)**: Atualizar `frontend/ios/Runner.xcodeproj/project.pbxproj`, `frontend/ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme` e `frontend/.gitignore` com as referências determinísticas ao `FlutterGeneratedPluginSwiftPackage` e a *PreAction* `"Run Prepare Flutter Framework Script"`, eliminando o passo de migração em tempo de execução (`Adding Swift Package Manager integration...`) durante os builds no CI.
- **Modernização do cache de dependências iOS no GitHub Actions (`build_ios.yml`)**: Substituir o passo obsoleto `Cache CocoaPods` (que referenciava `actions/cache@v5` e `Podfile.lock`) pelo cache nativo do Swift Package Manager utilizando `actions/cache@v6`, indexado pelo hash de `frontend/pubspec.lock`.

## Capabilities

### New Capabilities

### Modified Capabilities
- `otimizacao-compilacao-build`: Adição de requisito de integração 100% nativa com Swift Package Manager (SPM) no iOS (sem fallback para CocoaPods), persistência das referências do pacote gerado no projeto Xcode e cache de pacotes SPM via `actions/cache@v6` no pipeline de CI/CD.

## Impact

- **`frontend/pubspec.yaml` e `frontend/pubspec.lock`**: Adição da dependência direta `google_maps_flutter_ios_sdk9: ^2.19.0` como implementação federada de iOS para `google_maps_flutter`, substituindo `google_maps_flutter_ios`.
- **`frontend/ios/Runner.xcodeproj/project.pbxproj` e `Runner.xcscheme`**: Inclusão das seções `XCLocalSwiftPackageReference`, `XCSwiftPackageProductDependency`, `PBXBuildFile` e `PreActions` exigidas pelo Flutter 3.47+ para projetos com Swift Package Manager.
- **`frontend/.gitignore`**: Inclusão dos diretórios `.build/` e `.swiftpm/`.
- **`.github/workflows/build_ios.yml`**: Atualização do passo de cache para `actions/cache@v6` apontando para os diretórios de cache do Swift Package Manager no macOS.
