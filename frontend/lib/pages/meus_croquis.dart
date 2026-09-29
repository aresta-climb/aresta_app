// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../theme/cores_app.dart';
import '../view/function_library/meus_croquis_functions.dart';
import '../view/view_models/meus_croquis_view_model.dart';
import '../view/view_models/card_croqui_view_model.dart';
import '../view/function_library/biblioteca_funcoes_comuns.dart';

/// Página de apresentação dos croquis armazenados offline (Dumb UI).
///
/// Renderiza a interface a partir do estado gerenciado por [MeusCroquisViewModel],
/// mantendo-se totalmente desacoplada de mensagens do Protobuf, serviços de rede e repositórios.
class MeusCroquisPage extends StatelessWidget {
  /// ViewModel de apresentação de croquis salvos.
  final MeusCroquisViewModel viewModel;

  const MeusCroquisPage({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.deepBasalt,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MEUS CROQUIS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ARMAZENAMENTO OFFLINE',
                          style: TextStyle(
                            color: context.colors.dryMoss,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.sync, color: context.colors.ashGrey),
                        onPressed: () => viewModel.sincronizarManual(context),
                      ),
                      const SizedBox(width: 8),
                      buildFeedbackButton(
                        context,
                        color: context.colors.ashGrey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: viewModel,
                builder: (context, _) {
                  final List<CardCroquiViewModel> croquis = viewModel.croquisSalvos;

                  if (croquis.isEmpty) {
                    return Center(
                      child: Text(
                        'Nenhum croqui salvo offline ainda.',
                        style: TextStyle(color: context.colors.ashGrey),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: croquis.length,
                    itemBuilder: (context, index) {
                      final CardCroquiViewModel dados = croquis[index];
                      return OfflineCragCard(
                        dados: dados,
                        onAbrir: () => viewModel.abrirCroqui(context, dados.id),
                        onExcluir: () => viewModel.excluirCroqui(
                          context,
                          dados.id,
                          dados.titulo,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
