// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:frontend/application_managers/segundo_plano/despachante_segundo_plano.dart';
import 'package:frontend/application_managers/feedback/orquestrador_feedback.dart';
import 'package:frontend/constants/legal_version.g.dart';
import 'package:frontend/navigation/funcoes_navegacao.dart';
import 'package:frontend/navigation/wrapper_navegacao_arvore.dart';
import 'package:frontend/pages/tela_migracao_banco.dart';
import 'package:frontend/pages/tela_splash_inicial.dart';
import 'package:frontend/pages/termos_de_uso.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/feedback/gatilho_feedback_rede.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import 'package:frontend/services/firebase/inicializar_firebase.dart';
import 'package:frontend/services/firebase/performance_telemetria.dart';
import 'package:frontend/services/firebase/remote_config.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/inicializacao_app.dart';
import 'package:frontend/services/notificacoes/gerenciador_notificacao_download.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/theme/temas.dart';
import 'package:frontend/theme/gerenciador_tema.dart';
import 'package:frontend/widgets/verificador_versao_app.dart';
import 'package:frontend/widgets/banner_modo_experimental.dart';
import 'package:frontend/widgets/modal_sessao_experimental_encerrada.dart';
import 'package:frontend/widgets/feedback/construtor_feedback_usuario.dart';

// Re-exports de compatibilidade retroativa para testes e módulos existentes
export 'package:frontend/navigation/wrapper_navegacao_arvore.dart'
    show TreeNavigationWrapper, TreeNavigationWrapperState;
export 'package:frontend/services/inicializacao_app.dart'
    show
        ResultadoResolucaoColdStart,
        configurarExibicaoPontaAPonta,
        configurarGestaoMemoria,
        registrarOuvintesLiveReload,
        resolverDestinoInicialColdStart,
        setupAppServices;
export 'package:frontend/theme/temas.dart'
    show construirTemaClaro, construirTemaEscuro;

/// DSN do projeto `aresta-app` no Sentry (pode ser sobrescrito via `--dart-define=SENTRY_DSN=...`).
const String kSentryDsn = String.fromEnvironment(
  'SENTRY_DSN',
  defaultValue:
      'https://a9b8f04560a98ff2186ca8cdb654d22a@o4511980548849664.ingest.us.sentry.io/4512313345966080',
);

void main() async {
  ServicoPerformance.instancia.iniciarCronometroColdStart();

  // Garante que o Flutter esteja pronto antes de fazer I/O de arquivo
  WidgetsFlutterBinding.ensureInitialized();

  // Configura a gestão de memória e teto de cache de bitmaps para Vitals do Android
  configurarGestaoMemoria();

  // Inicializa o Workmanager para processamento de feedback em background
  Workmanager().initialize(callbackDispatcher);

  final editorDeCroqui = EditorDeCroqui();
  int? acceptedLegalVersion;

  // Executa tarefas independentes de inicialização em paralelo para acelerar o Cold Start
  await Future.wait([
    configurarExibicaoPontaAPonta(),
    GerenciadorNotificacaoDownload.instancia.inicializar(),
    initFirebase(),
    ThemeController().loadTheme(),
    SharedPreferences.getInstance().then((prefs) async {
      acceptedLegalVersion = await migrarTermosLegais(prefs);
    }),
    editorDeCroqui.loadFromDisk(),
  ]);

  // Instancia e inicializa o repositório
  final datasetRepo = DatasetRepository(editorDeCroqui: editorDeCroqui);
  final syncService = SyncService(datasetRepository: datasetRepo);

  // Escuta mudanças de modo para re-sincronizar de forma atômica com debounce
  Timer? debounceModo;
  void onModeChange() {
    debounceModo?.cancel();
    debounceModo = Timer(const Duration(milliseconds: 50), () async {
      await datasetRepo.init();
      syncService.syncIndex();
    });
  }

  editorDeCroqui.editorUrl.addListener(onModeChange);
  editorDeCroqui.isExperimentalMode.addListener(onModeChange);

  registrarOuvintesLiveReload(editorDeCroqui, datasetRepo, syncService);

  // Sincronização inicial na inicialização
  final needsMigration = await setupAppServices(datasetRepo, syncService);
  final resolucaoColdStart = needsMigration
      ? null
      : resolverDestinoInicialColdStart(
          datasetRepo,
          syncService: syncService,
        );

  void iniciarAplicativo() {
    runApp(
      MyApp(
        datasetRepo: datasetRepo,
        syncService: syncService,
        needsMigration: needsMigration,
        acceptedLegalVersion: acceptedLegalVersion ?? 0,
        resolucaoInicialColdStart: resolucaoColdStart,
      ),
    );
  }

  // Inicializa o Sentry encadeando os handlers globais do Crashlytics e executando o appRunner
  if (kSentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = kSentryDsn;
        options.sendDefaultPii = false;
        options.maxBreadcrumbs = 100;
      },
      appRunner: iniciarAplicativo,
    );
  } else {
    iniciarAplicativo();
  }
}

