# Tasks

## 1. Isolamento Arquitetural e Módulos de Auto-Smoke em `frontend/lib/services/smoke_ci/`

- [x] 1.1 Criar `frontend/test/architecture/isolamento_smoke_ci_test.dart` garantindo que nenhum arquivo em `frontend/lib/` fora de `lib/services/smoke_ci/` importe `smoke_ci` ou referencie `app.escalada.croquis/smoke_ci`.
- [x] 1.2 Implementar em TDD `frontend/lib/services/smoke_ci/configuracao_smoke_ci.dart` e `frontend/test/services/smoke_ci/configuracao_smoke_ci_test.dart` com 100% de cobertura comportamental (validação estrita de loopback HTTP e canal nativo).
- [x] 1.3 Implementar em TDD `frontend/lib/services/smoke_ci/executor_jornada_smoke.dart` e `frontend/test/services/smoke_ci/executor_jornada_smoke_test.dart` com 100% de cobertura usando exclusivamente `ClienteHttpAresta.instancia` e `AppLogger.instance` (aceite de Termos Legais, sincronização de índice/abertura de croqui Protobuf, navegação `AppNav`, login Google OIDC via canal nativo, atualização de perfil, registro de `Cadena` na caderneta e envio do relatório).
- [x] 1.4 Implementar em TDD `frontend/lib/services/smoke_ci/main_smoke_ci.dart`, `frontend/test/services/smoke_ci/main_smoke_ci_test.dart` e `frontend/lib/services/smoke_ci/README.md` com 100% de cobertura.

## 2. Guardas Nativas Condicionais (Android e iOS)

- [x] 2.1 Atualizar `frontend/android/app/build.gradle.kts`, `frontend/android/app/src/main/AndroidManifest.xml` e `frontend/android/app/src/main/kotlin/com/example/frontend/MainActivity.kt` expondo `BuildConfig.ARESTA_SMOKE_CI` (`false` por padrão no `.aab` da loja), `usesCleartextTraffic` condicional e o canal/desvio OIDC restrito a emulador Android + loopback.
- [x] 2.2 Atualizar `frontend/ios/Runner/AppDelegate.swift` encapsulando o canal `app.escalada.croquis/smoke_ci` e o retorno local de `idToken` OIDC estritamente sob `#if targetEnvironment(simulator)`.

## 3. Ferramentas CLI de Auditoria Binária, Servidor Loopback e Orquestrador Pós-Build

- [x] 3.1 Implementar em TDD `frontend/tool/release_tools/auditar_binario_loja.dart` e `frontend/test/tool/release_tools/auditar_binario_loja_test.dart` inspecionando `.aab` e `.ipa` oficiais contra marcadores de smoke e validando bibliotecas nativas e `Info.plist`.
- [x] 3.2 Implementar em TDD `frontend/tool/release_tools/servidor_smoke_ci.dart` e `frontend/test/tool/release_tools/servidor_smoke_ci_test.dart` servindo OIDC, GoTrue, `public.perfis`, `indice.binarypb`, `compilado.binarypb` Protobuf v5 com SHA-256 real e `/__smoke__/relatorio` em `127.0.0.1`.
- [x] 3.3 Implementar em TDD `frontend/tool/release_tools/smoke_test_pacote.dart` e `frontend/test/tool/release_tools/smoke_test_pacote_test.dart` orquestrando auditoria binária, Cold Start do `universal.apk` da loja no Android, verificação `codesign`/`otool` no iOS e jornada completa autenticada com simbolização de falhas.

## 4. Topologia Transacional de 4 Estágios nos Workflows de Release e Verificação Final

- [x] 4.1 Refatorar `.github/workflows/release_new_app_version.yml`, `.github/workflows/build_android.yml` e `.github/workflows/build_ios.yml` para os 4 estágios transacionais (`prepare_release` sem push Git → `build_e_smoke_android` + `build_e_smoke_ios` → `cortar_versao` com `git push --atomic` condicional a `publicar_nas_lojas` → `publicar_android` + `publicar_ios` + `submit_ios_review`).
- [x] 4.2 Criar `frontend/test/architecture/pipeline_release_arquitetura_test.dart` validando estaticamente os invariantes de segurança, staging e atomicidade dos workflows.
- [x] 4.3 Executar `flutter analyze --fatal-infos --fatal-warnings`, suíte completa `flutter test --coverage` (verificando 100% de cobertura nos módulos novos) e `openspec validate`.
