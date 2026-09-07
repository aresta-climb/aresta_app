// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:frontend/main.dart';
import 'package:flutter/material.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../view_functions/common_functions.dart';
import '../view_functions/pico_functions.dart';
import '../view_functions/browse_functions.dart';
import '../view_functions/via_functions.dart';
import '../services/dataset_repository.dart';
import '../navigation/navigation_functions.dart';
import '../navigation/navigation_tree.dart';
import '../services/firebase/telemetry_service.dart';
import '../theme/app_colors.dart';

// New imports for sub-pages
import '../widgets/bottom_sheets/regras_bottom_sheet.dart';
import '../widgets/pico_menu_card.dart';
import '../utils/pico_categorization.dart';
import '../widgets/banner_modo_online.dart';
import '../widgets/linha_credito_autor.dart';
import '../widgets/modal_confirmacao_saida.dart';
import '../services/http/servico_croqui_online.dart';
import '../services/http/servico_download_segundo_plano.dart';

class PicoDetailsPage extends StatefulWidget {
  final Pico pico;
  final Croqui croqui;
  final String cragId;
  final DatasetRepository datasetRepo;
  final bool scrollToMapaGeral;
  final Setor? returnToSetor;

  const PicoDetailsPage({
    super.key,
    required this.pico,
    required this.croqui,
    required this.cragId,
    required this.datasetRepo,
    this.scrollToMapaGeral = false,
    this.returnToSetor,
  });

  @override
  State<PicoDetailsPage> createState() => _PicoDetailsPageState();
}

class _PicoDetailsPageState extends State<PicoDetailsPage> {
  final GlobalKey _mapaKey = GlobalKey();
  late PicoCategorizedData _categories;
  late ServicoCroquiOnline _servicoCroquiOnline;
  late bool _isInitiallyDownloaded;

