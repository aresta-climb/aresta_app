## Requirements

### Requirement: Android R8 e Redução de Recursos (Resource Shrinking)
O sistema de build do Android DEVE compilar o aplicativo em modo release com minificação de código (R8), otimização de bytecode e redução de recursos não utilizados (resource shrinking) habilitados.

#### Scenario: Compilação de Release do Android
- **WHEN** o Gradle compilar a variante de `release` do Android
- **THEN** `isMinifyEnabled` e `isShrinkResources` são aplicados com as regras do `proguard-android-optimize.txt` e `proguard-rules.pro`

### Requirement: Regras de Preservação do ProGuard
O arquivo de regras ProGuard DEVE preservar classes, métodos e campos essenciais acessados via reflexão ou serialização nativa por plugins críticos.

#### Scenario: Execução de Tarefas em Segundo Plano e Serialização
- **WHEN** o app executa tarefas com WorkManager ou desserializa payloads Protobuf em release
- **THEN** as classes de `androidx.work.*`, `com.google.protobuf.*`, `com.google.android.gms.maps.*` e `com.google.firebase.*` não são ofuscadas de maneira que quebre sua execução

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