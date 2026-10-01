// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/cores_app.dart';
import '../view/view_models/home_view_model.dart';
import '../navigation/wrapper_navegacao_arvore.dart';
import '../navigation/arvore/nos_globais.dart';
import '../view/function_library/biblioteca_funcoes_comuns.dart';
import 'micro_badge_beta.dart';
import 'modal_beta_aberto.dart';

/// Barra de aplicativo superior dedicada da página inicial do Aresta Climb.
///
/// Apresenta o logotipo vetorizado, a marca com selo interativo [MicroBadgeBeta]
/// e os botões de ação para sincronização manual, feedback e configurações.
class ArestaHomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// ViewModel da tela inicial para sincronização manual padrão.
  final HomeViewModel? viewModel;

  /// Callback executado ao pressionar o botão de sincronização.
  final VoidCallback? onSync;

  /// Callback executado ao pressionar o botão de configurações.
  final VoidCallback? onSettings;

  const ArestaHomeAppBar({
    super.key,
    this.viewModel,
    this.onSync,
    this.onSettings,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  void _executarSincronizacao(BuildContext context) {
    if (onSync != null) {
      onSync!();
    } else {
      viewModel?.sincronizarManual(context);
    }
  }

  void _executarConfiguracoes(BuildContext context) {
    if (onSettings != null) {
      onSettings!();
    } else {
      TreeNavigationWrapper.of(
        context,
      ).treeController.navigateTo(SettingsNode(const HomeNode()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