  @override
  void initState() {
    super.initState();
    _categories = PicoCategorizedData(widget.croqui);
    _servicoCroquiOnline = ServicoCroquiOnline(
      sessaoOnline: widget.datasetRepo.gerenciadorSessaoOnline,
      verificarPicoBaixado: (id) => widget.datasetRepo.isPicoDownloaded(id),
    );

    _isInitiallyDownloaded =
        widget.datasetRepo.isPicoDownloaded(widget.cragId);

    widget.datasetRepo.activeDataset.addListener(_verificarStatusDownload);

    final dataset = widget.datasetRepo.activeDataset.value;
    if (!_isInitiallyDownloaded && dataset != null) {
      try {
        final picoItem = dataset.picosDisponiveis.firstWhere(
          (p) => p['id'] == widget.cragId,
        );
        final url = picoItem['url']?.toString();
        if (url != null && url.isNotEmpty) {
          _servicoCroquiOnline.iniciarPollingEtag(
            widget.cragId,
            url,
            aoAtualizar: (picoId, croqui) {
              widget.datasetRepo.notificarAtualizacaoSessaoOnline(picoId);
              final isExperimental =
                  widget.datasetRepo.editorDeCroqui.isExperimentalMode.value;
              if (isExperimental) {
                widget.datasetRepo.editorDeCroqui.dispararPulsoRecarregamento();
              } else {
                widget.datasetRepo.notificarCroquiOnlineAtualizadoNaUI(
                  widget.pico.nome.isNotEmpty ? widget.pico.nome : picoId,
                );
              }
            },
          );
        }
      } catch (_) {}
    }


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
              } catch (e) {
                debugPrint('[PicoDetailsPage] Falha ao rolar para mapa geral: $e');
              }
            }
          }
        });
      });
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

      if (staysInSameCroqui) {
        return false;
      }

      final isBaixado = widget.datasetRepo.isPicoDownloaded(widget.cragId);

      if (isBaixado) {
        tree.onBackInterceptor = null;
        return false;
      }


      Map<String, dynamic>? picoItem;
      try {
        picoItem = widget.datasetRepo.activeDataset.value?.picosDisponiveis
            .firstWhere((p) => p['id'] == widget.cragId);
      } catch (_) {}
      final tamanhoFormatado =
          picoItem?['tamanhoFormatado']?.toString() ?? 'Offline';

      ModalConfirmacaoSaida.mostrar(
        context: context,
        nomePico: widget.pico.nome,
        tamanhoFormatado: tamanhoFormatado,
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

  void _verificarStatusDownload() {
    if (!mounted) return;
    final isDownloaded = widget.datasetRepo.isPicoDownloaded(widget.cragId);
    if (isDownloaded) {
      _servicoCroquiOnline.cancelarPolling(widget.cragId);
      final tree = TreeNavigationWrapper.maybeOf(context)?.treeController ??
          TreeNavigationWrapper.currentTreeController;
      if (tree != null && tree.onBackInterceptor != null) {
        tree.onBackInterceptor = null;
      }
      if (!_isInitiallyDownloaded) {
        setState(() {
          _isInitiallyDownloaded = true;
        });
      }
    }
  }

  @override
  void didUpdateWidget(PicoDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cragId != widget.cragId ||
        oldWidget.datasetRepo != widget.datasetRepo) {
      oldWidget.datasetRepo.activeDataset.removeListener(_verificarStatusDownload);
      widget.datasetRepo.activeDataset.addListener(_verificarStatusDownload);
    }
    _verificarStatusDownload();
  }

  @override
  void dispose() {
    widget.datasetRepo.activeDataset.removeListener(_verificarStatusDownload);
    final tree = TreeNavigationWrapper.currentTreeController;
    if (tree != null) {
      tree.onBackInterceptor = null;
    }
    _servicoCroquiOnline.cancelarPolling(widget.cragId);
    _servicoCroquiOnline.dispose();
    super.dispose();
  }

  void _iniciarDownload() async {
    final indice = widget.datasetRepo.indiceData.value;
    if (indice == null) return;

    final resumos = indice.croquis.where((r) => r.id == widget.cragId).toList();
    if (resumos.isEmpty) return;

    final tree = TreeNavigationWrapper.of(context);
    final syncService = tree.syncService;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text('Baixando ${widget.pico.nome}...')));

    final servicoDownload =
        ServicoDownloadSegundoPlano(syncService: syncService);
    final success = await servicoDownload.executarDownload(resumos.first);

    if (!mounted) return;

    if (success) {
      _servicoCroquiOnline.cancelarPolling(widget.cragId);
      final currentTree = TreeNavigationWrapper.maybeOf(context)?.treeController ??
          TreeNavigationWrapper.currentTreeController;
      if (currentTree != null) {
        currentTree.onBackInterceptor = null;
      }
      setState(() {
        _isInitiallyDownloaded = true;
      });
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


  int _countTotalSetores() {
    int count = 0;
    for (var sg in widget.pico.setoresOuGrupos) {
      if (sg.whichTipo() == SetorOuGrupo_Tipo.setor) {
        count++;
      } else if (sg.whichTipo() == SetorOuGrupo_Tipo.grupo) {
        count += sg.grupo.conteudo.setores.length;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    String searchTooltip = 'Buscar via';
    if (isPicoBoulderArea(widget.pico)) {
      searchTooltip = 'Buscar boulder';
    }

    final int setoresCount = _countTotalSetores();
    int totalVias = 0;
    int totalBoulders = 0;
    int totalEsportivas = 0;
    int totalMoveis = 0;
    int totalMultiplasEnfiadas = 0;
    int totalHighlines = 0;

    void processEscaladas(Iterable<dynamic> escaladas) {
      for (var escalada in escaladas) {
        totalVias++;
        switch (escalada.whichTipo()) {
          case Escalada_Tipo.boulder:
            totalBoulders++;
            break;
          case Escalada_Tipo.viaEsportiva:
            totalEsportivas++;
            break;
          case Escalada_Tipo.viaMovel:
            totalMoveis++;
            break;
          case Escalada_Tipo.viaMultiplasEnfiadas:
            totalMultiplasEnfiadas++;
            break;
          case Escalada_Tipo.highline:
            totalHighlines++;
            break;
          default:
            break;
        }
      }
    }

    for (var sg in widget.pico.setoresOuGrupos) {
      if (sg.whichTipo() == SetorOuGrupo_Tipo.setor) {
        processEscaladas(sg.setor.conteudo.escaladas);
      } else if (sg.whichTipo() == SetorOuGrupo_Tipo.grupo) {
        for (var s in sg.grupo.conteudo.setores) {
          processEscaladas(s.conteudo.escaladas);
        }
      }
    }

    String statsText = '';
    if (totalVias > 0) {
      final List<String> modalidades = [];
      if (totalEsportivas > 0) modalidades.add('$totalEsportivas esportivas');
      if (totalBoulders > 0) modalidades.add('$totalBoulders boulders');
      if (totalMoveis > 0) modalidades.add('$totalMoveis móveis');
      if (totalMultiplasEnfiadas > 0) {
        modalidades.add('$totalMultiplasEnfiadas múltiplas enfiadas');
      }
      if (totalHighlines > 0) modalidades.add('$totalHighlines highlines');

      statsText = ' • $totalVias escaladas';
      if (modalidades.isNotEmpty) {
        statsText += ' (${modalidades.join(', ')})';
      }
    }    final String subtitleText =
        "${widget.pico.estado.toUpperCase()} • $setoresCount SETORES$statsText";

    final dataset = widget.datasetRepo.activeDataset.value;
    final bool isDownloaded = widget.datasetRepo.isPicoDownloaded(widget.cragId);



    Map<String, dynamic>? picoItem;
    try {
      picoItem = dataset?.picosDisponiveis.firstWhere(
        (p) => p['id'] == widget.cragId,
      );
    } catch (_) {}

    final String tamanhoFormatado =
        picoItem?['tamanhoFormatado']?.toString() ?? 'Offline';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final tree = TreeNavigationWrapper.maybeOf(context)?.treeController;
        final parentNode = tree?.currentNode.parent;
        final staysInSameCroqui =
            parentNode is PicoContextNode && parentNode.cragId == widget.cragId;

        if (staysInSameCroqui) {
          if (context.mounted && AppNav.canGoBack(context)) {
            AppNav.back(context);
          }
          return;
        }

        final isBaixado = widget.datasetRepo.activeDataset.value?.picosBaixados
                .any((p) => p['id'] == widget.cragId) ??
            false;

        if (isBaixado) {
          if (context.mounted && AppNav.canGoBack(context)) {
            AppNav.back(context);
          }
          return;
        }

        ModalConfirmacaoSaida.mostrar(
          context: context,
          nomePico: widget.pico.nome,
          tamanhoFormatado: tamanhoFormatado,
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
                      subtitleText,
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
                              tamanhoFormatado: tamanhoFormatado,
                              isDownloaded: isDownloaded,
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
                          tooltip: searchTooltip,
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
                            // Garante que o croqui permaneça em memória para transição suave para modo online
                            widget.datasetRepo.gerenciadorSessaoOnline
                                .registrarCroquiOnline(
                              widget.cragId,
                              widget.croqui,
                            );

                            final success = await widget.datasetRepo.deleteCrag(
                              widget.cragId,
                            );
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

                  // Main Hub Cards
                  PicoMenuCard(
                    title: 'Setores',
                    subtitle: 'Croquis detalhados, grau e vias',
                    icon: Icons.landscape,
                    iconColor: context.colors.rustIron,
                    backgroundColor: context.colors.caveShadow,
                    titleColor: context.colors.chalkWhite,
                    subtitleColor: context.colors.fishBone,
                    onTap: () {
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
                      showRegrasBottomSheet(
                        context,
                        _categories.regras,
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

                  if (_categories.creditos.isNotEmpty)
                    ..._categories.creditos.map(
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
                      'Última atualização: Hoje',
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
  }
}
