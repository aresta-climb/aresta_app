// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../aresta_api/proto/generated/croqui.pb.dart';
import '../../navigation/funcoes_navegacao.dart';
import '../../services/firebase/telemetria.dart';
import '../../theme/cores_app.dart';
import '../../utils/filtro_grau_escalada.dart';
import '../../utils/indexador_escaladas.dart';
import '../../view/function_library/pico_functions.dart';
import '../../view/function_library/biblioteca_funcoes_comuns.dart';
import '../../widgets/card_indice_escalada.dart';
import '../../widgets/mapa_thumbnail.dart';
import '../../services/gerenciador_filtros_croqui.dart';
import '../../widgets/painel_filtros_indice.dart';

/// Tela unificada de exploração de setores e escaladas de um pico.
///
/// Integra em uma visualização fluida com abas dinâmicas:
/// - A aba fixa "Setores" (com contadores dinâmicos, mapa thumbnail, filtros superset e ordenação por mediana);
/// - Abas contextuais para cada modalidade existente no pico (ex: "Esportivas", "Boulders", "Móveis").
///
/// Mantém estado global de filtros unificado ([EstadoFiltrosUnificado]) compartilhado entre
/// todas as abas, permitindo alternar de setores para escaladas preservando preferências do usuário.
class SetoresPage extends StatefulWidget {
  /// O pico cujos setores e escaladas serão explorados.
  final Pico pico;

  /// Identificador do croqui/pico para eventos de telemetria e navegação.
  final String cragId;

  /// Objeto Croqui opcional para navegação contextual completa.
  final Croqui? croqui;

  /// Modalidade opcional para abrir inicialmente a tela (útil para deep links legados).
  final String? modalidadeInicial;

  /// Callback opcional de toque em uma via (usado para navegação customizada ou testes).
  final void Function(ItemIndiceEscalada item)? onViaTap;

  const SetoresPage({
    super.key,
    required this.pico,
    required this.cragId,
    this.croqui,
    this.modalidadeInicial,
    this.onViaTap,
  });

  @override
  State<SetoresPage> createState() => _SetoresPageState();
}

