// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/modelos/perfil_escalador.dart';
import '../../utils/gerador_uid.dart';
import '../caderneta/repositorio_caderneta.dart';
import '../firebase/remote_config.dart';
import '../http/cliente_http_aresta.dart';
import 'cliente_supabase_autenticacao.dart';

/// Exceção de domínio lançada quando uma operação de autenticação ou validação falha.
class ExcecaoAutenticacao implements Exception {
  /// Mensagem descritiva em português destinada à exibição ao escalador.
  final String mensagem;

  /// Cria uma instância de [ExcecaoAutenticacao] com a [mensagem] informada.
  const ExcecaoAutenticacao(this.mensagem);

  @override
  String toString() => 'ExcecaoAutenticacao: $mensagem';
}

/// Representa a resposta de um provedor de autenticação externo (ex: Google / Supabase Auth).
class ResultadoProvedorAutenticacao {
  /// Identificador único do usuário retornado pelo provedor de autenticação.
  final String userId;

  /// Nome de exibição retornado pelo provedor, quando disponível.
  final String? nomeExibicao;

  /// URL ou Data URI da foto de perfil retornada pelo provedor, quando disponível.
  final String? fotoUrl;

  /// Token JWT de sessão do Supabase Auth, quando disponível.
  final String? accessToken;

  /// Identificador público NanoID 14c recuperado do banco remoto, quando existente.
  final String? autorIdPublicoRemoto;

  /// Indica se a conta foi registrada no servidor mas aguarda confirmação de e-mail antes de liberar a sessão.
  final bool requerConfirmacaoEmail;

  /// Cria uma instância imutável de [ResultadoProvedorAutenticacao].
  const ResultadoProvedorAutenticacao({
    required this.userId,
    this.nomeExibicao,
    this.fotoUrl,
    this.accessToken,
    this.autorIdPublicoRemoto,
    this.requerConfirmacaoEmail = false,
  });
}

/// Assinatura para provedor de login via e-mail e senha.
typedef ProvedorLoginEmailSenha = Future<ResultadoProvedorAutenticacao> Function(
  String email,
  String senha,
);

/// Assinatura para provedor de criação de conta via nome, e-mail e senha.
typedef ProvedorCriarContaEmailSenha = Future<ResultadoProvedorAutenticacao> Function(
  String nome,
  String email,
  String senha,
);

/// Assinatura para provedor de login via conta Google (Gmail).
typedef ProvedorLoginGoogle = Future<ResultadoProvedorAutenticacao> Function();

/// Assinatura para provedor de login via conta Apple (Apple ID).
typedef ProvedorLoginApple = Future<ResultadoProvedorAutenticacao> Function();

/// Contrato da camada de serviço responsável pela autenticação e vínculo do [PerfilEscalador].
abstract class ServicoAutenticacao {
  /// Notificador reativo do perfil atual do escalador.
  ValueListenable<PerfilEscalador> get perfilListenable;

  /// Retorna o [PerfilEscalador] ativo no momento.
  PerfilEscalador obterPerfil();

  /// Indica se há um usuário autenticado vinculado ao perfil atual.
  bool get estaAutenticado;

  /// Autentica o escalador utilizando [email] e [senha].
  Future<PerfilEscalador> entrarComEmailSenha({
    required String email,
    required String senha,
  });

  /// Cria uma nova conta de escalador com [nome], [email] e [senha] e vincula ao perfil local.
  Future<PerfilEscalador> criarContaComEmailSenha({
    required String nome,
    required String email,
    required String senha,
  });

  /// Autentica o escalador utilizando sua conta Google (Gmail) via Supabase OAuth.
  Future<PerfilEscalador> entrarComGoogle();

  /// Autentica o escalador utilizando sua conta Apple (Apple ID) via Supabase OAuth.
  Future<PerfilEscalador> entrarComApple();

  /// Atualiza o nome e/ou a foto de perfil localmente e sincroniza com o Supabase (Auth, Storage e `public.perfis`).
  Future<PerfilEscalador> atualizarPerfilRemoto({
    String? novoNome,
    String? novaFotoUrl,
  });

  /// Intercepta um deep link de retorno do fluxo OAuth (`aresta://app.arestaclimb.com/auth-callback`).
  ///
  /// Retorna `true` se o link era um callback de autenticação OAuth.
  bool processarCallbackOAuth(Uri uri);

