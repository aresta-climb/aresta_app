# Design

## Context

Conforme detalhado em `proposal.md`, o projeto já opera com o recurso `enable-swift-package-manager` ativo no Flutter 3.47+, porém sofre dois gargalos no build de iOS:
1. O pacote padrão `google_maps_flutter_ios` depende de seleção dinâmica no `.podspec` do CocoaPods e não possui `Package.swift`.
2. Como o desenvolvimento principal ocorre no Windows e o build de iOS roda em máquinas efêmeras `macos-latest` no GitHub Actions, as modificações que o `SwiftPackageManagerIntegrationMigration` do Flutter realiza em `project.pbxproj`, `Runner.xcscheme` e `.gitignore` nunca foram commitadas no repositório, custando ~173 segundos por build para migrar e validar o projeto Xcode do zero, além de manter um passo de cache obsoleto para CocoaPods (`actions/cache@v5`).

## Goals / Non-Goals

**Goals:**
- Eliminar 100% da dependência do CocoaPods no build de iOS substituindo `google_maps_flutter_ios` por `google_maps_flutter_ios_sdk9` (que suporta SPM e mantém o deployment target em **iOS 15.0+**, atendendo usuários em aparelhos como iPhone 7 Plus).
- Persistir no Git as alterações exatas esperadas pelo `SwiftPackageManagerIntegrationMigration` do Flutter em `project.pbxproj`, `Runner.xcscheme` e `.gitignore` para zerar o tempo de migração em runtime no CI.
- Atualizar o `.github/workflows/build_ios.yml` para `actions/cache@v6`, cacheando os diretórios do Swift Package Manager com base no `frontend/pubspec.lock`.

**Non-Goals:**
- Elevar o `IPHONEOS_DEPLOYMENT_TARGET` para iOS 16.0 (`google_maps_flutter_ios_sdk10`), pois há usuários ativos no iOS 15 (iPhone 7 Plus).
- Alterar código Dart da camada de apresentação ou regras de negócios de mapas.

## Decisions

### 1. Adoção de `google_maps_flutter_ios_sdk9` em vez de `sdk10`
- **Decisão**: Declarar `google_maps_flutter_ios_sdk9: ^2.19.0` ao lado de `google_maps_flutter: ^2.19.0` no `frontend/pubspec.yaml`.
- **Racional**: O mecanismo de *federated plugins* do Flutter substitui a implementação padrão (`google_maps_flutter_ios`) quando uma implementação não-padrão endossada é declarada no `pubspec.yaml`. A variante `sdk9` empacota o Google Maps iOS SDK 9.x via SwiftPM e exige iOS 15.0+, mantendo exatamente o mesmo SDK nativo que já rodava via CocoaPods e preservando suporte ao iPhone 7 Plus / 6s / SE (1ª ger.).
- **Alternativas consideradas**:
  - `google_maps_flutter_ios_sdk10`: Descartado por exigir `IPHONEOS_DEPLOYMENT_TARGET = 16.0`, o que deixaria usuários ativos de iPhone 7 Plus sem atualizações na App Store sem ganho funcional.
  - Desativar o SPM (`enable-swift-package-manager: false`): Descartado pois o Flutter tornará o suporte a SPM obrigatório em versões futuras.

### 2. Injeção Determinística da Integração SPM no `project.pbxproj` e `Runner.xcscheme`
- **Decisão**: Aplicar diretamente nos arquivos versionados os identificadores e blocos verificados por `SwiftPackageManagerIntegrationMigration` no `flutter_tools`:
  - `Runner.xcscheme`: Adicionar bloco `<PreActions>` com a ação `"Run Prepare Flutter Framework Script"` invocando `/bin/sh "$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh" prepare`.
  - `project.pbxproj`:
    - `PBXBuildFile`: `78A318202AECB46A00862997 /* FlutterGeneratedPluginSwiftPackage in Frameworks */`
    - `PBXFileReference`: `78E0A7A72DC9AD7400C4905E /* FlutterGeneratedPluginSwiftPackage */` apontando para `Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage`
    - `PBXFrameworksBuildPhase` (`97C146EB1CF9000F007C117D`): Incluir `78A318202AECB46A00862997` em `files`
    - `PBXGroup` (`9740EEB11CF90186004384FC /* Flutter */`): Incluir `78E0A7A72DC9AD7400C4905E` em `children`
    - `PBXNativeTarget` (`97C146ED1CF9000F007C117D /* Runner */`): Adicionar `packageProductDependencies` com `78A3181F2AECB46A00862997`
    - `PBXProject` (`97C146E61CF9000F007C117D`): Adicionar `packageReferences` com `781AD8BC2B33823900A9FFBB`
    - Seções `XCLocalSwiftPackageReference` (`781AD8BC2B33823900A9FFBB`) e `XCSwiftPackageProductDependency` (`78A3181F2AECB46A00862997`).
  - `frontend/.gitignore`: Adicionar `.build/` e `.swiftpm/`.
- **Racional**: O Flutter verifica exatamente esses UUIDs constantes (`isSchemeMigrated && isPbxprojMigrated && isOptionalFilesMigrated`). Quando presentes no Git, o `migrate()` retorna imediatamente sem invocar `xcodebuild -list`, economizando ~173 segundos no CI.

### 3. Cache do Swift Package Manager com `actions/cache@v6` no GitHub Actions
- **Decisão**: Substituir o passo `Cache CocoaPods` em `.github/workflows/build_ios.yml` por `Cache Swift Package Manager` usando `actions/cache@v6`, armazenando `~/Library/Caches/org.swift.swiftpm` e `~/Library/org.swift.swiftpm` com chave `${{ runner.os }}-spm-${{ hashFiles('frontend/pubspec.lock') }}`.
- **Racional**: Com 100% dos plugins no SPM, o diretório `frontend/ios/Pods` deixa de existir. Cachear os diretórios globais do SwiftPM com `actions/cache@v6` evita o re-download de artefatos binários pesados (`XCFrameworks` do Firebase, Google Maps e Sentry) a cada release.

## Risks / Trade-offs

- **[Risco] Erro de sintaxe no `project.pbxproj` ao editar fora do macOS** → **Mitigação**: Seguir linha a linha o formato exato e os UUIDs constantes definidos em `SwiftPackageManagerIntegrationMigration` do SDK Flutter 3.47 instalado localmente e validar a estrutura de todas as seções modificadas.
- **[Risco] Utilitário `upload-symbols` do Crashlytics mudar de caminho sem CocoaPods** → **Mitigação**: O script em `.github/workflows/build_ios.yml` (linhas 170-178) já busca em `~/Library/Developer/Xcode/DerivedData` (onde o SPM extrai os pacotes) e possui fallback automático via `curl` para o binário oficial do repositório `firebase-ios-sdk`.
