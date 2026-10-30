# otimizacao-compilacao-build Specification

## Purpose

Define os requisitos de otimização de compilação em release para Android e iOS, cobrindo minificação R8, ofuscação Dart, geração de símbolos de depuração e redução de recursos.

## Requirements

### Requirement: Android R8 e Redução de Recursos (Resource Shrinking)
O sistema de build do Android DEVE (MUST) compilar o aplicativo em modo release com minificação de código (R8), encolhimento de recursos (`isShrinkResources`), otimização de bytecode em R8 Full Mode, reempacotamento de classes (`-repackageclasses`) e permissão de modificação de acesso (`-allowaccessmodification`) habilitados.

#### Scenario: Compilação de Release do Android
- **WHEN** o Gradle compilar a variante de `release` do Android
- **THEN** `isMinifyEnabled = true` e `isShrinkResources = true` são aplicados com as regras do `proguard-android-optimize.txt`, `proguard-rules.pro` com `-repackageclasses 'app.escalada.croquis.r8'` e `-allowaccessmodification`, e `android.enableR8.fullMode=true` no `gradle.properties`

### Requirement: Regras de Preservação do ProGuard
O arquivo de regras ProGuard DEVE preservar atributos essenciais para stacktraces e membros críticos sem utilizar regras genéricas de preservação total em bibliotecas que possuem suas próprias Consumer ProGuard Rules, preservando asserções defensivas de runtime e delegando a poda de corrotinas do Kotlin ao consumidor nativo.

#### Scenario: Execução de Tarefas em Segundo Plano e Serialização
- **WHEN** o app compilar em modo release com R8
- **THEN** o `proguard-rules.pro` preserva atributos de anotação e depuração (`*Annotation*`, `Signature`, `InnerClasses`, `EnclosingMethod`, `SourceFile`, `LineNumberTable`), delega a otimização de Firebase, Google Play Services, AndroidX WorkManager, MLKit e Kotlin Coroutines às suas respectivas Consumer Rules, suprime warnings não críticos com `-dontwarn`, e mantém todas as asserções e verificações de parâmetros do Kotlin sem supressão por `-assumenosideeffects`

### Requirement: Ofuscação do Código Dart e Geração de Símbolos
O build de produção para Android e iOS DEVE compilar o código Dart com ofuscação habilitada e extração de tabelas de símbolos de depuração para diretório externo.

#### Scenario: Build de Release via CI/CD
- **WHEN** a GitHub Action executa `flutter build appbundle` ou `flutter build ipa`
- **THEN** as flags `--obfuscate` e `--split-debug-info=<diretório>` são fornecidas e os arquivos `.symbols` são gerados

### Requirement: Upload de Símbolos e Mapping para Desofuscação
O pipeline de CI/CD DEVE fazer o upload do arquivo `mapping.txt` do R8, dos arquivos `.symbols` de Dart e dos `dSYMs` da Apple para o Google Play Console e Firebase Crashlytics.

#### Scenario: Deploy automatizado no GitHub Actions
- **WHEN** a release é construída no GitHub Actions
- **THEN** o `mapping.txt` é enviado ao Google Play Console no step de upload do bundle, e os símbolos Dart e dSYMs nativos são enviados ao Firebase Crashlytics

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
