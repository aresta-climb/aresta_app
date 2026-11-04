// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../theme/cores_app.dart';
import '../view/function_library/funcoes_hub_perfil_caderneta.dart';
import '../view/function_library/biblioteca_funcoes_comuns.dart';
import '../view/view_models/hub_perfil_caderneta_view_model.dart';
import '../widgets/perfil/dialogos_hub_perfil.dart';
import '../navigation/funcoes_navegacao.dart';

/// Página central do Hub de Perfil do Escalador e Caderneta Esportiva.
///
/// Implementada como interface gráfica puramente declarativa (Dumb UI), delegando
/// o estado, métricas reativas e ações ao [HubPerfilCadernetaViewModel], os diálogos
/// a [dialogos_hub_perfil.dart] e a composição visual a [funcoes_hub_perfil_caderneta.dart].
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

  void _onEntrarNaConta(BuildContext context) {
    if (_viewModel.aoEntrarNaConta != null) {
      _viewModel.abrirLogin();
    } else {
      AppNav.toLogin(context);
    }
  }

  void _onAbrirCaderneta(BuildContext context) {
    if (_viewModel.aoAbrirCaderneta != null) {
      _viewModel.abrirCaderneta();
    } else {
      AppNav.toCaderneta(context);
    }
  }

  void _onAbrirConfiguracoes(BuildContext context) {
    if (_viewModel.aoAbrirConfiguracoes != null) {
      _viewModel.abrirConfiguracoes();
    } else {
      AppNav.toSettings(context);
    }
  }

  Future<void> _onAbrirDadosPrivacidade(BuildContext context) async {
    if (_viewModel.aoAbrirDadosPrivacidade != null) {
      _viewModel.abrirDadosPrivacidade();
    } else {
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
  }

  Future<void> _onConfirmarSaida(BuildContext context) async {
    if (_viewModel.aoConfirmarSaida != null) {
      _viewModel.confirmarSaida();
    } else {
      final confirmou = await exibirDialogoConfirmarSaida(context);
      if (confirmou == true) {
        await _viewModel.encerrarSessao();
        if (context.mounted) {
          AppNav.back(context);
        }
      }
    }
  }

  Future<void> _onEditarPerfil(BuildContext context) async {
    if (_viewModel.aoEditarPerfil != null) {
      _viewModel.editarPerfil();
    } else {
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
                    onEditarPerfil: () => _onEditarPerfil(context),
                    onAlterarFoto: () => _viewModel.selecionarEAtualizarFoto(),
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
                        : () => _onEntrarNaConta(context),
                    onAbrirCaderneta: () => _onAbrirCaderneta(context),
                    onAbrirConfiguracoes: () => _onAbrirConfiguracoes(context),
                    onAbrirDadosPrivacidade: () =>
                        _onAbrirDadosPrivacidade(context),
                    onConfirmarSaida: () => _onConfirmarSaida(context),
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
