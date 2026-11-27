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

