// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../navigation/funcoes_navegacao.dart';
import '../theme/cores_app.dart';
import '../view/view_models/login_view_model.dart';
import '../widgets/autenticacao/componentes_login.dart';

/// Página de autenticação sem senha do escalador (Dumb UI / MVVM).
///
/// Apresenta provedores sociais in-app adequados à plataforma atual (Google em Android e iOS;
/// Apple exclusivamente em iOS), autenticação por código OTP numérico de 6 dígitos enviado por e-mail
/// e atalho direto para abrir as configurações do aplicativo sem conta, delegando estado ao [LoginViewModel].
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
  late final TextEditingController _emailController;
  late final TextEditingController _codigoOtpController;

  @override
  void initState() {
    super.initState();
    _possuiViewModelProprio = widget.viewModel == null;
    _vm =
        widget.viewModel ?? (widget.construtorViewModel?.call() ?? LoginViewModel());
    _emailController = TextEditingController(text: _vm.email);
    _codigoOtpController = TextEditingController(text: _vm.codigoOtp);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codigoOtpController.dispose();
    if (_possuiViewModelProprio) {
      _vm.dispose();
    }
    super.dispose();
  }

  Future<void> _executarLoginGoogle() async {
    final autenticado = await _vm.entrarComGoogle();
    if (autenticado && mounted && _vm.aoAutenticarComSucesso == null) {
      AppNav.toPerfil(context);
    }
  }

  Future<void> _executarLoginApple() async {
    final autenticado = await _vm.entrarComApple();
    if (autenticado && mounted && _vm.aoAutenticarComSucesso == null) {
      AppNav.toPerfil(context);
    }
  }

  Future<void> _executarEnvioCodigoOtp() async {
    final enviado = await _vm.solicitarCodigoEmail();
    if (enviado && mounted) {
      _codigoOtpController.clear();
    }
  }

  Future<void> _executarReenvioCodigoOtp() async {
    final enviado = await _vm.reenviarCodigoEmail();
    if (enviado && mounted) {
      _codigoOtpController.clear();
    }
  }

  Future<void> _executarConfirmacaoCodigoOtp() async {
    final autenticado = await _vm.confirmarCodigoEmail();
    if (autenticado && mounted && _vm.aoAutenticarComSucesso == null) {
      AppNav.toPerfil(context);
    }
  }

  void _executarAlterarEmailOtp() {
    _codigoOtpController.clear();
    _vm.alterarEmailOtp();
  }

  void _executarAbrirConfiguracoes() {
    _vm.abrirConfiguracoes();
    if (_vm.aoAbrirConfiguracoes == null) {
      AppNav.toSettings(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    final exibirBotaoApple = Theme.of(context).platform == TargetPlatform.iOS;

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
                        if (_vm.mensagemErro != null) ...[
                          const SizedBox(height: 10),
                          BannerAvisoLogin(
                            key: const Key('banner_erro_login'),
                            mensagem: _vm.mensagemErro!,
                            icone: Icons.error_outline,
                            corDestaque: cores.rustIron,
                          ),
                        ],
                        const SizedBox(height: 12),
                        BotaoProvedorOAuthLogin(
                          key: const Key('btn_login_google'),
                          rotulo: 'Continuar com o Google',
                          aoPressionar: _vm.carregando
                              ? null
                              : _executarLoginGoogle,
                          distintivo: const Text(
                            'G',
                            style: TextStyle(
                              color: Color(0xFF4285F4),
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (exibirBotaoApple) ...[
                          const SizedBox(height: 8),
                          BotaoProvedorOAuthLogin(
                            key: const Key('btn_login_apple'),
                            rotulo: 'Continuar com a Apple',
                            aoPressionar: _vm.carregando
                                ? null
                                : _executarLoginApple,
                            distintivo: const Icon(
                              Icons.apple,
                              color: Colors.black,
                              size: 18,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        const DivisorSecaoLogin(
                          texto: 'ou receba um código por e-mail',
                        ),
                        const SizedBox(height: 10),
                        CartaoCodigoEmailLogin(
                          aguardandoCodigoOtp: _vm.aguardandoCodigoOtp,
                          carregando: _vm.carregando,
                          segundosRestantesReenvio:
                              _vm.segundosRestantesReenvio,
                          mensagemInfoOtp: _vm.mensagemInfoOtp,
                          emailController: _emailController,
                          codigoController: _codigoOtpController,
                          aoAlterarEmail: _vm.definirEmail,
                          aoAlterarCodigo: _vm.definirCodigoOtp,
                          aoSolicitarCodigo: _executarEnvioCodigoOtp,
                          aoConfirmarCodigo: _executarConfirmacaoCodigoOtp,
                          aoReenviarCodigo: _executarReenvioCodigoOtp,
                          aoAlterarEmailOtp: _executarAlterarEmailOtp,
                        ),
                        const SizedBox(height: 10),
                        BotaoAbrirConfiguracoesLogin(
                          aoPressionar: _executarAbrirConfiguracoes,
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
