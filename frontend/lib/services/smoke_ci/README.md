# Módulo `smoke_ci` (Smoke Test Pós-Build Descartável de CI)

Este módulo isola a validação automatizada pós-build do Aresta Climb executada em emuladores Android KVM (`x86_64`) e iOS Simulator (`arm64`) antes do corte de versão no Git e da publicação nas lojas.

## Invariantes de Segurança e Pureza Binária

1. **Zero Bytes nos Binários de Produção (`lib/main.dart`)**:
   - Os artefatos oficiais enviados à Google Play (`.aab`) e à App Store (`.ipa`) são compilados a partir de `lib/main.dart`, que jamais importa `lib/services/smoke_ci/` (enforçado por `test/architecture/isolamento_smoke_ci_test.dart`).
   - O script `tool/release_tools/auditar_binario_loja.dart` inspeciona os bytes de `classes*.dex`, `libapp.so`, `Runner` e `App.framework/App` e aborta a release se qualquer marcador de smoke estiver presente.
2. **Tripla Guarda Nativa em Loopback Local**:
   - **Android**: `BuildConfig.ARESTA_SMOKE_CI` é `false` por padrão em `build.gradle.kts` (removido pelo R8 no `.aab`) e exige simultaneamente hardware virtual QEMU (`ranchu`/`goldfish`) e endereço estritamente em loopback (`127.0.0.1`, `localhost`, `10.0.2.2`).
   - **iOS**: Todo o canal `app.escalada.croquis/smoke_ci` e o retorno local de `idToken` em `AppDelegate.swift` ficam dentro de `#if targetEnvironment(simulator)`, inexistindo fisicamente em compilações para iPhones reais (`iphoneos`).
3. **Conformidade Arquitetural**:
   - Toda comunicação HTTP em `lib/services/smoke_ci/` utiliza exclusivamente `ClienteHttpAresta.instancia` e todo registro de diagnóstico utiliza `AppLogger.instance`.
