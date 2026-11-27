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
