## ADDED Requirements

### Requirement: Empacotamento e Upload de Símbolos Nativos para o Google Play Console
O pipeline de CI/CD DEVE empacotar os símbolos de depuração nativos do Android em um arquivo compactado e enviá-los para o Google Play Console durante o deploy.

#### Scenario: Empacotamento e Upload Automático no Workflow Android
- **WHEN** o build do App Bundle (.aab) for concluído com sucesso no workflow `build_android.yml`
- **THEN** as bibliotecas nativas intermediárias do Gradle são compactadas em `frontend/build/native-debug-symbols/native-debug-symbols.zip` e enviadas ao Google Play Console via parâmetro `debugSymbols` da ação `r0adkll/upload-google-play`

## MODIFIED Requirements

### Requirement: Retenção e Arquivamento de Artefatos de Build no GitHub Actions
O pipeline de CI/CD DEVE salvar os artefatos de compilação completos de cada release (binários instaláveis, pacotes de símbolos e mapeamentos) como GitHub Actions Artifacts vinculados à execução da tag.

#### Scenario: Arquivamento de Artefatos do iOS
- **WHEN** o workflow `build_ios.yml` compilar uma release
- **THEN** um artefato nomeado `ios-release-<tag_name>` é publicado contendo o arquivo `.ipa`, a pasta `dSYMs` do `.xcarchive` e os arquivos `.symbols` do Dart com retenção de 90 dias

#### Scenario: Arquivamento de Artefatos do Android
- **WHEN** o workflow `build_android.yml` compilar uma release
- **THEN** um artefato nomeado `android-release-<tag_name>` é publicado contendo o arquivo `.aab`, o arquivo compactado `native-debug-symbols.zip`, os mapeamentos ProGuard/R8 em `frontend/build/app/outputs/mapping/release/` e os arquivos `.symbols` do Dart com retenção de 90 dias
