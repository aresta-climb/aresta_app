// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../navigation/funcoes_navegacao.dart';
import '../services/compartilhamento/servico_compartilhamento.dart';
import '../services/firebase/app_logger.dart';
import '../services/firebase/telemetria.dart';
import '../services/gerenciador_filtros_croqui.dart';
import '../theme/cores_app.dart';
import '../utils/filtro_grau_escalada.dart';
import '../utils/indexador_escaladas.dart';
import '../view/function_library/biblioteca_funcoes_comuns.dart';
import '../view/function_library/markdown_offline.dart';
import '../view/function_library/setor_functions.dart';
import '../widgets/card_indice_escalada.dart';
import '../widgets/mapa_thumbnail.dart';
import '../widgets/painel_filtros_indice.dart';

/// Página unificada de exploração de um setor específico de escalada.
///
/// Apresenta cabeçalho com foto de capa ou título colapsável, descrição em Markdown,
/// mapas thumbnails, abas de modalidades ordenadas por volume (quando existirem múltiplas),
/// painel de filtros e ordenação reativo sincronizado com o croqui e lista de escaladas
/// com rótulos de croqui e animação de realce para vias alvo.
class SetorPage extends StatefulWidget {
  /// O setor a ser explorado.
  final Setor setor;

  /// O grupo agregador opcional ao qual este setor pertence.
  final Grupo? grupoContext;

  /// O identificador do croqui/pico para eventos de telemetria e persistência de filtros.
  final String cragId;

  /// Escalada alvo opcional para navegação direta com rolagem e realce.
  final Escalada? scrollToEscalada;

  /// Provedor de imagem de capa futuro opcional para testes ou injeção em camadas.
  final Future<ImageProvider?>? coverProviderFutureOverride;

  const SetorPage({
    super.key,
    required this.setor,
    this.grupoContext,
    required this.cragId,
    this.scrollToEscalada,
    this.coverProviderFutureOverride,
  });

  @override
  State<SetorPage> createState() => _SetorPageState();
}

class _SetorPageState extends State<SetorPage> with TickerProviderStateMixin {
  late List<ItemIndiceEscalada> _todasEscaladas;
  late Map<String, List<ItemIndiceEscalada>> _escaladasPorModalidade;
  late List<String> _modalidadesDisponiveis;

  TabController? _tabController;
  int _indiceAbaAtual = 0;

  late EstadoFiltrosUnificado _estadoFiltros;
  Future<ImageProvider?>? _coverProviderFuture;
  GlobalKey? _targetKey;

  @override
  void initState() {
    super.initState();
    _coverProviderFuture =
        widget.coverProviderFutureOverride ?? _resolveCoverImage();
    _estadoFiltros =
        GerenciadorFiltrosCroqui.instance.obterFiltros(widget.cragId);
    GerenciadorFiltrosCroqui.instance.addListener(_onFiltrosGlobaisAlterados);
    _inicializarDados();

    if (widget.scrollToEscalada != null) {
      _targetKey = GlobalKey();
      _scheduleScrollToTarget();
    }
  }

  void _onFiltrosGlobaisAlterados() {
    final atualizado =
        GerenciadorFiltrosCroqui.instance.obterFiltros(widget.cragId);
    if (atualizado != _estadoFiltros && mounted) {
      setState(() {
        _estadoFiltros = atualizado;
      });
    }
  }

  void _atualizarEstadoFiltros(EstadoFiltrosUnificado novo) {
    _estadoFiltros = novo;
    GerenciadorFiltrosCroqui.instance.atualizarFiltros(widget.cragId, novo);
    setState(() {});
  }

