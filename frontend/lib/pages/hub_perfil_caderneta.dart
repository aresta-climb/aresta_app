// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../navigation/funcoes_navegacao.dart';
import '../theme/cores_app.dart';
import '../view/function_library/biblioteca_funcoes_comuns.dart';
import '../view/function_library/funcoes_hub_perfil_caderneta.dart';
import '../view/view_models/hub_perfil_caderneta_view_model.dart';
import '../widgets/perfil/dialogos_hub_perfil.dart';

/// Página central do Hub de Perfil do Escalador e Caderneta Esportiva.
///
/// Implementada como interface gráfica declarativa (Dumb UI), conectando as
/// interações visuais e de navegação ao estado e aos comandos do [HubPerfilCadernetaViewModel].
class HubPerfilCadernetaPage extends StatefulWidget {
  /// ViewModel injetado externamente (cujo ciclo de vida pertence ao chamador).
  final HubPerfilCadernetaViewModel? viewModel;

  /// Fábrica opcional para criação tardia do ViewModel em [State.initState],
  /// cujo ciclo de vida passa a ser gerenciado e descartado por esta página.
  final HubPerfilCadernetaViewModel Function()? construtorViewModel;

  const HubPerfilCadernetaPage({
    super.key,
    this.viewModel,
    this.construtorViewModel,
  });

  @override
  State<HubPerfilCadernetaPage> createState() => _HubPerfilCadernetaPageState();
}

class _HubPerfilCadernetaPageState extends State<HubPerfilCadernetaPage> {
  late final HubPerfilCadernetaViewModel _viewModel;
  bool _gerenciaCicloVida = false;

  @override
  void initState() {
    super.initState();
    if (widget.viewModel != null) {
      _viewModel = widget.viewModel!;
    } else {
      _viewModel =
          widget.construtorViewModel?.call() ??
          HubPerfilCadernetaViewModel.comCatalogo();
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

  Future<void> _abrirDadosPrivacidade(BuildContext context) async {
    var copiou = false;
    await exibirModalDadosPrivacidade(
      context,
      autorIdPublico: _viewModel.autorIdPublico,
      aoCopiarId: () async {
        await _viewModel.copiarIdPublico();
        copiou = true;
      },
    );
    if (copiou && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID público copiado!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _confirmarSaida(BuildContext context) async {
    final confirmou = await exibirDialogoConfirmarSaida(context);
    if (confirmou == true) {
      await _viewModel.encerrarSessao();
      if (context.mounted) {
        AppNav.back(context);
      }
    }
  }

  Future<void> _editarPerfil(BuildContext context) async {
    final novoNome = await exibirDialogoEditarPerfil(
      context,
      nomeAtual: _viewModel.nomeAtleta,
      fotoUrlAtual: _viewModel.fotoUrl,
      aoSelecionarNovaFoto: _viewModel.selecionarEObterNovaFoto,
    );

    if (novoNome != null && novoNome.isNotEmpty) {
      await _viewModel.atualizarNome(novoNome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final cores = context.colors;

        return Scaffold(
          backgroundColor: cores.deepBasalt,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        key: const Key('btn_voltar_hub_perfil'),
                        icon: Icon(Icons.arrow_back, color: cores.chalkWhite),
                        tooltip: 'Voltar',
                        onPressed: () => AppNav.back(context),
                      ),
                      buildFeedbackButton(context, color: cores.chalkWhite),
                    ],
                  ),
                  const SizedBox(height: 8),
                  buildCabecalhoHubPerfil(
                    nome: _viewModel.nomeAtleta,
                    funcao: _viewModel.funcaoAtleta,
                    avatarUrl: _viewModel.fotoUrl,
                    onEditarPerfil: () => _editarPerfil(context),
                    onAlterarFoto: _viewModel.selecionarEAtualizarFoto,
                  ),
                  const SizedBox(height: 24),
                  buildBarraMetricasHub(
                    totalCadenas: _viewModel.totalCadenas,
                    totalTentativas: _viewModel.totalTentativas,
                    totalPicos: _viewModel.totalPicos,
                    totalVias: _viewModel.totalVias,
                  ),
                  const SizedBox(height: 28),
                  buildMenuOpcoesHub(
                    onEntrarNaConta: _viewModel.estaAutenticado
                        ? null
                        : () => AppNav.toLogin(context),
                    onAbrirCaderneta: () => AppNav.toCaderneta(context),
                    onAbrirConfiguracoes: () => AppNav.toSettings(context),
                    onAbrirDadosPrivacidade: () =>
                        _abrirDadosPrivacidade(context),
                    onConfirmarSaida: () => _confirmarSaida(context),
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

/// Sinônimo em português para [HubPerfilCadernetaPage].
typedef PaginaHubPerfilCaderneta = HubPerfilCadernetaPage;
