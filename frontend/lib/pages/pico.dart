import '../main.dart';
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

  @override
  void initState() {
    super.initState();
    _categories = PicoCategorizedData(widget.croqui);

    if (widget.scrollToMapaGeral) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && _mapaKey.currentContext != null) {
          Scrollable.ensureVisible(
            _mapaKey.currentContext!,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            alignment: 0.1,
          );
        }
      });
    }
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
    
    // Attempt to fetch detailed statistics from activeDataset
    final picosList = widget.datasetRepo.activeDataset.value?.availablePicos ?? [];
    final picoData = picosList.where((p) => p['id'] == widget.cragId).firstOrNull;
    final estatisticas = picoData?['estatisticas'] as Map<String, dynamic>?;

    String statsText = '';
    if (estatisticas != null) {
      final vias = estatisticas['totalVias'] ?? 0;
      final List<String> modalidades = [];
      if ((estatisticas['totalBoulders'] ?? 0) > 0) modalidades.add('${estatisticas['totalBoulders']} boulders');
      if ((estatisticas['totalEsportivas'] ?? 0) > 0) modalidades.add('${estatisticas['totalEsportivas']} esportivas');
      if ((estatisticas['totalMoveis'] ?? 0) > 0) modalidades.add('${estatisticas['totalMoveis']} móveis');
      if ((estatisticas['totalMultiplasEnfiadas'] ?? 0) > 0) modalidades.add('${estatisticas['totalMultiplasEnfiadas']} múltiplas enfiadas');
      if ((estatisticas['totalHighlines'] ?? 0) > 0) modalidades.add('${estatisticas['totalHighlines']} highlines');

      if (vias > 0) {
        statsText = ' • $vias escaladas';
        if (modalidades.isNotEmpty) {
          statsText += ' (${modalidades.join(', ')})';
        }
      }
    }

    final String subtitleText =
        "${widget.pico.estado.toUpperCase()} • $setoresCount SETORES$statsText";

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            backgroundColor: context.colors.deepBasalt,
            iconTheme: IconThemeData(color: context.colors.chalkWhite),
            flexibleSpace: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final top = constraints.biggest.height;
                final collapsedHeight =
                    MediaQuery.of(context).padding.top + kToolbarHeight;
                final expandedHeight = 300.0;
                // A variável 't' (progresso) vai de 1.0 (totalmente expandido) a 0.0 (totalmente colapsado).
                // Usamos isso para animar manualmente o padding e o tamanho da fonte.
                double t =
                    (top - collapsedHeight) /
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

                          // Gradient to make text readable
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
                      // Anima a margem esquerda de 20 (expandido) para 72 (colapsado) para não sobrepor o botão de voltar.
                      left: 20 + (52 * (1 - t)),
                      // Anima a margem direita para dar espaço aos botões de share e feedback.
                      right: 20, // Make room for share and feedback buttons
                      bottom: 20,
                      child: Text(
                        widget.pico.nome.toUpperCase(),
                        style: TextStyle(
                          color: context.colors.chalkWhite,
                          fontWeight: FontWeight.w900,
                          // A fonte diminui suavemente de 24 para 18.
                          fontSize: 18 + (6 * t),
                        ),
                        // Força para 1 linha a partir da metade do scroll para evitar que o texto bata na status bar.
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
                  Text(
                    subtitleText,
                    style: TextStyle(
                      color: context.colors.mossRock,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: Icon(
                            Icons.check,
                            size: 18,
                            color: context.colors.chalkWhite,
                          ),
                          label: Text(
                            'SALVO OFFLINE',
                            style: TextStyle(
                              color: context.colors.chalkWhite,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.colors.mossRock,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: Icon(
                            Icons.share,
                            size: 18,
                            color: context.colors.chalkWhite,
                          ),
                          label: Text(
                            'COMPARTILHAR',
                            style: TextStyle(
                              color: context.colors.chalkWhite,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.colors.caveShadow,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      buildFeedbackButton(context, color: context.colors.chalkWhite),
                      IconButton(
                        icon: Icon(Icons.search, color: context.colors.chalkWhite),
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

                          // Limpa o interceptor apenas se ele for exatamente a função que registramos.
                          // Isso previne que zere um interceptor que possa ter sido registrado
                          // por outra coisa se a navegação ficasse muito rápida.
                          tree?.onBackInterceptor = null;

                          if (result != null && context.mounted) {
                            if (result is Escalada) {
                              final setor = findSetorForEscalada(widget.pico, result);
                              if (setor != null) {
                                AppNav.toSetor(
                                  context,
                                  setor: setor,
                                  scrollToEscalada: result,
                                );
                              }
                              TelemetryService.instance.logAcaoEscalada(
                                widget.cragId,
                                setor?.nome ?? 'Geral',
                                getEscaladaNome(result),
                                'abrir_detalhes',
                                'busca',
                              );
                              AppNav.toVia(context, escalada: result, setor: setor);
                            } else if (result is Setor) {
                              TelemetryService.instance.logAbrirSetor(
                                widget.cragId,
                                result.nome,
                              );
                              AppNav.toSetor(context, setor: result);
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
                            final success = await widget.datasetRepo.deleteCrag(
                              widget.cragId,
                            );
                            if (context.mounted) {
                              AppNav.home(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Guia excluído.'
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
    );
  }
}