class _SetoresPageState extends State<SetoresPage>
    with TickerProviderStateMixin {
  late List<ItemIndiceEscalada> _todasEscaladas;
  late Map<String, List<ItemIndiceEscalada>> _escaladasPorModalidade;
  late List<String> _modalidadesDisponiveis;
  late List<String> _abasDisponiveis;

  TabController? _tabController;
  int _indiceAbaAtual = 0;

  late EstadoFiltrosUnificado _estadoFiltros;

  @override
  void initState() {
    super.initState();
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

  /// Indexa todas as escaladas do pico e organiza as modalidades em ordem preferencial.
  void _inicializarDados() {
    _todasEscaladas = indexarEscaladasDoPico(widget.pico, widget.cragId);

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

    // A primeira aba é sempre 'Setores', seguida pelas modalidades existentes
    _abasDisponiveis = ['Setores', ..._modalidadesDisponiveis];

    int indiceInicial = 0;
    if (widget.modalidadeInicial != null) {
      final buscada = widget.modalidadeInicial!.toLowerCase().trim();
      final idx = _abasDisponiveis.indexWhere(
        (aba) =>
            aba.toLowerCase() == buscada ||
            _obterNomePluralModalidade(aba).toLowerCase() == buscada,
      );
      if (idx != -1) {
        indiceInicial = idx;
      }
    }

    _indiceAbaAtual = indiceInicial;

    _tabController = TabController(
      length: _abasDisponiveis.length,
      initialIndex: indiceInicial,
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

  @override
  void didUpdateWidget(SetoresPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pico != widget.pico || oldWidget.cragId != widget.cragId) {
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

  /// Retorna o nome no plural amigável para exibição na aba.
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

  /// Formata o rótulo da aba com contadores dinâmicos `(filtradas/total)` ou `(total)`.
  String _formatarRotuloAba(String aba) {
    if (aba == 'Setores') {
      final contador = _estadoFiltros.obterContadorSetores(
        widget.pico.setoresOuGrupos,
        _todasEscaladas,
      );
      return 'Setores $contador';
    }

    final nomePlural = _obterNomePluralModalidade(aba);
    final contador = _estadoFiltros.obterContadorModalidade(aba, _todasEscaladas);
    return '$nomePlural $contador';
  }

  /// Retorna os nomes de todos os setores disponíveis para filtros no contexto atual.
  List<String> _obterSetoresDisponiveis(String abaAtual) {
    if (abaAtual == 'Setores') {
      return widget.pico.setoresOuGrupos
          .where((sg) =>
              sg.whichTipo() == SetorOuGrupo_Tipo.setor && sg.setor.hasConteudo())
          .map((sg) => sg.setor.conteudo.nome)
          .toList();
    }
    final vias = _escaladasPorModalidade[abaAtual] ?? [];
    return vias.map((v) => v.setor.nome).where((n) => n.isNotEmpty).toSet().toList()
      ..sort((a, b) => a.compareTo(b));
  }

  /// Retorna os nomes de todos os grupos disponíveis no pico.
  List<String> _obterGruposDisponiveis() {
    return widget.pico.setoresOuGrupos
        .where((sg) =>
            sg.whichTipo() == SetorOuGrupo_Tipo.grupo && sg.grupo.hasConteudo())
        .map((sg) => sg.grupo.conteudo.nome)
        .toList()
      ..sort((a, b) => a.compareTo(b));
  }

  /// Retorna os conquistadores disponíveis no contexto atual.
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

  /// Verifica se há vias com destaque/clássicas cadastradas no contexto atual.
  bool _temClassicasDisponiveis(String abaAtual) {
    final List<ItemIndiceEscalada> viasBase = abaAtual == 'Setores'
        ? _todasEscaladas
        : (_escaladasPorModalidade[abaAtual] ?? []);

    return viasBase.any((v) => v.isDestaque);
  }

  /// Retorna a lista de escaladas de um setor específico que atendem aos filtros ativos.
  List<ItemIndiceEscalada> _obterEscaladasFiltradasDoSetor(String setorNome) {
    final viasDoSetor = _todasEscaladas.where((v) => v.setor.nome == setorNome).toList();
    if (!_estadoFiltros.temFiltrosAtivos) {
      return viasDoSetor;
    }
    return _estadoFiltros.filtrarEscaladas(viasDoSetor);
  }

  /// Retorna a lista de escaladas de um grupo específico que atendem aos filtros ativos.
  List<ItemIndiceEscalada> _obterEscaladasFiltradasDoGrupo(String grupoNome) {
    final viasDoGrupo = _todasEscaladas.where((v) => v.grupo?.nome == grupoNome).toList();
    if (!_estadoFiltros.temFiltrosAtivos) {
      return viasDoGrupo;
    }
    return _estadoFiltros.filtrarEscaladas(viasDoGrupo);
  }

  /// Obtém a lista ordenada de setores e grupos, aplicando filtros quando existirem.
  List<SetorOuGrupo> _obterSetoresOuGruposOrdenados() {
    if (_estadoFiltros.temFiltrosAtivos) {
      return _estadoFiltros.filtrarSetores(
        widget.pico.setoresOuGrupos,
        _todasEscaladas,
      );
    }

    final copia = List<SetorOuGrupo>.from(widget.pico.setoresOuGrupos);

    switch (_estadoFiltros.tipoOrdenacao) {
      case TipoOrdenacaoExploracao.padrao:
        return _estadoFiltros.direcaoCrescente ? copia : copia.reversed.toList();

      case TipoOrdenacaoExploracao.alfabetico:
        copia.sort((a, b) {
          final nomeA = EstadoFiltrosUnificado.obterNomeSetorOuGrupo(a).toLowerCase();
          final nomeB = EstadoFiltrosUnificado.obterNomeSetorOuGrupo(b).toLowerCase();
          return _estadoFiltros.direcaoCrescente
              ? nomeA.compareTo(nomeB)
              : nomeB.compareTo(nomeA);
        });
        return copia;

      case TipoOrdenacaoExploracao.grau:
        copia.sort((a, b) {
          final nomeA = EstadoFiltrosUnificado.obterNomeSetorOuGrupo(a);
          final nomeB = EstadoFiltrosUnificado.obterNomeSetorOuGrupo(b);

          final viasA = _todasEscaladas
              .where((e) => e.setor.nome == nomeA || e.grupo?.nome == nomeA)
              .map((e) => e.escalada);
          final viasB = _todasEscaladas
              .where((e) => e.setor.nome == nomeB || e.grupo?.nome == nomeB)
              .map((e) => e.escalada);

          final medA = calcularMedianaGrauSetor(viasA);
          final medB = calcularMedianaGrauSetor(viasB);

          final comp = _estadoFiltros.direcaoCrescente
              ? medA.compareTo(medB)
              : medB.compareTo(medA);
          if (comp != 0) return comp;
          return nomeA.toLowerCase().compareTo(nomeB.toLowerCase());
        });
        return copia;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasMap = widget.pico.hasMapasGerais() &&
        widget.pico.mapasGerais.hasConteudo() &&
        widget.pico.mapasGerais.conteudo.mapas.isNotEmpty;

    final abaAtual = _abasDisponiveis[_tabController?.index ?? 0];
    final bool isAbaSetores = abaAtual == 'Setores';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: buildCommonAppBar(
        context,
        'SETORES & ESCALADAS',
        subtitle: widget.pico.nome,
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Mapa Interativo (renderizado no topo, antes de abas e filtros)
          if (hasMap)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: MapaThumbnail(
                  mapas: widget.pico.mapasGerais.conteudo.mapas,
                  cragId: widget.cragId,
                  nomeContexto: widget.pico.nome,
                ),
              ),
            ),

          // 2. Abas [Setores | Esportivas | Boulders...], Filtros e Barra de Ordenação
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Barra de abas integradas (renderizada quando há setores e modalidades)
                if (_abasDisponiveis.length > 1 && _tabController != null)
                  Container(
                    color: colors.deepBasalt,
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

                // Painel de Filtros Unificado (Superset na aba Setores, Contextual nas demais)
                PainelFiltrosIndice(
                  cragId: widget.cragId,
                  estadoUnificado: _estadoFiltros,
                  abaAtiva: abaAtual,
                  modalidadesDisponiveis: _modalidadesDisponiveis,
                  setoresDisponiveis: _obterSetoresDisponiveis(abaAtual),
                  gruposDisponiveis: _obterGruposDisponiveis(),
                  conquistadoresDisponiveis: _obterConquistadoresDisponiveis(abaAtual),
                  temClassicasDisponiveis: _temClassicasDisponiveis(abaAtual),
                  onFiltrosUnificadosChanged: _atualizarEstadoFiltros,
                ),
              ],
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

  /// Constrói o sliver da lista de setores e grupos.
  Widget _buildSliverSetores(BuildContext context) {
    final colors = context.colors;
    final setoresOuGruposOrdenados = _obterSetoresOuGruposOrdenados();

    if (setoresOuGruposOrdenados.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.filter_alt_off,
                  size: 48,
                  color: colors.ashGrey.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'Nenhum setor encontrado com os filtros selecionados.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.ashGrey, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: setoresOuGruposOrdenados.map((sg) {
          if (sg.whichTipo() == SetorOuGrupo_Tipo.setor &&
              sg.setor.hasConteudo()) {
            final setor = sg.setor.conteudo;
            final viasFiltradas = _obterEscaladasFiltradasDoSetor(setor.nome);
            final escaladasFiltradas = _estadoFiltros.temFiltrosAtivos
                ? viasFiltradas.map((e) => e.escalada)
                : null;

            return buildSectorTile(
              context,
              setor,
              widget.cragId,
              escaladasFiltradas: escaladasFiltradas,
            );
          } else if (sg.whichTipo() == SetorOuGrupo_Tipo.grupo &&
              sg.grupo.hasConteudo()) {
            final grupo = sg.grupo.conteudo;
            final viasFiltradas = _obterEscaladasFiltradasDoGrupo(grupo.nome);
            final escaladasFiltradas = _estadoFiltros.temFiltrosAtivos
                ? viasFiltradas.map((e) => e.escalada)
                : null;

            return buildGrupoTile(
              context,
              grupo,
              widget.cragId,
              escaladasFiltradas: escaladasFiltradas,
            );
          }
          return const SizedBox.shrink();
        }).toList(),
      ),
    );
  }

  /// Constrói o sliver da lista de escaladas de uma modalidade.
  Widget _buildSliverModalidade(BuildContext context, String modalidade) {
    final colors = context.colors;
    final viasFiltradas = _estadoFiltros.filtrarEscaladas(
      _todasEscaladas,
      modalidadeEspecifica: modalidade,
    );

    if (viasFiltradas.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.filter_alt_off,
                  size: 48,
                  color: colors.ashGrey.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'Nenhuma escalada encontrada com os filtros selecionados.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.ashGrey, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: viasFiltradas.map((item) {
          return CardIndiceEscalada(
            item: item,
            onTap: () {
              TelemetryService.instance.logAcaoEscalada(
                widget.cragId,
                item.setor.nome,
                item.nome,
                'abrir_detalhes',
                'exploracao_${modalidade.toLowerCase()}',
              );
              if (widget.onViaTap != null) {
                widget.onViaTap!(item);
              } else {
                AppNav.toVia(
                  context,
                  escalada: item.escalada,
                  pico: widget.pico,
                  setor: item.setor,
                  grupo: item.grupo,
                  cragId: widget.cragId,
                );
              }
            },
          );
        }).toList(),
      ),
    );
  }
}
