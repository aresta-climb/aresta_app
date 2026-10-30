# Spec Delta

## ADDED Requirements

### Requirement: Gerenciamento Nativo de Dependências iOS via Swift Package Manager
O projeto iOS DEVE (MUST) resolver todas as dependências nativas de plugins exclusivamente via Swift Package Manager (SPM), mantendo compatibilidade mínima com iOS 15.0+ sem acionar fallback para CocoaPods ou migrações de projeto Xcode em tempo de build.

#### Scenario: Resolução de plugins iOS sem aviso de descontinuação de SPM
- **WHEN** o comando `flutter pub get` ou `flutter build ipa` for executado para a plataforma iOS
- **THEN** todos os plugins federados de iOS (incluindo a implementação de mapas compatível com iOS 15.0+) fornecem manifesto `Package.swift` válido e nenhum aviso de ausência de suporte ao Swift Package Manager é emitido

#### Scenario: Projeto Xcode pré-integrado com Swift Package Manager no controle de versão
- **WHEN** o comando `flutter build ipa` iniciar a compilação em ambiente macOS limpo
- **THEN** o projeto Xcode (`project.pbxproj` e `Runner.xcscheme`) já contém as referências ao pacote gerado `FlutterGeneratedPluginSwiftPackage` e à ação de preparação do framework, pulando a etapa de migração automática em tempo de execução

### Requirement: Cache de Pacotes Swift Package Manager no Pipeline de CI/CD
O workflow de compilação iOS no GitHub Actions DEVE (MUST) armazenar e restaurar o cache de pacotes do Swift Package Manager utilizando `actions/cache@v6` indexado pelo arquivo de trava de dependências do Flutter (`frontend/pubspec.lock`).

#### Scenario: Restauração de cache SPM no build de release iOS
- **WHEN** o workflow `.github/workflows/build_ios.yml` for executado no GitHub Actions
- **THEN** os diretórios de cache do Swift Package Manager no macOS são restaurados e salvos via `actions/cache@v6` utilizando uma chave derivada do hash de `frontend/pubspec.lock`, sem referenciar diretórios `Pods` ou `Podfile.lock`
