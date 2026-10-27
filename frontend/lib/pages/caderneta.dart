// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../data/modelos/cadena.dart';
import '../services/caderneta/repositorio_caderneta.dart';
import '../theme/cores_app.dart';
import '../view/function_library/biblioteca_funcoes_comuns.dart';
import '../view/view_models/perfil_view_model.dart';
import '../widgets/caderneta/grafico_piramide_graus.dart';
import '../navigation/funcoes_navegacao.dart';

/// Página dedicada à exibição da Caderneta Esportiva pessoal do atleta.
///
/// Apresenta o gráfico da pirâmide de graduação (vias e boulders) e o
/// histórico cronológico detalhado de ascensões, permitindo exclusão segura.
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
    final confirmado = await _DialogoConfirmarExclusao.exibir(context);

    if (confirmado == true) {
      await _viewModel.excluirCadena(cadena.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final historico = _viewModel.historicoCadenas;

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
                  _SecaoHistoricoCadenas(
                    historico: historico,
                    viewModel: _viewModel,
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

/// Seção com o histórico de ascensões cronológicas ou estado informativo vazio.
class _SecaoHistoricoCadenas extends StatelessWidget {
  final List<Cadena> historico;
  final PerfilViewModel viewModel;
  final ValueChanged<Cadena> onExcluirCadena;

  const _SecaoHistoricoCadenas({
    required this.historico,
    required this.viewModel,
    required this.onExcluirCadena,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Histórico de Ascensões (${historico.length})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: cores.chalkWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (historico.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: cores.caveShadow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cores.graniteEdge),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cores.deepBasalt,
                  ),
                  child: Icon(