  /// Inicializa as escaladas indexadas e organiza as modalidades por volume decrescente.
  void _inicializarDados() {
    _todasEscaladas = indexarEscaladasDoSetor(
      widget.setor,
      widget.cragId,
      grupoContext: widget.grupoContext,
    );

    _escaladasPorModalidade = {};
    for (final item in _todasEscaladas) {
      _escaladasPorModalidade.putIfAbsent(item.modalidade, () => []).add(item);
    }

    _modalidadesDisponiveis = _escaladasPorModalidade.keys.toList()
      ..sort((a, b) {
        final countA = _escaladasPorModalidade[a]?.length ?? 0;
        final countB = _escaladasPorModalidade[b]?.length ?? 0;
        final comp = countB.compareTo(countA);
        if (comp != 0) return comp;
        return a.compareTo(b);
      });

    int initialIndex = 0;
    if (widget.scrollToEscalada != null) {
      for (final item in _todasEscaladas) {
        if (item.escalada == widget.scrollToEscalada) {
          final idx = _modalidadesDisponiveis.indexOf(item.modalidade);
          if (idx != -1) {
            initialIndex = idx;
          }
          break;
        }
      }
    }

    _tabController?.dispose();
    if (_modalidadesDisponiveis.length > 1) {
      _tabController = TabController(
        length: _modalidadesDisponiveis.length,
        initialIndex: initialIndex,
        vsync: this,
      );
      _tabController!.addListener(() {
        if (!_tabController!.indexIsChanging &&
            _tabController!.index != _indiceAbaAtual) {
          final novaAba = _modalidadesDisponiveis[_tabController!.index];
          _indiceAbaAtual = _tabController!.index;
          TelemetryService.instance.logAcaoIndiceEscaladas(
            widget.cragId,
            'trocar_aba',
            modalidade: novaAba,
            detalhe: 'setor_${widget.setor.nome}',
          );
          setState(() {});
        }
      });
    } else {
      _tabController = null;
    }

    _indiceAbaAtual = initialIndex;
  }

  @override
  void didUpdateWidget(SetorPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.setor != widget.setor ||
        oldWidget.cragId != widget.cragId ||
        oldWidget.coverProviderFutureOverride !=
            widget.coverProviderFutureOverride) {
      _coverProviderFuture =
          widget.coverProviderFutureOverride ?? _resolveCoverImage();
      _estadoFiltros =
          GerenciadorFiltrosCroqui.instance.obterFiltros(widget.cragId);
      _inicializarDados();
    }

