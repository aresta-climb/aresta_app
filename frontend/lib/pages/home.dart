// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../view/function_library/home_functions.dart';
import '../view/view_models/home_view_model.dart';
import '../theme/cores_app.dart';

/// A página inicial do aplicativo (Dumb UI).
///
/// Apresenta o carrossel de picos próximos, atalhos de exploração e aciona a sincronização
/// através de [HomeViewModel].
class HomePage extends StatelessWidget {
  /// ViewModel de negócios e dados da tela inicial.
  final HomeViewModel viewModel;

  /// Callback acionado para troca de abas no navegador principal.
  final Function(int) onSwitchTab;

  const HomePage({
    super.key,
    required this.viewModel,
    required this.onSwitchTab,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.deepBasalt,
      body: SafeArea(
        child: RefreshIndicator(
          color: context.colors.dryMoss,
          backgroundColor: context.colors.caveShadow,
          onRefresh: () async {
            await viewModel.sincronizarManual(context);
          },
          child: buildHomeBody(context, viewModel, onSwitchTab),
        ),
      ),
    );
  }
}