// Global navigator key to allow overlays to push routes for back button interception
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Widget raiz da aplicação Aresta Climb.
///
/// Configura o [MaterialApp], injeção de feedback visual nativo ([BetterFeedback]),
/// temas claro/escuro e controla telas de bloqueio (Termos de Uso, Migração de Base e Versão Mínima).
class MyApp extends StatefulWidget {
  final DatasetRepository datasetRepo;
  final SyncService syncService;
  final bool needsMigration;
  final int acceptedLegalVersion;
  final AssetBundle? assetBundle;
  final RemoteConfigService? remoteConfigService;
  final Future<ResultadoResolucaoColdStart>? resolucaoInicialColdStart;

  const MyApp({
    super.key,
    required this.datasetRepo,
    required this.syncService,
    required this.needsMigration,
    required this.acceptedLegalVersion,
    this.assetBundle,
    this.remoteConfigService,
    this.resolucaoInicialColdStart,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late int _acceptedLegalVersion;
  late bool _needsMigration;
  late bool _aguardandoColdStart;
  ResultadoResolucaoColdStart? _resultadoColdStart;
  NetworkFeedbackTrigger? _networkFeedbackTrigger;

  @override
  void initState() {
    super.initState();
    ServicoPerformance.instancia.garantirCronometroColdStartAtivo();
    WidgetsBinding.instance.addObserver(this);
    _acceptedLegalVersion = widget.acceptedLegalVersion;
    _needsMigration = widget.needsMigration;
    _aguardandoColdStart = widget.resolucaoInicialColdStart != null;
    if (widget.resolucaoInicialColdStart != null) {
      widget.resolucaoInicialColdStart!
          .then((resultado) {
            if (mounted) {
              setState(() {
                _resultadoColdStart = resultado;
                _aguardandoColdStart = false;
              });
              if (resultado.linkInicialProcessado == null &&
                  _hasAcceptedTerms &&
                  !_needsMigration) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    ServicoPerformance.instancia.registrarColdStartHome();
                  }
                });
              }
            }
          })
          .catchError((Object erro, StackTrace stackTrace) {
            AppLogger.instance.logError(
              '[MyApp] Falha inesperada na resolução inicial do Cold Start. Liberando TelaSplashInicial para a Home.',
              error: erro,
              stackTrace: stackTrace,
            );
            if (mounted) {
              setState(() {
                _aguardandoColdStart = false;
              });
            }
          });
    } else if (_hasAcceptedTerms && !_needsMigration) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _resultadoColdStart?.linkInicialProcessado == null) {
          ServicoPerformance.instancia.registrarColdStartHome();
        }
      });
    }

    widget.datasetRepo.editorDeCroqui.notificadorSessaoExpirada.addListener(
      _aoExpirarSessaoExperimental,
    );

    // Tenta esvaziar a fila assim que o app abre (caso já tenha internet) sem propagar erro assíncrono não tratado
    FeedbackOrchestrator.processarFilaSemPropagarErro(dispatcher: 'app_startup');

    // Escuta transições de rede (ex: tirar do modo avião) para enviar feedbacks presos na fila,
    // sem depender da lentidão do agendamento do SO para o Workmanager.
    _networkFeedbackTrigger = NetworkFeedbackTrigger(
      connectivityStream: Connectivity().onConnectivityChanged,
      onNetworkRestored: () async {
        await FeedbackOrchestrator.processarFilaSemPropagarErro(
          dispatcher: 'connectivity_plus',
        );
      },
    );
  }

  @override
  void didUpdateWidget(covariant MyApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.datasetRepo.editorDeCroqui !=
        widget.datasetRepo.editorDeCroqui) {
      oldWidget.datasetRepo.editorDeCroqui.notificadorSessaoExpirada
          .removeListener(_aoExpirarSessaoExperimental);
      widget.datasetRepo.editorDeCroqui.notificadorSessaoExpirada.addListener(
        _aoExpirarSessaoExperimental,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.datasetRepo.editorDeCroqui.notificadorSessaoExpirada.removeListener(
      _aoExpirarSessaoExperimental,
    );
    _networkFeedbackTrigger?.dispose();
    super.dispose();
  }

  /// Intercepta notificações de rota enviadas pelo canal nativo do Flutter (`SystemChannels.navigation`)
  /// antes que alcancem o `_WidgetsAppState` do [MaterialApp].
  ///
  /// O Aresta Climb gerencia todos os deep links exclusivamente via `GerenciadorDeepLinks` (`app_links`)
  /// e `TreeNavigationController` no `Navigator` aninhado do [TreeNavigationWrapper].
  /// Retornar `true` aqui encerra o despacho no [WidgetsBinding] e impede que o [MaterialApp]
  /// tente empilhar rotas nomeadas inexistentes (como `/s/<uid>`) e lance [FlutterError] em `_onUnknownRoute`.
  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) async {
    return true;
  }

  /// Redireciona o usuário para a Home do catálogo oficial e apresenta o diálogo
  /// explicativo quando a sessão efêmera do Editor Desktop expira automaticamente.
  void _aoExpirarSessaoExperimental() {
    final navContext = TreeNavigationWrapper.navKey.currentContext;
    if (navContext != null && navContext.mounted) {
      AppNav.home(navContext);
    }
    final modalContext = appNavigatorKey.currentContext ?? navContext;
    if (modalContext != null && modalContext.mounted) {
      ModalSessaoExperimentalEncerrada.exibir(modalContext);
    }
  }

  void _onTermsAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('accepted_legal_version', kLegalVersion);
    await prefs.setString(
      'accepted_legal_timestamp',
      DateTime.now().toIso8601String(),
    );
    setState(() {
      _acceptedLegalVersion = kLegalVersion;
    });
  }

  bool get _hasAcceptedTerms => _acceptedLegalVersion >= kLegalVersion;
  bool get _isUpdatingTerms =>
      _acceptedLegalVersion > 0 && _acceptedLegalVersion < kLegalVersion;

  Widget _construirTelaRaiz(BuildContext context) {
    if (!_hasAcceptedTerms) {
      return TermsOfUsePage(
        onAccepted: _onTermsAccepted,
        isUpdatingTerms: _isUpdatingTerms,
        assetBundle: widget.assetBundle,
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: (_aguardandoColdStart && !_needsMigration)
          ? const TelaSplashInicial(
              key: ValueKey('tela_splash_inicial'),
              exibirIndicadorCarregamento: true,
            )
          : TreeNavigationWrapper(
              datasetRepo: widget.datasetRepo,
              syncService: widget.syncService,
              treeController: _resultadoColdStart?.treeController,
              linkInicialProcessado: _resultadoColdStart?.linkInicialProcessado,
              mensagemAvisoInicial: _resultadoColdStart?.mensagemAvisoInicial,
              itemSemConexaoInicial: _resultadoColdStart?.itemSemConexaoInicial,
              key: TreeNavigationWrapper.navKey,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final view = View.maybeOf(context) ??
        (WidgetsBinding.instance.platformDispatcher.views.isNotEmpty
            ? WidgetsBinding.instance.platformDispatcher.views.first
            : null);
    final double? alturaLogica = (view != null && view.devicePixelRatio > 0)
        ? view.physicalSize.height / view.devicePixelRatio
        : null;
    final double paddingInferior = (view != null && view.devicePixelRatio > 0)
        ? (view.viewPadding.bottom > view.padding.bottom
                ? view.viewPadding.bottom
                : view.padding.bottom) /
            view.devicePixelRatio
        : 0.0;
    if (alturaLogica != null) {
      GerenciadorFeedbackSheet.atualizarDimensoesManuais(
        alturaTela: alturaLogica,
        paddingInferiorSO: paddingInferior,
        temCroquiAtivo: false,
      );
    }

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController().themeMode,
      builder: (context, currentMode, _) {
        return ValueListenableBuilder<double>(
          valueListenable: GerenciadorFeedbackSheet.fracaoAlturaSheet,
          builder: (context, fracaoSheet, _) {
            return BetterFeedback(
              feedbackBuilder: (context, onSubmit, scrollController) {
                return Theme(
                  data: ThemeData(
                    brightness: Brightness.dark,
                    extensions: const [AppColors.dark],
                  ),
                  child: customFeedbackBuilder(context, onSubmit, scrollController),
                );
              },
              themeMode: ThemeMode.dark,
              theme: FeedbackThemeData(
                background: AppColors.light.slateStone,
                feedbackSheetColor: AppColors.light.obsidianBrown,
                activeFeedbackModeColor: AppColors.light.beastHide,
                sheetIsDraggable: false,
                feedbackSheetHeight: fracaoSheet,
                drawColors: const [
                  AppColors.brandColor,
                  Colors.red,
                  Colors.green,
                  Colors.blue,
                  Colors.yellow,
                ],
              ),
              darkTheme: FeedbackThemeData(
                background: AppColors.dark.deepBasalt,
                feedbackSheetColor: AppColors.dark.caveShadow,
                activeFeedbackModeColor: AppColors.dark.rustIron,
                sheetIsDraggable: false,
                feedbackSheetHeight: fracaoSheet,
                drawColors: const [
                  AppColors.brandColor,
                  Colors.red,
                  Colors.green,
                  Colors.blue,
                  Colors.yellow,
                ],
              ),
              localizationsDelegates: [GlobalFeedbackLocalizationsDelegate()],
              localeOverride: const Locale('pt', 'BR'),
              child: MaterialApp(
                navigatorKey: appNavigatorKey,
                title: 'Aresta Climb',
                debugShowCheckedModeBanner: false,
                themeMode: ThemeMode.dark, // Temporário: fixado em dark mode
                theme: construirTemaClaro(),
                darkTheme: construirTemaEscuro(),
                // Força o Navigator raiz a inicializar sempre apenas a rota '/' (home),
                // mesmo que a engine informe um defaultRouteName externo em Cold Start.
                routes: <String, WidgetBuilder>{
                  Navigator.defaultRouteName: _construirTelaRaiz,
                },
                onGenerateInitialRoutes: (String initialRouteName) {
                  return Navigator.defaultGenerateInitialRoutes(
                    appNavigatorKey.currentState!,
                    Navigator.defaultRouteName,
                  );
                },
                // Banner global para modo experimental/editor que persiste em todas as telas
                builder: (context, child) {
                  Widget effectiveChild = child!;

                  if (_needsMigration && _hasAcceptedTerms) {
                    effectiveChild = DatabaseMigrationScreen(
                      syncService: widget.syncService,
                      onMigrationComplete: () {
                        setState(() {
                          _needsMigration = false;
                        });
                      },
                    );
                  }

                  return AppVersionChecker(
                    remoteConfigService: widget.remoteConfigService,
                    child: Stack(
                      children: [
                        effectiveChild,
                        BannerModoExperimental(
                          editorDeCroqui: widget.datasetRepo.editorDeCroqui,
                          onSairModoExperimental: () async {
                            await widget.datasetRepo.editorDeCroqui.nukeExperimentalData();
                            await widget.datasetRepo.init();
                            final navContext = TreeNavigationWrapper.navKey.currentContext;
                            if (navContext != null && navContext.mounted) {
                              AppNav.home(navContext);
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
