// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:frontend/application_managers/feedback/caso_uso_enviar_feedback.dart';
import 'package:frontend/navigation/servico_navegacao_deep_link.dart';
import 'package:frontend/navigation/gerenciador_deep_links.dart';
import 'package:frontend/navigation/arvore_navegacao.dart';
import 'package:frontend/navigation/construtor_view_arvore.dart';
import 'package:frontend/pages/explorar.dart';
import 'package:frontend/pages/comunidade.dart';
import 'package:frontend/pages/home.dart';
import 'package:frontend/pages/meus_croquis.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/view/function_library/biblioteca_funcoes_comuns.dart';
import 'package:frontend/view/view_models/explorar_view_model.dart';
import 'package:frontend/view/view_models/home_view_model.dart';
import 'package:frontend/view/view_models/meus_croquis_view_model.dart';

/// O ponto de entrada principal para a navegação do aplicativo.
///
/// Orquestra a árvore de navegação reativa ([TreeNavigationController]), mantendo as abas
/// principais (Home, Browse, Meus Croquis, Comunidade) em um [IndexedStack] persistente
/// e empilhando telas e modais filhos de forma declarativa e resiliente a vazamentos de memória.
class TreeNavigationWrapper extends StatefulWidget {
  final DatasetRepository datasetRepo;
  final SyncService syncService;
  final TreeNavigationController? treeController;
  final GerenciadorDeepLinks? gerenciadorDeepLinks;
  final Widget? child; // Utilizado puramente para injeção em testes

  const TreeNavigationWrapper({
    super.key,
    required this.datasetRepo,
    required this.syncService,
    this.treeController,
    this.gerenciadorDeepLinks,
    this.child,
  });

  static final GlobalKey<TreeNavigationWrapperState> navKey =
      GlobalKey<TreeNavigationWrapperState>();

  /// Permite que widgets filhos acessem o estado do Wrapper de forma segura.
  // ignore: unreachable_from_main
  static TreeNavigationWrapperState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<TreeNavigationWrapperState>();
  }

  /// Permite que widgets filhos acessem o estado do Wrapper.
  // ignore: unreachable_from_main
  static TreeNavigationWrapperState of(BuildContext context) {
    return context.findAncestorStateOfType<TreeNavigationWrapperState>()!;
  }

  @override
  State<TreeNavigationWrapper> createState() => TreeNavigationWrapperState();

  /// Usado para atalhos do bottom nav
  static void switchTab(int index) {
    navKey.currentState?._onItemTapped(index);
  }

  /// Retorna o controlador de navegação atual (útil para extrair a árvore de navegação globalmente)
  // ignore: unreachable_from_main
  static TreeNavigationController? get currentTreeController =>
      navKey.currentState?.treeController;
}

class TreeNavigationWrapperState extends State<TreeNavigationWrapper> {
  late final TreeNavigationController treeController;
  late final DeepLinkNavigatorService deepLinkNavigator;
  late final GerenciadorDeepLinks gerenciadorDeepLinks;
  late final HomeViewModel _homeViewModel;
  late final BrowseViewModel _browseViewModel;
  late final MeusCroquisViewModel _meusCroquisViewModel;
  FeedbackController? _feedbackController;

  /// Expõe o SyncService para páginas filhas acessarem via TreeNavigationWrapper.of(context).
  // ignore: unreachable_from_main
  SyncService get syncService => widget.syncService;

  @override
  void initState() {
    super.initState();
    _homeViewModel = HomeViewModel(
      datasetRepo: widget.datasetRepo,
      syncService: widget.syncService,
    );
    _browseViewModel = BrowseViewModel(
      datasetRepo: widget.datasetRepo,
      syncService: widget.syncService,
    );
    _meusCroquisViewModel = MeusCroquisViewModel(
      datasetRepo: widget.datasetRepo,
      syncService: widget.syncService,
    );

    treeController = widget.treeController ?? TreeNavigationController();
    treeController.addListener(_onNodeChanged);
    widget.syncService.syncStatus.addListener(_onSyncStatusChanged);
    widget.datasetRepo.notificadorCroquiAtualizado.addListener(_onCroquiOnlineAtualizado);

    deepLinkNavigator = DeepLinkNavigatorService(
      datasetRepo: widget.datasetRepo,
      treeController: treeController,
    );
    gerenciadorDeepLinks = widget.gerenciadorDeepLinks ??
        GerenciadorDeepLinks(navigatorService: deepLinkNavigator);
    gerenciadorDeepLinks.inicializar();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    FeedbackController? controller;
    try {
      controller = BetterFeedback.of(context);
    } catch (_) {
      // Permite falha graciosa em testes onde BetterFeedback não está na árvore de widgets.
    }

    if (_feedbackController != controller) {
      _feedbackController?.removeListener(_onFeedbackChanged);
      _feedbackController = controller;
      _feedbackController?.addListener(_onFeedbackChanged);
    }
  }

