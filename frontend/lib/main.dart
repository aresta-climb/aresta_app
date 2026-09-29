// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'package:frontend/application_managers/background/background_dispatcher.dart';
import 'package:frontend/application_managers/feedback/feedback_orchestrator.dart';
import 'package:frontend/constants/legal_version.g.dart';
import 'package:frontend/navigation/navigation_functions.dart';
import 'package:frontend/navigation/tree_navigation_wrapper.dart';
import 'package:frontend/pages/database_migration_screen.dart';
import 'package:frontend/pages/terms_of_use.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/feedback/network_feedback_trigger.dart';
import 'package:frontend/services/firebase/init_firebase.dart';
import 'package:frontend/services/firebase/remote_config_service.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/inicializacao_app.dart';
import 'package:frontend/services/notificacoes/gerenciador_notificacao_download.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/temas.dart';
import 'package:frontend/theme/theme_controller.dart';
import 'package:frontend/widgets/app_version_checker.dart';
import 'package:frontend/widgets/banner_modo_experimental.dart';
import 'package:frontend/widgets/feedback/custom_feedback_builder.dart';

// Re-exports de compatibilidade retroativa para testes e módulos existentes
export 'package:frontend/navigation/tree_navigation_wrapper.dart'
    show TreeNavigationWrapper, TreeNavigationWrapperState;
export 'package:frontend/services/inicializacao_app.dart'
    show configurarGestaoMemoria, registrarOuvintesLiveReload, setupAppServices;
export 'package:frontend/theme/temas.dart'
    show construirTemaClaro, construirTemaEscuro;

void main() async {
  // Garante que o Flutter esteja pronto antes de fazer I/O de arquivo
  WidgetsFlutterBinding.ensureInitialized();

  // Configura a gestão de memória e teto de cache de bitmaps para Vitals do Android
  configurarGestaoMemoria();

  // Inicializa o Workmanager para processamento de feedback em background
  Workmanager().initialize(callbackDispatcher);

  // Inicializa o gerenciador de notificações nativas de download
  await GerenciadorNotificacaoDownload.instancia.inicializar();

  // Inicialização do Firebase antes de avançar para garantir que telemetria/crashlytics estão prontos
  await initFirebase();

  await ThemeController().loadTheme();

  final prefs = await SharedPreferences.getInstance();
  final acceptedLegalVersion = await migrarTermosLegais(prefs);

  // Instancia e carrega o EditorDeCroqui
  final editorDeCroqui = EditorDeCroqui();
  await editorDeCroqui.loadFromDisk();

  // Instancia e inicializa o repositório
  final datasetRepo = DatasetRepository(editorDeCroqui: editorDeCroqui);
  final syncService = SyncService(datasetRepository: datasetRepo);

  // Escuta mudanças de modo para re-sincronizar
  void onModeChange() {
    datasetRepo.loadEmpty();
    syncService.syncIndex();
  }

  editorDeCroqui.editorUrl.addListener(onModeChange);
  editorDeCroqui.isExperimentalMode.addListener(onModeChange);

  registrarOuvintesLiveReload(editorDeCroqui, datasetRepo, syncService);

  // Sincronização inicial na inicialização
  final needsMigration = await setupAppServices(datasetRepo, syncService);

  // Inicia o aplicativo Flutter
  runApp(
    MyApp(
      datasetRepo: datasetRepo,
      syncService: syncService,
      needsMigration: needsMigration,
      acceptedLegalVersion: acceptedLegalVersion ?? 0,
    ),
  );
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

  const MyApp({
    super.key,
    required this.datasetRepo,
    required this.syncService,
    required this.needsMigration,
    required this.acceptedLegalVersion,
    this.assetBundle,
    this.remoteConfigService,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late int _acceptedLegalVersion;
  late bool _needsMigration;
  NetworkFeedbackTrigger? _networkFeedbackTrigger;

  @override
  void initState() {
    super.initState();
    _acceptedLegalVersion = widget.acceptedLegalVersion;
    _needsMigration = widget.needsMigration;

    // Tenta esvaziar a fila assim que o app abre (caso já tenha internet)
    FeedbackOrchestrator.processFeedbackQueue(dispatcher: 'app_startup');

    // Escuta transições de rede (ex: tirar do modo avião) para enviar feedbacks presos na fila,
    // sem depender da lentidão do agendamento do SO para o Workmanager.
    _networkFeedbackTrigger = NetworkFeedbackTrigger(
      connectivityStream: Connectivity().onConnectivityChanged,
      onNetworkRestored: () async {
        await FeedbackOrchestrator.processFeedbackQueue(
          dispatcher: 'connectivity_plus',
        );
      },
    );
  }

  @override
  void dispose() {
    _networkFeedbackTrigger?.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController().themeMode,
      builder: (context, currentMode, _) {
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
            home: _hasAcceptedTerms
                ? TreeNavigationWrapper(
                    datasetRepo: widget.datasetRepo,
                    syncService: widget.syncService,
                    key: TreeNavigationWrapper.navKey,
                  )
                : TermsOfUsePage(
                    onAccepted: _onTermsAccepted,
                    isUpdatingTerms: _isUpdatingTerms,
                    assetBundle: widget.assetBundle,
                  ),
          ),
        );
      },
    );
  }
}
