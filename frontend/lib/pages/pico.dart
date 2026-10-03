// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:frontend/main.dart';
import 'package:flutter/material.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../view/function_library/biblioteca_funcoes_comuns.dart';
import '../view/function_library/pico_functions.dart';
import '../view/function_library/funcoes_explorar.dart';
import '../view/function_library/via_functions.dart';
import '../navigation/funcoes_navegacao.dart';
import '../navigation/arvore_navegacao.dart';
import '../services/firebase/telemetria.dart';
import '../services/firebase/app_logger.dart';
import '../theme/cores_app.dart';

// New imports for sub-pages
import '../widgets/bottom_sheets/regras_bottom_sheet.dart';
import '../widgets/pico_menu_card.dart';
import '../utils/construtor_caminho_trajeto.dart';
import '../widgets/banner_modo_online.dart';
import '../widgets/linha_credito_autor.dart';
import '../widgets/modal_confirmacao_saida.dart';
import '../view/view_models/pico_view_model.dart';

class PicoDetailsPage extends StatefulWidget {
  final PicoViewModel viewModel;
  final bool scrollToMapaGeral;
  final Setor? returnToSetor;

  const PicoDetailsPage({
    super.key,
    required this.viewModel,
    this.scrollToMapaGeral = false,
    this.returnToSetor,
  });

  String get cragId => viewModel.cragId;
  Pico get pico => viewModel.pico;
  Croqui get croqui => viewModel.croqui;

  @override
  State<PicoDetailsPage> createState() => _PicoDetailsPageState();
}

class _PicoDetailsPageState extends State<PicoDetailsPage> {
  final GlobalKey _mapaKey = GlobalKey();
  late final PicoViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel;
    _viewModel.addListener(_aoAtualizarViewModel);

