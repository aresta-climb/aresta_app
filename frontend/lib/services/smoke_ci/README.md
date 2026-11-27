# Módulo `smoke_ci` (`lib/services/smoke_ci/`)

Este diretório contém suporte para os testes automatizados pós-build executados em emulador Android (`x86_64`) e iOS Simulator (`arm64`) no CI antes da publicação nas lojas.

## Cobertura da Jornada UI Real Pós-Build

O módulo `piloto_arvore_ui_smoke.dart` conduz a interface real compilada (`--release --obfuscate` / `--simulator`) por `ValueKey<String>` e `GestureBinding`, enquanto `executor_jornada_smoke.dart` valida contra `ServidorSmokeCi`:

- **Autenticação sem senha multiplataforma:** Magic Code OTP de 6 dígitos (`/auth/v1/otp` e `/auth/v1/verify`), logout via diálogo real, Apple ID OIDC no iOS Simulator (e ocultação do botão no Android), Google `id_token` no Android, Google OAuth PKCE S256 no iOS Simulator, edição de perfil no `DialogoEditarPerfil`, renovação via `refresh_token` e exclusão definitiva de conta (`/rest/v1/rpc/excluir_minha_conta`).
- **Interações comunitárias e alertas Waze:** abertura de croqui Protobuf v5, navegação na árvore (`Pico` → `Setor` → `Via`), registro de cadena com voto de grau e beta público pelo `ModalRegistroCadena`, edição do comentário publicado, reporte de alerta de segurança com retenção offline (`503`) e drenagem posterior para `/rest/v1/fila_interacoes`, confirmação (`+1`) no modal *"Ainda está lá?"* e conferência de *Meus Alertas* na `CadernetaPage`.

## Garantias de Isolamento

1. **Ausência nos Binários de Loja (`lib/main.dart`)**:
   - Os pacotes `.aab` e `.ipa` são compilados a partir de `lib/main.dart`, que não importa `lib/services/smoke_ci/` (verificado por `test/architecture/isolamento_smoke_ci_test.dart`).
   - O script `tool/release_tools/auditar_binario_loja.dart` inspeciona `classes*.dex`, `libapp.so`, `Runner` e `App.framework/App` e interrompe a release se encontrar símbolos de smoke.
2. **Restrição Nativa a Emulador e Loopback**:
   - **Android**: `BuildConfig.ARESTA_SMOKE_CI` é `false` por padrão em `build.gradle.kts` e exige hardware virtual (`ranchu`/`goldfish`) e host de loopback (`127.0.0.1`, `localhost`, `10.0.2.2`).
   - **iOS**: Os canais e ganchos em `AppDelegate.swift` são compilados dentro de `#if targetEnvironment(simulator)`, ficando ausentes em builds para dispositivos físicos (`iphoneos`).
3. **Padronização de Rede e Logs**:
   - Usa apenas `ClienteHttpAresta.instancia` para HTTP e `AppLogger.instance` para logs.
