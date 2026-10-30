# Design

## Context

Conforme detalhado em `proposal.md`, a execução do *Pre-Launch Report* (Robo Test) da Google Play Store no pacote `0.6.0+98` (`split_config.x86_64.apk`) expôs defeitos interligados de ciclo de vida e timeouts:
1. **Issue #20 (`SIGSEGV` em `libandroidfw.so`)**: A inspeção com `aapt2 dump resources` sobre os artefatos de release gerados pelo AGP 9.0.1 + R8 Full Mode (`shrunk-resources-binary-format-release.ap_` vs. `linked-resources-proto-format-release.ap_`) comprovou que o novo encolhedor de recursos integrado ao R8 removeu 100% das entradas de 5 tipos de recursos (`anim` id `01`, `animator` id `02`, `interpolator` id `0a`, `raw` id `0d` e `styleable` id `10`), omitindo seus blocos `ResTable_typeSpec` de `resources.arsc` enquanto mantinha seus nomes no `type_string_pool_`. Quando a `MainActivity` é destruída e recriada no mesmo processo, chamadas nativas a `Resources.getIdentifier` (`AssetManager2::GetResourceId` $\rightarrow$ `LoadedPackage::FindEntryByName`) desreferenciam ponteiros nulos e causam `SIGSEGV`.
2. **Issue #19 (`[core/no-app] No Firebase App '[DEFAULT]' has been created`)**: Ao relançar o aplicativo 18,4 segundos após o `SIGSEGV` (enquanto o sistema ainda processava o *crash dump*), a etapa `initFirebase()` levou ~5,5s. Como `executarEtapaPreBootComTimeout` cortava a espera aos 4s, o `main()` avançou para `setupAppServices` e `runApp()` ~1,5s antes do `Firebase.initializeApp()` concluir em segundo plano. Durante essa janela de 1,48s, `RemoteConfigService`, `ServicoPerformance` e `TelemetryService` invocaram `.instance` sem guarda de inicialização, capturaram `[core/no-app]` e reportaram 5 falsos erros ao Sentry.
3. **Descarte de Diagnóstico e Feedback por Timeout em `resolverDestinoInicialColdStart`**: O cliente HTTP centralizado (`ClienteHttpAresta.tempoLimiteConexao = Duration(seconds: 10)`) e o serviço de busca remota (`ServicoCroquiOnline._timeoutsTentativas = [4s, 8s]`) já possuem controle de timeout próprio e diagnóstico estruturado de falhas. Um segundo timeout arbitrário de 8s sobre `resolverDestinoInicialColdStart` interrompia o fluxo antes da conclusão do diagnóstico, descartando `itemSemConexaoInicial` e fazendo fallback para a Home em vez de apresentar o `ModalCroquiSemConexao` ao usuário.

Todas as decisões abaixo seguem estritamente os 8 princípios do `AGENTS.md` (código 100% em português, modularidade, TDD com 100% de cobertura comportamental, espelhamento 1:1 de testes e ausência de mocks internos).

## Goals / Non-Goals

**Goals:**
- Eliminar na raiz a omissão de blocos `ResTable_typeSpec` em `resources.arsc` desativando `isShrinkResources` no build de release do Android (`isShrinkResources = false`), mantendo `isMinifyEnabled = true` e R8 Full Mode intactos.
- Garantir que todas as inicializações 100% locais e *offline-first* de pré-boot (`initFirebase`, `GerenciadorNotificacaoDownload.inicializar` e `MigracaoBackgroundOrchestrator.cancelarMigracaoSegundoPlano`) sejam sempre aguardadas até o fim sem *timeouts* artificiais que criem condições de corrida.
- Reduzir a latência de IPC do `initFirebase()` paralelizando as 4 ativações pós-`Firebase.initializeApp()` (`AppCheckService.instance.activate`, `initCrashlytics`, `initAnalytics` e `initPerformance`) com `Future.wait`.
- Remover o timeout redundante de `resolverDestinoInicialColdStart`, permitindo que os timeouts reais da camada HTTP completem o diagnóstico e entreguem `itemSemConexaoInicial` para abertura do `ModalCroquiSemConexao`.
- Proteger `RemoteConfigService`, `ServicoPerformance` e `TelemetryService` com guarda de inicialização (`AppLogger.firebaseInicializado`) para que jamais lancem `[core/no-app]` caso o Firebase não esteja disponível em produção.

**Non-Goals:**
- Alterar o comportamento de `MainActivity.onStop()` (que aplica `ColorDrawable(0xFF181312.toInt())` em memória para evitar flash branco no *Warm Start* e não possui relação com `resources.arsc`).
- Alterar a política de timeouts da camada HTTP inferior (`ClienteHttpAresta` e `ServicoCroquiOnline`).

