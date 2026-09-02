// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/application_managers/feedback/submit_feedback_usecase.dart';
import 'package:frontend/pages/pico_subpages/setores_page.dart';
import 'package:frontend/pages/pico_subpages/explorar_local_page.dart';
import 'package:frontend/pages/pico_subpages/comunidade_pico_page.dart';
import 'package:frontend/pages/pico_subpages/apoie_pico_page.dart';
import 'package:frontend/utils/pico_categorization.dart';
import 'package:frontend/pages/home.dart';
import 'package:frontend/pages/browse.dart';
import 'package:frontend/pages/meus_croquis.dart';
import 'package:frontend/pages/settings.dart';
import 'package:frontend/pages/sobre_time.dart';
import 'package:frontend/pages/comunidade.dart';
import 'package:frontend/pages/gps.dart';
import 'package:frontend/pages/pico.dart';
import 'package:frontend/pages/setor.dart';
import 'package:frontend/pages/grupo.dart';
import 'package:frontend/pages/via.dart';
import 'package:frontend/pages/mapas_carrossel.dart';
import 'package:frontend/pages/mapa_global.dart';
import 'package:frontend/view_functions/common_functions.dart';
import 'widgets/text_carousel_modal_content.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/navigation/navigation_tree.dart';
import 'package:frontend/navigation/navigation_functions.dart';
import 'package:frontend/widgets/banner_modo_experimental.dart';
import 'package:frontend/navigation/modal_bottom_sheet_page.dart';
import 'package:frontend/view_functions/offline_markdown.dart';
import 'package:frontend/utils/markdown_utils.dart';
import 'package:frontend/navigation/page_listenable_builder.dart';
import 'package:frontend/theme/theme_controller.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/pages/terms_of_use.dart';
import 'package:frontend/constants/legal_version.g.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:frontend/services/firebase/init_firebase.dart';
import 'package:frontend/services/firebase/remote_config_service.dart';
import 'package:frontend/pages/database_migration_screen.dart';
import 'package:frontend/widgets/app_version_checker.dart';
import 'package:frontend/application_managers/background/background_dispatcher.dart';
import 'package:frontend/application_managers/feedback/feedback_orchestrator.dart';
import 'package:frontend/application_managers/migracao/migracao_background_orchestrator.dart';
import 'package:frontend/services/feedback/network_feedback_trigger.dart';
import 'package:workmanager/workmanager.dart';
import 'package:feedback/feedback.dart';
import 'package:frontend/widgets/feedback/custom_feedback_builder.dart';

void main() async {
  // Garante que o Flutter esteja pronto antes de fazer I/O de arquivo
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Workmanager para processamento de feedback em background
  Workmanager().initialize(callbackDispatcher);

  // Inicialização do Firebase antes de avançar para garantir que telemetria/crashlytics estão prontos
  await initFirebase();

  await ThemeController().loadTheme();

  final prefs = await SharedPreferences.getInstance();

  int? acceptedLegalVersion = prefs.getInt('accepted_legal_version');
  final bool oldAcceptedTerms = prefs.getBool('accepted_terms') ?? false;

  // Migração silenciosa
  if (oldAcceptedTerms && acceptedLegalVersion == null) {
    await prefs.setInt('accepted_legal_version', 1);
    acceptedLegalVersion = 1;
    await prefs.remove('accepted_terms'); // Apaga chave antiga após migrar
  } else if (oldAcceptedTerms) {
    await prefs.remove(
      'accepted_terms',
    ); // Apaga chave antiga se já migrou antes
  }

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

  // Passa isso para o aplicativo
  runApp(
    MyApp(
      datasetRepo: datasetRepo,
      syncService: syncService,
      needsMigration: needsMigration,
      acceptedLegalVersion: acceptedLegalVersion ?? 0,
    ),
  );
}

@visibleForTesting
void registrarOuvintesLiveReload(
  EditorDeCroqui editor,
  DatasetRepository datasetRepo,
  SyncService syncService,
) {
  editor.eventoLiveReload.addListener(() async {
    final evento = editor.eventoLiveReload.value;
    if (evento != null) {
      debugPrint(
        '⚡ [LiveReload] Evento push recebido no Flutter! (Setor/ID: ${evento.setorId}). Disparando sync...',
      );
      await syncService.syncIndex();
      await datasetRepo.init();
      debugPrint(
        '⚡ [LiveReload] Sincronização automática concluída!',
      );
    }
  });
}

