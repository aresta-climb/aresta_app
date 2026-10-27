// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../services/caderneta/repositorio_caderneta.dart';
import '../theme/cores_app.dart';
import '../view/function_library/funcoes_hub_perfil_caderneta.dart';
import '../view/function_library/biblioteca_funcoes_comuns.dart';
import '../view/view_models/hub_perfil_caderneta_view_model.dart';
import '../navigation/funcoes_navegacao.dart';

/// Página central do Hub de Perfil do Escalador e Caderneta Esportiva.
///
/// Implementada como interface gráfica puramente declarativa (Dumb UI), delegando
/// o estado, métricas reativas e ações ao [HubPerfilCadernetaViewModel] e a
/// composição visual à biblioteca [funcoes_hub_perfil_caderneta.dart].
class HubPerfilCadernetaPage extends StatefulWidget {
  /// ViewModel injetado (ou inicializado por padrão com a instância local-first).
  final HubPerfilCadernetaViewModel? viewModel;

  const HubPerfilCadernetaPage({super.key, this.viewModel});

  @override
  State<HubPerfilCadernetaPage> createState() => _HubPerfilCadernetaPageState();
}

class _HubPerfilCadernetaPageState extends State<HubPerfilCadernetaPage> {
  late final HubPerfilCadernetaViewModel _viewModel;
  bool _criouViewModelInterno = false;

  @override
  void initState() {
    super.initState();
    if (widget.viewModel != null) {
      _viewModel = widget.viewModel!;
    } else {
      _viewModel = HubPerfilCadernetaViewModel(
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
        onCopiarId: () async {
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
      if (confirmou == true && context.mounted) {
        AppNav.back(context);
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
                    onEditarPerfil: () => _onEditarPerfil(context),
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
