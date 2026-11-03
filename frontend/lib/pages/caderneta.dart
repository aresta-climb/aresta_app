// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../data/modelos/cadena.dart';
import '../navigation/funcoes_navegacao.dart';
import '../view/function_library/biblioteca_funcoes_comuns.dart';
import '../view/function_library/funcoes_caderneta.dart';
import '../view/view_models/perfil_view_model.dart';
import '../widgets/caderneta/card_estatistica.dart';
import '../widgets/caderneta/grafico_piramide_graus.dart';
import '../widgets/caderneta/modal_registro_cadena.dart';

/// Página dedicada à exibição da Caderneta Esportiva pessoal do atleta (Dumb UI).
///
/// Apresenta o painel de resumo estatístico, o gráfico da pirâmide de graduação
/// (vias e boulders) e o histórico cronológico detalhado de ascensões com suporte
/// a edição, exclusão e navegação direta para a via, delegando todo o estado e a
/// formatação de apresentação ao [PerfilViewModel].
class CadernetaPage extends StatefulWidget {
  /// ViewModel injetado externamente (cujo ciclo de vida pertence ao chamador).
  final PerfilViewModel? viewModel;

  /// Fábrica opcional para criação tardia do ViewModel em [State.initState],
  /// cujo ciclo de vida passa a ser gerenciado e descartado por esta página.
  final PerfilViewModel Function()? construtorViewModel;

  const CadernetaPage({
    super.key,
    this.viewModel,
    this.construtorViewModel,
  });

  @override
  State<CadernetaPage> createState() => _CadernetaPageState();
}

class _CadernetaPageState extends State<CadernetaPage> {
  late final PerfilViewModel _viewModel;
  bool _gerenciaCicloVida = false;

  @override
  void initState() {
    super.initState();
    if (widget.viewModel != null) {
      _viewModel = widget.viewModel!;
    } else {
      _viewModel =
          widget.construtorViewModel?.call() ??
          PerfilViewModel.comCatalogo();
      _gerenciaCicloVida = true;
    }
  }

  @override
  void dispose() {
    if (_gerenciaCicloVida) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  Future<void> _aoSolicitarExclusao(Cadena cadena) async {
    if (_viewModel.possuiCallbackExcluir) {
      _viewModel.solicitarExclusaoCadena(cadena);
      return;
    }
    final confirmado = await exibirDialogoConfirmarExclusao(context);
    if (confirmado == true) {
      await _viewModel.excluirCadena(cadena.id);
    }
  }

  void _aoSolicitarEdicao(Cadena cadena) {
    if (_viewModel.possuiCallbackEditar) {
      _viewModel.editarCadena(cadena);
      return;
    }
    final vmEdicao = _viewModel.criarViewModelEdicao(cadena);
    exibirModalRegistroCadena(
      context,
      viewModel: vmEdicao,
      onSalvo: (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ascensão atualizada na caderneta!'),
            duration: Duration(seconds: 2),
          ),
        );
      },
    ).whenComplete(vmEdicao.dispose);
  }

  void _aoTocarVia(Cadena cadena) {
    if (_viewModel.possuiCallbackTocarVia) {
      _viewModel.tocarVia(cadena);
      return;
    }
    final navegou = AppNav.toViaPorUid(context, cadena.escaladaUid);
    if (!navegou && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Via não disponível offline no momento.'),
          duration: Duration(seconds: 2),
        ),
      );
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
                  PainelResumoEstatisticasCaderneta(
                    estatisticas: _viewModel.estatisticas,
                  ),
                  const SizedBox(height: 20),
                  GraficoPiramideGraus(
                    piramide: _viewModel.piramideAtiva,
                    modoVias: _viewModel.modoVias,
                    onAlternarModo: _viewModel.alternarModoModalidade,
                  ),
                  const SizedBox(height: 24),
                  SecaoHistoricoCadenas(
                    tituloSecao: _viewModel.tituloSecaoHistorico,
                    historico: _viewModel.historicoCadenas,
                    obterNomeVia: _viewModel.obterNomeEscalada,
                    obterGrauVia: _viewModel.obterGrauEscalada,
                    formatarSubtitulo: _viewModel.formatarSubtituloAscensao,
                    formatarCitacaoNotas: _viewModel.formatarCitacaoNotas,
                    onExcluirCadena: _aoSolicitarExclusao,
                    onEditarCadena: _aoSolicitarEdicao,
                    onTocarVia: _aoTocarVia,
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
