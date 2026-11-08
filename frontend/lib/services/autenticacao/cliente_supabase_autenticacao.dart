// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:app_links/app_links.dart';
import 'package:crypto/crypto.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/modelos/perfil_escalador.dart';
import '../../utils/gerador_uid.dart';
import '../firebase/remote_config.dart';
import '../http/cliente_http_aresta.dart';
import 'autenticador_nativo.dart';
import 'servico_autenticacao.dart';

/// Cliente modular dedicado ├á comunica├º├úo HTTP e OAuth 2.0 (PKCE/Implicit) com o Supabase.
///
/// Isola os protocolos de rede do GoTrue (`/auth/v1`), PostgREST (`/rest/v1/perfis`)
/// e Supabase Storage (`/storage/v1/object/avatars`) das regras de neg├│cio locais
/// de dom├¡nio do [ServicoAutenticacaoLocal].
class ClienteSupabaseAutenticacao {
  /// URL oficial de redirecionamento OAuth registrada nos esquemas nativos Android e iOS.
  static const String urlRedirecionamentoOAuth =
      'aresta://app.arestaclimb.com/auth-callback';

  final ClienteHttpAresta _clienteHttp;
  final String Function() _obterUrlSupabase;
  final AutenticadorNativo _autenticadorNativo;
  final String _idClienteWebGoogle;
  final Future<bool> Function(Uri uri) _lancadorUrlOAuth;
  final Stream<Uri>? _fluxoLinksOAuth;
  final Duration _timeoutOAuth;

  Completer<Uri>? _aguardandoCallbackOAuth;

  /// Cria uma inst├óncia de [ClienteSupabaseAutenticacao].
  ClienteSupabaseAutenticacao({
    ClienteHttpAresta? clienteHttp,
    String Function()? obterUrlSupabase,
    AutenticadorNativo? autenticadorNativo,
    String idClienteWebGoogle =
        AutenticadorNativoCanal.idClienteWebGooglePadrao,
    Future<bool> Function(Uri uri)? lancadorUrlOAuth,
    Stream<Uri>? fluxoLinksOAuth,
    Duration timeoutOAuth = const Duration(minutes: 3),
  }) : _clienteHttp = clienteHttp ?? ClienteHttpAresta.instancia,
       _obterUrlSupabase =
           obterUrlSupabase ?? (() => RemoteConfigService.instance.supabaseUrl),
       _autenticadorNativo =
           autenticadorNativo ?? AutenticadorNativoCanal.instancia,
       _idClienteWebGoogle = idClienteWebGoogle,
       _lancadorUrlOAuth =
           lancadorUrlOAuth ??
           ((uri) => launchUrl(uri, mode: LaunchMode.externalApplication)),
       _fluxoLinksOAuth = fluxoLinksOAuth,
       _timeoutOAuth = timeoutOAuth;

  String get _baseUrl =>
      _obterUrlSupabase().trim().replaceAll(RegExp(r'/+$'), '');

  /// Autentica um escalador existente via GoTrue (`/auth/v1/token?grant_type=password`)
  /// e sincroniza seus metadados com `public.perfis`.
  Future<ResultadoProvedorAutenticacao> autenticarEmailSenha({
    required String email,
    required String senha,
    required String autorIdPublicoLocal,
    required String anonKey,
  }) async {
    final baseUrl = _baseUrl;
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
    return _extrairESincronizarUsuario(
      baseUrl: baseUrl,
      anonKey: anonKey,
      accessToken: accessToken,
      usuario: usuario,
      autorIdPublicoLocal: autorIdPublicoLocal,
      nomeFallback: email.split('@').first,
    );
  }

