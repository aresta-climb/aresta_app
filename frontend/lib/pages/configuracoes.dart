// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../idioma/tradutor_app.dart';
import '../view/function_library/biblioteca_funcoes_comuns.dart';
import '../view/function_library/funcoes_configuracoes.dart';
import '../view/view_models/configuracoes_view_model.dart';
import '../widgets/configuracoes/cartao_preferencia_idioma.dart';

/// Página de Configurações do aplicativo (Dumb UI).
///
/// Apresenta opções de idioma, tema, modo experimental e conexões com servidor
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
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final recuoInferior = MediaQuery.paddingOf(context).bottom;
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              buildCommonAppBar(context, context.tr(ChaveTexto.configTitulo)),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + recuoInferior),
                  children: [
                    const CartaoPreferenciaIdioma(),
                    const SizedBox(height: 16),
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
      },
    );
  }
}