  /// Encerra a sessão autenticada, limpando o `userId` e preservando os dados offline locais.
  Future<void> encerrarSessao();
}

/// Implementação offline-first de [ServicoAutenticacao] integrada ao [RepositorioCaderneta] e ao Supabase.
///
/// Mantém o `autorIdPublico` (NanoID 14c) e as cadenas registradas offline intactos ao
/// vincular ou desvincular uma conta Google ou de e-mail/senha, delegando os detalhes de
/// protocolo HTTP e OAuth ao [ClienteSupabaseAutenticacao].
class ServicoAutenticacaoLocal implements ServicoAutenticacao {
  /// URL oficial de redirecionamento OAuth registrada nos esquemas nativos Android e iOS.
  static const String urlRedirecionamentoOAuth =
      ClienteSupabaseAutenticacao.urlRedirecionamentoOAuth;

  static ServicoAutenticacao? _instanciaCompartilhada;

  /// Instância compartilhada padrão do serviço de autenticação.
  static ServicoAutenticacao get instancia =>
      _instanciaCompartilhada ??= ServicoAutenticacaoLocal();

  /// Permite substituir a instância compartilhada em testes de integração.
  static set instancia(ServicoAutenticacao? valor) {
    _instanciaCompartilhada = valor;
  }

  /// Redefine a instância compartilhada para o estado inicial em testes.
  static void redefinirParaTestes() {
    _instanciaCompartilhada = null;
  }

  final RepositorioCaderneta _repositorio;
  final ClienteSupabaseAutenticacao _clienteSupabase;
  final String Function() _obterAnonKeySupabase;
  final ProvedorLoginEmailSenha? _provedorEmailSenha;
  final ProvedorCriarContaEmailSenha? _provedorCriarConta;
  final ProvedorLoginGoogle? _provedorGoogle;
  final ProvedorLoginApple? _provedorApple;

  /// Cria uma instância de [ServicoAutenticacaoLocal].
  ServicoAutenticacaoLocal({
    RepositorioCaderneta? repositorio,
    ClienteSupabaseAutenticacao? clienteSupabase,
    ClienteHttpAresta? clienteHttp,
    String Function()? obterUrlSupabase,
    String Function()? obterAnonKeySupabase,
    ProvedorLoginEmailSenha? provedorEmailSenha,
    ProvedorCriarContaEmailSenha? provedorCriarConta,
    ProvedorLoginGoogle? provedorGoogle,
    ProvedorLoginApple? provedorApple,
    Future<bool> Function(Uri uri)? lancadorUrlOAuth,
    Stream<Uri>? fluxoLinksOAuth,
    Duration timeoutOAuth = const Duration(minutes: 3),
  }) : _repositorio = repositorio ?? RepositorioCadernetaLocal.instancia,
       _clienteSupabase =
           clienteSupabase ??
           ClienteSupabaseAutenticacao(
             clienteHttp: clienteHttp,
             obterUrlSupabase: obterUrlSupabase,
             lancadorUrlOAuth: lancadorUrlOAuth,
             fluxoLinksOAuth: fluxoLinksOAuth,
             timeoutOAuth: timeoutOAuth,
           ),
       _obterAnonKeySupabase =
           obterAnonKeySupabase ??
           (() => RemoteConfigService.instance.supabaseAnonKey),
       _provedorEmailSenha = provedorEmailSenha,
       _provedorCriarConta = provedorCriarConta,
       _provedorGoogle = provedorGoogle,
       _provedorApple = provedorApple;

  @override
  ValueListenable<PerfilEscalador> get perfilListenable =>
      _repositorio.perfilNotifier;

  @override
  PerfilEscalador obterPerfil() => _repositorio.obterPerfil();

  @override
  bool get estaAutenticado => _repositorio.obterPerfil().estaAutenticado;

  void _validarEmailESenha(String email, String senha) {
    final emailLimpo = email.trim();
    final partes = emailLimpo.split('@');
    if (partes.length != 2 ||
        partes[0].isEmpty ||
        !partes[1].contains('.') ||
        partes[1].startsWith('.') ||
        partes[1].endsWith('.')) {
      throw const ExcecaoAutenticacao('Informe um endereço de e-mail válido.');
    }
    if (senha.length < 6) {
      throw const ExcecaoAutenticacao(
        'A senha deve ter pelo menos 6 caracteres.',
      );
    }
  }