  void _onFeedbackChanged() {
    final isVisible = _feedbackController?.isVisible ?? false;

    // Posterga a atualização para evitar erro de setState durante a fase de build
    Future.microtask(() {
      SubmitFeedbackUseCase.isFeedbackOpen.value = isVisible;
    });
  }

  @override
  void dispose() {
    _homeViewModel.dispose();
    _browseViewModel.dispose();
    _meusCroquisViewModel.dispose();
    gerenciadorDeepLinks.dispose();
    _feedbackController?.removeListener(_onFeedbackChanged);
    widget.datasetRepo.notificadorCroquiAtualizado.removeListener(_onCroquiOnlineAtualizado);
    widget.syncService.syncStatus.removeListener(_onSyncStatusChanged);
    treeController.removeListener(_onNodeChanged);
    treeController.dispose();
    super.dispose();
  }

  void _onCroquiOnlineAtualizado() {
    final nomeOuId = widget.datasetRepo.notificadorCroquiAtualizado.value;
    if (nomeOuId == null || !mounted) return;

    final isExperimental =
        widget.datasetRepo.editorDeCroqui.isExperimentalMode.value;
    if (!isExperimental) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('O guia de $nomeOuId foi atualizado!'),
          backgroundColor: context.colors.dryMoss,
          duration: const Duration(seconds: 4),
        ),
      );
    }
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

    widget.syncService.picoAbertoId.value = currentCragId;

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
            viewModel: _homeViewModel,
            onSwitchTab: _onItemTapped,
          ),
          BrowsePage(
            viewModel: _browseViewModel,
          ),
          MeusCroquisPage(
            viewModel: _meusCroquisViewModel,
          ),
          const ComunidadePage(),
        ],
      ),
      bottomNavigationBar: buildPrimaryBottomNav(
        context,
        tabIndex,
        _onItemTapped,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.child != null) {
      return widget.child!;
    }

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
    final pushedNodes = fullPath
        .where(
          (n) =>
              !(n is HomeNode ||
                  n is MeusCroquisNode ||
                  n is BrowseNode ||
                  n is ComunidadeNode),
        )
        .toList();

    // 4. ... e empilhados por cima da aba base de forma declarativa!
    final pages = <Page>[
      MaterialPage(
        key: const ValueKey('TabsPage'),
        child: _buildTabsWidget(baseNode),
      ),
      ...pushedNodes.map((node) {
        final modalPage = construirPaginaModalParaNo(node);
        if (modalPage != null) {
          return modalPage;
        }

        return MaterialPage(
          key: ValueKey(node.toString()),
          child: construirPaginaParaNo(
            node: node,
            datasetRepo: widget.datasetRepo,
            syncService: widget.syncService,
          ),
        );
      }),
    ];

    final navigator = Navigator(
      pages: pages,
      onDidRemovePage: (page) {
        treeController.goBack();
      },
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // Se o feedback estiver aberto, apenas feche o feedback
        if (SubmitFeedbackUseCase.isFeedbackOpen.value) {
          BetterFeedback.of(context).hide();
          SubmitFeedbackUseCase.isFeedbackOpen.value = false;
          return;
        }

        bool canGoBack = treeController.goBack();
        if (!canGoBack) {
          // Se estiver na raiz de uma aba secundária, volte para a aba Home
          if (treeController.currentNode is! HomeNode) {
            TreeNavigationWrapper.switchTab(0);
            return;
          }

          // Caso já esteja na raiz da Home, permite o encerramento do app pelo SO
          SystemNavigator.pop();
        }
      },
      child: navigator,
    );
  }
}

/// Envoltório reativo da página inicial para forçar recarregamento sob reset explícito.
class _HomePageWrapper extends StatelessWidget {
  final HomeViewModel viewModel;
  final Function(int) onSwitchTab;

  const _HomePageWrapper({
    required this.viewModel,
    required this.onSwitchTab,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: viewModel.datasetRepo.homeResetTrigger,
      builder: (context, counter, child) {
        return HomePage(
          key: ValueKey(counter),
          viewModel: viewModel,
          onSwitchTab: onSwitchTab,
        );
      },
    );
  }
}

/// Alias em português brasileiro para [TreeNavigationWrapper].
typedef WrapperNavegacaoArvore = TreeNavigationWrapper;
typedef WrapperNavegacaoArvoreState = TreeNavigationWrapperState;

