# Proposal

## Why

Na versão `v0.6.1+100` publicada na Google Play Store, após a correção da inicialização do Firebase permitir o registro integral dos breadcrumbs de telemetria até o momento exato da falha, identificou-se que o crash nativo `SIGSEGV` em `libandroidfw.so` (`android::LoadedPackage::FindEntryByName` $\leftarrow$ `android::AssetManager2::GetResourceId`, Issue #20) ocorre exatamente 77ms após o usuário (ou o robô do Pre-Launch Report) acionar **"Salvar Offline"** em um croqui.

A causa raiz não era o encolhimento de recursos do R8 (`isShrinkResources`), mas sim o uso de `largeIcon: const DrawableResourceAndroidBitmap('ic_launcher_foreground')` em `GerenciadorNotificacaoDownload`: enquanto `@mipmap/ic_launcher` possui configuração `anydpi-v26` (`res/mipmap-anydpi-v26/ic_launcher.xml`) que permanece sempre no APK base (`base-master.apk`, `packages_[0]`), o recurso `drawable/ic_launcher_foreground` existe apenas nas pastas qualificadas por densidade (`drawable-mdpi` a `drawable-xxxhdpi`). Quando o `bundletool` da Google Play Store fatia o `.aab` em Split APKs, `drawable/ic_launcher_foreground` é movido para fora do `base-master.apk`, fazendo com que `AssetManager2::GetResourceId` avance a busca para pacotes de configuração parciais (como `split_config.<idioma>.apk`) cujo ponteiro `type_specs_` para o tipo `"drawable"` é `nullptr`, provocando `SIGSEGV` imediato em `LoadedPackage::FindEntryByName`.

## What Changes

- **Remoção do `largeIcon` baseado em recurso de densidade (`ic_launcher_foreground`) em `GerenciadorNotificacaoDownload`**:
  - Remover a constante `iconeBitmapRaster = 'ic_launcher_foreground'` e o parâmetro `largeIcon: const DrawableResourceAndroidBitmap(iconeBitmapRaster)` nos métodos `atualizarProgresso`, `notificarConclusao` e `notificarFalha` de `GerenciadorNotificacaoDownload`.
  - Manter `icon: iconePequeno` (`'@mipmap/ic_launcher'`) como ícone da notificação na barra de status e no cabeçalho, preservando integralmente o `startForegroundService` (`foregroundServiceTypeDataSync`) durante o download em segundo plano.
- **Reativação de `isShrinkResources = true` no build de release Android**:
  - Restaurar `isShrinkResources = true` em `frontend/android/app/build.gradle.kts`, uma vez comprovado que a causa do `SIGSEGV` era a busca dinâmica de `ic_launcher_foreground` em Split APKs e que `@mipmap/ic_launcher` é preservado nativamente por ser referenciado no `AndroidManifest.xml` e possuir variante `anydpi-v26` no APK base.
- **Refatoração dos testes de `GerenciadorNotificacaoDownload` (Regra do Escoteiro - `AGENTS.md`)**:
  - Substituir o uso legado de `mocktail` em `gerenciador_notificacao_download_test.dart` e `servico_download_segundo_plano_test.dart` por bibliotecas `test-only` de Fakes determinísticos com seus respectivos testes espelhados (`*_fake_test.dart`).

## Capabilities

### New Capabilities
<!-- Nenhuma nova capacidade introduzida. -->

### Modified Capabilities
- `download-segundo-plano-persistente`: Especificar que as notificações nativas de progresso, conclusão e falha de download no Android utilizam exclusivamente o ícone principal do aplicativo (`@mipmap/ic_launcher`, garantido no APK base via `anydpi-v26`) sem carregar `largeIcon` via `Resources.getIdentifier` em recursos restritos a splits de densidade.
- `otimizacao-compilacao-build`: Restaurar a exigência de `isShrinkResources = true` junto com `isMinifyEnabled = true` na variante de release do Android.

## Impact

- `frontend/lib/services/notificacoes/gerenciador_notificacao_download.dart`
- `frontend/test/services/notificacoes/gerenciador_notificacao_download_test.dart`
- `frontend/android/app/build.gradle.kts`
- Especificações `download-segundo-plano-persistente` e `otimizacao-compilacao-build`.
