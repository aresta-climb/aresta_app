// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../navigation/funcoes_navegacao.dart';
import '../theme/cores_app.dart';
import '../view/view_models/login_view_model.dart';

/// P├ígina de autentica├º├úo e cria├º├úo de conta do escalador (Dumb UI / MVVM).
///
/// Apresenta op├º├Áes de login via conta Google (Gmail), autentica├º├úo/cadastro por
/// e-mail e senha e atalho para continuar sem conta (modo offline), delegando
/// estado, valida├º├Áes e persist├¬ncia ao [LoginViewModel].
class LoginPage extends StatefulWidget {
  /// ViewModel opcional injetado para testes ou controle externo.
  final LoginViewModel? viewModel;

  /// Construtor pregui├ºoso opcional do ViewModel (acionado apenas em `initState`).
  final LoginViewModel Function()? construtorViewModel;

  /// Cria uma inst├óncia da p├ígina de autentica├º├úo [LoginPage].
  const LoginPage({
    super.key,
    this.viewModel,
    this.construtorViewModel,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

/// Sin├┤nimo em portugu├¬s para [LoginPage].
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

  Future<void> _executarSubmissaoEmailSenha() async {
    final autenticado = await _vm.submeterEmailSenha();
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
                _construirBarraTopo(context, cores),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _construirCabecalho(cores),
                        const SizedBox(height: 12),
                        _construirBotaoGoogle(cores),
                        const SizedBox(height: 8),
                        _construirBotaoApple(cores),
                        const SizedBox(height: 10),
                        _construirDivisorOuEmail(cores),
                        const SizedBox(height: 10),
                        _construirCartaoFormulario(cores),
                        const SizedBox(height: 10),
                        _construirBotaoContinuarSemConta(cores),
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

  Widget _construirBarraTopo(BuildContext context, AppColors cores) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 20, 0),
      child: Row(
        children: [
          IconButton(
            key: const Key('btn_voltar_login'),
            icon: Icon(Icons.arrow_back, color: cores.chalkWhite),
            tooltip: 'Voltar',
            onPressed: () => AppNav.back(context),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'ARESTA CLIMB',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cores.dryMoss,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirCabecalho(AppColors cores) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _vm.tituloCabecalho,
          style: TextStyle(
            color: cores.chalkWhite,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _vm.subtituloCabecalho,
          style: TextStyle(
            color: cores.ashGrey,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _construirBotaoGoogle(AppColors cores) {
    return OutlinedButton(
      key: const Key('btn_login_google'),
      onPressed: _vm.carregando ? null : _executarLoginGoogle,
      style: OutlinedButton.styleFrom(
        backgroundColor: cores.caveShadow,
        foregroundColor: cores.chalkWhite,
        side: BorderSide(color: cores.graniteEdge, width: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'G',
              style: TextStyle(
                color: Color(0xFF4285F4),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Continuar com o Google',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cores.chalkWhite,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirBotaoApple(AppColors cores) {
    return OutlinedButton(
      key: const Key('btn_login_apple'),
      onPressed: _vm.carregando ? null : _executarLoginApple,
      style: OutlinedButton.styleFrom(
        backgroundColor: cores.caveShadow,
        foregroundColor: cores.chalkWhite,
        side: BorderSide(color: cores.graniteEdge, width: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.apple,
              color: Colors.black,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Continuar com a Apple',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cores.chalkWhite,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirDivisorOuEmail(AppColors cores) {
    return Row(
      children: [
        Expanded(child: Divider(color: cores.graniteEdge, thickness: 1)),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'ou use seu e-mail',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cores.ashGrey,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Expanded(child: Divider(color: cores.graniteEdge, thickness: 1)),
      ],
    );
  }

  Widget _construirCartaoFormulario(AppColors cores) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cores.caveShadow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cores.graniteEdge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_vm.modoCriarConta) ...[
            TextField(
              key: const Key('campo_login_nome'),
              controller: _nomeController,
              onChanged: _vm.definirNome,
              style: TextStyle(color: cores.chalkWhite, fontSize: 14),
              decoration: _decoracaoCampo(
                cores: cores,
                rotulo: 'Nome ou apelido',
                icone: Icons.person_outline,
              ),
            ),
            const SizedBox(height: 10),
          ],
          TextField(
            key: const Key('campo_login_email'),
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            onChanged: _vm.definirEmail,
            style: TextStyle(color: cores.chalkWhite, fontSize: 14),
            decoration: _decoracaoCampo(
              cores: cores,
              rotulo: 'E-mail',
              icone: Icons.alternate_email,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('campo_login_senha'),
            controller: _senhaController,
            obscureText: _vm.ocultarSenha,
            onChanged: _vm.definirSenha,
            style: TextStyle(color: cores.chalkWhite, fontSize: 14),
            decoration: _decoracaoCampo(
              cores: cores,
              rotulo: 'Senha',
              icone: Icons.lock_outline,
              sufixo: IconButton(
                key: const Key('btn_alternar_visibilidade_senha'),
                icon: Icon(
                  _vm.ocultarSenha
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: cores.ashGrey,
                  size: 20,
                ),
                onPressed: _vm.alternarVisibilidadeSenha,
              ),
            ),
          ),
          if (_vm.mensagemErro != null) ...[
            const SizedBox(height: 10),
            Container(
              key: const Key('banner_erro_login'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}
