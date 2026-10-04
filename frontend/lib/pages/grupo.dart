// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../navigation/funcoes_navegacao.dart';
import '../services/firebase/telemetria.dart';
import '../services/gerenciador_filtros_croqui.dart';
import '../theme/cores_app.dart';
import '../utils/filtro_grau_escalada.dart';
import '../utils/indexador_escaladas.dart';
import '../view/function_library/biblioteca_funcoes_comuns.dart';
import '../view/function_library/markdown_offline.dart';
import '../view/function_library/pico_functions.dart';
import '../widgets/barra_ordenacao_exploracao.dart';
import '../widgets/card_indice_escalada.dart';
import '../widgets/mapa_thumbnail.dart';
import '../widgets/painel_filtros_indice.dart';

/// Uma página que exibe informações detalhadas sobre um grupo específico de setores.
///
/// Apresenta capa animada, descrição, mapa (se houver), e a mesma interface unificada de
/// exploração com abas dinâmicas, filtros superset/contextuais e ordenação por grau/alfabético,
/// sincronizada globalmente no croqui com o [GerenciadorFiltrosCroqui].
class GrupoPage extends StatefulWidget {
  /// O grupo cujos setores e escaladas serão explorados.
  final Grupo grupo;

  /// Identificador do croqui para telemetria, navegação e persistência de filtros.
  final String cragId;

  /// Objeto Croqui opcional para navegação contextual completa.
  final Croqui? croqui;

  /// Callback opcional de toque em uma via (usado para navegação customizada ou testes).
  final void Function(ItemIndiceEscalada item)? onViaTap;

  const GrupoPage({
    super.key,
    required this.grupo,
    required this.cragId,
    this.croqui,
    this.onViaTap,
  });

  @override
  State<GrupoPage> createState() => _GrupoPageState();
}

