# Integração Firebase - Aresta Climb

Este diretório (`lib/services/firebase/`) consolida **absolutamente todos** os contatos da aplicação com os SDKs do Firebase. Essa arquitetura de isolamento foi construída para evitar acoplamento forte da UI com provedores analíticos de terceiros, garantindo que o resto do sistema desconheça a existência do Firebase.

## Testes de Arquitetura (Linter)
Existe um teste unitário (`test/architecture/firebase_isolation_test.dart`) desenhado especificamente para analisar todos os arquivos `.dart` de `lib/`. Ele garantirá que o build/CI falhe caso um desenvolvedor importe qualquer pacote do firebase (ex: `firebase_core`, `firebase_crashlytics`, `firebase_performance`) em um arquivo fora deste diretório.

## Componentes

### 1. `inicializar_firebase.dart`
Ponto central de inicialização. Exporta a função `initFirebase()` que deve ser chamada **somente uma vez** durante a inicialização do app no `main.dart`. 
O que ele faz:
- Chama `Firebase.initializeApp()` injetando as opções de plataforma (geradas pelo flutterfire).
- Captura exceções não-fatais do SDK do Flutter mapeando-as para `recordFlutterFatalError`.
- Captura _Unhandled Exceptions_ em processamento Assíncrono do Dart via `PlatformDispatcher.instance.onError` e as envia como falhas fatais.
- Desativa a coleta do Firebase Analytics (`initAnalytics`) e do Firebase Performance (`initPerformance`) em modo debug.
- Dá o "Start" no serviço de _Remote Config_.

### 2. `telemetria.dart`, `performance_telemetria.dart` e `classificador_dispositivo.dart`
Abstrações construídas em cima dos pacotes `firebase_analytics` e `firebase_performance`.
Nenhuma tela ou componente no Aresta Climb deve chamar o Firebase Analytics ou o Firebase Performance diretamente.
- **`ClassificadorDispositivo` (`classificador_dispositivo.dart`)**: Classifica o porte de memória RAM do aparelho (`'baixo'` ≤ 3 GB, `'medio'` 4–6 GB, `'alto'` ≥ 8 GB ou `'desconhecido'`) a partir de `/proc/meminfo` (com injeção limpa para testes determinísticos), calculando o teto adaptativo de `imageCache` (50 MB / 100 MB / 150 MB) e fornecendo `tier_dispositivo` e `ram_gb`.
- **`TelemetryService` (`telemetria.dart`)**: Centraliza todos os eventos do GA4 (incluindo dimensões de fatiamento, `duracao_ms`, `tier_dispositivo` e `ram_gb` para painéis no Looker Studio).
- **`ServicoPerformance` (`performance_telemetria.dart`)**: Centraliza a coleta de performance ponta a ponta até a interatividade real da página (`addPostFrameCallback` / primeiro frame decodificado em `MapaInterativoPage`) e o monitoramento de fluidez de quadros via `SchedulerBinding.addTimingsCallback` (`iniciarMonitoramentoFluidez` / `encerrarMonitoramentoFluidez` emitindo `fluidez_sessao_tela` com `total_frames`, `frames_jank`, `taxa_jank_pct`, `p95_ui_ms` e `p95_raster_ms`), realizando **dupla emissão** (Custom `Trace` no Firebase Performance + evento GA4 via `TelemetryService`).
- **Bloqueio Estrito em Modo Debug**: Quando `kDebugMode` é `true`, `setAnalyticsCollectionEnabled(false)` e `setPerformanceCollectionEnabled(false)` são acionados e nenhuma trace é transmitida ao Firebase Performance, mantendo apenas logs locais no `AppLogger`.
- **Mocking**: Para testes unitários de funções de tela, usamos `MockTelemetryService` e `FakeFirebasePerformance` que substituem essas instâncias para evitar _crashes_ de inicialização do SDK nativo e validar quais eventos e traces foram requisitados.

### 3. `remote_config.dart`
Abstração do `firebase_remote_config`. 
Ele funciona mantendo uma tabela de _feature flags_ ou valores remotos de configuração.
- **Valores Padrão**: Toda flag invocada neste app deve ter um fallback inquebrável caso o dispositivo não tenha internet.
- **Cache e Resiliência Offline**: Valores são armazenados localmente e atualizados com cache (12h). Quando o dispositivo inicia sem conexão (ou quando o SDK nativo falha ao obter o token do *Firebase Installations* / contatar o backend), a falha é registrada apenas como `logAviso` (breadcrumb) e `_initFuture` é limpo para permitir nova tentativa futura na sessão.
- **URLs Dinâmicas**: Permite alterar dinamicamente a URL do endpoint de feedback (`feedback_edge_function_url`) e a URL base do servidor de dados (`serving_base_url`) sem necessidade de nova compilação do app.
- **Como expandir**: Para adicionar uma nova flag, declare-a nos fallbacks internos e crie um _getter_ tipado para a UI ler de forma nativa e simples.

