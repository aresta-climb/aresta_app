// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import '../../services/autenticacao/servico_autenticacao.dart';

/// ViewModel respons├ível pelo estado e regras de neg├│cio da tela de Login e Cria├º├úo de Conta (MVVM).
///
/// Gerencia a altern├óncia entre os modos de entrada e cadastro, valida├º├úo de credenciais
/// via [ServicoAutenticacao], autentica├º├úo com Google (Gmail) e op├º├úo de continuar
/// sem conta (modo offline).
class LoginViewModel extends ChangeNotifier {
  /// Servi├ºo de autentica├º├úo subjacente.
  final ServicoAutenticacao servicoAutenticacao;

  /// Callback opcional invocado ap├│s autentica├º├úo ou cria├º├úo de conta bem-sucedida.
  final VoidCallback? aoAutenticarComSucesso;

  /// Callback opcional invocado quando o escalador opta por continuar sem conta (offline).
  final VoidCallback? aoContinuarSemConta;

  bool _modoCriarConta = false;
  String _nome = '';
  String _email = '';
  String _senha = '';
  bool _ocultarSenha = true;
  bool _carregando = false;
  String? _mensagemErro;
  String? _mensagemConfirmacaoEmail;

  /// Cria uma inst├óncia de [LoginViewModel].
  LoginViewModel({
    ServicoAutenticacao? servicoAutenticacao,
    this.aoAutenticarComSucesso,
    this.aoContinuarSemConta,
  }) : servicoAutenticacao =
           servicoAutenticacao ?? ServicoAutenticacaoLocal.instancia;

  /// Indica se o formul├írio est├í no modo de cria├º├úo de nova conta (`true`) ou login (`false`).
  bool get modoCriarConta => _modoCriarConta;

  /// Nome ou apelido informado pelo escalador no modo de cria├º├úo de conta.
  String get nome => _nome;

  /// Endere├ºo de e-mail informado pelo escalador.
  String get email => _email;

  /// Senha informada pelo escalador.
  String get senha => _senha;

  /// Indica se os caracteres do campo de senha devem permanecer ocultos.
  bool get ocultarSenha => _ocultarSenha;

  /// Indica se uma opera├º├úo de autentica├º├úo est├í em andamento.
  bool get carregando => _carregando;

  /// Mensagem de erro de valida├º├úo ou falha de autentica├º├úo a ser exibida na interface.
  String? get mensagemErro => _mensagemErro;

  /// Mensagem informativa exibida ap├│s o cadastro quando o servidor exige confirma├º├úo por e-mail antes do primeiro login.
  String? get mensagemConfirmacaoEmail => _mensagemConfirmacaoEmail;

  /// T├¡tulo principal exibido no cabe├ºalho da tela de login.
  String get tituloCabecalho =>
      _modoCriarConta ? 'Criar conta Aresta' : 'Entrar na sua conta';

  /// Subt├¡tulo explicativo exibido abaixo do t├¡tulo principal.
  String get subtituloCabecalho => _modoCriarConta
      ? 'Sincronize sua caderneta esportiva na nuvem e acesse seus registros em qualquer dispositivo.'
      : 'Entre com sua conta Google ou e-mail para sincronizar sua caderneta na nuvem.';

  /// R├│tulo do bot├úo prim├írio de submiss├úo do formul├írio de e-mail e senha.
  String get rotuloBotaoPrincipal => _modoCriarConta ? 'Criar conta' : 'Entrar';

  /// R├│tulo do bot├úo de altern├óncia entre os modos de login e cria├º├úo de conta.
  String get rotuloAlternarModo => _modoCriarConta
      ? 'J├í tem uma conta? Entrar'
      : 'N├úo tem conta? Criar agora';

  void _limparAvisosAoEditar() {
    if (_mensagemErro != null || _mensagemConfirmacaoEmail != null) {
      _mensagemErro = null;
      _mensagemConfirmacaoEmail = null;
      notifyListeners();
    }
  }

  /// Atualiza o nome/apelido digitado e limpa mensagens de erro anteriores.
  void definirNome(String valor) {
    _nome = valor;
    _limparAvisosAoEditar();
  }

  /// Atualiza o e-mail digitado e limpa mensagens de erro anteriores.
  void definirEmail(String valor) {
    _email = valor;
    _limparAvisosAoEditar();
  }

