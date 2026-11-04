// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:app_links/app_links.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
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

  /// URL ou Data URI da foto de perfil retornada pelo provedor, quando disponível.
  final String? fotoUrl;

  /// Token JWT de sessão do Supabase Auth, quando disponível.
  final String? accessToken;

  /// Identificador público NanoID 14c recuperado do banco remoto, quando existente.
  final String? autorIdPublicoRemoto;

  /// Cria uma instância imutável de [ResultadoProvedorAutenticacao].
  const ResultadoProvedorAutenticacao({
    required this.userId,
    this.nomeExibicao,
    this.fotoUrl,
    this.accessToken,
    this.autorIdPublicoRemoto,
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

  /// Autentica o escalador utilizando sua conta Google (Gmail) via Supabase OAuth.
  Future<PerfilEscalador> entrarComGoogle();

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
/// vincular ou desvincular uma conta Google ou de e-mail/senha, sincronizando os metadados
/// e a foto de perfil diretamente com o Supabase Auth, Supabase Storage e `public.perfis`.
class ServicoAutenticacaoLocal implements ServicoAutenticacao {
  /// URL oficial de redirecionamento OAuth registrada nos esquemas nativos Android e iOS.
  static const String urlRedirecionamentoOAuth =
      'aresta://app.arestaclimb.com/auth-callback';

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
  final Future<bool> Function(Uri uri) _lancadorUrlOAuth;
  final Stream<Uri>? _fluxoLinksOAuth;
  final Duration _timeoutOAuth;

  Completer<Uri>? _aguardandoCallbackOAuth;

  /// Cria uma instância de [ServicoAutenticacaoLocal].
  ServicoAutenticacaoLocal({
    RepositorioCaderneta? repositorio,
    ClienteHttpAresta? clienteHttp,
    String Function()? obterUrlSupabase,
    String Function()? obterAnonKeySupabase,
    ProvedorLoginEmailSenha? provedorEmailSenha,
    ProvedorCriarContaEmailSenha? provedorCriarConta,
    ProvedorLoginGoogle? provedorGoogle,
    Future<bool> Function(Uri uri)? lancadorUrlOAuth,
    Stream<Uri>? fluxoLinksOAuth,
    Duration timeoutOAuth = const Duration(minutes: 3),
  }) : _repositorio = repositorio ?? RepositorioCadernetaLocal.instancia,
       _clienteHttp = clienteHttp ?? ClienteHttpAresta.instancia,
       _obterUrlSupabase =
           obterUrlSupabase ?? (() => RemoteConfigService.instance.supabaseUrl),
       _obterAnonKeySupabase =
           obterAnonKeySupabase ??
           (() => RemoteConfigService.instance.supabaseAnonKey),
       _provedorEmailSenha = provedorEmailSenha,
       _provedorCriarConta = provedorCriarConta,
       _provedorGoogle = provedorGoogle,
       _lancadorUrlOAuth =
           lancadorUrlOAuth ??
           ((uri) => launchUrl(uri, mode: LaunchMode.externalApplication)),
       _fluxoLinksOAuth = fluxoLinksOAuth,
       _timeoutOAuth = timeoutOAuth;

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

    final atual = _repositorio.obterPerfil();
    final anonKey = _obterAnonKeySupabase().trim();
    final resultado = _provedorEmailSenha != null
        ? await _provedorEmailSenha(emailLimpo, senha)
        : anonKey.isNotEmpty
        ? await _autenticarEmailSenhaNoSupabase(
            email: emailLimpo,
            senha: senha,
            autorIdPublicoLocal: atual.autorIdPublico,
            anonKey: anonKey,
          )
        : ResultadoProvedorAutenticacao(
            userId: 'usr_email_${gerarUid()}',
            nomeExibicao: emailLimpo.split('@').first,
          );

    final usarNomeSugerido =
        _provedorEmailSenha != null ||
        anonKey.isNotEmpty ||
        atual.autorNomePublico == PerfilEscalador.apelidoPadrao;
    final novoPerfil = atual.copyWith(
      autorIdPublico: resultado.autorIdPublicoRemoto ?? atual.autorIdPublico,
      userId: resultado.userId,
      autorNomePublico: usarNomeSugerido && resultado.nomeExibicao != null
          ? resultado.nomeExibicao
          : atual.autorNomePublico,
      fotoUrl: resultado.fotoUrl ?? atual.fotoUrl,
      accessToken: resultado.accessToken,
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
            fotoUrlAtual: atual.fotoUrl,
            anonKey: anonKey,
          )
        : ResultadoProvedorAutenticacao(
            userId: 'usr_conta_${gerarUid()}',
            nomeExibicao: nomeLimpo,
          );

    final novoPerfil = atual.copyWith(
      autorIdPublico: resultado.autorIdPublicoRemoto ?? atual.autorIdPublico,
      userId: resultado.userId,
      autorNomePublico: resultado.nomeExibicao ?? nomeLimpo,
      fotoUrl: resultado.fotoUrl ?? atual.fotoUrl,
      accessToken: resultado.accessToken,
    );
    await _repositorio.salvarPerfil(novoPerfil);
    return _repositorio.obterPerfil();
  }

  static String _extrairMensagemErro(
    Map<String, dynamic> mapa,
    String mensagemPadrao,
  ) {
    final msg = mapa['error_description'] ?? mapa['msg'];
    return msg != null ? msg.toString() : mensagemPadrao;
  }

  Future<ResultadoProvedorAutenticacao> _autenticarEmailSenhaNoSupabase({
    required String email,
    required String senha,
    required String autorIdPublicoLocal,
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
      throw ExcecaoAutenticacao(
        _extrairMensagemErro(mapa, 'E-mail ou senha incorretos.'),
      );
    }

    final accessToken = mapa['access_token'] as String?;
    final usuario = (mapa['user'] as Map<String, dynamic>?) ?? mapa;
    return _extrairESincronizarUsuarioSupabase(
      baseUrl: baseUrl,
      anonKey: anonKey,
      accessToken: accessToken,
      usuario: usuario,
      autorIdPublicoLocal: autorIdPublicoLocal,
      nomeFallback: email.split('@').first,
    );
  }

  Future<ResultadoProvedorAutenticacao> _criarContaNoSupabase({
    required String nome,
    required String email,
    required String senha,
    required String autorIdPublico,
    required String? fotoUrlAtual,
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
          'avatar_url': ?fotoUrlAtual,
        },
      }),
    );

    final mapa = jsonDecode(resposta.body) as Map<String, dynamic>;
    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      throw ExcecaoAutenticacao(
        _extrairMensagemErro(mapa, 'Não foi possível criar a conta.'),
      );
    }

    final accessToken = mapa['access_token'] as String?;
    final usuario = (mapa['user'] as Map<String, dynamic>?) ?? mapa;
    return _extrairESincronizarUsuarioSupabase(
      baseUrl: baseUrl,
      anonKey: anonKey,
      accessToken: accessToken,
      usuario: usuario,
      autorIdPublicoLocal: autorIdPublico,
      nomeFallback: nome,
    );
  }

  Future<ResultadoProvedorAutenticacao> _extrairESincronizarUsuarioSupabase({
    required String baseUrl,
    required String anonKey,
    required String? accessToken,
    required Map<String, dynamic> usuario,
    required String autorIdPublicoLocal,
    required String nomeFallback,
  }) async {
    final userId = usuario['id'].toString();
    final metadados = usuario['user_metadata'] as Map<String, dynamic>?;
    var nomeEfetivo =
        (metadados?['autor_nome_publico'] ??
                metadados?['full_name'] ??
                metadados?['name'])
            as String? ??
        nomeFallback;
    var fotoEfetiva =
        (metadados?['foto_url'] ??
                metadados?['avatar_url'] ??
                metadados?['picture'])
            as String?;
    var autorIdEfetivo =
        validarUid(metadados?['autor_id_publico'] as String?)
        ? (metadados!['autor_id_publico'] as String)
        : autorIdPublicoLocal;

    if (accessToken != null && accessToken.isNotEmpty) {
      final sincronizado = await _sincronizarLinhaPerfisSupabase(
        baseUrl: baseUrl,
        anonKey: anonKey,
        accessToken: accessToken,
        userId: userId,
        autorIdPublico: autorIdEfetivo,
        nomePublico: nomeEfetivo,
        fotoUrl: fotoEfetiva,
      );
      autorIdEfetivo = sincronizado.autorIdPublico;
      nomeEfetivo = sincronizado.nomePublico;
      fotoEfetiva = sincronizado.fotoUrl ?? fotoEfetiva;
    }

    return ResultadoProvedorAutenticacao(
      userId: userId,
      nomeExibicao: nomeEfetivo,
      fotoUrl: fotoEfetiva,
      accessToken: accessToken,
      autorIdPublicoRemoto: autorIdEfetivo,
    );
  }

  Future<({String autorIdPublico, String nomePublico, String? fotoUrl})>
  _sincronizarLinhaPerfisSupabase({
    required String baseUrl,
    required String anonKey,
    required String accessToken,
    required String userId,
    required String autorIdPublico,
    required String nomePublico,
    required String? fotoUrl,
  }) async {
    var idFinal = autorIdPublico;
    var nomeFinal = nomePublico;
    var fotoFinal = fotoUrl;

    try {
      final consulta = await _clienteHttp.get(
        Uri.parse(
          '$baseUrl/rest/v1/perfis?user_id=eq.$userId&select=autor_id_publico,autor_nome_publico,avatar_url',
        ),
        headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (consulta.statusCode >= 200 && consulta.statusCode < 300) {
        final lista = jsonDecode(consulta.body) as List<dynamic>;
        if (lista.isNotEmpty) {
          final linha = lista.first as Map<String, dynamic>;
          final idBanco = linha['autor_id_publico'] as String?;
          final nomeBanco = linha['autor_nome_publico'] as String?;
          final fotoBanco = linha['avatar_url'] as String?;
          if (validarUid(idBanco)) {
            idFinal = idBanco!;
          }
          if (nomeBanco != null &&
              nomeBanco.trim().isNotEmpty &&
              nomeBanco != PerfilEscalador.apelidoPadrao) {
            nomeFinal = nomeBanco.trim();
          }
          if (fotoBanco != null && fotoBanco.trim().isNotEmpty) {
            fotoFinal = fotoBanco.trim();
          }
        } else {
          await _upsertPerfilNoSupabase(
            baseUrl: baseUrl,
            anonKey: anonKey,
            accessToken: accessToken,
            userId: userId,
            autorIdPublico: idFinal,
            nomePublico: nomeFinal,
            fotoUrl: fotoFinal,
          );
        }
      }
    } catch (_) {}

    return (
      autorIdPublico: idFinal,
      nomePublico: nomeFinal,
      fotoUrl: fotoFinal,
    );
  }

  Future<void> _upsertPerfilNoSupabase({
    required String baseUrl,
    required String anonKey,
    required String accessToken,
    required String userId,
    required String autorIdPublico,
    required String nomePublico,
    required String? fotoUrl,
  }) async {
    try {
      await _clienteHttp.post(
        Uri.parse('$baseUrl/rest/v1/perfis?on_conflict=user_id'),
        headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Prefer': 'resolution=merge-duplicates',
        },
        body: jsonEncode({
          'user_id': userId,
          'autor_id_publico': autorIdPublico,
          'autor_nome_publico': nomePublico,
          'avatar_url': ?fotoUrl,
        }),
      );
    } catch (_) {}
  }

  static bool _ehCallbackOAuth(Uri uri) {
    final caminho = uri.path.toLowerCase();
    final host = uri.host.toLowerCase();
    return host == 'auth-callback' || caminho.contains('auth-callback');
  }

  @override
  bool processarCallbackOAuth(Uri uri) {
    if (!_ehCallbackOAuth(uri)) {
      return false;
    }
    final pendente = _aguardandoCallbackOAuth;
    if (pendente != null && !pendente.isCompleted) {
      pendente.complete(uri);
    }
    return true;
  }

  static String _gerarCodeVerifierPkce() {
    const caracteres =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(
      56,
      (_) => caracteres[random.nextInt(caracteres.length)],
    ).join();
  }

  static String _calcularCodeChallengeS256(String codeVerifier) {
    final digest = sha256.convert(utf8.encode(codeVerifier));
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  static Map<String, String> _extrairParametrosCallback(Uri uri) {
    final resultado = <String, String>{...uri.queryParameters};
    if (uri.fragment.isNotEmpty) {
      try {
        resultado.addAll(Uri.splitQueryString(uri.fragment));
      } catch (_) {}
    }
    return resultado;
  }

  Future<ResultadoProvedorAutenticacao> _autenticarGoogleNoSupabase({
    required String autorIdPublicoLocal,
    required String anonKey,
  }) async {
    final baseUrl = _obterUrlSupabase().trim().replaceAll(RegExp(r'/+$'), '');
    final codeVerifier = _gerarCodeVerifierPkce();
    final codeChallenge = _calcularCodeChallengeS256(codeVerifier);

    final uriAutorizacao = Uri.parse('$baseUrl/auth/v1/authorize').replace(
      queryParameters: {
        'provider': 'google',
        'redirect_to': urlRedirecionamentoOAuth,
        'code_challenge': codeChallenge,
        'code_challenge_method': 's256',
      },
    );

    final completer = Completer<Uri>();
    _aguardandoCallbackOAuth = completer;

    final fluxo = _fluxoLinksOAuth ?? AppLinks().uriLinkStream;
    final inscricao = fluxo.listen((uri) {
      processarCallbackOAuth(uri);
    });

    try {
      final abriu = await _lancadorUrlOAuth(uriAutorizacao);
      if (!abriu) {
        throw const ExcecaoAutenticacao(
          'Não foi possível abrir o navegador para autenticar com o Google.',
        );
      }

      final uriRetorno = await completer.future.timeout(_timeoutOAuth);
      final params = _extrairParametrosCallback(uriRetorno);

      final erroOAuth = params['error_description'] ?? params['error'];
      if (erroOAuth != null && erroOAuth.trim().isNotEmpty) {
        throw ExcecaoAutenticacao(erroOAuth.replaceAll('+', ' '));
      }

      final codigoPkce = params['code'];
      final tokenImplicito = params['access_token'];

      if (codigoPkce != null && codigoPkce.isNotEmpty) {
        final resposta = await _clienteHttp.post(
          Uri.parse('$baseUrl/auth/v1/token?grant_type=pkce'),
          headers: {
            'apikey': anonKey,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'auth_code': codigoPkce,
            'code_verifier': codeVerifier,
          }),
        );

        final mapa = jsonDecode(resposta.body) as Map<String, dynamic>;
        if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
          throw ExcecaoAutenticacao(
            _extrairMensagemErro(mapa, 'Falha ao validar login com o Google.'),
          );
        }

        final accessToken = mapa['access_token'] as String?;
        final usuario = (mapa['user'] as Map<String, dynamic>?) ?? mapa;
        return await _extrairESincronizarUsuarioSupabase(
          baseUrl: baseUrl,
          anonKey: anonKey,
          accessToken: accessToken,
          usuario: usuario,
          autorIdPublicoLocal: autorIdPublicoLocal,
          nomeFallback: 'Escalador Google',
        );
      }

      if (tokenImplicito != null && tokenImplicito.isNotEmpty) {
        final resposta = await _clienteHttp.get(
          Uri.parse('$baseUrl/auth/v1/user'),
          headers: {
            'apikey': anonKey,
            'Authorization': 'Bearer $tokenImplicito',
          },
        );

        final mapa = jsonDecode(resposta.body) as Map<String, dynamic>;
        if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
          throw ExcecaoAutenticacao(
            _extrairMensagemErro(mapa, 'Sessão do Google inválida.'),
          );
        }

        return await _extrairESincronizarUsuarioSupabase(
          baseUrl: baseUrl,
          anonKey: anonKey,
          accessToken: tokenImplicito,
          usuario: mapa,
          autorIdPublicoLocal: autorIdPublicoLocal,
          nomeFallback: 'Escalador Google',
        );
      }

      throw const ExcecaoAutenticacao(
        'Resposta de autenticação do Google incompleta.',
      );
    } on TimeoutException {
      throw const ExcecaoAutenticacao(
        'Tempo esgotado ao aguardar o retorno do login com Google.',
      );
    } finally {
      await inscricao.cancel();
      if (identical(_aguardandoCallbackOAuth, completer)) {
        _aguardandoCallbackOAuth = null;
      }
    }
  }

  @override
  Future<PerfilEscalador> entrarComGoogle() async {
    final atual = _repositorio.obterPerfil();
    final anonKey = _obterAnonKeySupabase().trim();
    final resultado = _provedorGoogle != null
        ? await _provedorGoogle()
        : anonKey.isNotEmpty
        ? await _autenticarGoogleNoSupabase(
            autorIdPublicoLocal: atual.autorIdPublico,
            anonKey: anonKey,
          )
        : ResultadoProvedorAutenticacao(
            userId: 'usr_google_${gerarUid()}',
            nomeExibicao: 'Escalador Google',
          );

    final usarNomeSugerido =
        _provedorGoogle != null ||
        anonKey.isNotEmpty ||
        atual.autorNomePublico == PerfilEscalador.apelidoPadrao;
    final novoPerfil = atual.copyWith(
      autorIdPublico: resultado.autorIdPublicoRemoto ?? atual.autorIdPublico,
      userId: resultado.userId,
      autorNomePublico: usarNomeSugerido && resultado.nomeExibicao != null
          ? resultado.nomeExibicao
          : atual.autorNomePublico,
      fotoUrl: resultado.fotoUrl ?? atual.fotoUrl,
      accessToken: resultado.accessToken,
    );
    await _repositorio.salvarPerfil(novoPerfil);
    return _repositorio.obterPerfil();
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
      final baseUrl = _obterUrlSupabase().trim().replaceAll(RegExp(r'/+$'), '');

      if (novaFotoUrl != null && novaFotoUrl.startsWith('data:image/')) {
        final indiceVirgula = novaFotoUrl.indexOf(',');
        if (indiceVirgula != -1) {
          try {
            final bytesImagem = base64Decode(
              novaFotoUrl.substring(indiceVirgula + 1),
            );
            final caminhoObjeto = '${atual.userId}/avatar.jpg';
            final respStorage = await _clienteHttp.post(
              Uri.parse('$baseUrl/storage/v1/object/avatars/$caminhoObjeto'),
              headers: {
                'apikey': anonKey,
                'Authorization': 'Bearer $accessToken',
                'Content-Type': 'image/jpeg',
                'x-upsert': 'true',
              },
              body: bytesImagem,
            );
            if (respStorage.statusCode >= 200 && respStorage.statusCode < 300) {
              fotoFinal =
                  '$baseUrl/storage/v1/object/public/avatars/$caminhoObjeto?t=${DateTime.now().millisecondsSinceEpoch}';
            }
          } catch (_) {}
        }
      }

      try {
        final reqPut = Request('PUT', Uri.parse('$baseUrl/auth/v1/user'))
          ..headers.addAll({
            'apikey': anonKey,
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          })
          ..body = jsonEncode({
            'data': {
              'autor_id_publico': atual.autorIdPublico,
              'autor_nome_publico': nomeFinal,
              'avatar_url': ?fotoFinal,
            },
          });
        await _clienteHttp.send(reqPut);
      } catch (_) {}

      await _upsertPerfilNoSupabase(
        baseUrl: baseUrl,
        anonKey: anonKey,
        accessToken: accessToken,
        userId: atual.userId!,
        autorIdPublico: atual.autorIdPublico,
        nomePublico: nomeFinal,
        fotoUrl: fotoFinal,
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
  Future<void> encerrarSessao() async {
    final atual = _repositorio.obterPerfil();
    if (!atual.estaAutenticado) return;
    await _repositorio.salvarPerfil(atual.copyWith(limparUserId: true));
  }
}
