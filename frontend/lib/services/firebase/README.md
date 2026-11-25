# Integração Firebase e Logs (`lib/services/firebase/`)

Este diretório concentra todo o acesso do aplicativo aos SDKs do Firebase e ao envio de logs para Crashlytics e Sentry. O teste `test/architecture/firebase_isolation_test.dart` bloqueia importações de pacotes `firebase_*` fora desta pasta.

---

## Componentes

### 1. `inicializar_firebase.dart`
Exporta `initFirebase()`, chamada uma vez na inicialização (`main.dart`):
- Inicializa `Firebase.initializeApp()` com `firebase_options.dart`.
- Encaminha erros do Flutter (`FlutterError.onError`) e exceções assíncronas não tratadas (`PlatformDispatcher.instance.onError`) ao Crashlytics.
- Desativa a coleta de Analytics e Performance quando `kDebugMode` é `true`.
- Inicializa o `RemoteConfigService`.

### 2. `telemetria.dart`, `performance_telemetria.dart` e `classificador_dispositivo.dart`
- **`ClassificadorDispositivo`**: Classifica a RAM do aparelho (`baixo` $\le 3$ GB, `medio` $4\text{--}6$ GB, `alto` $\ge 8$ GB ou `desconhecido`) lendo `/proc/meminfo` e define o limite do `imageCache` (50 / 100 / 150 MB).
- **`TelemetryService`**: Registra eventos GA4 com parâmetros em português (`duracao_ms`, `tier_dispositivo`, `ram_gb`, `modo_acesso`, etc.).
- **`ServicoPerformance`**: Mede traces (`cold_start_home`, `cold_start_deep_link`, `warm_start_deep_link`, `sync_index_fase1`, `sync_index_fase2`, `abrir_croqui`, `navegacao_interna_croqui`, `abrir_mapa_interativo`) e métricas de quadros (`SchedulerBinding.addTimingsCallback` $\rightarrow$ `fluidez_sessao_tela`), enviando para Firebase Performance e GA4 fora do modo debug.

### 3. `remote_config.dart`
Abstração sobre `firebase_remote_config` com valores locais padrão e cache de 12 horas:
- Expõe `supabaseUrl`, `supabaseAnonKey`, `feedbackEdgeFunctionUrl` e `servingBaseUrl`, aplicando o valor padrão local sempre que o dispositivo estiver offline ou o valor remoto vier vazio.
- Falhas de rede na inicialização são registradas como `logAviso` e limpam `_initFuture` para permitir nova tentativa.

### 4. `validador_app.dart`
Abstração sobre `firebase_app_check`:
- Em `kModoReleaseOficial`, usa Play Integrity (Android) e App Attest (iOS).
- Em `kModoDesenvolvimento` (`--debug`, `--profile` ou `--dart-define=RELEASE_LOCAL=true`), usa `AndroidDebugProvider` / `AppleDebugProvider`.
- Falhas de conexão ao obter token são tratadas como `logAviso`.

### 5. `app_logger.dart`
Serviço único de logging do projeto (`test/architecture/isolamento_logs_arquitetura_test.dart` proíbe `print` e `debugPrint` fora deste arquivo):
- **`logInfo` e `logAviso`**: Imprimem no console em debug e registram breadcrumbs no Crashlytics e no Sentry.
- **`logError` e `logCrash`**: Enviam exceção e `StackTrace` ao Crashlytics e ao Sentry (`fatal: true` em `logCrash`).
- **`logFalhaSyncOuDownload`**: Rebaixa falhas transitórias de rede/transporte (`SocketException`, timeouts, HTTP `408`, `429`, `502`, `503`, `504`) para `logAviso` e reporta códigos HTTP definitivos (`400`, `401`, `403`, `404`, `422`, `500`) como erro.

### 6. Símbolos de Desofuscação (CI/CD)
Os workflows de release enviam os `dSYMs` do iOS (`Runner.xcarchive`) e os arquivos `.symbols` do Dart (`--split-debug-info=build/symbols`) ao Crashlytics usando a credencial `FIREBASE_SERVICE_ACCOUNT_JSON`.