  /// Atualiza a senha digitada e limpa mensagens de erro anteriores.
  void definirSenha(String valor) {
    _senha = valor;
    _limparAvisosAoEditar();
  }

  /// Alterna entre o modo de login (`Entrar`) e cria├º├úo de conta (`Criar conta`).
  void alternarModoConta() {
    _modoCriarConta = !_modoCriarConta;
    _mensagemErro = null;
    _mensagemConfirmacaoEmail = null;
    notifyListeners();
  }

  /// Alterna a visibilidade do texto da senha no campo de entrada.
  void alternarVisibilidadeSenha() {
    _ocultarSenha = !_ocultarSenha;
    notifyListeners();
  }

  /// Submete o formul├írio de e-mail e senha de acordo com o [modoCriarConta] ativo.
  ///
  /// Retorna `true` se a autentica├º├úo ocorrer com sucesso e aciona [aoAutenticarComSucesso].
  Future<bool> submeterEmailSenha() async {
    _carregando = true;
    _mensagemErro = null;
    _mensagemConfirmacaoEmail = null;
    notifyListeners();

    try {
      if (_modoCriarConta) {
        final perfil = await servicoAutenticacao.criarContaComEmailSenha(
          nome: _nome,
          email: _email,
          senha: _senha,
        );
        if (!perfil.estaAutenticado) {
          _carregando = false;
          _modoCriarConta = false;
          _mensagemConfirmacaoEmail =
              'Enviamos um link de confirma├º├úo para ${_email.trim()}. Verifique sua caixa de entrada (e a pasta de spam) antes de entrar.';
          notifyListeners();
          return false;
        }
      } else {
        await servicoAutenticacao.entrarComEmailSenha(
          email: _email,
          senha: _senha,
        );
      }
      _carregando = false;
      notifyListeners();
      aoAutenticarComSucesso?.call();
      return true;
    } on ExcecaoAutenticacao catch (e) {
      _carregando = false;
      _mensagemErro = e.mensagem;
      notifyListeners();
      return false;
    } catch (_) {
      _carregando = false;
      _mensagemErro =
          'N├úo foi poss├¡vel concluir a autentica├º├úo. Tente novamente.';
      notifyListeners();
      return false;
    }
  }

  /// Inicia o fluxo de autentica├º├úo via conta Google (Gmail).
          'Não foi possível concluir a autenticação. Tente novamente.',
    );
  }

  /// Inicia o fluxo de autenticação via conta Google (Gmail).
  ///
  /// Retorna `true` se a autenticação ocorrer com sucesso e aciona [aoAutenticarComSucesso].
  Future<bool> entrarComGoogle() {
    return _executarFluxoAutenticacao(
      acao: () async {
        await servicoAutenticacao.entrarComGoogle();
        return true;
      },
      mensagemErroGenerico:
          'Não foi possível entrar com o Google. Tente novamente.',
    );
  }

  /// Inicia o fluxo de autenticação via conta Apple (Apple ID).
  ///
  /// Retorna `true` se a autenticação ocorrer com sucesso e aciona [aoAutenticarComSucesso].
  Future<bool> entrarComApple() {
    return _executarFluxoAutenticacao(
      acao: () async {
        await servicoAutenticacao.entrarComApple();
        return true;
      },
      mensagemErroGenerico:
          'Não foi possível entrar com a Apple. Tente novamente.',
    );
  }

  Future<bool> _executarFluxoAutenticacao({
    required Future<bool> Function() acao,
    required String mensagemErroGenerico,
  }) async {
    _carregando = true;
    _mensagemErro = null;
    notifyListeners();

    try {
      final autenticado = await acao();
      _carregando = false;
      notifyListeners();
      if (autenticado) {
        aoAutenticarComSucesso?.call();
      }
      return autenticado;
    } on ExcecaoAutenticacao catch (e) {
      _carregando = false;
      _mensagemErro = e.mensagem;
      notifyListeners();
      return false;
    } catch (_) {
      _carregando = false;
      _mensagemErro = mensagemErroGenerico;
      notifyListeners();
      return false;
    }
  }

  /// Aciona o fluxo de navegação para continuar usando o aplicativo sem conta (modo offline).
  void continuarSemConta() {
    _mensagemErro = null;
    aoContinuarSemConta?.call();
  }
