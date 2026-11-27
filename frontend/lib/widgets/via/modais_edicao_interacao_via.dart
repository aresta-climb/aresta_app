// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../data/modelos/interacao_via.dart';
import '../../idioma/tradutor_app.dart';
import '../../theme/cores_app.dart';
import '../../view/view_models/formulario_alerta_via_view_model.dart';

const Color _corVermelhoAlertaModal = Color(0xFFD93829);

/// Abre o modal rápido (Dumb UI) para reportar um novo alerta ou editar [alertaInicial] na via.
Future<void> exibirModalFormularioAlertaVia(
  BuildContext context, {
  AlertaSegurancaVia? alertaInicial,
  required Future<void> Function(
    CategoriaAlertaSeguranca categoria,
    String? detalhe,
  ) aoSubmeter,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: context.colors.deepBasalt,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (modalCtx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(modalCtx).viewInsets.bottom,
        ),
        child: _FormularioAlertaViaSheet(
          alertaInicial: alertaInicial,
          aoSubmeter: aoSubmeter,
        ),
      );
    },
  );
}

class _FormularioAlertaViaSheet extends StatefulWidget {
  final AlertaSegurancaVia? alertaInicial;
  final Future<void> Function(
    CategoriaAlertaSeguranca categoria,
    String? detalhe,
  ) aoSubmeter;

  const _FormularioAlertaViaSheet({
    this.alertaInicial,
    required this.aoSubmeter,
  });

  @override
  State<_FormularioAlertaViaSheet> createState() =>
      _FormularioAlertaViaSheetState();
}

class _FormularioAlertaViaSheetState extends State<_FormularioAlertaViaSheet> {
  late final FormularioAlertaViaViewModel _viewModel;
  late final TextEditingController _detalheController;

  @override
  void initState() {
    super.initState();
    final inicial = widget.alertaInicial;
    _viewModel = FormularioAlertaViaViewModel(
      categoriaInicial: inicial?.categoria ?? CategoriaAlertaSeguranca.fauna,
      detalheInicial: inicial?.detalhe ?? '',
    );
    _detalheController = TextEditingController(text: _viewModel.detalhe)
      ..addListener(() => _viewModel.definirDetalhe(_detalheController.text));
  }

  @override
  void dispose() {
    _detalheController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    final modoEdicao = widget.alertaInicial != null;