  Future<PerfilEscalador> _salvarPerfilAutenticado({
    required PerfilEscalador perfilAtual,
    required ResultadoProvedorAutenticacao resultado,
    required String nomeFinal,
  }) async {
    final novoPerfil = perfilAtual.copyWith(
      autorIdPublico:
          resultado.autorIdPublicoRemoto ?? perfilAtual.autorIdPublico,
      userId: resultado.userId,
      autorNomePublico: nomeFinal,
      fotoUrl: resultado.fotoUrl ?? perfilAtual.fotoUrl,
      accessToken: resultado.accessToken,
    );
    await _repositorio.salvarPerfil(novoPerfil);
    return _repositorio.obterPerfil();
  }

  String _resolverNomeParaLogin({
    required PerfilEscalador perfilAtual,
    required String? nomeDoProvedor,
    required bool autenticouEmProvedorReal,
  }) {
    final podeAdotarNomeSugerido =
        autenticouEmProvedorReal ||
        perfilAtual.autorNomePublico == PerfilEscalador.apelidoPadrao;
    if (podeAdotarNomeSugerido && nomeDoProvedor != null) {
      return nomeDoProvedor;
    }
    return perfilAtual.autorNomePublico;
  }

  @override
  Future<PerfilEscalador> entrarComEmailSenha({
    required String email,
    required String senha,
  }) async {
    final emailLimpo = email.trim();
    _validarEmailESenha(emailLimpo, senha);

    final atual = _repositorio.obterPerfil();
    final anonKey = _obterAnonKeySupabase().trim();

    final ResultadoProvedorAutenticacao resultado;
    if (_provedorEmailSenha != null) {
      resultado = await _provedorEmailSenha(emailLimpo, senha);
    } else if (anonKey.isNotEmpty) {
      resultado = await _clienteSupabase.autenticarEmailSenha(
        email: emailLimpo,
        senha: senha,
        autorIdPublicoLocal: atual.autorIdPublico,
        anonKey: anonKey,
      );
    } else {
      resultado = ResultadoProvedorAutenticacao(
        userId: 'usr_email_${gerarUid()}',
        nomeExibicao: emailLimpo.split('@').first,
      );
    }

    final nomeFinal = _resolverNomeParaLogin(
      perfilAtual: atual,
      nomeDoProvedor: resultado.nomeExibicao,
      autenticouEmProvedorReal:
          _provedorEmailSenha != null || anonKey.isNotEmpty,
    );

    return _salvarPerfilAutenticado(
      perfilAtual: atual,
      resultado: resultado,
      nomeFinal: nomeFinal,
    );
  }

  @override
  Future<PerfilEscalador> criarContaComEmailSenha({
    required String nome,
    required String email,
    required String senha,
  }) async {
    final nomeLimpo = nome.trim();
    if (nomeLimpo.isEmpty) {
      throw const ExcecaoAutenticacao(
        'Informe seu nome ou apelido de escalador.',
      );
    }
    final emailLimpo = email.trim();
    _validarEmailESenha(emailLimpo, senha);

    final atual = _repositorio.obterPerfil();
    final anonKey = _obterAnonKeySupabase().trim();

    final ResultadoProvedorAutenticacao resultado;
    if (_provedorCriarConta != null) {
      resultado = await _provedorCriarConta(nomeLimpo, emailLimpo, senha);
    } else if (anonKey.isNotEmpty) {
      resultado = await _clienteSupabase.criarConta(
        nome: nomeLimpo,
        email: emailLimpo,
        senha: senha,
        autorIdPublico: atual.autorIdPublico,
        fotoUrlAtual: atual.fotoUrl,
        anonKey: anonKey,
      );
    } else {
      resultado = ResultadoProvedorAutenticacao(
        userId: 'usr_conta_${gerarUid()}',
        nomeExibicao: nomeLimpo,
      );
    }

    final nomeFinal = resultado.nomeExibicao ?? nomeLimpo;
    if (resultado.requerConfirmacaoEmail) {
      await _repositorio.salvarPerfil(
        atual.copyWith(
          autorNomePublico: nomeFinal,
          limparUserId: true,
        ),
      );
      return _repositorio.obterPerfil();
    }

    return _salvarPerfilAutenticado(
      perfilAtual: atual,
      resultado: resultado,
      nomeFinal: nomeFinal,
    );
  }

