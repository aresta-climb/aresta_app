import 'package:flutter/material.dart';
import 'package:frontend/pages/home.dart';
import 'package:frontend/pages/browse.dart';
import 'package:frontend/pages/settings.dart';
import 'package:frontend/pages/gps.dart';
import 'package:frontend/pages/pico.dart';
import 'package:frontend/pages/setor.dart';
import 'package:frontend/pages/grupo.dart';
import 'package:frontend/pages/via.dart';
import 'package:frontend/pages/mapa_interativo.dart';
import 'package:frontend/pages/mapa_geral_pico.dart';
import 'package:frontend/pages/mapao_global.dart';
import 'package:frontend/view_functions/common_functions.dart';
import 'package:frontend/view_functions/pico_functions.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/navigation/navigation_tree.dart';
import 'package:frontend/navigation/page_listenable_builder.dart';
import 'package:frontend/theme/theme_controller.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/pages/terms_of_use.dart';
import 'package:frontend/constants/legal_version.g.dart';

import 'package:frontend/services/firebase/init_firebase.dart';

void main() async {
  // Garante que o Flutter esteja pronto antes de fazer I/O de arquivo
  WidgetsFlutterBinding.ensureInitialized();

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

  // Sincronização inicial na inicialização
  syncService.syncIndex();

  // Passa isso para o aplicativo
  runApp(
    MyApp(
      datasetRepo: datasetRepo,
      syncService: syncService,
      acceptedLegalVersion: acceptedLegalVersion ?? 0,
    ),
  );
}

class MyApp extends StatefulWidget {
  final DatasetRepository datasetRepo;
  final SyncService syncService;
  final int acceptedLegalVersion;
  final AssetBundle? assetBundle;

