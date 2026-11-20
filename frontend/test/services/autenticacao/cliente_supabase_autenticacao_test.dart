// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/autenticacao/autenticador_nativo.dart';
import 'package:frontend/services/autenticacao/cliente_supabase_autenticacao.dart';
import 'package:frontend/services/autenticacao/servico_autenticacao.dart';
import 'package:frontend/services/http/cliente_http_aresta.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _FakeAutenticadorNativo implements AutenticadorNativo {
  CredencialNativaOAuth? respostaGoogle;
  CredencialNativaOAuth? respostaApple;
  Uri? ultimaUriPkceGoogle;
  String? ultimoEsquemaGoogle;

  _FakeAutenticadorNativo({this.respostaGoogle, this.respostaApple});

  @override
  Future<CredencialNativaOAuth?> solicitarCredencialGoogle({
    required String webClientId,
    Uri? uriAutorizacaoPkce,
    String esquemaCallback = 'aresta',
  }) async {
    ultimaUriPkceGoogle = uriAutorizacaoPkce;
    ultimoEsquemaGoogle = esquemaCallback;
    return respostaGoogle;
  }

  @override
  Future<CredencialNativaOAuth?> solicitarCredencialApple() async =>
      respostaApple;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClienteSupabaseAutenticacao', () {
    const urlBase = 'https://yzkhiaoqtxvvcyyuwmqg.supabase.co';
    const anonKey = 'sb_publishable_teste';
    const idPublicoLocal = 'x8siJek3FiG3aB';

    test('solicitarCodigoOtpEmail e verificarCodigoOtpEmail realizam fluxo Magic Code 6 dígitos e classificam erros HTTP', () async {
      final requisicoes = <http.Request>[];
      final clienteHttp = ClienteHttpAresta.paraTestes(
        MockClient((request) async {
          requisicoes.add(request);
          if (request.url.path.endsWith('/auth/v1/otp')) {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            if (body['email'] == 'cooldown@aresta.com') {
              return http.Response(
                jsonEncode({
                  'msg':
                      'For security purposes, you can only request this after 25 seconds.',
                }),
                429,
              );
            }
            if (body['email'] == 'desabilitado@aresta.com') {
              return http.Response(
                jsonEncode({
                  'error_code': 'otp_disabled',
                  'msg': 'Signups not allowed for otp',
                }),
                422,
              );
            }
            // Corpo vazio para validar decodificação segura em 200 OK
            return http.Response('', 200);
          }

          if (request.url.path.endsWith('/auth/v1/verify')) {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            if (body['token'] == '000000') {
              return http.Response(
                jsonEncode({
                  'error_code': 'otp_expired',
                  'msg': 'Token has expired or is invalid',
                }),
                403,
              );
            }
            if (body['token'] == '999999') {
              return http.Response('Erro interno de gateway HTML', 500);
            }
            if (body['token'] == '888888') {
              return http.Response('["erro_em_array_json"]', 500);
            }
            return http.Response(
              jsonEncode({
                'access_token': 'jwt-otp-1',
                'refresh_token': 'refresh-otp-1',
                'user': {
                  'id': 'uuid-otp-1',
                  'user_metadata': <String, dynamic>{},
                },
              }),
              200,
            );
          }

          if (request.url.path.endsWith('/rest/v1/perfis')) {
            if (request.method == 'GET') {
              return http.Response(jsonEncode([]), 200);
            }
            return http.Response(jsonEncode([{}]), 201);
          }
          return http.Response('{}', 404);
        }),
      );

      final cliente = ClienteSupabaseAutenticacao(
        clienteHttp: clienteHttp,
        obterUrlSupabase: () => '$urlBase///',
      );

      await cliente.solicitarCodigoOtpEmail(
        email: '  atleta@aresta.com  ',
        anonKey: anonKey,
      );
      final reqOtp = requisicoes.first;
      expect(reqOtp.url.toString(), equals('$urlBase/auth/v1/otp'));
      expect(reqOtp.headers['apikey'], equals(anonKey));
      expect(reqOtp.headers['Authorization'], equals('Bearer $anonKey'));
      expect(
        jsonDecode(reqOtp.body),
        equals({'email': 'atleta@aresta.com', 'create_user': true}),
      );

      // Cooldown OTP -> ehErroUsuario = true e codigoStatusHttp = 429
      await expectLater(
        () => cliente.solicitarCodigoOtpEmail(
          email: 'cooldown@aresta.com',
          anonKey: anonKey,
        ),
        throwsA(
          isA<ExcecaoAutenticacao>()
              .having((e) => e.ehErroUsuario, 'ehErroUsuario', isTrue)
              .having((e) => e.codigoStatusHttp, 'codigoStatusHttp', 429)
              .having(
                (e) => e.mensagem,
                'mensagem',
                contains('25 segundos'),
              ),
        ),
      );

      // Erro de configuração OTP -> ehErroUsuario = false e codigoStatusHttp = 422
      await expectLater(
        () => cliente.solicitarCodigoOtpEmail(
          email: 'desabilitado@aresta.com',
          anonKey: anonKey,
        ),
        throwsA(
          isA<ExcecaoAutenticacao>()
              .having((e) => e.ehErroUsuario, 'ehErroUsuario', isFalse)
              .having((e) => e.codigoStatusHttp, 'codigoStatusHttp', 422),
        ),
      );

      // Verificação de código OTP inválido -> ehErroUsuario = true
      await expectLater(
        () => cliente.verificarCodigoOtpEmail(
          email: 'atleta@aresta.com',
          codigo: '000000',
          autorIdPublicoLocal: idPublicoLocal,
          anonKey: anonKey,
        ),
        throwsA(
          isA<ExcecaoAutenticacao>()
              .having((e) => e.ehErroUsuario, 'ehErroUsuario', isTrue)
              .having(
                (e) => e.mensagem,
                'mensagem',
                'O código de acesso expirou ou é inválido.',
              ),
        ),
      );

      // Resposta não-JSON 500 -> ehErroUsuario = false e codigoStatusHttp = 500
      await expectLater(
        () => cliente.verificarCodigoOtpEmail(
          email: 'atleta@aresta.com',
          codigo: '999999',
          autorIdPublicoLocal: idPublicoLocal,
          anonKey: anonKey,
        ),
        throwsA(
          isA<ExcecaoAutenticacao>()
              .having((e) => e.ehErroUsuario, 'ehErroUsuario', isFalse)
              .having((e) => e.codigoStatusHttp, 'codigoStatusHttp', 500),
        ),
      );

      // Resposta JSON que não é objeto (lista JSON) 500 -> decodificada com segurança
      await expectLater(
        () => ClienteSupabaseAutenticacao(clienteHttp: clienteHttp)
            .verificarCodigoOtpEmail(
              email: 'atleta@aresta.com',
              codigo: '888888',
              autorIdPublicoLocal: idPublicoLocal,
              anonKey: anonKey,
            ),
        throwsA(isA<ExcecaoAutenticacao>()),
      );

      // Sucesso na verificação do código de 6 dígitos
      final resOtp = await cliente.verificarCodigoOtpEmail(
        email: 'atleta@aresta.com',
        codigo: '123456',
        autorIdPublicoLocal: idPublicoLocal,
        anonKey: anonKey,
      );
      expect(resOtp.userId, equals('uuid-otp-1'));
      expect(resOtp.accessToken, equals('jwt-otp-1'));
      expect(resOtp.refreshToken, equals('refresh-otp-1'));
      expect(resOtp.nomeExibicao, equals('atleta'));
      expect(resOtp.autorIdPublicoRemoto, equals(idPublicoLocal));
    });

    test('autenticarGoogleOAuth suporta id_token nativo (Android) e callbackUri PKCE in-app (iOS) sem navegador externo', () async {
      final clienteHttp = ClienteHttpAresta.paraTestes(
        MockClient((request) async {
          if (request.url.path.endsWith('/auth/v1/token') &&
              request.url.queryParameters['grant_type'] == 'id_token') {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            if (body['id_token'] == 'token-invalido') {
              return http.Response(
                jsonEncode({'message': 'Unacceptable audience in id_token'}),
                400,
              );
            }
            return http.Response(
              jsonEncode({
                'access_token': 'jwt-google-android',
                'user': {
                  'id': 'uuid-google-android',
                  'user_metadata': <String, dynamic>{},
                },
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/auth/v1/token') &&
              request.url.queryParameters['grant_type'] == 'pkce') {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            if (body['auth_code'] == 'codigo-expirado') {
              return http.Response(
                jsonEncode({'error_description': 'Código PKCE expirado.'}),
                400,
              );
            }
            return http.Response(
              jsonEncode({
                'access_token': 'jwt-google-ios-pkce',
                'user': {
                  'id': 'uuid-google-ios',
                  'user_metadata': {
                    'full_name': 'Atleta iOS PKCE',
                    'avatar_url': 'https://lh3.googleusercontent.com/a/ios.jpg',
                  },
                },
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/rest/v1/perfis')) {
            return http.Response(jsonEncode([]), 200);
          }
          return http.Response('{}', 200);
        }),
      );

      final fakeNativo = _FakeAutenticadorNativo(
        respostaGoogle: const CredencialNativaOAuth(
          idToken: 'id-token-google-valido',
          nomeExibicao: 'Eduardo Android',
          fotoUrl: 'https://lh3.googleusercontent.com/a/android.jpg',
        ),
      );
      final cliente = ClienteSupabaseAutenticacao(
        clienteHttp: clienteHttp,
        obterUrlSupabase: () => urlBase,
        autenticadorNativo: fakeNativo,
      );

      // 1. Android: id_token via CredentialManager
      final resAndroid = await cliente.autenticarGoogleOAuth(
        autorIdPublicoLocal: idPublicoLocal,
        anonKey: anonKey,
      );
      expect(resAndroid.userId, equals('uuid-google-android'));
      expect(resAndroid.nomeExibicao, equals('Eduardo Android'));
      expect(
        resAndroid.fotoUrl,
        equals('https://lh3.googleusercontent.com/a/android.jpg'),
      );
      expect(
        fakeNativo.ultimaUriPkceGoogle?.queryParameters['provider'],
        equals('google'),
      );
      expect(fakeNativo.ultimoEsquemaGoogle, equals('aresta'));

      // 2. iOS: callbackUri via ASWebAuthenticationSession + PKCE
      fakeNativo.respostaGoogle = CredencialNativaOAuth(
        callbackUri: Uri.parse(
          'aresta://app.arestaclimb.com/auth-callback?code=codigo-ios-ok',
        ),
      );
      final resIos = await cliente.autenticarGoogleOAuth(
        autorIdPublicoLocal: idPublicoLocal,
        anonKey: anonKey,
      );
      expect(resIos.userId, equals('uuid-google-ios'));
      expect(resIos.nomeExibicao, equals('Atleta iOS PKCE'));
      expect(resIos.accessToken, equals('jwt-google-ios-pkce'));

      // 3. Cancelamento voluntário (cancelado: true ou access_denied no callback) -> ExcecaoAutenticacaoCancelada
      fakeNativo.respostaGoogle = const CredencialNativaOAuth(cancelado: true);
      await expectLater(
        () => cliente.autenticarGoogleOAuth(
          autorIdPublicoLocal: idPublicoLocal,
          anonKey: anonKey,
        ),
        throwsA(isA<ExcecaoAutenticacaoCancelada>()),
      );

      fakeNativo.respostaGoogle = CredencialNativaOAuth(
        callbackUri: Uri.parse(
          'aresta://app.arestaclimb.com/auth-callback?error=access_denied',
        ),
      );
      await expectLater(
        () => cliente.autenticarGoogleOAuth(
          autorIdPublicoLocal: idPublicoLocal,
          anonKey: anonKey,
        ),
        throwsA(isA<ExcecaoAutenticacaoCancelada>()),
      );

      // 4. Erros operacionais: canal nulo, erroNativo, callback com erro, callback vazio, erro PKCE e erro id_token
      for (final credencialFalha in <CredencialNativaOAuth?>[
        null,
        const CredencialNativaOAuth(erroNativo: 'Play Services indisponível'),
        CredencialNativaOAuth(
          callbackUri: Uri.parse(
            'aresta://app.arestaclimb.com/auth-callback?error_description=Server+error',
          ),
        ),
        CredencialNativaOAuth(
          callbackUri: Uri.parse('aresta://app.arestaclimb.com/auth-callback'),
        ),
        CredencialNativaOAuth(
          callbackUri: Uri.parse(
            'aresta://app.arestaclimb.com/auth-callback?code=codigo-expirado',
          ),
        ),
        const CredencialNativaOAuth(idToken: 'token-invalido'),
      ]) {
        fakeNativo.respostaGoogle = credencialFalha;
        await expectLater(
          () => cliente.autenticarGoogleOAuth(
            autorIdPublicoLocal: idPublicoLocal,
            anonKey: anonKey,
          ),
          throwsA(
            isA<ExcecaoAutenticacao>().having(
              (e) => e.ehErroUsuario,
              'ehErroUsuario',
              isFalse,
            ),
          ),
        );
      }
    });

    test('autenticarAppleOAuth valida id_token nativo + nonce, trata cancelamento silencioso e falha rápido sem navegador', () async {
      final clienteHttp = ClienteHttpAresta.paraTestes(
        MockClient((request) async {
          if (request.url.path.endsWith('/auth/v1/token') &&
              request.url.queryParameters['grant_type'] == 'id_token') {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            if (body['id_token'] == 'apple-provider-disabled') {
              return http.Response(
                jsonEncode({
                  'code': 400,
                  'error_code': 'provider_disabled',
                  'msg':
                      'Provider (issuer "https://appleid.apple.com") is not enabled',
                }),
                400,
              );
            }
            return http.Response(
              jsonEncode({
                'access_token': 'jwt-supabase-apple',
                'user': {
                  'id': 'uuid-apple-nativo',
                  'user_metadata': <String, dynamic>{},
                },
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/rest/v1/perfis')) {
            return http.Response(jsonEncode([]), 200);
          }
          return http.Response('{}', 200);
        }),
      );

      final fakeNativo = _FakeAutenticadorNativo(
        respostaApple: const CredencialNativaOAuth(
          idToken: 'id-token-apple-valido',
          nonce: 'nonce-apple-123',
          nomeExibicao: 'Escalador Apple',
        ),
      );
      final cliente = ClienteSupabaseAutenticacao(
        clienteHttp: clienteHttp,
        obterUrlSupabase: () => urlBase,
        autenticadorNativo: fakeNativo,
      );

      final resApple = await cliente.autenticarAppleOAuth(
        autorIdPublicoLocal: idPublicoLocal,
        anonKey: anonKey,
      );
      expect(resApple.userId, equals('uuid-apple-nativo'));
      expect(resApple.nomeExibicao, equals('Escalador Apple'));

      // Cancelamento voluntário no Face ID
      fakeNativo.respostaApple = const CredencialNativaOAuth(cancelado: true);
      await expectLater(
        () => cliente.autenticarAppleOAuth(
          autorIdPublicoLocal: idPublicoLocal,
          anonKey: anonKey,
        ),
        throwsA(isA<ExcecaoAutenticacaoCancelada>()),
      );

      // Canal nulo, erroNativo e provider_disabled 400 -> ExcecaoAutenticacao(ehErroUsuario: false)
      for (final credencialFalha in <CredencialNativaOAuth?>[
        null,
        const CredencialNativaOAuth(erroNativo: 'AuthorizationError 1000'),
        const CredencialNativaOAuth(idToken: 'apple-provider-disabled'),
      ]) {
        fakeNativo.respostaApple = credencialFalha;
        await expectLater(
          () => cliente.autenticarAppleOAuth(
            autorIdPublicoLocal: idPublicoLocal,
            anonKey: anonKey,
          ),
          throwsA(
            isA<ExcecaoAutenticacao>().having(
              (e) => e.ehErroUsuario,
              'ehErroUsuario',
              isFalse,
            ),
          ),
        );
      }
    });

    test('sincronizarPerfilAtualizado delega ao SincronizadorPerfilSupabase e construtor padrão inicializa dependências', () async {
      final padrao = ClienteSupabaseAutenticacao();
      expect(padrao, isNotNull);

      final clienteHttp = ClienteHttpAresta.paraTestes(
        MockClient((request) async => http.Response('{}', 200)),
      );
      final cliente = ClienteSupabaseAutenticacao(
        clienteHttp: clienteHttp,
        obterUrlSupabase: () => urlBase,
      );
      final dataUri = 'data:image/webp;base64,${base64Encode([1, 2, 3])}';
      final urlStorage = await cliente.sincronizarPerfilAtualizado(
        anonKey: anonKey,
        accessToken: 'jwt-1',
        userId: 'usr-1',
        autorIdPublico: idPublicoLocal,
        nomeFinal: 'Atleta',
        fotoFinal: dataUri,
      );
      expect(
        urlStorage,
        startsWith('$urlBase/storage/v1/object/public/avatars/usr-1/avatar.webp'),
      );
    });

    test('renovarSessaoComRefreshToken e garantirLinhaPerfisSincronizada renovam JWT e reconciliam public.perfis', () async {
      final clienteHttp = ClienteHttpAresta.paraTestes(
        MockClient((request) async {
          if (request.url.path.endsWith('/auth/v1/token') &&
              request.url.queryParameters['grant_type'] == 'refresh_token') {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            if (body['refresh_token'] == 'refresh-invalido') {
              return http.Response(
                jsonEncode({
                  'error_code': 'refresh_token_not_found',
                  'msg': 'Invalid Refresh Token',
                }),
                400,
              );
            }
            return http.Response(
              jsonEncode({
                'access_token': 'jwt-renovado-99',
                if (body['refresh_token'] == 'refresh-rotacionado')
                  'refresh_token': 'refresh-novo-99',
                'user': {
                  'id': 'uuid-usr-99',
                  'user_metadata': <String, dynamic>{},
                },
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/rest/v1/perfis')) {
            if (request.method == 'GET') {
              return http.Response(
                jsonEncode([
                  {
                    'autor_id_publico': 'z9Yx8Wv7Ut6Sr5',
                    'autor_nome_publico': 'Atleta Reconciliado',
                    'avatar_url': null,
                  },
                ]),
                200,
              );
            }
            return http.Response('[]', 201);
          }
          return http.Response('{}', 404);
        }),
      );

      final cliente = ClienteSupabaseAutenticacao(
        clienteHttp: clienteHttp,
        obterUrlSupabase: () => urlBase,
      );

      final renovadoRotacionado = await cliente.renovarSessaoComRefreshToken(
        refreshToken: '  refresh-rotacionado  ',
        autorIdPublicoLocal: idPublicoLocal,
        nomeFallback: 'Fallback',
        anonKey: anonKey,
      );
      expect(renovadoRotacionado.accessToken, 'jwt-renovado-99');
      expect(renovadoRotacionado.refreshToken, 'refresh-novo-99');
      expect(renovadoRotacionado.autorIdPublicoRemoto, 'z9Yx8Wv7Ut6Sr5');

      final renovadoMantido = await cliente.renovarSessaoComRefreshToken(
        refreshToken: 'refresh-sem-rotacao',
        autorIdPublicoLocal: idPublicoLocal,
        nomeFallback: 'Fallback',
        anonKey: anonKey,
      );
      expect(renovadoMantido.refreshToken, 'refresh-sem-rotacao');

      await expectLater(
        () => cliente.renovarSessaoComRefreshToken(
          refreshToken: 'refresh-invalido',
          autorIdPublicoLocal: idPublicoLocal,
          nomeFallback: 'Fallback',
          anonKey: anonKey,
        ),
        throwsA(
          isA<ExcecaoAutenticacao>()
              .having((e) => e.codigoStatusHttp, 'codigoStatusHttp', 400)
              .having((e) => e.ehErroUsuario, 'ehErroUsuario', isFalse),
        ),
      );

      final linha = await cliente.garantirLinhaPerfisSincronizada(
        anonKey: anonKey,
        accessToken: 'jwt-renovado-99',
        userId: 'uuid-usr-99',
        autorIdPublico: idPublicoLocal,
        nomePublico: 'Local',
        fotoUrl: null,
      );
      expect(linha.autorIdPublico, 'z9Yx8Wv7Ut6Sr5');
      expect(linha.nomePublico, 'Atleta Reconciliado');
    });
  });
}