    // Registra interceptor de saída no controlador de navegação em árvore
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _setupBackInterceptor();
    });

    if (widget.scrollToMapaGeral) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final targetContext = _mapaKey.currentContext;
          if (targetContext != null) {
            final renderObject = targetContext.findRenderObject();
            if (renderObject is RenderBox &&
                renderObject.attached &&
                renderObject.hasSize) {
              try {
                Scrollable.ensureVisible(
                  targetContext,
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOut,
                  alignment: 0.1,
                );
              } catch (e, stackTrace) {
                AppLogger.instance.logError(
                  '[PicoDetailsPage] Falha ao rolar para mapa geral',
                  error: e,
                  stackTrace: stackTrace,
                );
              }
            }
          }
        });
      });
    }
  }

  void _aoAtualizarViewModel() {
    if (!mounted) return;
    if (_viewModel.isDownloaded) {
      final tree = TreeNavigationWrapper.maybeOf(context)?.treeController ??
          TreeNavigationWrapper.currentTreeController;
      if (tree != null && tree.onBackInterceptor != null) {
        tree.onBackInterceptor = null;
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setupBackInterceptor();
  }

  void _setupBackInterceptor() {
    final tree = TreeNavigationWrapper.maybeOf(context)?.treeController ??
        TreeNavigationWrapper.currentTreeController;
    if (tree == null) return;

    tree.onBackInterceptor = () {
      final parentNode = tree.currentNode.parent;
      final staysInSameCroqui =
          parentNode is PicoContextNode && parentNode.cragId == widget.cragId;

      if (!_viewModel.deveInterceptarSaida(staysInSameCroqui: staysInSameCroqui)) {
        tree.onBackInterceptor = null;
        return false;
      }

      ModalConfirmacaoSaida.mostrar(
        context: context,
        nomePico: widget.pico.nome,
        cragId: widget.cragId,
        tamanhoFormatado: _viewModel.tamanhoFormatado,
        onSalvar: () {
          _iniciarDownload();
          tree.onBackInterceptor = null;
          if (context.mounted && AppNav.canGoBack(context)) {
            AppNav.back(context);
          }
        },
        onSairSemSalvar: () {
          tree.onBackInterceptor = null;
          if (context.mounted && AppNav.canGoBack(context)) {
            AppNav.back(context);
          }
        },
      );
      return true;
    };
  }

  @override
  void dispose() {
    ConstrutorCaminhoTrajeto.limparCache();
    _viewModel.removeListener(_aoAtualizarViewModel);
    final tree = TreeNavigationWrapper.currentTreeController;
    if (tree != null) {
      tree.onBackInterceptor = null;
    }
    _viewModel.dispose();
    super.dispose();
  }

  void _iniciarDownload() async {
    final tree = TreeNavigationWrapper.maybeOf(context);
    final syncService = tree?.syncService;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text('Baixando ${widget.pico.nome}...')));

    final success = await _viewModel.baixarPico(syncService: syncService);

    if (!mounted) return;

    if (success) {
      final currentTree = TreeNavigationWrapper.maybeOf(context)?.treeController ??
          TreeNavigationWrapper.currentTreeController;
      if (currentTree != null) {
        currentTree.onBackInterceptor = null;
      }
    }

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '${widget.pico.nome} salvo offline!'
                : 'Falha ao baixar ${widget.pico.nome}',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
  }


  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            final tree = TreeNavigationWrapper.maybeOf(context)?.treeController;
            final parentNode = tree?.currentNode.parent;
            final staysInSameCroqui =
                parentNode is PicoContextNode && parentNode.cragId == widget.cragId;

            if (!_viewModel.deveInterceptarSaida(staysInSameCroqui: staysInSameCroqui)) {
              if (context.mounted && AppNav.canGoBack(context)) {
                AppNav.back(context);
              }
              return;
            }

            ModalConfirmacaoSaida.mostrar(
              context: context,
              nomePico: widget.pico.nome,
              tamanhoFormatado: _viewModel.tamanhoFormatado,
              onSalvar: () {
                _iniciarDownload();
                if (context.mounted && AppNav.canGoBack(context)) {
                  AppNav.back(context);
                }
              },
              onSairSemSalvar: () {
                if (context.mounted && AppNav.canGoBack(context)) {
                  AppNav.back(context);
                }
              },
            );
          },
          child: Scaffold(
        backgroundColor: context.colors.deepBasalt,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 300.0,
              pinned: true,
              backgroundColor: context.colors.deepBasalt,
              iconTheme: IconThemeData(color: context.colors.chalkWhite),
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.circle,
                  ),
                  child: BackButton(
                    color: Colors.white,
                    onPressed: () {
                      AppNav.back(context);
                    },
                  ),
                ),
              ),
              flexibleSpace: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final top = constraints.biggest.height;
                  final collapsedHeight =
                      MediaQuery.of(context).padding.top + kToolbarHeight;
                  final expandedHeight = 300.0;
                  double t = (top - collapsedHeight) /
                      (expandedHeight - collapsedHeight);
                  t = t.clamp(0.0, 1.0);

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      FlexibleSpaceBar(
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            buildCragBackground(
                              widget.croqui.caminhoThumbnail,
                              cragId: widget.cragId,
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    context.colors.deepBasalt.withValues(
                                      alpha: 0.8,
                                    ),
                                    context.colors.deepBasalt,
                                  ],
                                  stops: const [0.5, 0.8, 1.0],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 20 + (52 * (1 - t)),
                        right: 20,
                        bottom: 20,
                        child: Text(
                          widget.pico.nome.toUpperCase(),
                          style: TextStyle(
                            color: context.colors.chalkWhite,
                            fontWeight: FontWeight.w900,
                            fontSize: 18 + (6 * t),
                          ),
                          maxLines: t > 0.5 ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinhaCreditoAutor(creditos: widget.croqui.creditos),
                    Text(
                      _viewModel.subtitulo,
                      style: TextStyle(
                        color: context.colors.mossRock,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Banner de Modo Online / Salvar Offline
                    Builder(
                      builder: (context) {
                        final tree = TreeNavigationWrapper.maybeOf(context);
                        final syncService = tree?.syncService;
                        final downloadingMapNotifier = syncService?.downloadingCrags ??
                            ValueNotifier<Map<String, double>>({});

                        return ValueListenableBuilder<Map<String, double>>(
                          valueListenable: downloadingMapNotifier,
                          builder: (context, downloadingMap, _) {
                            final progresso = downloadingMap[widget.cragId];

                            return BannerModoOnline(
                              cragId: widget.cragId,
                              tamanhoFormatado: _viewModel.tamanhoFormatado,
                              isDownloaded: _viewModel.isDownloaded,
                              progressoDownload: progresso,
                              onSalvarOffline: _iniciarDownload,
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Botões de Ação Auxiliares
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        buildFeedbackButton(
                          context,
                          color: context.colors.chalkWhite,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.search,
                            color: context.colors.chalkWhite,
                          ),
                          tooltip: _viewModel.tooltipBusca,
                          onPressed: () async {
                            TelemetryService.instance.logAcaoCroqui(
                              widget.cragId,
                              'buscar',
                            );
                          final tree = TreeNavigationWrapper.currentTreeController;
                          tree?.onBackInterceptor = () {
                            // Tenta fechar o search
                            Navigator.of(context).maybePop();
                            return true;
                          };

                          final result = await showSearch<Object?>(
                            context: context,
                            delegate: PicoSearchDelegate(widget.pico, widget.cragId),
                          );

                          _setupBackInterceptor();

                          if (result != null && context.mounted) {
                            if (result is Escalada) {
                              final setor = findSetorForEscalada(widget.pico, result);
                              if (setor != null) {
                                AppNav.toSetor(
                                  context,
                                  setor: setor,
                                  scrollToEscalada: result,
                                  cragId: widget.cragId,
                                );
                              }
                              TelemetryService.instance.logAcaoEscalada(
                                widget.cragId,
                                setor?.nome ?? 'Geral',
                                getEscaladaNome(result),
                                'abrir_detalhes',
                                'busca',
                              );
                              AppNav.toVia(
                                context,
                                escalada: result,
                                setor: setor,
                                cragId: widget.cragId,
                              );
                            } else if (result is Setor) {
                              TelemetryService.instance.logAbrirSetor(
                                widget.cragId,
                                result.nome,
                              );
                              AppNav.toSetor(
                                context,
                                setor: result,
                                cragId: widget.cragId,
                              );
                            }
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: context.colors.chalkWhite,
                        ),
                        tooltip: 'Excluir guia',
                        onPressed: () async {
                          TelemetryService.instance.logAcaoCroqui(
                            widget.cragId,
                            'excluir',
                          );
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: context.colors.caveShadow,
                              title: const Text(
                                'Excluir?',
                                style: TextStyle(color: Colors.white),
                              ),
                              content: Text(
                                'Deseja excluir o guia de ${widget.pico.nome}?',
                                style: TextStyle(color: context.colors.ashGrey),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(
                                    'CANCELAR',
                                    style: TextStyle(color: context.colors.ashGrey),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text(
                                    'EXCLUIR',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true && context.mounted) {
                            final success = await _viewModel.excluirPico();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Guia removido do armazenamento offline.'
                                        : 'Erro ao excluir guia.',
                                  ),
                                  backgroundColor: success
                                      ? context.colors.dryMoss
                                      : Theme.of(context).colorScheme.error,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Main Hub Cards (Grade de 2 colunas com Setores e Índice de Escaladas)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: PicoMenuCard(
                            isCompact: true,
                            title: 'Setores',
                            subtitle: 'Croquis detalhados e mapas de cada setor',
                            icon: Icons.landscape,
                            iconColor: context.colors.rustIron,
                            backgroundColor: context.colors.caveShadow,
                            titleColor: context.colors.chalkWhite,
                            subtitleColor: context.colors.fishBone,
                            onTap: () {
                              TelemetryService.instance.logNavegacaoPicoHub(
                                widget.cragId,
                                'abrir_setores',
                              );
                              TreeNavigationWrapper.of(
                                context,
                              ).treeController.navigateTo(
                                SetoresNode(
                                  cragId: widget.cragId,
                                  parent: TreeNavigationWrapper.of(
                                    context,
                                  ).treeController.currentNode,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: PicoMenuCard(
                            isCompact: true,
                            title: 'Índice de Escaladas',
                            subtitle:
                                'Todas as vias e boulders filtrados por grau e tipo',
                            icon: Icons.format_list_bulleted,
                            iconColor: context.colors.beastHide,
                            backgroundColor: context.colors.caveShadow,
                            titleColor: context.colors.chalkWhite,
                            subtitleColor: context.colors.fishBone,
                            onTap: () {
                              TelemetryService.instance.logNavegacaoPicoHub(
                                widget.cragId,
                                'abrir_indice_escaladas',
                              );
                              TreeNavigationWrapper.of(
                                context,
                              ).treeController.navigateTo(
                                IndiceEscaladasNode(
                                  cragId: widget.cragId,
                                  parent: TreeNavigationWrapper.of(
                                    context,
                                  ).treeController.currentNode,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  PicoMenuCard(
                    title: 'Explorar Local',
                    subtitle:
                        'Como chegar, mapas gerais do croqui, clima e informações úteis.',
                    icon: Icons.explore,
                    iconColor: context.colors.beastHide,
                    backgroundColor: context.colors.caveShadow,
                    titleColor: context.colors.chalkWhite,
                    subtitleColor: context.colors.fishBone,
                    onTap: () {
                      TelemetryService.instance.logNavegacaoPicoHub(
                        widget.cragId,
                        'abrir_explorar_local',
                      );
                      TreeNavigationWrapper.of(
                        context,
                      ).treeController.navigateTo(
                        ExplorarLocalNode(
                          cragId: widget.cragId,
                          parent: TreeNavigationWrapper.of(
                            context,
                          ).treeController.currentNode,
                        ),
                      );
                    },
                  ),

                  PicoMenuCard(
                    title: 'Regras e recomendações',
                    subtitle:
                        'Normas de conduta ecológica, segurança básica, ética e boa convivência.',
                    icon: Icons.warning_amber_rounded,
                    iconColor: context.colors.dryMoss,
                    backgroundColor: context.colors.caveShadow,
                    titleColor: context.colors.chalkWhite,
                    subtitleColor: context.colors.fishBone,
                    onTap: () {
                      TelemetryService.instance.logNavegacaoPicoHub(
                        widget.cragId,
                        'abrir_regras',
                      );
                      showRegrasBottomSheet(
                        context,
                        _viewModel.regras,
                        widget.cragId,
                      );
                    },
                  ),

                  PicoMenuCard(
                    title: 'Comunidade',
                    subtitle:
                        'Redes sociais, canal de Whatsapp, patrocinadores e comércio local.',
                    icon: Icons.people_outline,
                    iconColor: context.colors.rustIron,
                    backgroundColor: context.colors.caveShadow,
                    titleColor: context.colors.chalkWhite,
                    subtitleColor: context.colors.fishBone,
                    onTap: () {
                      TelemetryService.instance.logNavegacaoPicoHub(
                        widget.cragId,
                        'abrir_comunidade',
                      );
                      TreeNavigationWrapper.of(
                        context,
                      ).treeController.navigateTo(
                        ComunidadePicoNode(
                          cragId: widget.cragId,
                          parent: TreeNavigationWrapper.of(
                            context,
                          ).treeController.currentNode,
                        ),
                      );
                    },
                  ),

                  /*
                  PicoMenuCard(
                    title: 'Apoie o Pico',
                    subtitle:
                        'Contribua para a manutenção e sustentabilidade do pico.',
                    icon: Icons.favorite_border,
                    iconColor: context.colors.mossRock,
                    backgroundColor: context.colors.caveShadow,
                    titleColor: context.colors.chalkWhite,
                    subtitleColor: context.colors.fishBone,
                    onTap: () {
                      TreeNavigationWrapper.of(
                        context,
                      ).treeController.navigateTo(
                        ApoiePicoNode(
                          cragId: widget.cragId,
                          parent: TreeNavigationWrapper.of(
                            context,
                          ).treeController.currentNode,
                        ),
                      );
                    },
                  ),
                  */

                  if (_viewModel.creditos.isNotEmpty)
                    ..._viewModel.creditos.map(
                      (b) => PicoMenuCard(
                        title: b.texto,
                        subtitle:
                            'Conheça os autores, colaboradores e agradecimentos.',
                        icon: Icons.workspace_premium,
                        iconColor: context.colors.ashGrey,
                        backgroundColor: context.colors.caveShadow,
                        titleColor: context.colors.chalkWhite,
                        subtitleColor: context.colors.fishBone,
                        onTap: () {
                          TelemetryService.instance.logNavegacaoPicoHub(
                            widget.cragId,
                            'abrir_creditos',
                          );
                          TreeNavigationWrapper.of(
                            context,
                          ).treeController.navigateTo(
                            TextNode(
                              title: b.texto,
                              content: b.destino.secaoTextual.conteudo,
                              cragId: widget.cragId,
                              icon: Icons.workspace_premium,
                              parent: TreeNavigationWrapper.of(
                                context,
                              ).treeController.currentNode,
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      _viewModel.textoUltimaAtualizacao,
                      style: TextStyle(
                        color: context.colors.ashGrey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 100), // spacing for FAB
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: widget.returnToSetor != null
          ? FloatingActionButton.extended(
              onPressed: () {
                TelemetryService.instance.logAcaoCroqui(
                  widget.cragId,
                  'voltar_mapa_setor',
                );
                AppNav.toSetor(context, setor: widget.returnToSetor!);
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (context.mounted) {
                    AppNav.toMapas(
                      context,
                      cragId: widget.cragId,
                      mapas: [
                        CarrosselItemData(
                          mapaCaminhoImagem: widget
                              .returnToSetor!
                              .mapas
                              .first
                              .caminhoImagemMapa,
                          setorContextNome: widget.returnToSetor!.nome,
                        ),
                      ],
                    );
                  }
                });
              },
              backgroundColor: context.colors.rustIron,
              icon: Icon(Icons.map, color: context.colors.chalkWhite),
              label: Text(
                'Voltar para o Mapa do Setor',
                style: TextStyle(
                  color: context.colors.chalkWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    ),
    );
      },
    );
  }
}