  const MyApp({
    super.key,
    required this.datasetRepo,
    required this.syncService,
    required this.acceptedLegalVersion,
    this.assetBundle,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late int _acceptedLegalVersion;

  @override
  void initState() {
    super.initState();
    _acceptedLegalVersion = widget.acceptedLegalVersion;
  }

  void _onTermsAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('accepted_legal_version', kLegalVersion);
    await prefs.setString('accepted_legal_timestamp', DateTime.now().toIso8601String());
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
        return MaterialApp(
          title: 'Aresta Climb',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            fontFamily: 'Montserrat',
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.light.beastHide,
              brightness: Brightness.light,
              primary: AppColors.light.beastHide,
            ),
            scaffoldBackgroundColor: AppColors.light.nobleBlack,
            textSelectionTheme: TextSelectionThemeData(
              cursorColor: AppColors.light.fishBone,
              selectionColor: AppColors.light.beastHide.withValues(alpha: 0.3),
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
            scaffoldBackgroundColor: AppColors.dark.nobleBlack,
            textSelectionTheme: TextSelectionThemeData(
              cursorColor: AppColors.dark.fishBone,
              selectionColor: AppColors.dark.beastHide.withValues(alpha: 0.3),
              selectionHandleColor: AppColors.dark.beastHide,
            ),
            extensions: const [AppColors.dark],
          ),
          // Banner global para modo experimental/editor que persiste em todas as telas
          builder: (context, child) {
            return Stack(
              children: [
                child!,
                ValueListenableBuilder<bool>(
                  valueListenable:
                      widget.datasetRepo.editorDeCroqui.isExperimentalMode,
                  builder: (context, isExperimental, _) {
                    return ValueListenableBuilder<String?>(
                      valueListenable:
                          widget.datasetRepo.editorDeCroqui.editorUrl,
                      builder: (context, editorUrl, _) {
                        final isEditor = isExperimental;
                        if (!isEditor) return const SizedBox.shrink();

                        String bannerText = 'MODO EXPERIMENTAL ATIVO (LOCAL)';

                        return Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Material(
                            color: Colors.transparent,
                            child: ValueListenableBuilder<Duration?>(
                              valueListenable: widget
                                  .datasetRepo
                                  .editorDeCroqui
                                  .timeRemaining,
                              builder: (context, remaining, _) {
                                String timerText = '';
                                if (remaining != null) {
                                  final minutes = remaining.inMinutes
                                      .toString()
                                      .padLeft(2, '0');
                                  final seconds = (remaining.inSeconds % 60)
                                      .toString()
                                      .padLeft(2, '0');
                                  timerText = ' ($minutes:$seconds)';
                                }

                                return Container(
                                  padding: EdgeInsets.only(
                                    top: MediaQuery.of(context).padding.top + 2,
                                    bottom: 4,
                                  ),
                                  color: Colors.red.withValues(alpha: 0.7),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '$bannerText$timerText',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
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
        );
      },
    );
  }
}

/// O ponto de entrada principal para a navegação do aplicativo
class TreeNavigationWrapper extends StatefulWidget {
  final DatasetRepository datasetRepo;
  final SyncService syncService;

  const TreeNavigationWrapper({
    super.key,
    required this.datasetRepo,
    required this.syncService,
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
}

class _TreeNavigationWrapperState extends State<TreeNavigationWrapper> {
  late final TreeNavigationController treeController;

  @override
  void initState() {
    super.initState();
    treeController = TreeNavigationController();
    treeController.addListener(_onNodeChanged);
    widget.syncService.syncStatus.addListener(_onSyncStatusChanged);
  }

  @override
  void dispose() {
    widget.syncService.syncStatus.removeListener(_onSyncStatusChanged);
    treeController.removeListener(_onNodeChanged);
    treeController.dispose();
    super.dispose();
  }

  void _onSyncStatusChanged() {
    if (widget.syncService.syncStatus.value == SyncStatus.error &&
        widget.syncService.lastSyncWasAuto.value) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Falha na sincronização em segundo plano. Verifique sua conexão.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _onNodeChanged() {
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
      if (treeController.currentNode is! SettingsNode) {
        treeController.navigateTo(SettingsNode(const HomeNode()));
      }
    } else if (index == 2) {
      if (treeController.currentNode is! BrowseNode) {
        treeController.navigateTo(BrowseNode(const HomeNode()));
      }
    }
    // index == 3 (GPS) is handled via AppNav.toGPS from the secondary bottom nav
  }

  Widget _buildCurrentNode() {
    final node = treeController.currentNode;

    // Use IndexedStack for top-level tabs to preserve their state
    if (node is HomeNode || node is SettingsNode || node is BrowseNode) {
      int tabIndex = 0;
      if (node is SettingsNode) tabIndex = 1;
      if (node is BrowseNode) tabIndex = 2;

      return Scaffold(
        body: IndexedStack(
          index: tabIndex,
          children: [
            _HomePageWrapper(
              datasetRepo: widget.datasetRepo,
              syncService: widget.syncService,
              onSwitchTab: _onItemTapped,
            ),
            SettingsPage(datasetRepo: widget.datasetRepo),
            BrowsePage(
              datasetRepo: widget.datasetRepo,
              syncService: widget.syncService,
            ),
          ],
        ),
        bottomNavigationBar: buildPrimaryBottomNav(
          context,
          tabIndex,
          _onItemTapped,
        ),
      );
    }

    if (node is PicoNode ||
        node is SetorNode ||
        node is GrupoNode ||
        node is ViaNode ||
        node is MapaGeralPicoNode ||
        node is MapaInterativoNode) {
      String cragId = '';
      String? setorNome;
      String? grupoNome;
      String? escaladaNome;

      if (node is PicoContextNode) cragId = node.cragId;
      if (node is MapaInterativoNode) cragId = node.cragId;

      if (node is SetorNode) setorNome = node.setorNome;
      if (node is ViaNode) {
        escaladaNome = node.escaladaNome;
        setorNome = node.setorNome;
      }
      if (node is GrupoNode) grupoNome = node.grupoNome;
      if (node is MapaInterativoNode) setorNome = node.setorContextNome;

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
                    .where((sg) => sg.whichTipo() == SetorOuGrupo_Tipo.setor && sg.setor.hasConteudo())
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
          } else if (node is MapaInterativoNode) {
            Mapa? mapa;
            for (var sg in pico.setoresOuGrupos) {
              if (sg.whichTipo() == SetorOuGrupo_Tipo.setor && sg.setor.hasConteudo()) {
                for (var m in sg.setor.conteudo.mapas) {
                  if (m.caminhoImagemMapa == node.mapaCaminhoImagem) {
                    mapa = m;
                    break;
                  }
                }
              } else if (sg.whichTipo() == SetorOuGrupo_Tipo.grupo && sg.grupo.hasConteudo()) {
                for (var m in sg.grupo.conteudo.mapas) {
                  if (m.caminhoImagemMapa == node.mapaCaminhoImagem) {
                    mapa = m;
                    break;
                  }
                }
              }
              if (mapa != null) break;
            }
            if (mapa == null) {
              // Map might be in a via (Multipitch etc)
              for (var esc in getAllEscaladasFromPico(pico)) {
                if (esc.hasViaMultiplasEnfiadas()) {
                  for (var m in esc.viaMultiplasEnfiadas.mapas) {
                    if (m.caminhoImagemMapa == node.mapaCaminhoImagem) {
                      mapa = m;
                      break;
                    }
                  }
                }
                if (mapa != null) break;
              }
            }
            // Coleta todas as escaladas do pico ou setor dependendo do contexto
            List<Escalada> escaladas = [];
            if (setor != null) {
              escaladas = setor.escaladas;
            } else {
              for (var sg in pico.setoresOuGrupos) {
                if (sg.whichTipo() == SetorOuGrupo_Tipo.setor && sg.setor.hasConteudo()) {
                  escaladas.addAll(sg.setor.conteudo.escaladas);
                } else if (sg.whichTipo() == SetorOuGrupo_Tipo.grupo && sg.grupo.hasConteudo()) {
                  for (var s in sg.grupo.conteudo.setores) {
                    if (s.hasConteudo()) escaladas.addAll(s.conteudo.escaladas);
                  }
                }
              }
            }
            return MapaInterativoPage(
              mapa: mapa ?? Mapa(),
              cragId: cragId,
              escaladas: escaladas,
              setores: pico.setoresOuGrupos
                  .where((sg) => sg.whichTipo() == SetorOuGrupo_Tipo.setor)
                  .map((sg) => sg.setor)
                  .toList(),
              initialSelectedId: node.initialSelectedId,
              setorContext: setor,
            );
          } else if (node is MapaGeralPicoNode) {
            Setor? returnToSetor;
            if (node.returnToSetorNome != null) {
              try {
                returnToSetor = pico.setoresOuGrupos
                    .where((sg) => sg.whichTipo() == SetorOuGrupo_Tipo.setor && sg.setor.hasConteudo())
                    .map((sg) => sg.setor.conteudo)
                    .firstWhere((s) => s.nome == node.returnToSetorNome);
              } catch (_) {}
            }
            return MapaGeralPicoPage(
              pico: pico,
              croqui: croqui,
              cragId: cragId,
              returnToSetor: returnToSetor,
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
                    return e.viaMultiplasEnfiadas.nome == node.scrollToEscaladaNome;
                  }
                  if (e.hasHighline()) {
                    return e.highline.nome == node.scrollToEscaladaNome;
                  }
                  return false;
                });
              } catch (_) {}
            }
            return SetorPage(
              setor: setor!,
              cragId: cragId,
              scrollToEscalada: scrollToEscalada,
            );
          } else if (node is GrupoNode) {
            return GrupoPage(grupo: grupo!, cragId: cragId);
          } else if (node is ViaNode) {
            return ViaPage(
              escalada: escalada!,
              setor: setor,
              cragId: cragId,
            );
          }
          return const Scaffold();
        },
      );
    }

    if (node is MapaoGlobalNode) {
      return MapaoGlobalPage(
        crags: node.crags,
        datasetRepo: widget.datasetRepo,
        syncService: widget.syncService,
      );
    }

    if (node is GPSNode) {
      return GPSPage(datasetRepo: widget.datasetRepo);
    }

    return const Center(child: Text('Unknown Node'));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: treeController.currentNode.parent == null,
      onPopInvoked: (didPop) {
        if (didPop) return;
        treeController.goBack();
      },
      child: _buildCurrentNode(),
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