  @override
  Future<PerfilEscalador> entrarComGoogle() async {
    final atual = _repositorio.obterPerfil();
    final anonKey = _obterAnonKeySupabase().trim();

    final ResultadoProvedorAutenticacao resultado;
    if (_provedorGoogle != null) {
      resultado = await _provedorGoogle();
    } else if (anonKey.isNotEmpty) {
      resultado = await _clienteSupabase.autenticarGoogleOAuth(
        autorIdPublicoLocal: atual.autorIdPublico,
        anonKey: anonKey,
      );
    } else {
      resultado = ResultadoProvedorAutenticacao(
        userId: 'usr_google_${gerarUid()}',
        nomeExibicao: 'Escalador Google',
      );
    }

    final nomeFinal = _resolverNomeParaLogin(
      perfilAtual: atual,
      nomeDoProvedor: resultado.nomeExibicao,
      autenticouEmProvedorReal: _provedorGoogle != null || anonKey.isNotEmpty,
    );

    return _salvarPerfilAutenticado(
      perfilAtual: atual,
      resultado: resultado,
      nomeFinal: nomeFinal,
    );
  }

  @override
  Future<PerfilEscalador> entrarComApple() async {
    final atual = _repositorio.obterPerfil();
    final anonKey = _obterAnonKeySupabase().trim();

    final ResultadoProvedorAutenticacao resultado;
    if (_provedorApple != null) {
      resultado = await _provedorApple();
    } else if (anonKey.isNotEmpty) {
      resultado = await _clienteSupabase.autenticarAppleOAuth(
        autorIdPublicoLocal: atual.autorIdPublico,
        anonKey: anonKey,
      );
    } else {
      resultado = ResultadoProvedorAutenticacao(
        userId: 'usr_apple_${gerarUid()}',
        nomeExibicao: 'Escalador Apple',
      );
    }

    final nomeFinal = _resolverNomeParaLogin(
      perfilAtual: atual,
      nomeDoProvedor: resultado.nomeExibicao,
      autenticouEmProvedorReal: _provedorApple != null || anonKey.isNotEmpty,
    );

    return _salvarPerfilAutenticado(
      perfilAtual: atual,
      resultado: resultado,
      nomeFinal: nomeFinal,
    );
  }

  @override
  Future<PerfilEscalador> atualizarPerfilRemoto({
    String? novoNome,
    String? novaFotoUrl,
  }) async {
    final atual = _repositorio.obterPerfil();
    final nomeFinal = (novoNome != null && novoNome.trim().isNotEmpty)
        ? novoNome.trim()
        : atual.autorNomePublico;
    var fotoFinal = (novaFotoUrl != null && novaFotoUrl.trim().isNotEmpty)
        ? novaFotoUrl.trim()
        : atual.fotoUrl;

    final anonKey = _obterAnonKeySupabase().trim();
    final accessToken = atual.accessToken;
    if (atual.estaAutenticado &&
        accessToken != null &&
        accessToken.isNotEmpty &&
        anonKey.isNotEmpty) {
      fotoFinal = await _clienteSupabase.sincronizarPerfilAtualizado(
        anonKey: anonKey,
        accessToken: accessToken,
        userId: atual.userId!,
        autorIdPublico: atual.autorIdPublico,
        nomeFinal: nomeFinal,
        fotoFinal: fotoFinal,
      );
    }

    final atualizado = atual.copyWith(
      autorNomePublico: nomeFinal,
      fotoUrl: fotoFinal,
    );
    await _repositorio.salvarPerfil(atualizado);
    return _repositorio.obterPerfil();
  }

  @override
  bool processarCallbackOAuth(Uri uri) =>
      _clienteSupabase.processarCallbackOAuth(uri);

  @override
  Future<void> encerrarSessao() async {
    final atual = _repositorio.obterPerfil();
    if (!atual.estaAutenticado) {
      return;
    }
    await _repositorio.salvarPerfil(atual.copyWith(limparUserId: true));
  }
}
