# Módulo `smoke_ci` (`lib/services/smoke_ci/`)

Este diretório contém suporte para os testes automatizados pós-build executados em emulador Android (`x86_64`) e iOS Simulator (`arm64`) no CI antes da publicação nas lojas.

## Garantias de Isolamento

1. **Ausência nos Binários de Loja (`lib/main.dart`)**:
   - Os pacotes `.aab` e `.ipa` são compilados a partir de `lib/main.dart`, que não importa `lib/services/smoke_ci/` (verificado por `test/architecture/isolamento_smoke_ci_test.dart`).
   - O script `tool/release_tools/auditar_binario_loja.dart` inspeciona `classes*.dex`, `libapp.so`, `Runner` e `App.framework/App` e interrompe a release se encontrar símbolos de smoke.
2. **Restrição Nativa a Emulador e Loopback**:
   - **Android**: `BuildConfig.ARESTA_SMOKE_CI` é `false` por padrão em `build.gradle.kts` e exige hardware virtual (`ranchu`/`goldfish`) e host de loopback (`127.0.0.1`, `localhost`, `10.0.2.2`).
   - **iOS**: O canal `app.escalada.croquis/smoke_ci` em `AppDelegate.swift` é compilado dentro de `#if targetEnvironment(simulator)`, ficando ausente em builds para dispositivos físicos (`iphoneos`).
3. **Padronização de Rede e Logs**:
   - Usa apenas `ClienteHttpAresta.instancia` para HTTP e `AppLogger.instance` para logs.
