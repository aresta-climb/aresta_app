// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:convert';
import '../firebase/remote_config.dart';
import '../http/cliente_http_aresta.dart';
import 'autenticador_nativo.dart';
import 'servico_autenticacao.dart';
import 'sincronizador_perfil_supabase.dart';
import 'tradutor_erros_autenticacao.dart';

/// Cliente modular dedicado à comunicação HTTP sem senha (OTP de 6 dígitos e OAuth in-app `id_token`/PKCE) com o Supabase GoTrue.
///
/// Isola os protocolos de autenticação do GoTrue (`/auth/v1`), delegando a sincronização
/// de perfil e avatar ao [SincronizadorPerfilSupabase] e a tradução/classificação de erros ao
/// módulo `tradutor_erros_autenticacao.dart`.
class ClienteSupabaseAutenticacao {
  /// URL oficial de redirecionamento OAuth registrada para sessão PKCE in-app (`ASWebAuthenticationSession`).
  static const String urlRedirecionamentoOAuth =
      'aresta://app.arestaclimb.com/auth-callback';

  final ClienteHttpAresta _clienteHttp;
  final SincronizadorPerfilSupabase _sincronizadorPerfil;
  final String Function() _obterUrlSupabase;
  final AutenticadorNativo _autenticadorNativo;
  final String _idClienteWebGoogle;

  /// Cria uma instância de [ClienteSupabaseAutenticacao].
  ClienteSupabaseAutenticacao({
    ClienteHttpAresta? clienteHttp,
    SincronizadorPerfilSupabase? sincronizadorPerfil,
    String Function()? obterUrlSupabase,
    AutenticadorNativo? autenticadorNativo,
    String idClienteWebGoogle =
        AutenticadorNativoCanal.idClienteWebGooglePadrao,
  }) : _clienteHttp = clienteHttp ?? ClienteHttpAresta.instancia,
       _sincronizadorPerfil =
           sincronizadorPerfil ??
           SincronizadorPerfilSupabase(
             clienteHttp: clienteHttp ?? ClienteHttpAresta.instancia,
           ),
       _obterUrlSupabase =
           obterUrlSupabase ?? (() => RemoteConfigService.instance.supabaseUrl),
       _autenticadorNativo =
           autenticadorNativo ?? AutenticadorNativoCanal.instancia,
       _idClienteWebGoogle = idClienteWebGoogle;

  String get _baseUrl =>
      _obterUrlSupabase().trim().replaceAll(RegExp(r'/+$'), '');

  static Map<String, dynamic> _decodificarJsonSeguro(String corpo) {
    final limpo = corpo.trim();
    if (limpo.isEmpty) {
      return const <String, dynamic>{};
    }
    try {
      final decodificado = jsonDecode(limpo);
      if (decodificado is Map<String, dynamic>) {
        return decodificado;
      }
      return <String, dynamic>{'msg': limpo};
    } catch (_) {
      return <String, dynamic>{'msg': limpo};
    }
  }

