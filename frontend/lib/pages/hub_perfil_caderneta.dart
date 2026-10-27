// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../services/caderneta/repositorio_caderneta.dart';
import '../theme/cores_app.dart';
import '../view/function_library/funcoes_hub_perfil_caderneta.dart';
import '../view/function_library/biblioteca_funcoes_comuns.dart';
import '../view/view_models/hub_perfil_caderneta_view_model.dart';
import '../navigation/funcoes_navegacao.dart';

/// Página central do Hub de Perfil do Escalador e Caderneta Esportiva.
///
/// Implementada como interface gráfica puramente declarativa (Dumb UI), delegando
/// o estado, métricas reativas e ações ao [HubPerfilCadernetaViewModel] e a
/// composição visual à biblioteca [funcoes_hub_perfil_caderneta.dart].
class HubPerfilCadernetaPage extends StatefulWidget {
  /// ViewModel injetado (ou inicializado por padrão com a instância local-first).
  final HubPerfilCadernetaViewModel? viewModel;

  const HubPerfilCadernetaPage({super.key, this.viewModel});

  @override
  State<HubPerfilCadernetaPage> createState() => _HubPerfilCadernetaPageState();
}

class _HubPerfilCadernetaPageState extends State<HubPerfilCadernetaPage> {
  late final HubPerfilCadernetaViewModel _viewModel;
  bool _criouViewModelInterno = false;

  @override
  void initState() {
    super.initState();
    if (widget.viewModel != null) {
      _viewModel = widget.viewModel!;
    } else {
      _viewModel = HubPerfilCadernetaViewModel(
        repositorio: RepositorioCadernetaLocal.instancia,
      );
      _criouViewModelInterno = true;
    }
  }

  @override
  void dispose() {
    if (_criouViewModelInterno) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  void _onAbrirCaderneta(BuildContext context) {
    if (_viewModel.aoAbrirCaderneta != null) {
      _viewModel.abrirCaderneta(context);
    } else {
      AppNav.toCaderneta(context);
    }
  }

  void _onAbrirConfiguracoes(BuildContext context) {
    if (_viewModel.aoAbrirConfiguracoes != null) {
      _viewModel.abrirConfiguracoes(context);
    } else {
      AppNav.toSettings(context);
    }
