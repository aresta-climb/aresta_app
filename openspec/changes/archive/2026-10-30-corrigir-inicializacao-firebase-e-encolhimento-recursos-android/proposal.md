# Proposal

## Why

Os testes automatizados de Pré-Lançamento da Google Play Store (*Pre-Launch Report / Robo Test*) na versão `0.6.0+98` revelaram dois problemas críticos interligados:
1. **Crash nativo `SIGSEGV` em `libandroidfw.so` (`LoadedPackage::FindEntryByName` $\leftarrow$ `AssetManager2::GetResourceId`, Issue #20)**: Ao compilar o App Bundle (`.aab`) com AGP 9.0.1, R8 Full Mode e `isShrinkResources = true`, o novo encolhedor de recursos removeu 100% das entradas de cinco tipos inteiros (`anim`, `animator`, `interpolator`, `raw` e `styleable`), omitindo seus blocos `ResTable_typeSpec` de `resources.arsc` enquanto mantinha seus nomes no `type_string_pool_`. Na recriação da `MainActivity` em APKs divididos (`split_config.x86_64.apk`), consultas dinâmicas via `Resources.getIdentifier` encontram ponteiros nulos em `LoadedPackage::FindEntryByName` e derrubam o processo com `SIGSEGV`.
2. **Condição de corrida e cascata de erros `[core/no-app] No Firebase App '[DEFAULT]' has been created` (Issue #19)**: Os *timeouts* artificiais de pré-boot (`executarEtapaPreBootComTimeout` de 4s em `initFirebase()` e `GerenciadorNotificacaoDownload.inicializar()`, além do timeout de 2s em `MigracaoBackgroundOrchestrator.cancelarMigracaoSegundoPlano`) abortam a espera de operações que são 100% locais e *offline-first* (sem uso de rede) quando o dispositivo/emulador está sob carga de I/O no boot. Isso faz o `runApp()` iniciar ~1,5s antes do `Firebase.initializeApp()` concluir em segundo plano, disparando falsos erros no Sentry quando `RemoteConfigService`, `ServicoPerformance` e `TelemetryService` acessam singletons do Firebase sem verificar `AppLogger.firebaseInicializado`.
3. **Supressão do modal de croqui sem conexão por timeout redundante em `resolverDestinoInicialColdStart`**: O código de rede subjacente (`ClienteHttpAresta` e `ServicoCroquiOnline`) já possui timeouts próprios e escalonados para tratamento de falhas. Um segundo timeout arbitrário de 8s sobre `resolverDestinoInicialColdStart` abortava a resolução prematuramente e descartava `itemSemConexaoInicial`, impedindo a exibição do diálogo contextual `ModalCroquiSemConexao` ao usuário e forçando um fallback silencioso e confuso para a Home.

## What Changes

- **Desativação do `isShrinkResources` no build de release do Android (`build.gradle.kts`)**: Alterar `isShrinkResources = false` mantendo `isMinifyEnabled = true` e R8 Full Mode ativos, preservando a integridade estrutural da tabela `resources.arsc` nos *split APKs* do Android App Bundle e eliminando o `SIGSEGV` em `libandroidfw.so` (`LoadedPackage::FindEntryByName`).
- **Remoção de timeouts artificiais em inicializações locais pré-boot e paralelização de `initFirebase()`**:
  - Remover `executarEtapaPreBootComTimeout` e aguardar até a conclusão todas as etapas locais de pré-boot (`initFirebase()`, `GerenciadorNotificacaoDownload.instancia.inicializar()` e `MigracaoBackgroundOrchestrator.cancelarMigracaoSegundoPlano()`), garantindo que `Firebase.app('[DEFAULT]')` esteja sempre pronto antes de `setupAppServices` e `runApp()`.
  - Otimizar `initFirebase()` executando em paralelo (`Future.wait`) as 4 ativações independentes e 100% locais pós-`Firebase.initializeApp()` (`AppCheckService.instance.activate()`, `initCrashlytics()`, `initAnalytics()` e `initPerformance()`).
- **Remoção do timeout redundante em `resolverDestinoInicialColdStart` preservando o fluxo de erro contextual**:
  - Remover o `.timeout(timeoutResolucao)` de `resolverDestinoInicialColdStart`, permitindo que os timeouts reais do cliente HTTP (`ClienteHttpAresta` e `ServicoCroquiOnline`) concluam seu diagnóstico e retornem `itemSemConexaoInicial` (ou `mensagemAvisoInicial`) para acionar o `ModalCroquiSemConexao` em vez de descartar o feedback e cair na Home em silêncio.
- **Guarda defensiva de inicialização (`AppLogger.firebaseInicializado`) nos serviços Firebase**: Proteger `RemoteConfigService`, `ServicoPerformance` e `TelemetryService` para que, caso o Firebase não esteja inicializado e nenhuma instância de teste (*override*) tenha sido injetada, degradem silenciosamente com aviso contextual (`logAviso`) sem lançar `[core/no-app]` nem poluir o Sentry.

## Capabilities

### New Capabilities

### Modified Capabilities
- `offline-first-initialization`: Substitui os timeouts artificiais de pré-boot e da resolução de Cold Start pela espera determinística e paralelizada dos serviços, confiando nos timeouts reais da camada HTTP para preservar o `itemSemConexaoInicial` e acionar `ModalCroquiSemConexao`, e adicionando guarda defensiva contra ausência do app `[DEFAULT]` nos serviços dependentes do Firebase.
- `otimizacao-compilacao-build`: Atualiza o requisito de compilação de release do Android para manter a minificação e otimização de código R8 Full Mode (`isMinifyEnabled = true`) com `isShrinkResources = false`, preservando os blocos `ResTable_typeSpec` em `resources.arsc`.

## Impact

- **Android Build (`frontend/android/app/build.gradle.kts`)**: Ajuste de `isShrinkResources = false` no `buildTypes.release`.
- **Inicialização e Cold Start (`frontend/lib/main.dart`, `frontend/lib/services/inicializacao_app.dart`, `frontend/lib/application_managers/migracao/migracao_background_orchestrator.dart`)**: Remoção de `executarEtapaPreBootComTimeout`, do timeout em `cancelarMigracaoSegundoPlano` e do timeout em `resolverDestinoInicialColdStart`.
- **Serviços Firebase (`frontend/lib/services/firebase/inicializar_firebase.dart`, `frontend/lib/services/firebase/remote_config.dart`, `frontend/lib/services/firebase/performance_telemetria.dart`, `frontend/lib/services/firebase/telemetria.dart`)**: Paralelização das sub-etapas de `initFirebase()` e guarda com `AppLogger.firebaseInicializado` antes de acessar singletons globais do Firebase.
- **Testes Automatizados (`frontend/test/`)**: Atualização e criação de testes unitários e de widget espelhados 1:1 com 100% de cobertura comportamental.
