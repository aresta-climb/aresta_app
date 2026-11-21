# Proposal

## Why

O pipeline de lançamento do Aresta App (`release_new_app_version.yml`) hoje executa testes apenas na Dart VM de Linux e envia os binários `.aab` e `.ipa` compilados com R8, `--obfuscate` e plugins nativos diretamente às lojas, além de criar e publicar o commit/tag da versão antes de validar se Android e iOS compilaram e inicializaram sem falhas. Qualquer regressão pós-build (como poda indevida do R8 em `workmanager`/`flutter_local_notifications`/`CredentialManager`, quebra de SQLite nativo ou extração de `assets/preload/`) queimaria permanentemente um `versionCode` nas lojas sem possibilidade de rollback instantâneo.

## What Changes

- Criação da capacidade de **Smoke Test Pós-Build Segregado por Compilação Condicional** para Android (emulador KVM `x86_64`) e iOS (iOS Simulator `arm64` + auditoria estrutural do `.ipa` `iphoneos`):
  - Os artefatos oficiais de loja (`.aab` e `.ipa` a partir de `lib/main.dart`) permanecem 100% livres de código de smoke (`BuildConfig.ARESTA_SMOKE_CI = false` no Android e exclusão via `#if targetEnvironment(simulator)` no iOS), sendo auditados binariamente para provar ausência de símbolos/rotas de smoke e testados em Cold Start puro no emulador Android;
  - Um artefato gêmeo descartável de CI (`--release --obfuscate` com o mesmo R8, `proguard-rules.pro`, NDK e CocoaPods, apontando para `lib/services/smoke_ci/main_smoke_ci.dart` restrito a emulador/simulador e loopback local) executa a jornada completa: inicialização nativa (`Workmanager`, notificações, SQLite `catalogo.db`, extração de `assets/preload/`), aceite dos Termos de Uso, login OIDC via `MethodChannel` nativo contra GoTrue local, abertura e navegação em croqui Protobuf real (`Pico` → `Setor` → `Escalada`) e registro de ascensão (`Cadena`) na caderneta local.
- Reestruturação da esteira de CI/CD (`release_new_app_version.yml`, `build_android.yml` e `build_ios.yml`) para **Topologia Transacional em Quatro Estágios** em paridade com o Fixalog:
  1. Validação (`flutter analyze`, `flutter test`, Robô Caótico) e preparação do pacote candidato (`pubspec.yaml`, `assets/preload/` e `legal_version.g.dart`) sem realizar push no Git;
  2. Compilação + Auditoria Binária + Smoke Test pós-build em paralelo para Android e iOS;
  3. Corte atômico da versão (`git push --atomic`) apenas após todas as plataformas habilitadas passarem no build e no smoke test;
  4. Publicação unificada dos artefatos aprovados (sem recompilar) para Sentry, Firebase Crashlytics, Google Play Console e App Store Connect, incluindo o input `publicar_nas_lojas` (padrão `true`) para disparos completos de validação interna de CI sem publicar nas lojas nem criar tags.

## Capabilities

### New Capabilities
- `smoke-test-pos-build`: Validação funcional automatizada pós-build em Android Emulator KVM e iOS Simulator exercitando inicialização nativa, login OIDC, abertura de croqui Protobuf e registro na caderneta via compilação condicional ausente dos binários das lojas.

### Modified Capabilities
- `publicacao-producao-lojas`: Evolução da orquestração unificada de release para topologia transacional (corte atômico de versão e upload às lojas condicionados à aprovação prévia dos smoke tests pós-build) e modo de validação interna sem publicação (`publicar_nas_lojas`).

## Impact

- **Código Dart (`frontend/lib/services/smoke_ci/` e `frontend/tool/release_tools/`)**: Módulo de jornada smoke usando exclusivamente `ClienteHttpAresta.instancia` e `AppLogger.instance`, servidor HTTP local OIDC/GoTrue/Catálogo e ferramentas CLI de auditoria binária e orquestração de emulador/simulador, com espelhamento 1:1 e 100% de cobertura em `frontend/test/`.
- **Camada Nativa (`frontend/android/app/build.gradle.kts`, `AndroidManifest.xml`, `MainActivity.kt` e `frontend/ios/Runner/AppDelegate.swift`)**: Guarda condicional (`BuildConfig.ARESTA_SMOKE_CI` + verificação de hardware QEMU no Android; `#if targetEnvironment(simulator)` no iOS) restrita a loopback local.
- **CI/CD (`.github/workflows/release_new_app_version.yml`, `build_android.yml`, `build_ios.yml`)**: Separação entre estágios `build_e_smoke` e `publicar`, corte transacional via `git push --atomic` e suíte arquitetural `pipeline_release_arquitetura_test.dart`.
