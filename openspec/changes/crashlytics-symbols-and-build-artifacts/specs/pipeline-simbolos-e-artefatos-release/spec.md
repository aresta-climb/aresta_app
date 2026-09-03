## ADDED Requirements

### Requirement: Geração e Extração de Símbolos Dart de Release
O pipeline de CI/CD DEVE compilar o código Flutter em modo release gerando tabelas de símbolos Dart de depuração em um diretório externo segregado.

#### Scenario: Compilação de Release do Flutter
- **WHEN** os workflows `build_ios.yml` ou `build_android.yml` executarem `flutter build` em modo release
- **THEN** o comando inclui a flag `--split-debug-info=build/symbols` e gera os arquivos `.symbols` correspondentes às arquiteturas alvo

### Requirement: Upload Automático de Símbolos para o Firebase Crashlytics no iOS
O workflow de release do iOS DEVE fazer o upload dos arquivos dSYM gerados pelo Xcode e dos arquivos de símbolos Dart para o Firebase Crashlytics via Firebase CLI.

#### Scenario: Envio de dSYMs e Símbolos Dart no iOS
- **WHEN** o build do arquivo IPA for concluído com sucesso no workflow `build_ios.yml`
- **THEN** o GitHub Actions utiliza as credenciais da Service Account (`FIREBASE_SERVICE_ACCOUNT_JSON`) para autenticar e executar o upload da pasta `frontend/build/ios/archive/Runner.xcarchive/dSYMs` e da pasta `frontend/build/symbols` para o App ID do iOS (`1:737982062809:ios:0402933638e489bcd5dec8`)

### Requirement: Upload Automático de Símbolos para o Firebase Crashlytics no Android
O workflow de release do Android DEVE fazer o upload dos símbolos Dart para o Firebase Crashlytics via Firebase CLI.

#### Scenario: Envio de Símbolos Dart no Android
- **WHEN** o build do App Bundle (.aab) for concluído com sucesso no workflow `build_android.yml`
- **THEN** o GitHub Actions utiliza as credenciais da Service Account (`FIREBASE_SERVICE_ACCOUNT_JSON`) para autenticar e executar o upload da pasta `frontend/build/symbols` para o App ID do Android (`1:737982062809:android:e168a4e15cd353e1d5dec8`)

### Requirement: Retenção e Arquivamento de Artefatos de Build no GitHub Actions
O pipeline de CI/CD DEVE salvar os artefatos de compilação completos de cada release (binários instaláveis, pacotes de símbolos e mapeamentos) como GitHub Actions Artifacts vinculados à execução da tag.

#### Scenario: Arquivamento de Artefatos do iOS
- **WHEN** o workflow `build_ios.yml` compilar uma release
- **THEN** um artefato nomeado `ios-release-<tag_name>` é publicado contendo o arquivo `.ipa`, a pasta `dSYMs` do `.xcarchive` e os arquivos `.symbols` do Dart com retenção de 90 dias

#### Scenario: Arquivamento de Artefatos do Android
- **WHEN** o workflow `build_android.yml` compilar uma release
- **THEN** um artefato nomeado `android-release-<tag_name>` é publicado contendo o arquivo `.aab`, os mapeamentos ProGuard/R8 em `frontend/build/app/outputs/mapping/release/` e os arquivos `.symbols` do Dart com retenção de 90 dias