class _GrupoPageState extends State<GrupoPage>
    with TickerProviderStateMixin {
  late List<ItemIndiceEscalada> _todasEscaladas;
  late Map<String, List<ItemIndiceEscalada>> _escaladasPorModalidade;
  late List<String> _modalidadesDisponiveis;
  late List<String> _abasDisponiveis;

  TabController? _tabController;
  int _indiceAbaAtual = 0;

  late EstadoFiltrosUnificado _estadoFiltros;
  Future<ImageProvider?>? _coverProviderFuture;

  @override
  void initState() {
    super.initState();
    _coverProviderFuture = _resolveCoverImage();
    _estadoFiltros =
        GerenciadorFiltrosCroqui.instance.obterFiltros(widget.cragId);
    GerenciadorFiltrosCroqui.instance.addListener(_onFiltrosGlobaisAlterados);
    _inicializarDados();
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

  @override
  void didUpdateWidget(GrupoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.grupo != widget.grupo || oldWidget.cragId != widget.cragId) {
      _coverProviderFuture = _resolveCoverImage();
      _tabController?.dispose();
      _estadoFiltros =
          GerenciadorFiltrosCroqui.instance.obterFiltros(widget.cragId);
      _inicializarDados();
    }
  }

  @override
  void dispose() {
    GerenciadorFiltrosCroqui.instance.removeListener(_onFiltrosGlobaisAlterados);
    _tabController?.dispose();
    super.dispose();
  }

  bool get _temCapa =>
      widget.grupo.hasCaminhoImagemCapa() &&
      widget.grupo.caminhoImagemCapa.isNotEmpty;

  /// Resolve a imagem de capa do grupo a partir do caminhoImagemCapa.
  Future<ImageProvider?> _resolveCoverImage() async {
    if (_temCapa) {
      return resolveImagePathProvider(
        widget.cragId,
        widget.grupo.caminhoImagemCapa,
        larguraAlvo: 600,
      );
    }
    return null;
  }

  /// Indexa todas as escaladas dos setores do grupo e organiza as modalidades em ordem preferencial.
  void _inicializarDados() {
    _todasEscaladas = indexarEscaladasDoGrupo(widget.grupo, widget.cragId);

    const ordemPreferencial = [
      'Esportiva',
      'Boulder',
      'Móvel',
      'Multienfiada',
      'Highline',
    ];

    _escaladasPorModalidade = {};
    for (final item in _todasEscaladas) {
      final mod = item.modalidade.isNotEmpty ? item.modalidade : 'Outras';
      _escaladasPorModalidade.putIfAbsent(mod, () => []).add(item);
    }

    _modalidadesDisponiveis = ordemPreferencial
        .where((m) => _escaladasPorModalidade.containsKey(m))
        .toList();

    for (final mod in _escaladasPorModalidade.keys) {
      if (!_modalidadesDisponiveis.contains(mod)) {
        _modalidadesDisponiveis.add(mod);
      }
    }

    _abasDisponiveis = ['Setores', ..._modalidadesDisponiveis];

    _indiceAbaAtual = 0;
    _tabController = TabController(
      length: _abasDisponiveis.length,
      initialIndex: 0,
      vsync: this,
    );

    _tabController!.addListener(() {
      if (!_tabController!.indexIsChanging &&
          _tabController!.index != _indiceAbaAtual) {
        final novaAba = _abasDisponiveis[_tabController!.index];
        _indiceAbaAtual = _tabController!.index;
        TelemetryService.instance.logAcaoIndiceEscaladas(
          widget.cragId,
          'trocar_aba',
          modalidade: novaAba,
          detalhe: novaAba,
        );
        setState(() {});
      }
    });
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

  String _formatarRotuloAba(String aba) {
    if (aba == 'Setores') {
      final total = widget.grupo.setores.where((s) => s.hasConteudo()).length;
      if (_estadoFiltros.temFiltrosAtivos) {
        final filtrados = _obterSetoresFiltrados().length;
        return 'Setores ($filtrados/$total)';
      }
      return 'Setores ($total)';
    }

    final nomePlural = _obterNomePluralModalidade(aba);
    final contador = _estadoFiltros.obterContadorModalidade(aba, _todasEscaladas);
    return '$nomePlural $contador';
  }

  List<String> _obterSetoresDisponiveis(String abaAtual) {
    if (abaAtual == 'Setores') {
      return widget.grupo.setores
          .where((s) => s.hasConteudo())
          .map((s) => s.conteudo.nome)
          .toList()
        ..sort((a, b) => a.compareTo(b));
    }
    final vias = _escaladasPorModalidade[abaAtual] ?? [];
    return vias.map((v) => v.setor.nome).where((n) => n.isNotEmpty).toSet().toList()
      ..sort((a, b) => a.compareTo(b));
  }

  List<String> _obterConquistadoresDisponiveis(String abaAtual) {
    final List<ItemIndiceEscalada> viasBase = abaAtual == 'Setores'
        ? _todasEscaladas
        : (_escaladasPorModalidade[abaAtual] ?? []);

    return viasBase
        .expand((v) => v.conquistadores)
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.compareTo(b));
  }

  bool _temClassicasDisponiveis(String abaAtual) {
    final List<ItemIndiceEscalada> viasBase = abaAtual == 'Setores'
        ? _todasEscaladas
        : (_escaladasPorModalidade[abaAtual] ?? []);

    return viasBase.any((v) => v.isDestaque);
  }

  /// Retorna os setores do grupo filtrados e ordenados.
  List<Setor> _obterSetoresFiltrados() {
    final List<Setor> setoresValidos = widget.grupo.setores
        .where((s) => s.hasConteudo())
        .map((s) => s.conteudo)
        .toList();

    List<Setor> filtrados;
    if (_estadoFiltros.temFiltrosAtivos) {
      final viasValidas = _estadoFiltros.filtrarEscaladas(_todasEscaladas);
      final nomesSetoresComVias = viasValidas.map((v) => v.setor.nome).toSet();
      filtrados = setoresValidos
          .where((setor) => nomesSetoresComVias.contains(setor.nome))
          .toList();
    } else {
      filtrados = List<Setor>.from(setoresValidos);
    }

    switch (_estadoFiltros.tipoOrdenacao) {
      case TipoOrdenacaoExploracao.padrao:
        return _estadoFiltros.direcaoCrescente ? filtrados : filtrados.reversed.toList();
      case TipoOrdenacaoExploracao.alfabetico:
        filtrados.sort((a, b) {
          final comp = a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
          return _estadoFiltros.direcaoCrescente ? comp : -comp;
        });
        return filtrados;
      case TipoOrdenacaoExploracao.grau:
        filtrados.sort((a, b) {
          final medA = calcularMedianaGrauSetor(a.escaladas);
          final medB = calcularMedianaGrauSetor(b.escaladas);
          final comp = _estadoFiltros.direcaoCrescente
              ? medA.compareTo(medB)
              : medB.compareTo(medA);
          if (comp != 0) return comp;
          return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
        });
        return filtrados;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final validMapas = widget.grupo.mapas
        .where((m) =>
            m.caminhoImagemMapa.isNotEmpty &&
            m.larguraMapa > 0 &&
            m.alturaMapa > 0)
        .toList();

    final abaAtual = _abasDisponiveis[_tabController?.index ?? 0];
    final bool isAbaSetores = abaAtual == 'Setores';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // 1. Cabeçalho com Capa Animada e Título
          SliverAppBar(
            expandedHeight: _temCapa ? 300.0 : null,
            pinned: true,
            backgroundColor: context.colors.deepBasalt,
            iconTheme: IconThemeData(color: context.colors.chalkWhite),
            title: !_temCapa
                ? Text(
                    widget.grupo.nome.toUpperCase(),
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
                      double t =
                          (top - collapsedHeight) / (expandedHeight - collapsedHeight);
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
                              widget.grupo.nome.toUpperCase(),
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

          // 2. Seção Fixa: Descrição, Mapa, Abas de Modalidade, Filtros e Ordenação
          SliverToBoxAdapter(
            child: SafeArea(
              top: false,
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Descrição do Grupo
                  if (widget.grupo.descricao.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: OfflineMarkdown(
                        data: widget.grupo.descricao,
                        cragId: widget.cragId,
                      ),
                    ),

                  // Mapa Thumbnail do Grupo
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
                            grupoContext: widget.grupo,
                            nomeContexto: widget.grupo.nome,
                          ),
                        ),
                      ),
                    ),

                  // Barra de Abas Dinâmicas [Setores | Esportivas | Boulders | ...]
                  if (_abasDisponiveis.length > 1)
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
                        tabs: _abasDisponiveis.map((aba) {
                          return Tab(text: _formatarRotuloAba(aba));
                        }).toList(),
                      ),
                    ),

                  // Painel de Filtros Unificado
                  PainelFiltrosIndice(
                    cragId: widget.cragId,
                    estadoUnificado: _estadoFiltros,
                    abaAtiva: abaAtual,
                    modalidadesDisponiveis: _modalidadesDisponiveis,
                    setoresDisponiveis: _obterSetoresDisponiveis(abaAtual),
                    gruposDisponiveis: const [],
                    conquistadoresDisponiveis:
                        _obterConquistadoresDisponiveis(abaAtual),
                    temClassicasDisponiveis: _temClassicasDisponiveis(abaAtual),
                    onFiltrosUnificadosChanged: _atualizarEstadoFiltros,
                  ),

                  // Barra de Ordenação
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: BarraOrdenacaoExploracao(
                      ordenacaoAtual: _estadoFiltros.tipoOrdenacao,
                      direcaoCrescente: _estadoFiltros.direcaoCrescente,
                      onOrdenacaoChanged: (novoModo) {
                        final modoStr = novoModo == TipoOrdenacaoExploracao.alfabetico
                            ? (_estadoFiltros.direcaoCrescente ? 'alphaAsc' : 'alphaDesc')
                            : novoModo.name;
                        TelemetryService.instance.logAlterarOrdenacao('grupo', modoStr);
                        _atualizarEstadoFiltros(
                          _estadoFiltros.copyWith(tipoOrdenacao: novoModo),
                        );
                      },
                      onDirecaoChanged: (novaDirecao) {
                        if (_estadoFiltros.tipoOrdenacao ==
                            TipoOrdenacaoExploracao.alfabetico) {
                          TelemetryService.instance.logAlterarOrdenacao(
                            'grupo',
                            novaDirecao ? 'alphaAsc' : 'alphaDesc',
                          );
                        }
                        _atualizarEstadoFiltros(
                          _estadoFiltros.copyWith(direcaoCrescente: novaDirecao),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Conteúdo da aba ativa: Lista de Setores ou Lista de Escaladas
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              24 + MediaQuery.of(context).padding.bottom,
            ),
            sliver: isAbaSetores
                ? _buildSliverSetores(context)
                : _buildSliverModalidade(context, abaAtual),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverSetores(BuildContext context) {
    final colors = context.colors;
    final setoresFiltrados = _obterSetoresFiltrados();

    if (setoresFiltrados.isEmpty) {
      return SliverToBoxAdapter(
        child: SafeArea(
          top: false,
          bottom: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'Nenhum setor disponível.',
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
          final setor = setoresFiltrados[index];
          final viasDoSetor =
              _todasEscaladas.where((e) => e.setor.nome == setor.nome).toList();
          final viasFiltradas = _estadoFiltros.temFiltrosAtivos
              ? _estadoFiltros.filtrarEscaladas(viasDoSetor)
              : viasDoSetor;
          final escaladasFiltradas = _estadoFiltros.temFiltrosAtivos
              ? viasFiltradas.map((e) => e.escalada)
              : null;

          return SafeArea(
            top: false,
            bottom: index == setoresFiltrados.length - 1,
            child: buildSectorTile(
              context,
              setor,
              widget.cragId,
              grupoContext: widget.grupo,
              escaladasFiltradas: escaladasFiltradas,
            ),
          );
        },
        childCount: setoresFiltrados.length,
      ),
    );
  }

  Widget _buildSliverModalidade(BuildContext context, String modalidade) {
    final colors = context.colors;
    final viasBase = _escaladasPorModalidade[modalidade] ?? [];
    final viasFiltradas = _estadoFiltros.filtrarEscaladas(
      viasBase,
      modalidadeEspecifica: modalidade,
    );

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
          return SafeArea(
            top: false,
            bottom: index == viasFiltradas.length - 1,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CardIndiceEscalada(
                item: item,
                onTap: () {
                  TelemetryService.instance.logAcaoEscalada(
                    widget.cragId,
                    item.setor.nome,
                    item.nome,
                    'abrir_detalhes',
                    'grupo_${modalidade.toLowerCase()}',
                  );
                  if (widget.onViaTap != null) {
                    widget.onViaTap!(item);
                  } else {
                    AppNav.toVia(
                      context,
                      escalada: item.escalada,
                      setor: item.setor,
                      grupo: widget.grupo,
                      croqui: widget.croqui,
                      cragId: widget.cragId,
                    );
                  }
                },
              ),
            ),
          );
        },
        childCount: viasFiltradas.length,
      ),
    );
  }
}
