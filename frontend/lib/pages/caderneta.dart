// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../data/modelos/cadena.dart';
import '../services/caderneta/repositorio_caderneta.dart';
import '../view/function_library/biblioteca_funcoes_comuns.dart';
import '../view/function_library/funcoes_caderneta.dart';
import '../view/view_models/perfil_view_model.dart';
import '../widgets/caderneta/grafico_piramide_graus.dart';
import '../navigation/funcoes_navegacao.dart';

/// Página dedicada à exibição da Caderneta Esportiva pessoal do atleta (Dumb UI).
///
/// Apresenta o gráfico da pirâmide de graduação (vias e boulders) e o
/// histórico cronológico detalhado de ascensões, delegando o estado ao
/// [PerfilViewModel] e os elementos visuais à biblioteca [funcoes_caderneta.dart].
class CadernetaPage extends StatefulWidget {
  /// ViewModel injetado (ou inicializado por padrão com a instância local-first).
  final PerfilViewModel? viewModel;

  const CadernetaPage({super.key, this.viewModel});

  @override
  State<CadernetaPage> createState() => _CadernetaPageState();
}

class _CadernetaPageState extends State<CadernetaPage> {
  late final PerfilViewModel _viewModel;
  bool _criouViewModelInterno = false;

  @override
  void initState() {
    super.initState();
    if (widget.viewModel != null) {
      _viewModel = widget.viewModel!;
    } else {
      _viewModel = PerfilViewModel(
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

  Future<void> _confirmarExclusaoCadena(Cadena cadena) async {
    final confirmado = await exibirDialogoConfirmarExclusao(context);

    if (confirmado == true) {
      await _viewModel.excluirCadena(cadena.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: buildCommonAppBar(
            context,
            'MINHA CADERNETA',
            onBack: () => AppNav.back(context),
          ),
          body: SafeArea(
            bottom: true,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GraficoPiramideGraus(
                    piramide: _viewModel.piramideAtiva,
                    modoVias: _viewModel.modoVias,
                    onAlternarModo: _viewModel.alternarModoModalidade,
                  ),
                  const SizedBox(height: 24),
                  buildSecaoHistoricoCadenas(
                    context,
                    historico: _viewModel.historicoCadenas,
                    obterNomeVia: _viewModel.obterNomeEscalada,
                    obterGrauVia: _viewModel.obterGrauEscalada,
                    formatarData: _viewModel.formatarDataAscensao,
                    onExcluirCadena: _confirmarExclusaoCadena,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
