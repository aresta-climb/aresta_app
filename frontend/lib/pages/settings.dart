// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../view/function_library/common_functions.dart';
import '../view/function_library/settings_functions.dart';
import '../view/view_models/settings_view_model.dart';

/// Página de Configurações do aplicativo (Dumb UI).
///
/// Apresenta opções de tema, alternância de modo experimental e conexões com servidor
/// delegadas ao [SettingsViewModel].
class SettingsPage extends StatelessWidget {
  /// ViewModel de configurações e ambiente do aplicativo.
  final SettingsViewModel viewModel;

  const SettingsPage({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          buildCommonAppBar(context, 'Configurações'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                buildThemeSelectionCard(context),
                const SizedBox(height: 16),
                buildEditorCard(
                  context: context,
                  datasetRepo: viewModel.datasetRepo,
                ),
                const SizedBox(height: 24),
                buildVersaoBetaFooter(context),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
