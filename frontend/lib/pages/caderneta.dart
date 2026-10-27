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
                    Icons.menu_book_outlined,
                    color: cores.ashGrey,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Nenhuma ascensão registrada ainda',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cores.chalkWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Suas cadenas salvas nas páginas das vias aparecerão aqui.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cores.ashGrey, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: historico.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final cadena = historico[index];
              return _ItemHistoricoCadena(
                cadena: cadena,
                nomeVia: viewModel.obterNomeEscalada(cadena.escaladaUid),
                grauVia: viewModel.obterGrauEscalada(cadena.escaladaUid),
                dataFormatada: viewModel.formatarDataAscensao(
                  cadena.dataAscensao,
                ),
                onExcluir: () => onExcluirCadena(cadena),
              );
            },
          ),
      ],
    );
  }
}

/// Card de exibição individual de uma ascensão esportiva no histórico.
class _ItemHistoricoCadena extends StatelessWidget {
  final Cadena cadena;
  final String nomeVia;
  final String? grauVia;
  final String dataFormatada;
  final VoidCallback onExcluir;

  const _ItemHistoricoCadena({
    required this.cadena,
    required this.nomeVia,
    this.grauVia,
    required this.dataFormatada,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cores.caveShadow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cores.graniteEdge),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: cadena.isCadena
                  ? cores.fernGreen.withValues(alpha: 0.2)
                  : cores.rustIron.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              cadena.tipoAscensao.rotulo,
              style: TextStyle(
                color: cadena.isCadena ? cores.fernGreen : cores.rustIron,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        nomeVia,
                        style: TextStyle(
                          color: cores.chalkWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (grauVia != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cores.deepBasalt,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          grauVia!,
                          style: TextStyle(
                            color: cores.rustIron,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