@visibleForTesting
Future<bool> setupAppServices(
  DatasetRepository datasetRepo,
  SyncService syncService, {
  Workmanager? workmanager,
}) async {
  // Cancela com segurança qualquer migração em segundo plano ativa (Foreground Takeover)
  await MigracaoBackgroundOrchestrator.cancelarMigracaoSegundoPlano(
    workmanager: workmanager,
  );

  await datasetRepo.init();

  final needsMigration = await syncService.checkNeedsMigration();
  if (!needsMigration) {
    // Roda em background sem dar await
    syncService.syncIndex();
  }
  return needsMigration;
}

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

// Global navigator key to allow overlays to push routes for back button interception
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

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
            themeMode: ThemeMode.dark, // Temporary: locked to dark mode
            theme: ThemeData(
              fontFamily: 'Montserrat',
              useMaterial3: true,
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.light.beastHide,
                brightness: Brightness.light,
                primary: AppColors.light.beastHide,
              ),
              scaffoldBackgroundColor: AppColors.light.slateStone,
              textSelectionTheme: TextSelectionThemeData(
                cursorColor: AppColors.light.fishBone,
                selectionColor: AppColors.light.beastHide.withValues(
                  alpha: 0.3,
                ),
                selectionHandleColor: AppColors.light.beastHide,
              ),
              extensions: const [AppColors.light],
            ),
            darkTheme: ThemeData(
              fontFamily: 'Montserrat',
              useMaterial3: true,
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.dark.beastHide,
                brightness: Brightness.dark,
                primary: AppColors.dark.beastHide,
              ),
              scaffoldBackgroundColor: AppColors.dark.deepBasalt,
              textSelectionTheme: TextSelectionThemeData(
                cursorColor: AppColors.dark.fishBone,
                selectionColor: AppColors.dark.beastHide.withValues(alpha: 0.3),
                selectionHandleColor: AppColors.dark.beastHide,
              ),
              extensions: const [AppColors.dark],
            ),
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
                        if (navContext != null) {
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

/// O ponto de entrada principal para a navegação do aplicativo
class TreeNavigationWrapper extends StatefulWidget {
  final DatasetRepository datasetRepo;
  final SyncService syncService;
  final Widget? child; // Utilizado puramente para injeção em testes

  const TreeNavigationWrapper({
    super.key,
    required this.datasetRepo,
    required this.syncService,
    this.child,
  });

  static final GlobalKey<_TreeNavigationWrapperState> navKey =
      GlobalKey<_TreeNavigationWrapperState>();

  static _TreeNavigationWrapperState of(BuildContext context) {
    return context.findAncestorStateOfType<_TreeNavigationWrapperState>()!;
  }

  @override
  State<TreeNavigationWrapper> createState() => _TreeNavigationWrapperState();

  /// Usado para atalhos do bottom nav
  static void switchTab(int index) {
    navKey.currentState?._onItemTapped(index);
  }

  /// Retorna o controlador de navegação atual (útil para extrair a árvore de navegação globalmente)
  static TreeNavigationController? get currentTreeController =>
      navKey.currentState?.treeController;
}

class _TreeNavigationWrapperState extends State<TreeNavigationWrapper> {
  late final TreeNavigationController treeController;

  SyncService get syncService => widget.syncService;

  @override
  void initState() {
    super.initState();
    treeController = TreeNavigationController();
    treeController.addListener(_onNodeChanged);
    widget.syncService.syncStatus.addListener(_onSyncStatusChanged);
  }

  FeedbackController? _feedbackController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    FeedbackController? controller;
    try {
      controller = BetterFeedback.of(context);
    } catch (_) {
      // Allow it to fail gracefully in tests where BetterFeedback is not in the widget tree.
    }
    
    if (_feedbackController != controller) {
      _feedbackController?.removeListener(_onFeedbackChanged);
      _feedbackController = controller;
      _feedbackController?.addListener(_onFeedbackChanged);
    }
  }

  void _onFeedbackChanged() {
    final isVisible = _feedbackController?.isVisible ?? false;
    
    // Delay the state update by a microtask to prevent state update during build
    // phase if BetterFeedback rebuilds synchronously.
    Future.microtask(() {
      SubmitFeedbackUseCase.isFeedbackOpen.value = isVisible;
    });
  }

  @override
  void dispose() {
    _feedbackController?.removeListener(_onFeedbackChanged);
    widget.syncService.syncStatus.removeListener(_onSyncStatusChanged);
    treeController.removeListener(_onNodeChanged);
    treeController.dispose();
    super.dispose();
  }

  void _onSyncStatusChanged() {
    final status = widget.syncService.syncStatus.value;
    final isAuto = widget.syncService.lastSyncWasAuto.value;

    if (status == SyncStatus.error && isAuto) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Erro ao sincronizar os dados. Tente novamente mais tarde.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } else if (status == SyncStatus.justUpdated && isAuto) {
      final isExperimental =
          widget.datasetRepo.editorDeCroqui.isExperimentalMode.value;
      if (!isExperimental) {
        final croquisAtualizados = widget
            .syncService
            .quantidadeCroquisBaixadosAtualizadosNoUltimoSync
            .value;
        if (croquisAtualizados > 0 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Seus croquis baixados foram atualizados!'),
              backgroundColor: context.colors.dryMoss,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  void _onNodeChanged() {
    final path = treeController.currentNode.path;
    String? currentCragId;

    // Procura na ordem do mais interno (ativo) para o mais externo
    for (final node in path.reversed) {
      if (node is PicoContextNode) {
        currentCragId = node.cragId;
        break;
      }
      if (node is TextNode) {
        currentCragId = node.cragId;
        break;
      }
      if (node is TextCarouselNode) {
        currentCragId = node.cragId;
        break;
      }
      if (node is MapasCarrosselNode) {
        currentCragId = node.cragId;
        break;
      }
    }

    widget.syncService.pico_aberto_id.value = currentCragId;

    setState(() {});
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      if (treeController.currentNode is HomeNode) {
        widget.datasetRepo.triggerHomeReset();
      } else {
        treeController.navigateTo(const HomeNode());
      }
    } else if (index == 1) {
      if (treeController.currentNode is! BrowseNode) {
        treeController.navigateTo(BrowseNode(const HomeNode()));
      }
    } else if (index == 2) {
      if (treeController.currentNode is! MeusCroquisNode) {
        treeController.navigateTo(MeusCroquisNode(const HomeNode()));
      }
    } else if (index == 3) {
      if (treeController.currentNode is! ComunidadeNode) {
        treeController.navigateTo(ComunidadeNode(const HomeNode()));
      }
    }
  }

  /// Constrói o alicerce principal do aplicativo (Tabs).
  /// Esta tela fica perpetuamente na base do Navigator para preservar o estado de rolagem
  /// (scroll) e navegação entre abas usando um `IndexedStack`.
  Widget _buildTabsWidget(NavNode node) {
    int tabIndex = 0;
    if (node is BrowseNode) tabIndex = 1;
    if (node is MeusCroquisNode) tabIndex = 2;
    if (node is ComunidadeNode) tabIndex = 3;

    return Scaffold(
      body: IndexedStack(
        index: tabIndex,
        children: [
          _HomePageWrapper(
            datasetRepo: widget.datasetRepo,
            syncService: widget.syncService,
            onSwitchTab: _onItemTapped,
          ),
          BrowsePage(
            datasetRepo: widget.datasetRepo,
            syncService: widget.syncService,
          ),
          MeusCroquisPage(
            datasetRepo: widget.datasetRepo,
            syncService: widget.syncService,
          ),
          const ComunidadePage(), // Pass dependencies if needed in the future
        ],
      ),
      bottomNavigationBar: buildPrimaryBottomNav(
        context,
        tabIndex,
        _onItemTapped,
      ),
    );
  }

  /// Resolve e constrói a página (Widget) correspondente a um nó (NavNode) da árvore de roteamento.
  Widget _buildNodeAsWidget(NavNode node) {
    if (node is PicoNode ||
        node is SetoresNode ||
        node is ExplorarLocalNode ||
        node is ComunidadePicoNode ||
        node is ApoiePicoNode ||
        node is SetorNode ||
        node is GrupoNode ||
        node is ViaNode ||
        node is TextNode ||
        node is TextCarouselNode ||
        node is MapasCarrosselNode) {
      String cragId = '';
      String? setorNome;
      String? grupoNome;
      String? escaladaNome;

      if (node is PicoContextNode) cragId = node.cragId;
      if (node is TextNode) cragId = node.cragId;
      if (node is TextCarouselNode) cragId = node.cragId;
      if (node is MapasCarrosselNode) cragId = node.cragId;

      if (node is SetorNode) {
        setorNome = node.setorNome;
        grupoNome = node.grupoNome;
      }
      if (node is ViaNode) {
        escaladaNome = node.escaladaNome;
        setorNome = node.setorNome;
        grupoNome = node.grupoNome;
      }
      if (node is GrupoNode) grupoNome = node.grupoNome;

      return PageListenableBuilder(
        cragId: cragId,
        datasetRepo: widget.datasetRepo,
        setorNome: setorNome,
        grupoNome: grupoNome,
        escaladaNome: escaladaNome,
        builder: (context, pico, croqui, setor, grupo, escalada) {
          if (node is PicoNode) {
            Setor? returnToSetor;
            if (node.returnToSetorNome != null) {
              try {
                returnToSetor = pico.setoresOuGrupos
                    .where(
                      (sg) =>
                          sg.whichTipo() == SetorOuGrupo_Tipo.setor &&
                          sg.setor.hasConteudo(),
                    )
                    .map((sg) => sg.setor.conteudo)
                    .firstWhere((s) => s.nome == node.returnToSetorNome);
              } catch (_) {}
            }
            return PicoDetailsPage(
              pico: pico,
              croqui: croqui,
              cragId: cragId,
              datasetRepo: widget.datasetRepo,
              scrollToMapaGeral: node.scrollToMapaGeral,
              returnToSetor: returnToSetor,
            );
          } else if (node is SetoresNode) {
            return SetoresPage(pico: pico, cragId: cragId);
          } else if (node is ExplorarLocalNode) {
            return ExplorarLocalPage(
              pico: pico,
              cragId: cragId,
              categories: PicoCategorizedData(croqui),
            );
          } else if (node is ComunidadePicoNode) {
            return ComunidadePicoPage(
              pico: pico,
              cragId: cragId,
              categories: PicoCategorizedData(croqui),
            );
          } else if (node is ApoiePicoNode) {
            return ApoiePicoPage(
              pico: pico,
              cragId: cragId,
              categories: PicoCategorizedData(croqui),
            );
          } else if (node is MapasCarrosselNode) {
            return MapasCarrosselPage(
              pico: pico,
              cragId: cragId,
              mapas: node.mapas,
              initialIndex: node.initialIndex,
              imageProviderOverride: node.imageProviderOverride,
            );
          } else if (node is SetorNode) {
            Escalada? scrollToEscalada;
            if (node.scrollToEscaladaNome != null && setor != null) {
              try {
                scrollToEscalada = setor.escaladas.firstWhere((e) {
                  if (e.hasViaEsportiva()) {
                    return e.viaEsportiva.nome == node.scrollToEscaladaNome;
                  }
                  if (e.hasViaMovel()) {
                    return e.viaMovel.nome == node.scrollToEscaladaNome;
                  }
                  if (e.hasBoulder()) {
                    return e.boulder.nome == node.scrollToEscaladaNome;
                  }
                  if (e.hasViaMultiplasEnfiadas()) {
                    return e.viaMultiplasEnfiadas.nome ==
                        node.scrollToEscaladaNome;
                  }
                  if (e.hasHighline()) {
                    return e.highline.nome == node.scrollToEscaladaNome;
                  }
                  return false;
                });
              } catch (_) {}
            }
            if (setor != null) {
              return SetorPage(
                setor: setor,
                grupoContext: grupo,
                cragId: cragId,
                scrollToEscalada: scrollToEscalada,
              );
            } else {
              return const Scaffold();
            }
          } else if (node is GrupoNode) {
            return GrupoPage(grupo: grupo!, cragId: cragId);
          } else if (node is ViaNode) {
            return ViaPage(
              pico: pico,
              escalada: escalada!,
              setor: setor,
              grupo: grupo,
              cragId: cragId,
            );
          }
          return const Scaffold();
        },
      );
    }

    if (node is MapaGlobalNode) {
      return MapaGlobalPage(
        crags: node.crags,
        datasetRepo: widget.datasetRepo,
        syncService: widget.syncService,
      );
    }

    if (node is GPSNode) {
      return GPSPage(datasetRepo: widget.datasetRepo);
    }

    if (node is SettingsNode) {
      return SettingsPage(datasetRepo: widget.datasetRepo);
    }

    if (node is SobreTimeNode) {
      return const SobreTimePage();
    }

    return const Center(child: Text('Unknown Node'));
  }

  @override
  Widget build(BuildContext context) {
    // 1. Extraímos o caminho completo da raiz até o nó atual
    final fullPath = treeController.currentNode.path;

    // 2. A página base é estritamente a nossa aba (Home, Settings, Browse).
    // Como ela contém um IndexedStack, evitamos desmontá-la para preservar scrolls infinitos e abas de usuário.
    final baseNode = fullPath.lastWhere(
      (n) =>
          n is HomeNode ||
          n is MeusCroquisNode ||
          n is BrowseNode ||
          n is ComunidadeNode,
      orElse: () => const HomeNode(),
    );

    // 3. Todo o resto dos nós (croquis, setores, mapas, modais) que vêm após a aba principal são separados...
    // Agora INCLUÍMOS o TextNode, pois ele mapeia para um ModalBottomSheetPage!
    final pushedNodes = fullPath
        .where(
          (n) =>
              !(n is HomeNode ||
                  n is MeusCroquisNode ||
                  n is BrowseNode ||
                  n is ComunidadeNode),
        )
        .toList();

    // 4. ... e magicamente empilhados por cima da aba base de forma declarativa!
    final pages = <Page>[
      MaterialPage(
        key: const ValueKey(
          'TabsPage',
        ), // Chave constante: Impede que o Flutter reconstrua a base desnecessariamente!
        child: _buildTabsWidget(baseNode),
      ),
      ...pushedNodes.map((node) {
        if (node is TextNode) {
          return ModalBottomSheetPage(
            key: ValueKey(node.toString()),
            isScrollControlled: true,
            builder: (context) {
              return DraggableScrollableSheet(
                initialChildSize: 0.6,
                minChildSize: 0.4,
                maxChildSize: 0.9,
                expand: false,
                builder: (context, scrollController) {
                  final bottomPadding = MediaQuery.of(context).padding.bottom;
                  return ListView(
                    controller: scrollController,
                    padding: EdgeInsets.only(
                      top: 20,
                      left: 20,
                      right: 20,
                      bottom: 20 + bottomPadding,
                    ),
                    children: [
                      Column(
                        children: [
                          Center(
                            child: Container(
                              width: 32,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: AppColors.brandColor.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    if (node.icon != null) ...[
                                      Icon(node.icon, color: AppColors.brandColor, size: 24),
                                      const SizedBox(width: 8),
                                    ],
                                    Expanded(
                                      child: Text(
                                        node.title.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              buildFeedbackButton(context, color: Colors.white),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Builder(
                        builder: (context) {
                          final content = MarkdownUtils.cleanModalContent(
                            node.content,
                            node.title,
                          );
                          return OfflineMarkdown(
                            data: content,
                            cragId: node.cragId,
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
          );
        }
        if (node is TextCarouselNode) {
          return ModalBottomSheetPage(
            key: ValueKey(node.toString()),
            isScrollControlled: true,
            builder: (context) {
              return DraggableScrollableSheet(
                initialChildSize: 0.6,
                minChildSize: 0.4,
                maxChildSize: 0.9,
                expand: false,
                builder: (context, scrollController) {
                  return TextCarouselModalContent(
                    node: node,
                    scrollController: scrollController,
                  );
                },
              );
            },
          );
        }
        return MaterialPage(
          key: ValueKey(node.toString()), // Identificação estrita dos nós
          child: _buildNodeAsWidget(node),
        );
      }),
    ];

    final navigator = Navigator(
      pages: pages,
      // Define o comportamento de quando um comando imperativo como `Navigator.pop(context)` for chamado diretamente neste Navigator.
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false; // Rejeitado
        }
        // Garante sincronia: a rota saiu da UI, devemos retirá-la da nossa Tree Controller
        treeController.goBack();
        return true; // Sucesso, de acordo com as especificações do Flutter Navigator 2.0
      },
    );
    return PopScope(
      canPop: false, // Never let the OS exit directly; handle it explicitly in onPopInvoked
      onPopInvoked: (didPop) {
        if (didPop) return;

        // Check if feedback is currently open
        if (SubmitFeedbackUseCase.isFeedbackOpen.value) {
          BetterFeedback.of(context).hide();
          SubmitFeedbackUseCase.isFeedbackOpen.value = false;
          return;
        }

        bool canGoBack = treeController.goBack();
        if (!canGoBack) {
          // If we are at the root of a tab that is NOT the Home tab, switch to the Home tab.
          if (treeController.currentNode is! HomeNode) {
            TreeNavigationWrapper.switchTab(0);
            return;
          }
          
          // Now it is safe to exit the app.
          SystemNavigator.pop();
        }
      },
      child: navigator,
    );
  }
}

class _HomePageWrapper extends StatelessWidget {
  final DatasetRepository datasetRepo;
  final SyncService syncService;
  final Function(int) onSwitchTab;

  const _HomePageWrapper({
    required this.datasetRepo,
    required this.syncService,
    required this.onSwitchTab,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: datasetRepo.homeResetTrigger,
      builder: (context, counter, child) {
        return HomePage(
          key: ValueKey(counter),
          datasetRepo: datasetRepo,
          syncService: syncService,
          onSwitchTab: onSwitchTab,
        );
      },
    );
  }
}