    if (widget.scrollToEscalada != oldWidget.scrollToEscalada &&
        widget.scrollToEscalada != null) {
      _targetKey = GlobalKey();
      _scheduleScrollToTarget();
    }
  }

  @override
  void dispose() {
    GerenciadorFiltrosCroqui.instance.removeListener(_onFiltrosGlobaisAlterados);
    _tabController?.dispose();
    super.dispose();
  }

  void _scheduleScrollToTarget() {
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final targetContext = _targetKey?.currentContext;
        if (targetContext != null) {
          final renderObject = targetContext.findRenderObject();
          if (renderObject is RenderBox &&
              renderObject.attached &&
              renderObject.hasSize) {
            try {
              Scrollable.ensureVisible(
                targetContext,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
                alignment: 0.5,
              );
            } catch (e, stackTrace) {
              AppLogger.instance.logError(
                '[SetorPage] Falha ao rolar para via alvo',
                error: e,
                stackTrace: stackTrace,
              );
            }
          }
        }
      });
    });
  }

  bool get _temCapa =>
      widget.setor.hasCaminhoImagemCapa() &&
      widget.setor.caminhoImagemCapa.isNotEmpty;

  Future<ImageProvider?> _resolveCoverImage() async {
    if (_temCapa) {
      return resolveImagePathProvider(
        widget.cragId,
        widget.setor.caminhoImagemCapa,
        larguraAlvo: 600,
      );
    }
    return null;
  }

  String _obterNomePluralModalidade(String modalidade) {
    switch (modalidade) {
      case 'Esportiva':
        return 'Esportivas';
      case 'Boulder':
        return 'Boulders';
      case 'Móvel':
        return 'Móveis';
      case 'Multienfiada':
        return 'Multienfiadas';
      case 'Highline':
        return 'Highlines';
      default:
        return modalidade;
    }
  }

  String _formatarRotuloAba(String modalidade) {
    final nomePlural = _obterNomePluralModalidade(modalidade);
    final viasBase = _escaladasPorModalidade[modalidade] ?? [];
    if (_estadoFiltros.temFiltrosAtivos) {
      final filtradas = _estadoFiltros
          .filtrarEscaladas(viasBase, modalidadeEspecifica: modalidade)
          .length;
      return '$nomePlural ($filtradas/${viasBase.length})';
    }
    return '$nomePlural (${viasBase.length})';
  }

  List<String> _obterConquistadoresDisponiveis(String modalidade) {
    final viasBase = _escaladasPorModalidade[modalidade] ?? _todasEscaladas;
    return viasBase
        .expand((v) => v.conquistadores)
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.compareTo(b));
  }

  bool _temClassicasDisponiveis(String modalidade) {
    final viasBase = _escaladasPorModalidade[modalidade] ?? _todasEscaladas;
    return viasBase.any((v) => v.isDestaque);
  }

  Map<String, FaixaGrauDisponivel> _obterFaixasGrauDisponiveis(String modalidade) {
    final viasBase = _escaladasPorModalidade[modalidade] ?? _todasEscaladas;
    return calcularFaixasGrauDisponiveis(viasBase);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final validMapas = widget.setor.mapas
        .where((m) =>
            m.caminhoImagemMapa.isNotEmpty &&
            m.larguraMapa > 0 &&
            m.alturaMapa > 0)
        .toList();

    final String abaAtual = _modalidadesDisponiveis.isNotEmpty
        ? _modalidadesDisponiveis[_tabController?.index ?? _indiceAbaAtual]
        : '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // 1. Cabeçalho com Capa Animada ou Barra Simples
          SliverAppBar(
            expandedHeight: _temCapa ? 300.0 : null,
            pinned: true,
            backgroundColor: context.colors.deepBasalt,
            iconTheme: IconThemeData(color: context.colors.chalkWhite),
            title: !_temCapa
                ? Text(
                    widget.setor.nome.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'BebasNeue',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Colors.white,
                    ),
                  )
                : null,
            centerTitle: false,
            actions: [
              if (widget.setor.uid.isNotEmpty)
                IconButton(
                  icon: Icon(
                    Icons.share_outlined,
                    color: context.colors.chalkWhite,
                  ),
                  tooltip: 'Compartilhar setor',
                  onPressed: () {
                    ServicoCompartilhamento.instancia.compartilharSetor(
                      idCroqui: widget.cragId,
                      uid: widget.setor.uid,
                      nomeSetor: widget.setor.nome,
                      nomePico: widget.cragId,
                    );
                  },
                ),
              buildFeedbackButton(context, color: context.colors.chalkWhite),
              const SizedBox(width: 8),
            ],
            flexibleSpace: _temCapa
                ? LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      final top = constraints.biggest.height;
                      final collapsedHeight =
                          MediaQuery.of(context).padding.top + kToolbarHeight;
                      const expandedHeight = 300.0;
                      double t = (top - collapsedHeight) /
                          (expandedHeight - collapsedHeight);
                      t = t.clamp(0.0, 1.0);

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          FlexibleSpaceBar(
                            background: FutureBuilder<ImageProvider?>(
                              future: _coverProviderFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Container(
                                    color: context.colors.deepBasalt,
                                  );
                                }
                                if (snapshot.hasData && snapshot.data != null) {
                                  return Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image(
                                        image: snapshot.data!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const SizedBox.shrink(),
                                      ),
                                      Positioned(
                                        top: 0,
                                        left: 0,
                                        right: 0,
                                        height: 200,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.black,
                                                Colors.black.withValues(alpha: 0.7),
                                                Colors.transparent,
                                              ],
                                              stops: const [0.0, 0.4, 1.0],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        height: 200,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: [
                                                Colors.black.withValues(alpha: 0.9),
                                                Colors.black.withValues(alpha: 0.6),
                                                Colors.transparent,
                                              ],
                                              stops: const [0.0, 0.4, 1.0],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }
                                return Container(
                                  color: context.colors.deepBasalt,
                                );
                              },
                            ),
                          ),
                          Positioned(
                            left: 16 + (56 * (1 - t)),
                            right: 16 + (72 * (1 - t)),
                            bottom: 16,
                            child: Text(
                              widget.setor.nome.toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'BebasNeue',
                                fontSize: 20 + (8 * t),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: Colors.white,
                              ),
                              maxLines: t > 0.5 ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );
                    },
                  )
                : null,
          ),

          // 2. Seção Fixa: Descrição, Mapa, Abas de Modalidade e Painel de Filtros
          SliverToBoxAdapter(
            child: SafeArea(
              top: false,
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Descrição do Setor em Markdown
                  if (widget.setor.descricao.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: OfflineMarkdown(
                        data: widget.setor.descricao,
                        cragId: widget.cragId,
                      ),
                    ),

                  // Mapa Thumbnail do Setor
                  if (validMapas.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AspectRatio(
                          aspectRatio: validMapas.first.larguraMapa /
                              validMapas.first.alturaMapa,
                          child: MapaThumbnail(
                            mapas: validMapas,
                            cragId: widget.cragId,
                            setorContext: widget.setor,
                            grupoContext: widget.grupoContext,
                            nomeContexto: widget.setor.nome,
                          ),
                        ),
                      ),
                    ),

                  // Barra de Abas Dinâmicas (apenas se houver > 1 modalidade)
                  if (_modalidadesDisponiveis.length > 1 && _tabController != null)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.caveShadow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.graniteEdge),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 14),
                        indicatorColor: colors.rustIron,
                        indicatorWeight: 3,
                        labelColor: colors.chalkWhite,
                        unselectedLabelColor: colors.ashGrey,
                        dividerColor: Colors.transparent,
                        onTap: (_) => setState(() {}),
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        tabs: _modalidadesDisponiveis.map((mod) {
                          return Tab(text: _formatarRotuloAba(mod));
                        }).toList(),
                      ),
                    ),

                  // Painel de Filtros Unificado
                  PainelFiltrosIndice(
                    cragId: widget.cragId,
                    estadoUnificado: _estadoFiltros,
                    abaAtiva: abaAtual,
                    modalidadesDisponiveis: _modalidadesDisponiveis,
                    setoresDisponiveis: [widget.setor.nome],
                    gruposDisponiveis: widget.grupoContext != null
                        ? [widget.grupoContext!.nome]
                        : const [],
                    conquistadoresDisponiveis:
                        _obterConquistadoresDisponiveis(abaAtual),
                    temClassicasDisponiveis:
                        _temClassicasDisponiveis(abaAtual),
                    faixasGrauDisponiveis:
                        _obterFaixasGrauDisponiveis(abaAtual),
                    totalResultados: _obterEscaladasFiltradas(abaAtual).length,
                    onFiltrosUnificadosChanged: _atualizarEstadoFiltros,
                  ),
                ],
              ),
            ),
          ),

          // 3. Conteúdo da aba ativa: Lista de Escaladas
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              24 + MediaQuery.of(context).padding.bottom,
            ),
            sliver: _buildSliverEscaladas(context, abaAtual),
          ),
        ],
      ),
    );
  }

  /// Obtém a lista de escaladas filtradas e ordenadas para a modalidade ativa.
  List<ItemIndiceEscalada> _obterEscaladasFiltradas(String modalidade) {
    final List<ItemIndiceEscalada> viasBase = modalidade.isNotEmpty
        ? (_escaladasPorModalidade[modalidade] ?? [])
        : _todasEscaladas;

    return _estadoFiltros.filtrarEscaladas(
      viasBase,
      modalidadeEspecifica: modalidade.isNotEmpty ? modalidade : null,
    );
  }

  /// Constrói o sliver com a lista de escaladas filtradas e ordenadas.
  Widget _buildSliverEscaladas(BuildContext context, String modalidade) {
    final colors = context.colors;
    final viasFiltradas = _obterEscaladasFiltradas(modalidade);

    if (viasFiltradas.isEmpty) {
      return SliverToBoxAdapter(
        child: SafeArea(
          top: false,
          bottom: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'Nenhuma escalada encontrada nos filtros atuais.',
                style: TextStyle(color: colors.ashGrey, fontSize: 14),
              ),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = viasFiltradas[index];
          final rotulos = resolveRouteLabels(item.escalada, widget.setor);
          final bool isTarget = widget.scrollToEscalada != null &&
              item.escalada == widget.scrollToEscalada;

          final card = CardIndiceEscalada(
            item: item,
            rotuloCroqui: rotulos,
            mostrarLocalizacao: false,
            isTarget: isTarget,
            onTap: () {
              TelemetryService.instance.logAcaoEscalada(
                widget.cragId,
                widget.setor.nome,
                item.nome,
                'abrir_detalhes',
                'setor_${modalidade.toLowerCase()}',
              );
              AppNav.toVia(
                context,
                escalada: item.escalada,
                setor: widget.setor,
                grupo: widget.grupoContext,
              );
            },
          );

          final child = SafeArea(
            top: false,
            bottom: index == viasFiltradas.length - 1,
            child: isTarget
                ? KeyedSubtree(key: _targetKey, child: card)
                : card,
          );

          return child;
        },
        childCount: viasFiltradas.length,
      ),
    );
  }
}