  /// Cria uma nova conta no GoTrue (`/auth/v1/signup`) com os metadados p├║blicos do escalador
  /// e garante o espelhamento em `public.perfis`.
  Future<ResultadoProvedorAutenticacao> criarConta({
    required String nome,
    required String email,
    required String senha,
    required String autorIdPublico,
    required String? fotoUrlAtual,
    required String anonKey,
  }) async {
    final baseUrl = _baseUrl;
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
        _extrairMensagemErro(mapa, 'N├úo foi poss├¡vel criar a conta.'),
      );
    }

    final accessToken = mapa['access_token'] as String?;
    final usuario = (mapa['user'] as Map<String, dynamic>?) ?? mapa;
    return _extrairESincronizarUsuario(
      baseUrl: baseUrl,
      anonKey: anonKey,
      accessToken: accessToken,
      usuario: usuario,
      autorIdPublicoLocal: autorIdPublico,
      nomeFallback: nome,
    );
  }

  /// Autentica com o Google priorizando o seletor nativo de contas do sistema operacional
  /// (`grant_type=id_token`) e utilizando o fluxo OAuth 2.0 via navegador como fallback.
  Future<ResultadoProvedorAutenticacao> autenticarGoogleOAuth({
    required String autorIdPublicoLocal,
    required String anonKey,
  }) async {
    final credencialNativa = await _autenticadorNativo.solicitarCredencialGoogle(
      webClientId: _idClienteWebGoogle,
    );
    if (credencialNativa != null) {
      if (credencialNativa.cancelado) {
        throw const ExcecaoAutenticacao('Login com o Google cancelado.');
      }
      return autenticarComIdToken(
        provedor: 'google',
        idToken: credencialNativa.idToken!,
        nonce: credencialNativa.nonce,
        nomeSugeridoNativo: credencialNativa.nomeExibicao,
        fotoSugeridaNativa: credencialNativa.fotoUrl,
        nomeFallback: 'Escalador Google',
        autorIdPublicoLocal: autorIdPublicoLocal,
        anonKey: anonKey,
      );
    }

    return autenticarProvedorOAuth(
      provedor: 'google',
      nomeFallback: 'Escalador Google',
      autorIdPublicoLocal: autorIdPublicoLocal,
      anonKey: anonKey,
    );
  }

  /// Autentica com a Apple priorizando o modal nativo do sistema operacional (Face ID / Touch ID
  /// via `grant_type=id_token`) e utilizando o fluxo OAuth 2.0 via navegador como fallback.
  Future<ResultadoProvedorAutenticacao> autenticarAppleOAuth({
    required String autorIdPublicoLocal,
    required String anonKey,
  }) async {
    final credencialNativa = await _autenticadorNativo.solicitarCredencialApple();
    if (credencialNativa != null) {
      if (credencialNativa.cancelado) {
        throw const ExcecaoAutenticacao('Login com a Apple cancelado.');
      }
      return autenticarComIdToken(
        provedor: 'apple',
        idToken: credencialNativa.idToken!,
        nonce: credencialNativa.nonce,
        nomeSugeridoNativo: credencialNativa.nomeExibicao,
        fotoSugeridaNativa: credencialNativa.fotoUrl,
        nomeFallback: 'Escalador Apple',
        autorIdPublicoLocal: autorIdPublicoLocal,
        anonKey: anonKey,
      );
    }

    return autenticarProvedorOAuth(
      provedor: 'apple',
      nomeFallback: 'Escalador Apple',
      autorIdPublicoLocal: autorIdPublicoLocal,
      anonKey: anonKey,
    );
  }

  /// Autentica diretamente no GoTrue (`/auth/v1/token?grant_type=id_token`) utilizando
  /// um `id_token` emitido pelo modal nativo do sistema operacional (sem abrir o navegador).
  Future<ResultadoProvedorAutenticacao> autenticarComIdToken({
    required String provedor,
    required String idToken,
    String? nonce,
    String? nomeSugeridoNativo,
    String? fotoSugeridaNativa,
    required String nomeFallback,
    required String autorIdPublicoLocal,
    required String anonKey,
  }) async {
    final baseUrl = _baseUrl;
    final resposta = await _clienteHttp.post(
      Uri.parse('$baseUrl/auth/v1/token?grant_type=id_token'),
      headers: {
        'apikey': anonKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'provider': provedor,
        'id_token': idToken,
        'nonce': ?nonce,
      }),
    );

    final mapa = jsonDecode(resposta.body) as Map<String, dynamic>;
    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      throw ExcecaoAutenticacao(
        _extrairMensagemErro(mapa, 'Falha ao validar credencial nativa.'),
      );
    }

    final accessToken = mapa['access_token'] as String?;
    final usuarioBruto = (mapa['user'] as Map<String, dynamic>?) ?? mapa;
    final metadadosAtuais = Map<String, dynamic>.from(
      (usuarioBruto['user_metadata'] as Map<String, dynamic>?) ?? const {},
    );
    if (nomeSugeridoNativo != null && nomeSugeridoNativo.trim().isNotEmpty) {
      metadadosAtuais.putIfAbsent('full_name', () => nomeSugeridoNativo.trim());
    }
    if (fotoSugeridaNativa != null && fotoSugeridaNativa.trim().isNotEmpty) {
      metadadosAtuais.putIfAbsent('avatar_url', () => fotoSugeridaNativa.trim());
    }
    final usuarioEnriquecido = <String, dynamic>{
      ...usuarioBruto,
      'user_metadata': metadadosAtuais,
    };

    return _extrairESincronizarUsuario(
      baseUrl: baseUrl,
      anonKey: anonKey,
      accessToken: accessToken,
      usuario: usuarioEnriquecido,
      autorIdPublicoLocal: autorIdPublicoLocal,
      nomeFallback: nomeFallback,
    );
  }

  /// Inicia o fluxo OAuth 2.0 com o [provedor] (`'google'` ou `'apple'`) via navegador externo
  /// e aguarda o callback (`PKCE` ou `Implicit`) para concluir a sess├úo no Supabase.
  Future<ResultadoProvedorAutenticacao> autenticarProvedorOAuth({
    required String provedor,
    required String nomeFallback,
    required String autorIdPublicoLocal,
    required String anonKey,
  }) async {
    final baseUrl = _baseUrl;
    final codeVerifier = _gerarCodeVerifierPkce();
    final codeChallenge = _calcularCodeChallengeS256(codeVerifier);

    final uriAutorizacao = Uri.parse('$baseUrl/auth/v1/authorize').replace(
      queryParameters: {
        'provider': provedor,
        'redirect_to': urlRedirecionamentoOAuth,
        'code_challenge': codeChallenge,
        'code_challenge_method': 's256',
      },
    );

    final completer = Completer<Uri>();
    _aguardandoCallbackOAuth = completer;

    final fluxo = _fluxoLinksOAuth ?? AppLinks().uriLinkStream;
    final inscricao = fluxo.listen(processarCallbackOAuth);

    try {
      final abriu = await _lancadorUrlOAuth(uriAutorizacao);
      if (!abriu) {
        throw const ExcecaoAutenticacao(
          'N├úo foi poss├¡vel abrir o navegador para concluir a autentica├º├úo.',
        );
      }

      final uriRetorno = await completer.future.timeout(_timeoutOAuth);
      final params = _extrairParametrosCallback(uriRetorno);

      final erroOAuth = params['error_description'] ?? params['error'];
      if (erroOAuth != null && erroOAuth.trim().isNotEmpty) {
        throw ExcecaoAutenticacao(
          _traduzirMensagemServidor(
            erroOAuth.replaceAll('+', ' '),
            'N├úo foi poss├¡vel concluir a autentica├º├úo.',
          ),
        );
      }

      final codigoPkce = params['code'];
      if (codigoPkce != null && codigoPkce.isNotEmpty) {
        return await _trocarCodigoPkcePorSessao(
          baseUrl: baseUrl,
          anonKey: anonKey,
          codigoPkce: codigoPkce,
          codeVerifier: codeVerifier,
          autorIdPublicoLocal: autorIdPublicoLocal,
          nomeFallback: nomeFallback,
        );
      }

      final tokenImplicito = params['access_token'];
      if (tokenImplicito != null && tokenImplicito.isNotEmpty) {
        return await _consultarUsuarioComTokenImplicito(
          baseUrl: baseUrl,
          anonKey: anonKey,
          tokenImplicito: tokenImplicito,
          autorIdPublicoLocal: autorIdPublicoLocal,
          nomeFallback: nomeFallback,
        );
      }

      throw const ExcecaoAutenticacao(
        'Resposta de autentica├º├úo OAuth incompleta.',
      );
    } on TimeoutException {
      throw const ExcecaoAutenticacao(
        'Tempo esgotado ao aguardar o retorno da autentica├º├úo.',
      );
    } finally {
      await inscricao.cancel();
      if (identical(_aguardandoCallbackOAuth, completer)) {
        _aguardandoCallbackOAuth = null;
      }
    }
  }

  /// Sincroniza altera├º├Áes de nome e foto de perfil com o Supabase Storage (`avatars`),
  /// GoTrue (`PUT /auth/v1/user`) e PostgREST (`public.perfis`).
  ///
  /// Retorna a URL p├║blica definitiva da foto (ou a [fotoFinal] original em fallback).
  Future<String?> sincronizarPerfilAtualizado({
    required String anonKey,
    required String accessToken,
    required String userId,
    required String autorIdPublico,
    required String nomeFinal,
    required String? fotoFinal,
  }) async {
    final baseUrl = _baseUrl;
    var urlFotoResolvida = fotoFinal;

    if (fotoFinal != null && fotoFinal.startsWith('data:image/')) {
      final urlStorage = await _enviarAvatarParaStorage(
        baseUrl: baseUrl,
        anonKey: anonKey,
        accessToken: accessToken,
        userId: userId,
        dataUri: fotoFinal,
      );
      if (urlStorage != null) {
        urlFotoResolvida = urlStorage;
      }
    }

    await _atualizarMetadadosAuthUsuario(
      baseUrl: baseUrl,
      anonKey: anonKey,
      accessToken: accessToken,
      autorIdPublico: autorIdPublico,
      nomePublico: nomeFinal,
      fotoUrl: urlFotoResolvida,
    );

    await _upsertLinhaPerfis(
      baseUrl: baseUrl,
      anonKey: anonKey,
      accessToken: accessToken,
      userId: userId,
      autorIdPublico: autorIdPublico,
      nomePublico: nomeFinal,
      fotoUrl: urlFotoResolvida,
    );

    return urlFotoResolvida;
  }

  /// Intercepta um deep link de retorno do fluxo OAuth (`aresta://app.arestaclimb.com/auth-callback`).
  ///
  /// Retorna `true` se o link era um callback de autentica├º├úo OAuth.
  bool processarCallbackOAuth(Uri uri) {
    final caminho = uri.path.toLowerCase();
    final host = uri.host.toLowerCase();
    if (host != 'auth-callback' && !caminho.contains('auth-callback')) {
      return false;
    }
    final pendente = _aguardandoCallbackOAuth;
    if (pendente != null && !pendente.isCompleted) {
      pendente.complete(uri);
    }
    return true;
  }

  Future<ResultadoProvedorAutenticacao> _trocarCodigoPkcePorSessao({
    required String baseUrl,
    required String anonKey,
    required String codigoPkce,
    required String codeVerifier,
    required String autorIdPublicoLocal,
    required String nomeFallback,
  }) async {
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
        _extrairMensagemErro(mapa, 'Falha ao validar login OAuth.'),
      );
    }

    final accessToken = mapa['access_token'] as String?;
    final usuario = (mapa['user'] as Map<String, dynamic>?) ?? mapa;
    return _extrairESincronizarUsuario(
      baseUrl: baseUrl,
      anonKey: anonKey,
      accessToken: accessToken,
      usuario: usuario,
      autorIdPublicoLocal: autorIdPublicoLocal,
      nomeFallback: nomeFallback,
    );
  }

  Future<ResultadoProvedorAutenticacao> _consultarUsuarioComTokenImplicito({
    required String baseUrl,
    required String anonKey,
    required String tokenImplicito,
    required String autorIdPublicoLocal,
    required String nomeFallback,
  }) async {
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
        _extrairMensagemErro(mapa, 'Sess├úo OAuth inv├ílida.'),
      );
    }

    return _extrairESincronizarUsuario(
      baseUrl: baseUrl,
      anonKey: anonKey,
      accessToken: tokenImplicito,
      usuario: mapa,
      autorIdPublicoLocal: autorIdPublicoLocal,
      nomeFallback: nomeFallback,
    );
  }

  Future<ResultadoProvedorAutenticacao> _extrairESincronizarUsuario({
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
    var autorIdEfetivo = validarUid(metadados?['autor_id_publico'] as String?)
        ? (metadados!['autor_id_publico'] as String)
        : autorIdPublicoLocal;

    if (accessToken != null && accessToken.isNotEmpty) {
      final sincronizado = await _sincronizarLinhaPerfis(
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
  _sincronizarLinhaPerfis({
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
          await _upsertLinhaPerfis(
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

  Future<String?> _enviarAvatarParaStorage({
    required String baseUrl,
    required String anonKey,
    required String accessToken,
    required String userId,
    required String dataUri,
  }) async {
    final indiceVirgula = dataUri.indexOf(',');
    if (indiceVirgula == -1) return null;
    try {
      final bytesImagem = base64Decode(dataUri.substring(indiceVirgula + 1));
      final caminhoObjeto = '$userId/avatar.jpg';
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
        return '$baseUrl/storage/v1/object/public/avatars/$caminhoObjeto?t=${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (_) {}
    return null;
  }

}
