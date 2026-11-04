// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../data/modelos/perfil_escalador.dart';
import '../../utils/gerador_uid.dart';
import '../caderneta/repositorio_caderneta.dart';
import '../firebase/remote_config.dart';
import '../http/cliente_http_aresta.dart';

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

  /// Cria uma instância imutável de [ResultadoProvedorAutenticacao].
  const ResultadoProvedorAutenticacao({
    required this.userId,
    this.nomeExibicao,
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

  /// Autentica o escalador utilizando sua conta Google (Gmail).
  Future<PerfilEscalador> entrarComGoogle();

  /// Encerra a sessão autenticada, limpando o `userId` e preservando os dados offline locais.
  Future<void> encerrarSessao();
}

/// Implementação offline-first de [ServicoAutenticacao] integrada ao [RepositorioCaderneta].
///
/// Mantém o `autorIdPublico` (NanoID 14c) e as cadenas registradas offline intactos ao
/// vincular ou desvincular uma conta Google ou de e-mail/senha, permitindo injeção de
/// provedores externos sem acoplamento na camada de interface ou ViewModel.
class ServicoAutenticacaoLocal implements ServicoAutenticacao {
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
  final ClienteHttpAresta _clienteHttp;
  final String Function() _obterUrlSupabase;
  final String Function() _obterAnonKeySupabase;
  final ProvedorLoginEmailSenha? _provedorEmailSenha;
  final ProvedorCriarContaEmailSenha? _provedorCriarConta;
  final ProvedorLoginGoogle? _provedorGoogle;

  /// Cria uma instância de [ServicoAutenticacaoLocal].
  ///
  /// Quando `supabase_anon_key` está disponível no [RemoteConfigService], autentica
  /// diretamente contra a API GoTrue do Supabase reutilizando o pool de [ClienteHttpAresta].
  ServicoAutenticacaoLocal({
    RepositorioCaderneta? repositorio,
    ClienteHttpAresta? clienteHttp,
    String Function()? obterUrlSupabase,
    String Function()? obterAnonKeySupabase,
    ProvedorLoginEmailSenha? provedorEmailSenha,
    ProvedorCriarContaEmailSenha? provedorCriarConta,
    ProvedorLoginGoogle? provedorGoogle,
  }) : _repositorio = repositorio ?? RepositorioCadernetaLocal.instancia,
       _clienteHttp = clienteHttp ?? ClienteHttpAresta.instancia,
       _obterUrlSupabase =
           obterUrlSupabase ?? (() => RemoteConfigService.instance.supabaseUrl),
       _obterAnonKeySupabase =
           obterAnonKeySupabase ??
           (() => RemoteConfigService.instance.supabaseAnonKey),
       _provedorEmailSenha = provedorEmailSenha,
       _provedorCriarConta = provedorCriarConta,
       _provedorGoogle = provedorGoogle;

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

  @override
  Future<PerfilEscalador> entrarComEmailSenha({
    required String email,
    required String senha,
  }) async {
    final emailLimpo = email.trim();
    _validarEmailESenha(emailLimpo, senha);

    final anonKey = _obterAnonKeySupabase().trim();
    final resultado = _provedorEmailSenha != null
        ? await _provedorEmailSenha(emailLimpo, senha)
        : anonKey.isNotEmpty
        ? await _autenticarEmailSenhaNoSupabase(
            email: emailLimpo,
            senha: senha,
            anonKey: anonKey,
          )
        : ResultadoProvedorAutenticacao(
            userId: 'usr_email_${gerarUid()}',
            nomeExibicao: emailLimpo.split('@').first,
          );

    final atual = _repositorio.obterPerfil();
    final usarNomeSugerido = _provedorEmailSenha != null ||
        anonKey.isNotEmpty ||
        atual.autorNomePublico == PerfilEscalador.apelidoPadrao;
    final novoPerfil = atual.copyWith(
      userId: resultado.userId,
      autorNomePublico: usarNomeSugerido && resultado.nomeExibicao != null
          ? resultado.nomeExibicao
          : atual.autorNomePublico,
    );
    await _repositorio.salvarPerfil(novoPerfil);
    return _repositorio.obterPerfil();
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
    final resultado = _provedorCriarConta != null
        ? await _provedorCriarConta(nomeLimpo, emailLimpo, senha)
        : anonKey.isNotEmpty
        ? await _criarContaNoSupabase(
            nome: nomeLimpo,
            email: emailLimpo,
            senha: senha,
            autorIdPublico: atual.autorIdPublico,
            anonKey: anonKey,
          )
        : ResultadoProvedorAutenticacao(
            userId: 'usr_conta_${gerarUid()}',
            nomeExibicao: nomeLimpo,
          );

    final novoPerfil = atual.copyWith(
      userId: resultado.userId,
      autorNomePublico: resultado.nomeExibicao ?? nomeLimpo,
    );
    await _repositorio.salvarPerfil(novoPerfil);
    return _repositorio.obterPerfil();
  }

  Future<ResultadoProvedorAutenticacao> _autenticarEmailSenhaNoSupabase({
    required String email,
    required String senha,
    required String anonKey,
  }) async {
    final baseUrl = _obterUrlSupabase().trim().replaceAll(RegExp(r'/+$'), '');
    final resposta = await _clienteHttp.post(
      Uri.parse('$baseUrl/auth/v1/token?grant_type=password'),
      headers: {
        'apikey': anonKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': senha,
      }),
    );

    final mapa = jsonDecode(resposta.body) as Map<String, dynamic>;
    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      final erroMsg =
          (mapa['error_description'] ?? mapa['msg'] ?? 'E-mail ou senha incorretos.')
              .toString();
      throw ExcecaoAutenticacao(erroMsg);
    }

    final usuario = (mapa['user'] as Map<String, dynamic>?) ?? mapa;
    final metadados = usuario['user_metadata'] as Map<String, dynamic>?;
    final nomeRemoto = metadados?['autor_nome_publico'] as String?;
    return ResultadoProvedorAutenticacao(
      userId: usuario['id'].toString(),
      nomeExibicao: nomeRemoto ?? email.split('@').first,
    );
  }

  Future<ResultadoProvedorAutenticacao> _criarContaNoSupabase({
    required String nome,
    required String email,
    required String senha,
    required String autorIdPublico,
    required String anonKey,
  }) async {
    final baseUrl = _obterUrlSupabase().trim().replaceAll(RegExp(r'/+$'), '');
    final resposta = await _clienteHttp.post(
      Uri.parse('$baseUrl/auth/v1/signup'),
      headers: {
        'apikey': anonKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': senha,
        'data': {
          'autor_id_publico': autorIdPublico,
          'autor_nome_publico': nome,
        },
      }),
    );

    final mapa = jsonDecode(resposta.body) as Map<String, dynamic>;
    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      final erroMsg =
          (mapa['error_description'] ??
                  mapa['msg'] ??
                  'Não foi possível criar a conta.')
              .toString();
      throw ExcecaoAutenticacao(erroMsg);
    }

    final usuario = (mapa['user'] as Map<String, dynamic>?) ?? mapa;
    return ResultadoProvedorAutenticacao(
      userId: usuario['id'].toString(),
      nomeExibicao: nome,
    );
  }

  @override
  Future<PerfilEscalador> entrarComGoogle() async {
    final resultado = _provedorGoogle != null
        ? await _provedorGoogle()
        : ResultadoProvedorAutenticacao(
            userId: 'usr_google_${gerarUid()}',
            nomeExibicao: 'Escalador Google',
          );

    final atual = _repositorio.obterPerfil();
    final usarNomeSugerido = _provedorGoogle != null ||
        atual.autorNomePublico == PerfilEscalador.apelidoPadrao;
    final novoPerfil = atual.copyWith(
      userId: resultado.userId,
      autorNomePublico: usarNomeSugerido && resultado.nomeExibicao != null
          ? resultado.nomeExibicao
          : atual.autorNomePublico,
    );
    await _repositorio.salvarPerfil(novoPerfil);
    return _repositorio.obterPerfil();
  }

  @override
  Future<void> encerrarSessao() async {
    final atual = _repositorio.obterPerfil();
    if (!atual.estaAutenticado) return;
    await _repositorio.salvarPerfil(atual.copyWith(limparUserId: true));
  }
}
