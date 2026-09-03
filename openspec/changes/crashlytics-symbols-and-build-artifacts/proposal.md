# Proposta: Upload de Símbolos no Crashlytics e Retenção de Artefatos de Build

## Why

O Firebase Crashlytics passou a reportar erros com "missing dSYM" para a versão de iOS (ex: 0.1.3), tornando os relatórios de crash ilegíveis e sem número de linha/função. Como a Apple removeu o Bitcode no Xcode moderno, o App Store Connect não gera nem armazena mais dSYMs para download. Os símbolos de depuração (dSYMs do iOS, mapeamentos R8 do Android e tabelas de símbolos Dart de ambas as plataformas) existem apenas no ambiente temporário do GitHub Actions e são descartados assim que a execução do runner termina.

Esta mudança resolve o problema de maneira definitiva:
1. Automatiza o upload de todos os símbolos de depuração (dSYMs nativos e símbolos Dart) diretamente para o Firebase Crashlytics durante o pipeline de release.
2. Faz o backup integral dos artefatos de cada build (binários `.ipa`/`.aab`, dSYMs, símbolos Dart e mapeamentos ProGuard/R8) como artefatos protegidos na aba Actions do GitHub.

## What Changes

- **Upload de dSYMs e Símbolos Dart no iOS (`build_ios.yml`)**:
  - Geração de tabelas de símbolos Dart com `--split-debug-info=build/symbols`.
  - Autenticação via Google Service Account (`FIREBASE_SERVICE_ACCOUNT_JSON`).
  - Upload automático dos dSYMs do Xcode (`build/ios/archive/Runner.xcarchive/dSYMs`) e dos símbolos Dart (`build/symbols`) para o Crashlytics via Firebase CLI.
- **Retenção de Artefatos de Build do iOS (`build_ios.yml`)**:
  - Upload de artefatos da release no GitHub Actions contendo o arquivo `.ipa`, a pasta `dSYMs` e os símbolos Dart.
- **Upload e Retenção de Artefatos de Build do Android (`build_android.yml`)**:
  - Geração de tabelas de símbolos Dart com `--split-debug-info=build/symbols`.
  - Upload automático dos símbolos Dart para o Crashlytics.
  - Upload de artefatos da release no GitHub Actions contendo o bundle `.aab`, a pasta `build/symbols` e o mapeamento ProGuard/R8 (`build/app/outputs/mapping/release/`).
- **Repasse de Segredos**: Repasse do secret `FIREBASE_SERVICE_ACCOUNT_JSON` nos workflows orquestradores (`release_new_app_version.yml`).

## Capabilities

### New Capabilities
- `pipeline-simbolos-e-artefatos-release`: Automação do ciclo de envio de símbolos de depuração ao Firebase Crashlytics e retenção versionada dos artefatos de compilação em CI/CD.

### Modified Capabilities
<!-- Nenhuma especificação de comportamento de usuário em tempo de execução foi modificada. -->

## Impact

- **CI/CD (`.github/workflows/`)**: Alterações em `build_ios.yml`, `build_android.yml` e `release_new_app_version.yml`.
- **Segurança e Secrets**: Requer a configuração da secret `FIREBASE_SERVICE_ACCOUNT_JSON` no repositório GitHub.
- **Operação e Monitoramento**: Elimina relatórios *unsymbolicated* no painel do Firebase Crashlytics para todas as versões futuras lançadas.