## Decisions

### 1. Desativação de `isShrinkResources` no Android (`build.gradle.kts`)
- **Decisão**: Alterar `isShrinkResources = false` no bloco `buildTypes.release` de `frontend/android/app/build.gradle.kts`, mantendo `isMinifyEnabled = true`.
- **Racional**: Em aplicativos Flutter, todos os assets pesados residem em `flutter_assets`. Os recursos XML de `res/` do AndroidX/Play Services somam apenas ~40 KB, enquanto o encolhedor do AGP 9.0.1 remove tipos inteiros (`ResTable_typeSpec`) da tabela `resources.arsc`, provocando `SIGSEGV` nativo em `libandroidfw.so` nos *split APKs* gerados pela Google Play Store.

### 2. Remoção de Timeouts Redundantes em Pré-Boot e Cold Start e Paralelização de `initFirebase()`
- **Decisão**:
  1. Remover a função `executarEtapaPreBootComTimeout` de `frontend/lib/services/inicializacao_app.dart` (e seu re-export em `main.dart`), invocando diretamente `GerenciadorNotificacaoDownload.instancia.inicializar()` e `initFirebase()` dentro do `Future.wait` de `main()`.
  2. Remover o `.timeout(timeoutCancelamento)` e o parâmetro `timeoutCancelamento` de `MigracaoBackgroundOrchestrator.cancelarMigracaoSegundoPlano` e `setupAppServices`.
  3. Em `resolverDestinoInicialColdStart` (`frontend/lib/services/inicializacao_app.dart`), remover o wrapper `.timeout(timeoutResolucao)` e o parâmetro `timeoutResolucao`. Manter a captura interna de exceções e a proteção `.catchError` em `_MyAppState` (linha 210) que garante que `_aguardandoColdStart` sempre se torne `false`.
  4. Em `initFirebase()` (`frontend/lib/services/firebase/inicializar_firebase.dart`), manter `await (initializer ?? Firebase.initializeApp)()` como primeira etapa e executar em paralelo logo em seguida:
     ```dart
     await Future.wait([
       AppCheckService.instance.activate(),
       initCrashlytics(),
       initAnalytics(),
       initPerformance(),
     ]);
     ```
- **Racional**: A auditoria do código confirmou que os componentes locais não usam rede. Além disso, a camada de rede possui seus próprios timeouts (10s de conexão TCP, 4s/8s por requisição). Ter um timeout externo sobre `resolverDestinoInicialColdStart` cortava prematuramente a resolução e descartava o objeto `itemSemConexao`, impedindo a exibição do diálogo `ModalCroquiSemConexao` ao usuário e forçando uma queda silenciosa e confusa na Home.

### 3. Guarda Defensiva `AppLogger.firebaseInicializado` nos Serviços Dependentes do Firebase
- **Decisão**: Alinhar `RemoteConfigService`, `ServicoPerformance` e `TelemetryService` ao mesmo contrato defensivo já utilizado em `AppLogger`:
  - Em `RemoteConfigService`: quando `_instanceOverride == null && !AppLogger.firebaseInicializado`, `initialize()` registra apenas `AppLogger.instance.logAviso(...)` e retorna imediatamente sem criar `_initFuture` nem acessar `FirebaseRemoteConfig.instance`; os getters de versão (`minRequiredVersion`, `recommendedVersion`, `getString`) retornam `'0.0.0'` (ou `''`) com segurança.
  - Em `ServicoPerformance`: em `_iniciarTraceFirebase`, se `_performanceOverride == null && !AppLogger.firebaseInicializado`, retorna `null` imediatamente sem invocar `FirebasePerformance.instance`.
  - Em `TelemetryService`: em `_logEvent`, se `_analyticsOverride == null && !AppLogger.firebaseInicializado`, retorna imediatamente sem invocar `FirebaseAnalytics.instance`.
- **Racional**: Preserva 100% da testabilidade com Fakes e garante que falhas ou atrasos no núcleo do Firebase não disparem cascatas de exceções `[core/no-app]`.

## Risks / Trade-offs

- **[Risco] Deep link em conexão extremamente lenta aguardar os timeouts do cliente HTTP** $\rightarrow$ **Mitigação**: Os timeouts escalonados de `ServicoCroquiOnline` (4s na 1ª tentativa, 8s na 2ª tentativa) e o timeout de conexão do `ClienteHttpAresta` (10s) são limitados e previsíveis. Ao atingir o timeout da camada de transporte, `DeepLinkNavigatorService` recebe o erro estruturado e apresenta `ModalCroquiSemConexao`, oferecendo ao usuário a opção clara de tentar novamente.