  /// Solicita ao Supabase Auth (`/auth/v1/otp`) o envio de um código OTP numérico de 6 dígitos
  /// via Resend SMTP para [email] (criando a conta automaticamente quando inexistente).
  Future<void> solicitarCodigoOtpEmail({
    required String email,
    required String anonKey,
  }) async {
    final baseUrl = _baseUrl;
    final resposta = await _clienteHttp.post(
      Uri.parse('$baseUrl/auth/v1/otp'),
      headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $anonKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim(),
        'create_user': true,
      }),
    );

    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      final mapa = _decodificarJsonSeguro(resposta.body);
      throw ExcecaoAutenticacao(
        extrairMensagemErroAutenticacao(
          mapa,
          'Não foi possível enviar o código de acesso.',
        ),
        codigoStatusHttp: resposta.statusCode,
        ehErroUsuario: ehErroEntradaUsuarioServidor(mapa),
        causaTecnica: 'HTTP ${resposta.statusCode} /auth/v1/otp: ${resposta.body}',
      );
    }
  }

  /// Valida o código numérico de 6 dígitos [codigo] informado para [email] em `/auth/v1/verify`
  /// (`type: "email"`) e sincroniza os metadados do escalador com `public.perfis`.
  Future<ResultadoProvedorAutenticacao> verificarCodigoOtpEmail({
    required String email,
    required String codigo,
    required String autorIdPublicoLocal,
    required String anonKey,
  }) async {
    final baseUrl = _baseUrl;
    final emailLimpo = email.trim();
    final resposta = await _clienteHttp.post(
      Uri.parse('$baseUrl/auth/v1/verify'),
      headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $anonKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'type': 'email',
        'email': emailLimpo,
        'token': codigo.trim(),
      }),
    );

    final mapa = _decodificarJsonSeguro(resposta.body);
    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      throw ExcecaoAutenticacao(
        extrairMensagemErroAutenticacao(
          mapa,
          'O código de acesso expirou ou é inválido.',
        ),
        codigoStatusHttp: resposta.statusCode,
        ehErroUsuario: ehErroEntradaUsuarioServidor(mapa),
        causaTecnica:
            'HTTP ${resposta.statusCode} /auth/v1/verify: ${resposta.body}',
      );
    }

    final accessToken = mapa['access_token'] as String?;
    final usuario = (mapa['user'] as Map<String, dynamic>?) ?? mapa;
    return _sincronizadorPerfil.extrairESincronizarUsuario(
      baseUrl: baseUrl,
      anonKey: anonKey,
      accessToken: accessToken,
      usuario: usuario,
      autorIdPublicoLocal: autorIdPublicoLocal,
      nomeFallback: emailLimpo.split('@').first,
    );
  }

  /// Autentica com o Google 100% dentro do aplicativo:
  /// - No Android: recebe `id_token` emitido pelo `CredentialManager` (`grant_type=id_token`).
  /// - No iOS: recebe `callbackUri` capturada em `ASWebAuthenticationSession` com PKCE (`grant_type=pkce`).
  Future<ResultadoProvedorAutenticacao> autenticarGoogleOAuth({
    required String autorIdPublicoLocal,
    required String anonKey,
  }) async {
    final baseUrl = _baseUrl;
    final codeVerifier = gerarCodeVerifierPkce();
    final codeChallenge = calcularCodeChallengeS256(codeVerifier);
    final uriAutorizacao = Uri.parse('$baseUrl/auth/v1/authorize').replace(
      queryParameters: {
        'provider': 'google',
        'redirect_to': urlRedirecionamentoOAuth,
        'code_challenge': codeChallenge,
        'code_challenge_method': 's256',
      },
    );

    final credencial = await _autenticadorNativo.solicitarCredencialGoogle(
      webClientId: _idClienteWebGoogle,
      uriAutorizacaoPkce: uriAutorizacao,
      esquemaCallback: 'aresta',
    );
    if (credencial == null) {
      throw const ExcecaoAutenticacao(
        'Não foi possível iniciar o login com o Google neste dispositivo.',
        ehErroUsuario: false,
        causaTecnica: 'Canal nativo Google retornou nulo',
      );
    }
    if (credencial.cancelado) {
      throw const ExcecaoAutenticacaoCancelada();
    }
    if (credencial.erroNativo != null) {
      throw ExcecaoAutenticacao(
        'Não foi possível entrar com o Google. Tente novamente.',
        ehErroUsuario: false,
        causaTecnica: 'Canal nativo Google: ${credencial.erroNativo}',
      );
    }
    if (credencial.possuiCallbackUri) {
      return _processarRetornoPkceInApp(
        uriRetorno: credencial.callbackUri!,
        baseUrl: baseUrl,
        anonKey: anonKey,
        codeVerifier: codeVerifier,
        autorIdPublicoLocal: autorIdPublicoLocal,
        nomeFallback: 'Escalador Google',
      );
    }
    return autenticarComIdToken(
      provedor: 'google',
      idToken: credencial.idToken!,
      nonce: credencial.nonce,
      nomeSugeridoNativo: credencial.nomeExibicao,
      fotoSugeridaNativa: credencial.fotoUrl,
      nomeFallback: 'Escalador Google',
      autorIdPublicoLocal: autorIdPublicoLocal,
      anonKey: anonKey,
    );
  }

  /// Autentica com a Apple exclusivamente pelo modal nativo do iOS (`ASAuthorizationAppleIDProvider`
  /// via `grant_type=id_token`), sem fallback de navegador externo.
  Future<ResultadoProvedorAutenticacao> autenticarAppleOAuth({
    required String autorIdPublicoLocal,
    required String anonKey,
  }) async {
    final credencial = await _autenticadorNativo.solicitarCredencialApple();
    if (credencial == null) {
      throw const ExcecaoAutenticacao(
        'Não foi possível iniciar o login com a Apple neste dispositivo.',
        ehErroUsuario: false,
        causaTecnica: 'Canal nativo Apple retornou nulo',
      );
    }
    if (credencial.cancelado) {
      throw const ExcecaoAutenticacaoCancelada();
    }
    if (credencial.erroNativo != null) {
      throw ExcecaoAutenticacao(
        'Não foi possível entrar com a Apple. Tente novamente.',
        ehErroUsuario: false,
        causaTecnica: 'Canal nativo Apple: ${credencial.erroNativo}',
      );
    }
    return autenticarComIdToken(
      provedor: 'apple',
      idToken: credencial.idToken!,
      nonce: credencial.nonce,
      nomeSugeridoNativo: credencial.nomeExibicao,
      fotoSugeridaNativa: credencial.fotoUrl,
      nomeFallback: 'Escalador Apple',
      autorIdPublicoLocal: autorIdPublicoLocal,
      anonKey: anonKey,
    );
  }

  /// Autentica diretamente no GoTrue (`/auth/v1/token?grant_type=id_token`) utilizando
  /// um `id_token` emitido pelo modal nativo do sistema operacional.
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
        'Authorization': 'Bearer $anonKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'provider': provedor,
        'id_token': idToken,
        'nonce': ?nonce,
      }),
    );

    final mapa = _decodificarJsonSeguro(resposta.body);
    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      throw ExcecaoAutenticacao(
        extrairMensagemErroAutenticacao(
          mapa,
          'Falha ao validar credencial nativa.',
        ),
        codigoStatusHttp: resposta.statusCode,
        ehErroUsuario: false,
        causaTecnica:
            'HTTP ${resposta.statusCode} /auth/v1/token?grant_type=id_token ($provedor): ${resposta.body}',
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

    return _sincronizadorPerfil.extrairESincronizarUsuario(
      baseUrl: baseUrl,
      anonKey: anonKey,
      accessToken: accessToken,
      usuario: usuarioEnriquecido,
      autorIdPublicoLocal: autorIdPublicoLocal,
      nomeFallback: nomeFallback,
    );
  }

  Future<ResultadoProvedorAutenticacao> _processarRetornoPkceInApp({
    required Uri uriRetorno,
    required String baseUrl,
    required String anonKey,
    required String codeVerifier,
    required String autorIdPublicoLocal,
    required String nomeFallback,
  }) async {
    final params = extrairParametrosCallbackOAuth(uriRetorno);
    final codigoErro = (params['error'] ?? '').toLowerCase();
    if (codigoErro == 'access_denied' || codigoErro == 'user_cancelled') {
      throw const ExcecaoAutenticacaoCancelada();
    }

    final erroOAuth = params['error_description'] ?? params['error'];
    if (erroOAuth != null && erroOAuth.trim().isNotEmpty) {
      throw ExcecaoAutenticacao(
        traduzirMensagemServidorAutenticacao(
          erroOAuth.replaceAll('+', ' '),
          'Não foi possível concluir a autenticação.',
        ),
        ehErroUsuario: false,
        causaTecnica: 'Callback OAuth in-app com erro: $erroOAuth',
      );
    }

    final codigoPkce = params['code'];
    if (codigoPkce == null || codigoPkce.isEmpty) {
      throw const ExcecaoAutenticacao(
        'Resposta de autenticação OAuth incompleta.',
        ehErroUsuario: false,
        causaTecnica: 'Callback OAuth in-app sem parâmetro code',
      );
    }

    final resposta = await _clienteHttp.post(
      Uri.parse('$baseUrl/auth/v1/token?grant_type=pkce'),
      headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $anonKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'auth_code': codigoPkce,
        'code_verifier': codeVerifier,
      }),
    );

    final mapa = _decodificarJsonSeguro(resposta.body);
    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      throw ExcecaoAutenticacao(
        extrairMensagemErroAutenticacao(mapa, 'Falha ao validar login OAuth.'),
        codigoStatusHttp: resposta.statusCode,
        ehErroUsuario: false,
        causaTecnica:
            'HTTP ${resposta.statusCode} /auth/v1/token?grant_type=pkce: ${resposta.body}',
      );
    }

    final accessToken = mapa['access_token'] as String?;
    final usuario = (mapa['user'] as Map<String, dynamic>?) ?? mapa;
    return _sincronizadorPerfil.extrairESincronizarUsuario(
      baseUrl: baseUrl,
      anonKey: anonKey,
      accessToken: accessToken,
      usuario: usuario,
      autorIdPublicoLocal: autorIdPublicoLocal,
      nomeFallback: nomeFallback,
    );
  }

  /// Sincroniza alterações de nome e foto de perfil com o Supabase Storage (`avatars`),
  /// GoTrue (`PUT /auth/v1/user`) e PostgREST (`public.perfis`).
  Future<String?> sincronizarPerfilAtualizado({
    required String anonKey,
    required String accessToken,
    required String userId,
    required String autorIdPublico,
    required String nomeFinal,
    required String? fotoFinal,
  }) {
    return _sincronizadorPerfil.sincronizarPerfilAtualizado(
      baseUrl: _baseUrl,
      anonKey: anonKey,
      accessToken: accessToken,
      userId: userId,
      autorIdPublico: autorIdPublico,
      nomeFinal: nomeFinal,
      fotoFinal: fotoFinal,
    );
  }
}
