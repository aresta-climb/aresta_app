# Design

## Context

Conforme detalhado em `proposal.md`, o crash nativo `SIGSEGV` em `libandroidfw.so` (`android::LoadedPackage::FindEntryByName` $\leftarrow$ `android::AssetManager2::GetResourceId`, Issue #20) foi rastreado até a chamada `GerenciadorNotificacaoDownload.atualizarProgresso` ao clicar em **"Salvar Offline"**.

A inspeção da tabela de recursos compilada pelo `aapt2` (`resources-release-optimize.ap_`) demonstrou a diferença estrutural entre os dois recursos consultados via `Resources.getIdentifier` pelo plugin `flutter_local_notifications`:
1. `0x7f0c0000 mipmap/ic_launcher`: possui configurações `(mdpi)` a `(xxxhdpi)` **e** `(anydpi) res/mipmap-anydpi-v26/ic_launcher.xml`. Por não depender de qualificador de densidade, a entrada `anydpi` permanece dentro do `base-master.apk` (`packages_[0]`) quando o `bundletool` da Google Play Store gera os Split APKs. Assim, `AssetManager2::GetResourceId` encontra `@mipmap/ic_launcher` imediatamente em `packages_[0]` na primeira iteração do laço.
2. `0x7f070078 drawable/ic_launcher_foreground`: possui **apenas** configurações qualificadas por densidade (`drawable-mdpi` a `drawable-xxxhdpi`), sem entrada padrão `()` nem `(anydpi)`. Ao fatiar o `.aab` em Split APKs, todas as variantes de `ic_launcher_foreground` são movidas para `split_config.<dpi>.apk`. Quando `AssetManager2::GetResourceId` busca `"ic_launcher_foreground"` do tipo `"drawable"`, não encontra a entrada no `base-master.apk` (`packages_[0]`) e avança a iteração para os demais `LoadedPackage`s do pacote `0x7f` (como `split_config.<idioma>.apk`), onde `"drawable"` consta na `type_string_pool_` mas `type_specs_[drawable]` é `nullptr`, provocando desreferenciação de ponteiro nulo (`SIGSEGV`) em `LoadedPackage::FindEntryByName`.

## Goals / Non-Goals

**Goals:**
- Eliminar completamente a busca dinâmica de `ic_launcher_foreground` via `Resources.getIdentifier` em todas as notificações de download (`atualizarProgresso`, `notificarConclusao` e `notificarFalha`).
- Manter o ícone principal do aplicativo (`@mipmap/ic_launcher`) na barra de status e no cabeçalho das notificações e preservar o `ForegroundService` (`foregroundServiceTypeDataSync`) para proteção de downloads em segundo plano.
- Reativar `isShrinkResources = true` na build de release Android mantendo suporte integral a Split APKs do Android App Bundle.
- Adequar os testes de `GerenciadorNotificacaoDownload` aos princípios de engenharia do `AGENTS.md` (substituindo mocks do `mocktail` por Fake determinístico testado 1:1).

**Non-Goals:**
- Desativar a geração de Split APKs de densidade ou idioma no Android App Bundle.
- Alterar o fluxo de permissões ou o protocolo de download em `SyncService` / `SyncIsolate`.

## Decisions

### Decisão 1: Remoção de `largeIcon` (`ic_launcher_foreground`) mantendo `icon: '@mipmap/ic_launcher'` e `startForegroundService`
- **Escolha**: Remover a constante `iconeBitmapRaster = 'ic_launcher_foreground'` e o parâmetro `largeIcon: const DrawableResourceAndroidBitmap(iconeBitmapRaster)` de `AndroidNotificationDetails` em `atualizarProgresso`, `notificarConclusao` e `notificarFalha` em `GerenciadorNotificacaoDownload`.
- **Racional**:
  - No Android 8.0+ (`minSdk = 26`), toda notificação já exibe o `smallIcon` (`icon: '@mipmap/ic_launcher'`) na barra de status e no cabeçalho da notificação ao lado do nome do aplicativo.
  - O `largeIcon` na direita da notificação de progresso apenas duplicava visualmente o ícone do app e exigia decodificação repetida de `Bitmap` via `BitmapFactory.decodeResource` + `Resources.getIdentifier("ic_launcher_foreground", "drawable", ...)` a cada atualização percentual.
  - Sem o `largeIcon`, o único recurso consultado pelo `flutter_local_notifications` é `@mipmap/ic_launcher`, que comprovadamente funciona no `base-master.apk` tanto no cold start (`inicializar()`) quanto no `startForegroundService` e `show`.
- **Alternativas consideradas**:
  - *Desabilitar Split APKs no `build.gradle.kts` (`enableSplit = false`)*: descartado, pois penaliza o tamanho de download para todos os usuários em vez de corrigir a busca indevida de recurso no código.
  - *Substituir `startForegroundService` por `show` simples*: descartado, pois perderíamos a proteção de processo em primeiro plano (`dataSync`) do Android durante downloads longos com a tela bloqueada, e `show` também passava pela mesma validação `extractNotificationDetails` com `hasInvalidLargeIcon`.

### Decisão 2: Reativação de `isShrinkResources = true` no `build.gradle.kts`
- **Escolha**: Reverter `isShrinkResources` para `true` no bloco `buildTypes.release` de `frontend/android/app/build.gradle.kts`.
- **Racional**:
  - Comprovou-se que o `SIGSEGV` ocorreu mesmo com `isShrinkResources = false` na `v0.6.1+100` devido ao fatiamento de `ic_launcher_foreground` em Split APKs pelo `bundletool`.
  - O recurso `@mipmap/ic_launcher` é referenciado diretamente em `AndroidManifest.xml` (`android:icon="@mipmap/ic_launcher"`), sendo tratado como raiz incondicional pelo R8 resource shrinker e jamais removido.

### Decisão 3: Fakes Determinísticos para `GerenciadorNotificacaoDownload` (Regra do Escoteiro - `AGENTS.md`)
- **Escolha**: Criar uma biblioteca `test-only` de Fake determinístico (`test/fakes/plugin_notificacoes_locais_fake.dart`) com seu respectivo teste espelhado (`test/fakes/plugin_notificacoes_locais_fake_test.dart`) para substituir o uso legado de `mocktail` em `test/services/notificacoes/gerenciador_notificacao_download_test.dart`.
- **Racional**: Cumpre estritamente os Princípios III, IV, V e VII do `AGENTS.md` (proibição de `mocktail`, espelhamento 1:1 e Fakes como bibliotecas de primeira classe testadas).

## Risks / Trade-offs

- **[Risco] Alteração sutil no layout visual da notificação (ausência da miniatura repetida à direita)** $\rightarrow$ **Mitigação**: O ícone do aplicativo continua visível na barra de status e no cabeçalho da notificação (padrão nativo do Android para notificações de progresso de download), economizando memória e CPU a cada atualização da barra de progresso.
