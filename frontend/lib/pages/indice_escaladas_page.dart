// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../navigation/navigation_functions.dart';
import '../theme/app_colors.dart';
import '../utils/filtro_grau_escalada.dart';
import '../utils/indexador_escaladas.dart';
import '../view_functions/common_functions.dart';
import '../widgets/card_indice_escalada.dart';
import '../widgets/painel_filtros_indice.dart';

/// Página completa do Índice de Escaladas de um pico, estruturada em abas dinâmicas
/// por modalidade (ex: 'Esportivas', 'Boulders', 'Móveis', 'Multienfiadas'),
/// com painel expansível de filtros contextuais e listagem rápida com navegação direta.
class IndiceEscaladasPage extends StatefulWidget {
  final Pico pico;
  final Croqui croqui;
  final String cragId;

  /// Callback opcional para navegação customizada ou testes.
  final void Function(ItemIndiceEscalada item)? onViaTap;

  const IndiceEscaladasPage({
    super.key,
    required this.pico,
    required this.croqui,
    required this.cragId,
    this.onViaTap,
  });

  @override
  State<IndiceEscaladasPage> createState() => _IndiceEscaladasPageState();
}

class _IndiceEscaladasPageState extends State<IndiceEscaladasPage>
    with TickerProviderStateMixin {
  late List<ItemIndiceEscalada> _todasEscaladas;
  late List<String> _modalidadesDisponiveis;
  late Map<String, List<ItemIndiceEscalada>> _itensPorModalidade;
  late Map<String, EstadoFiltrosIndice> _filtrosPorModalidade;

  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _inicializarDados();
  }

  void _inicializarDados() {
    _todasEscaladas = indexarEscaladasDoPico(widget.pico, widget.cragId);

    // Mapeamento de modalidades padronizadas
    const ordemPreferencial = [
      'Esportiva',
      'Boulder',
      'Móvel',
      'Multienfiada',
      'Highline',
    ];

    _itensPorModalidade = {};
    for (final item in _todasEscaladas) {
      final mod = item.modalidade.isNotEmpty ? item.modalidade : 'Outras';
      _itensPorModalidade.putIfAbsent(mod, () => []).add(item);
    }

    _modalidadesDisponiveis = ordemPreferencial
        .where((m) => _itensPorModalidade.containsKey(m))
        .toList();

    for (final mod in _itensPorModalidade.keys) {
      if (!_modalidadesDisponiveis.contains(mod)) {
        _modalidadesDisponiveis.add(mod);
      }
    }

    // Inicializa estados independentes de filtro por modalidade
    _filtrosPorModalidade = {
      for (final mod in _modalidadesDisponiveis)
        mod: const EstadoFiltrosIndice(),
    };

    if (_modalidadesDisponiveis.isNotEmpty) {
      _tabController = TabController(
        length: _modalidadesDisponiveis.length,
        vsync: this,
      );
      _tabController!.addListener(() {
        if (!_tabController!.indexIsChanging) {
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  /// Retorna a lista de setores que possuem escaladas na modalidade informada.
  List<String> _obterSetoresParaModalidade(String modalidade) {
    final itens = _itensPorModalidade[modalidade] ?? [];
    return itens
        .map((i) => i.setor.nome)
        .where((nome) => nome.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.compareTo(b));
  }

  /// Retorna a lista de conquistadores que possuem escaladas na modalidade informada.
  List<String> _obterConquistadoresParaModalidade(String modalidade) {
    final itens = _itensPorModalidade[modalidade] ?? [];
    return itens
        .expand((i) => i.conquistadores)
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.compareTo(b));
  }

  String _formatarNomeAba(String modalidade, int quantidade) {
    switch (modalidade) {
      case 'Esportiva':
        return 'Esportivas ($quantidade)';
      case 'Boulder':
        return 'Boulders ($quantidade)';
      case 'Móvel':
        return 'Móveis ($quantidade)';
      case 'Multienfiada':
        return 'Multienfiadas ($quantidade)';
      case 'Highline':
        return 'Highlines ($quantidade)';
      default:
        return '$modalidade ($quantidade)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_modalidadesDisponiveis.isEmpty) {
      return Scaffold(
        backgroundColor: colors.deepBasalt,
        appBar: buildCommonAppBar(
          context,
          'ÍNDICE DE ESCALADAS',
          subtitle: widget.pico.nome,
        ),
        body: Center(
          child: Text(
            'Nenhuma escalada cadastrada neste pico.',
            style: TextStyle(color: colors.ashGrey, fontSize: 16),
          ),
        ),
      );
    }

    final modalidadeAtiva = _modalidadesDisponiveis[_tabController?.index ?? 0];
    final estadoAtivo = _filtrosPorModalidade[modalidadeAtiva] ?? const EstadoFiltrosIndice();
    final itensDaModalidade = _itensPorModalidade[modalidadeAtiva] ?? [];
    final itensFiltrados = estadoAtivo.aplicar(itensDaModalidade);

    return Scaffold(
      backgroundColor: colors.deepBasalt,
      appBar: buildCommonAppBar(
        context,
        'ÍNDICE DE ESCALADAS',
        subtitle: widget.pico.nome,
      ),
      body: Column(
        children: [
          // Abas Dinâmicas de Modalidades (renderizadas apenas se houver mais de uma)
          if (_modalidadesDisponiveis.length > 1 && _tabController != null)
            Container(
              color: colors.deepBasalt,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: colors.rustIron,
                indicatorWeight: 3,
                labelColor: colors.chalkWhite,
                unselectedLabelColor: colors.ashGrey,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                tabs: _modalidadesDisponiveis.map((mod) {
                  final qtd = _itensPorModalidade[mod]?.length ?? 0;
                  return Tab(text: _formatarNomeAba(mod, qtd));
                }).toList(),
              ),
            ),

          // Painel Expansível de Filtros com RangeSlider e Dropdowns com Chips
          PainelFiltrosIndice(
            estado: estadoAtivo,
            modalidade: modalidadeAtiva,
            setoresDisponiveis:
                estadoAtivo.obterSetoresDisponiveis(itensDaModalidade),
            conquistadoresDisponiveis:
                estadoAtivo.obterConquistadoresDisponiveis(itensDaModalidade),
            possuiConquistadores:
                _obterConquistadoresParaModalidade(modalidadeAtiva).isNotEmpty,
            temClassicasDisponiveis:
                estadoAtivo.temClassicasDisponiveis(itensDaModalidade),
            onFiltrosChanged: (novoEstado) {
              setState(() {
                _filtrosPorModalidade[modalidadeAtiva] = novoEstado;
              });
            },
          ),

          // Contador de resultados e cabeçalho da lista
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${itensFiltrados.length} ${itensFiltrados.length == 1 ? 'escalada' : 'escaladas'}',
                  style: TextStyle(
                    color: colors.ashGrey,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (estadoAtivo.temFiltrosAtivos)
                  Text(
                    'Filtros aplicados',
                    style: TextStyle(
                      color: colors.rustIron,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),

          // Lista rolante de escaladas
          Expanded(
            child: itensFiltrados.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
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
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: itensFiltrados.length,
                    itemBuilder: (context, index) {
                      final item = itensFiltrados[index];
                      return CardIndiceEscalada(
                        item: item,
                        onTap: () {
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
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
