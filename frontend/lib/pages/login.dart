// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../navigation/funcoes_navegacao.dart';
import '../theme/cores_app.dart';
import '../view/view_models/login_view_model.dart';
import '../widgets/autenticacao/componentes_login.dart';

/// Página de autenticação e criação de conta do escalador (Dumb UI / MVVM).
///
/// Apresenta opções de login via conta Google (Gmail) ou Apple, autenticação/cadastro
/// por e-mail e senha e atalho para continuar sem conta (modo offline), delegando
/// estado, validações e persistência ao [LoginViewModel].
class LoginPage extends StatefulWidget {
  /// ViewModel opcional injetado para testes ou controle externo.
  final LoginViewModel? viewModel;

  /// Construtor preguiçoso opcional do ViewModel (acionado apenas em `initState`).
  final LoginViewModel Function()? construtorViewModel;

  /// Cria uma instância da página de autenticação [LoginPage].
  const LoginPage({
    super.key,
    this.viewModel,
    this.construtorViewModel,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

/// Sinônimo em português para [LoginPage].
typedef PaginaLogin = LoginPage;

class _LoginPageState extends State<LoginPage> {
  late final LoginViewModel _vm;
  late final bool _possuiViewModelProprio;
  late final TextEditingController _nomeController;
  late final TextEditingController _emailController;
  late final TextEditingController _senhaController;

  @override
  void initState() {
    super.initState();
    _possuiViewModelProprio = widget.viewModel == null;
    _vm =
        widget.viewModel ?? (widget.construtorViewModel?.call() ?? LoginViewModel());
    _nomeController = TextEditingController(text: _vm.nome);
    _emailController = TextEditingController(text: _vm.email);
    _senhaController = TextEditingController(text: _vm.senha);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    if (_possuiViewModelProprio) {
      _vm.dispose();
    }
    super.dispose();
  }

  Future<void> _executarAutenticacao(Future<bool> Function() acao) async {
    final autenticado = await acao();
    if (autenticado && mounted && _vm.aoAutenticarComSucesso == null) {
      AppNav.toPerfil(context);
    }
  }

  void _executarContinuarSemConta() {
    _vm.continuarSemConta();
    if (_vm.aoContinuarSemConta == null) {
      AppNav.toPerfil(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    return Scaffold(
      backgroundColor: cores.deepBasalt,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _vm,
          builder: (context, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BarraTopoLogin(aoVoltar: () => AppNav.back(context)),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CabecalhoTelaLogin(
                          titulo: _vm.tituloCabecalho,
                          subtitulo: _vm.subtituloCabecalho,
                        ),
                        const SizedBox(height: 12),
                        BotaoProvedorOAuthLogin(
                          key: const Key('btn_login_google'),
                          rotulo: 'Continuar com o Google',
                          aoPressionar: _vm.carregando
                              ? null
                              : () => _executarAutenticacao(_vm.entrarComGoogle),
                          distintivo: const Text(
                            'G',
                            style: TextStyle(
                              color: Color(0xFF4285F4),
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        BotaoProvedorOAuthLogin(
                          key: const Key('btn_login_apple'),
                          rotulo: 'Continuar com a Apple',
                          aoPressionar: _vm.carregando
                              ? null
                              : () => _executarAutenticacao(_vm.entrarComApple),
                          distintivo: const Icon(
                            Icons.apple,
                            color: Colors.black,
                            size: 18,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const DivisorSecaoLogin(texto: 'ou use seu e-mail'),
                        const SizedBox(height: 10),
                        CartaoFormularioEmailLogin(
                          modoCriarConta: _vm.modoCriarConta,
                          ocultarSenha: _vm.ocultarSenha,
                          carregando: _vm.carregando,
                          rotuloBotaoPrincipal: _vm.rotuloBotaoPrincipal,
                          rotuloAlternarModo: _vm.rotuloAlternarModo,
                          mensagemConfirmacaoEmail:
                              _vm.mensagemConfirmacaoEmail,
                          mensagemErro: _vm.mensagemErro,
                          nomeController: _nomeController,
                          emailController: _emailController,
                          senhaController: _senhaController,
                          aoAlterarNome: _vm.definirNome,
                          aoAlterarEmail: _vm.definirEmail,
                          aoAlterarSenha: _vm.definirSenha,
                          aoAlternarVisibilidadeSenha:
                              _vm.alternarVisibilidadeSenha,
                          aoSubmeter: () =>
                              _executarAutenticacao(_vm.submeterEmailSenha),
                          aoAlternarModoConta: _vm.alternarModoConta,
                        ),
                        const SizedBox(height: 10),
                        BotaoContinuarSemContaLogin(
                          aoPressionar: _executarContinuarSemConta,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
