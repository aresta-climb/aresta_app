// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';

import '../../idioma/tradutor_app.dart';
import '../../theme/cores_app.dart';
import '../../utils/filtro_grau_escalada.dart';
import '../../view/function_library/biblioteca_funcoes_comuns.dart';
import '../../view/view_models/explorar_view_model.dart';
import 'modal_filtros_ordenacao_explorar.dart';

export 'modal_filtros_ordenacao_explorar.dart';

/// Barra superior flutuante da aba unificada `Explorar` (Dumb UI).
///
/// Reúne pesquisa difusa textual, botão de abertura do modal `Filtros e Ordenação`
/// com contador de recortes ativos e fileira horizontal de chips removíveis.
class BarraBuscaFiltrosExplorar extends StatefulWidget {
  final BrowseViewModel viewModel;
  final VoidCallback? aoSincronizar;
  final VoidCallback? aoTrocarServing;

  const BarraBuscaFiltrosExplorar({
    super.key,
    required this.viewModel,
    this.aoSincronizar,
    this.aoTrocarServing,
  });

  @override
  State<BarraBuscaFiltrosExplorar> createState() =>
      _BarraBuscaFiltrosExplorarState();
}

class _BarraBuscaFiltrosExplorarState extends State<BarraBuscaFiltrosExplorar> {
  final TextEditingController _controladorTexto = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controladorTexto.text = widget.viewModel.termoBusca;
    widget.viewModel.addListener(_sincronizarTextoComViewModel);
  }

  @override
  void didUpdateWidget(covariant BarraBuscaFiltrosExplorar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.removeListener(_sincronizarTextoComViewModel);
      widget.viewModel.addListener(_sincronizarTextoComViewModel);
      _sincronizarTextoComViewModel();
    }
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_sincronizarTextoComViewModel);
    _controladorTexto.dispose();
    super.dispose();
  }

  void _sincronizarTextoComViewModel() {
    if (_controladorTexto.text != widget.viewModel.termoBusca) {
      _controladorTexto.value = TextEditingValue(
        text: widget.viewModel.termoBusca,
        selection: TextSelection.collapsed(
          offset: widget.viewModel.termoBusca.length,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final colors = context.colors;

    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final totalAtivos = vm.totalFiltrosAtivos;
        final chipsAtivos = _construirChipsAtivos(context, vm);

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xDF141920),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: colors.ashGrey,
                            size: 19,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _controladorTexto,
                              onChanged: vm.alterarTermoBusca,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: context.tr(
                                  ChaveTexto.explorarBuscaHint,
                                ),
                                hintStyle: TextStyle(
                                  color: colors.ashGrey,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          if (vm.termoBusca.isNotEmpty)
                            InkWell(
                              key: const Key('botao_limpar_busca_explorar'),
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                _controladorTexto.clear();
                                vm.alterarTermoBusca('');
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 17,
                                  color: colors.ashGrey,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Material(
                        color: totalAtivos > 0
                            ? colors.rustIron.withValues(alpha: 0.22)
                            : const Color(0xDF141920),
                        borderRadius: BorderRadius.circular(22),
                        child: InkWell(
                          key: const Key('botao_abrir_filtros_explorar'),
                          borderRadius: BorderRadius.circular(22),
                          onTap: () => exibirModalFiltrosOrdenacaoExplorar(
                            context: context,
                            viewModel: vm,
                          ),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: totalAtivos > 0
                                    ? colors.rustIron
                                    : Colors.white12,
                              ),
                            ),
                            child: Icon(
                              Icons.tune_rounded,
                              size: 19,
                              color: totalAtivos > 0
                                  ? colors.rustIron
                                  : colors.chalkWhite,
                            ),
                          ),
                        ),
                      ),
                      if (totalAtivos > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: colors.rustIron,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$totalAtivos',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (widget.aoSincronizar != null) ...[
                    const SizedBox(width: 4),
                    Container(
                      width: 40,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xDF141920),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        tooltip: context.tr(
                          ChaveTexto.comumSincronizarServingTooltip,
                        ),
                        icon: Icon(
                          Icons.sync_rounded,
                          size: 18,
                          color: colors.chalkWhite,
                        ),
                        onPressed: widget.aoSincronizar,
                      ),
                    ),
                  ],
                  if (widget.aoTrocarServing != null) ...[
                    const SizedBox(width: 4),
                    Container(
                      width: 40,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xDF141920),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colors.beastHide.withValues(alpha: 0.6),
                        ),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        tooltip: context.tr(ChaveTexto.explorarTrocarServing),
                        icon: Icon(
                          Icons.dns_outlined,
                          size: 18,
                          color: colors.beastHide,
                        ),
                        onPressed: widget.aoTrocarServing,
                      ),
                    ),
                  ],
                  buildFeedbackButton(context, color: Colors.white70),
                ],
              ),
              if (chipsAtivos.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: chipsAtivos),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _construirChipsAtivos(BuildContext context, BrowseViewModel vm) {
    final chips = <Widget>[];
    for (final mod in vm.modalidadesAtivas) {
      chips.add(
        _ChipFiltroRemovivel(
          key: Key('chip_ativo_modalidade_${mod.name}'),
          rotulo: mod.rotulo,
          aoRemover: () => vm.alternarModalidade(mod),
        ),
      );
    }
    if (vm.temFiltroGrauVia) {
      final resumo = formatarResumoGrauExplorar(
        OpcoesGrau.grausVia,
        vm.minGrauVia,
        vm.maxGrauVia,
      );
      chips.add(
        _ChipFiltroRemovivel(
          key: const Key('chip_ativo_grau_via'),
          rotulo: '${context.tr(ChaveTexto.modVias)} $resumo',
          aoRemover: () => vm.definirFaixaGrauVia(null, null),
        ),
      );
    }
    if (vm.temFiltroGrauBoulder) {
      final resumo = formatarResumoGrauExplorar(
        OpcoesGrau.grausBoulder,
        vm.minGrauBoulder,
        vm.maxGrauBoulder,
      );
      chips.add(
        _ChipFiltroRemovivel(
          key: const Key('chip_ativo_grau_boulder'),
          rotulo: '${context.tr(ChaveTexto.modBoulder)} $resumo',
          aoRemover: () => vm.definirFaixaGrauBoulder(null, null),
        ),
      );
    }
    if (vm.raioMaximoKm != null) {
      chips.add(
        _ChipFiltroRemovivel(
          key: const Key('chip_ativo_raio'),
          rotulo: context.tr(
            ChaveTexto.explorarAteKm,
            {'km': vm.raioMaximoKm!.toInt()},
          ),
          aoRemover: () => vm.definirRaioMaximoKm(null),
        ),
      );
    }
    if (vm.apenasSalvosOffline) {
      chips.add(
        _ChipFiltroRemovivel(
          key: const Key('chip_ativo_offline'),
          rotulo: context.tr(ChaveTexto.explorarSalvosOffline),
          aoRemover: () => vm.definirApenasSalvosOffline(false),
        ),
      );
    }
    return chips;
  }
}

class _ChipFiltroRemovivel extends StatelessWidget {
  final String rotulo;
  final VoidCallback aoRemover;

  const _ChipFiltroRemovivel({
    super.key,
    required this.rotulo,
    required this.aoRemover,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: const Color(0xE618202A),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: aoRemover,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.rustIron.withValues(alpha: 0.7),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  rotulo,
                  style: TextStyle(
                    color: colors.chalkWhite,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.close_rounded, size: 13, color: colors.rustIron),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