### 4. `validador_app.dart`
Abstração do `firebase_app_check`.
Responsável pela atestação de integridade de hardware e software da aplicação.
- **Produção Oficial (`kModoReleaseOficial`)**: Ativa Play Integrity no Android e App Attest no iOS para gerar tokens JWT que comprovam a autenticidade do binário perante o backend Supabase.
- **Desenvolvimento e Release Local (`kModoDesenvolvimento`)**: Em `--debug`, `--profile` ou quando compilado com `--dart-define=RELEASE_LOCAL=true`, utiliza o Provedor de Depuração (`AndroidDebugProvider` / `AppleDebugProvider`) com suporte a UUIDs cadastrados no Firebase Console, evitando erros `403` do Play Integrity quando o APK é assinado com `debug.keystore`.
- **Degradação Offline em `getToken`**: Falhas de rede ou indisponibilidade ao renovar o token do App Check são reconhecidas via `AppLogger.isFalhaConexaoOuTimeout` e registradas como `logAviso` (breadcrumb), evitando falsos positivos de erro não-fatal no Crashlytics.

### 5. `app_logger.dart`
Abstração centralizada de logging, constantes de modo de compilação (`kReleaseLocal`, `kModoReleaseOficial`, `kModoDesenvolvimento`) e relatórios de erro com **envio dual** para o `firebase_crashlytics` e o `sentry_flutter` (quando inicializado via `--dart-define=SENTRY_DSN=...` em `main.dart`).
O aplicativo adota a regra arquitetural estrita de que nenhum código em `lib/` (fora deste serviço) pode invocar `print` ou `debugPrint` diretamente.
- **Fila Offline (`outbox`)**: Tanto o Crashlytics quanto o `sentry_flutter` armazenam envelopes e breadcrumbs em disco local quando o escalador está sem sinal na rocha, despachando automaticamente quando a conectividade é restabelecida.
- **`logInfo(String mensagem)`**:
  - *Debug*: Imprime no console local com prefixo `ℹ️ [AppLogger]`.
  - *Breadcrumbs*: Registra simultaneamente no Crashlytics (`FirebaseCrashlytics.instance.log`) e no Sentry (`Sentry.addBreadcrumb` com `SentryLevel.info`).
- **`logAviso(String mensagem)`**:
  - *Debug*: Imprime no console com prefixo de aviso `⚠️ [AppLogger AVISO]`.
  - *Release*: Registra exclusivamente como breadcrumb contextual no Crashlytics e no Sentry (`SentryLevel.warning`), sem abrir issues.
- **`logError(String contextMessage, {error, required StackTrace stackTrace, bool fatal = false})`**:
  - *Debug*: Imprime detalhes completos no console local.
  - *Release*: Envia simultaneamente ao Crashlytics (`recordError`) e ao Sentry (`Sentry.captureException`) com o `stackTrace` de origem obrigatório para permitir agrupamento correto, abertura automática de issue deduplicada no GitHub e alertas no WhatsApp.
- **`logCrash(String contextMessage, {error, required StackTrace stackTrace})`**:
  - Registra falhas severas com nível crítico (`fatal: true` / `SentryLevel.fatal`), acionando alertas imediatos de emergência.
- **`logFalhaSyncOuDownload(String contextMessage, {error, required StackTrace stackTrace})`** e **`isFalhaConexaoOuTimeout(dynamic error)`**:
  - Analisa inteligentemente se a falha é decorrente de instabilidade transitória de rede (timeout, socket, HTTP 502/503/504/429 ou erros nativos de transporte de `FirebaseException` no Installations, Remote Config e App Check), registrando apenas como breadcrumb (`logAviso`) em ambos os provedores, ou se é falha de integridade/corrupção de dados (`fatal: true`).

### 6. Desofuscação e Símbolos no Crashlytics (CI/CD)
Para que os relatórios de crash no painel do Firebase Crashlytics exibam os nomes de funções, arquivos e linhas de código (ao invés de ponteiros hexadecimais *unsymbolicated*), a pipeline do GitHub Actions realiza o upload automático de dois tipos de símbolos a cada release:
- **dSYMs nativos do iOS**: extraídos do `Runner.xcarchive` gerado pelo Xcode.
- **Símbolos Dart (Android e iOS)**: gerados com a flag `--split-debug-info=build/symbols` do Flutter.

**Autenticação**: O upload é autenticado via Google Cloud Service Account com a role `Firebase Crashlytics Admin`, configurada no repositório GitHub como o segredo `FIREBASE_SERVICE_ACCOUNT_JSON`.
