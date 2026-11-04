// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import '../../services/autenticacao/servico_autenticacao.dart';

/// ViewModel responsável pelo estado e regras de negócio da tela de Login e Criação de Conta (MVVM).
///
/// Gerencia a alternância entre os modos de entrada e cadastro, validação de credenciais
/// via [ServicoAutenticacao], autenticação com Google (Gmail) e opção de continuar
/// sem conta (modo offline).
class LoginViewModel extends ChangeNotifier {
  /// Serviço de autenticação subjacente.
  final ServicoAutenticacao servicoAutenticacao;

  /// Callback opcional invocado após autenticação ou criação de conta bem-sucedida.
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

  /// Cria uma instância de [LoginViewModel].
  LoginViewModel({
    ServicoAutenticacao? servicoAutenticacao,
    this.aoAutenticarComSucesso,
    this.aoContinuarSemConta,
  }) : servicoAutenticacao =
           servicoAutenticacao ?? ServicoAutenticacaoLocal.instancia;

  /// Indica se o formulário está no modo de criação de nova conta (`true`) ou login (`false`).
  bool get modoCriarConta => _modoCriarConta;

  /// Nome ou apelido informado pelo escalador no modo de criação de conta.
  String get nome => _nome;

  /// Endereço de e-mail informado pelo escalador.
  String get email => _email;

  /// Senha informada pelo escalador.
  String get senha => _senha;

  /// Indica se os caracteres do campo de senha devem permanecer ocultos.
  bool get ocultarSenha => _ocultarSenha;

  /// Indica se uma operação de autenticação está em andamento.
  bool get carregando => _carregando;

  /// Mensagem de erro de validação ou falha de autenticação a ser exibida na interface.
  String? get mensagemErro => _mensagemErro;

  /// Título principal exibido no cabeçalho da tela de login.
  String get tituloCabecalho =>
      _modoCriarConta ? 'Criar conta Aresta' : 'Entrar na sua conta';

  /// Subtítulo explicativo exibido abaixo do título principal.
  String get subtituloCabecalho => _modoCriarConta
      ? 'Sincronize sua caderneta esportiva na nuvem e acesse seus registros em qualquer dispositivo.'
      : 'Entre com sua conta Google ou e-mail para sincronizar sua caderneta na nuvem.';

  /// Rótulo do botão primário de submissão do formulário de e-mail e senha.
  String get rotuloBotaoPrincipal => _modoCriarConta ? 'Criar conta' : 'Entrar';

  /// Rótulo do botão de alternância entre os modos de login e criação de conta.
  String get rotuloAlternarModo => _modoCriarConta
      ? 'Já tem uma conta? Entrar'
      : 'Não tem conta? Criar agora';

  /// Atualiza o nome/apelido digitado e limpa mensagens de erro anteriores.
  void definirNome(String valor) {
    _nome = valor;
    if (_mensagemErro != null) {
      _mensagemErro = null;
      notifyListeners();
    }
  }

  /// Atualiza o e-mail digitado e limpa mensagens de erro anteriores.
  void definirEmail(String valor) {
    _email = valor;
    if (_mensagemErro != null) {
      _mensagemErro = null;
      notifyListeners();
    }
  }

  /// Atualiza a senha digitada e limpa mensagens de erro anteriores.
  void definirSenha(String valor) {
    _senha = valor;
    if (_mensagemErro != null) {
      _mensagemErro = null;
      notifyListeners();
    }
  }

  /// Alterna entre o modo de login (`Entrar`) e criação de conta (`Criar conta`).
  void alternarModoConta() {
    _modoCriarConta = !_modoCriarConta;
    _mensagemErro = null;
    notifyListeners();
  }

  /// Alterna a visibilidade do texto da senha no campo de entrada.
  void alternarVisibilidadeSenha() {
    _ocultarSenha = !_ocultarSenha;
    notifyListeners();
  }

  /// Submete o formulário de e-mail e senha de acordo com o [modoCriarConta] ativo.
  ///
  /// Retorna `true` se a autenticação ocorrer com sucesso e aciona [aoAutenticarComSucesso].
  Future<bool> submeterEmailSenha() async {
    _carregando = true;
    _mensagemErro = null;
    notifyListeners();

    try {
      if (_modoCriarConta) {
        await servicoAutenticacao.criarContaComEmailSenha(
          nome: _nome,
          email: _email,
          senha: _senha,
        );
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
          'Não foi possível concluir a autenticação. Tente novamente.';
      notifyListeners();
      return false;
    }
  }

  /// Inicia o fluxo de autenticação via conta Google (Gmail).
  ///
  /// Retorna `true` se a autenticação ocorrer com sucesso e aciona [aoAutenticarComSucesso].
  Future<bool> entrarComGoogle() async {
    _carregando = true;
    _mensagemErro = null;
    notifyListeners();

    try {
      await servicoAutenticacao.entrarComGoogle();
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
      _mensagemErro = 'Não foi possível entrar com o Google. Tente novamente.';
      notifyListeners();
      return false;
    }
  }

  /// Aciona o fluxo de navegação para continuar usando o aplicativo sem conta (modo offline).
  void continuarSemConta() {
    _mensagemErro = null;
    aoContinuarSemConta?.call();
  }
}
