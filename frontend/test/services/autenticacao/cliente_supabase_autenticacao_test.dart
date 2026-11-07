// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/autenticacao/cliente_supabase_autenticacao.dart';
import 'package:frontend/services/autenticacao/servico_autenticacao.dart';
import 'package:frontend/services/http/cliente_http_aresta.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class _FakeUrlLauncherOAuth extends UrlLauncherPlatform {
  final void Function(String url) aoAbrir;
  _FakeUrlLauncherOAuth(this.aoAbrir);

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    aoAbrir(url);
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClienteSupabaseAutenticacao', () {
    const urlBase = 'https://yzkhiaoqtxvvcyyuwmqg.supabase.co';
    const anonKey = 'anon-key-teste';
    const idPublicoLocal = 'x8siJek3FiG3aB';

    test('autenticarEmailSenha e criarConta sincronizam metadados com Supabase Auth e public.perfis', () async {
      final requisicoes = <http.Request>[];
      final clienteHttp = ClienteHttpAresta.paraTestes(
        MockClient((request) async {
          requisicoes.add(request);
          if (request.url.path.endsWith('/auth/v1/token') &&
              request.url.queryParameters['grant_type'] == 'password') {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            if (body['password'] == 'errada') {
              return http.Response(
                jsonEncode({'error_description': 'Senha inválida.'}),
                400,
              );
            }
            if (body['email'] == 'novo@gmail.com') {
              return http.Response(
                jsonEncode({
                  'access_token': 'jwt-novo',
                  'user': {'id': 'uuid-novo'},
                }),
                200,
              );
            }
            return http.Response(
              jsonEncode({
                'access_token': 'jwt-1',
                'user': {
                  'id': 'uuid-1',
                  'user_metadata': {
                    'autor_id_publico': 'm9siJek3FiG3aZ',
                    'autor_nome_publico': 'Nome Meta',
                  },
                },
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/auth/v1/signup')) {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            if (body['email'] == 'erro@gmail.com') {
              return http.Response(jsonEncode({}), 500);
            }
            return http.Response(
              jsonEncode({
                'access_token': 'jwt-signup',
                'user': {
                  'id': 'uuid-signup',
                  'user_metadata': body['data'],
                },
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/rest/v1/perfis')) {
            if (request.method == 'GET') {
              if (request.url.queryParameters['user_id'] == 'eq.uuid-1') {
                return http.Response(
                  jsonEncode([
                    {
                      'autor_id_publico': 'r9siJek3FiG3aZ',
                      'autor_nome_publico': 'Nome Perfis',
                      'avatar_url': 'https://supabase.co/f1.jpg',
                    },
                  ]),
                  200,
                );
              }
              return http.Response(jsonEncode([]), 200);
            }
            return http.Response(jsonEncode([{}]), 201);
          }
          return http.Response('{}', 404);
        }),
      );

      final cliente = ClienteSupabaseAutenticacao(
        clienteHttp: clienteHttp,
        obterUrlSupabase: () => urlBase,
      );

      await expectLater(
        () => cliente.autenticarEmailSenha(
          email: 'a@b.com',
          senha: 'errada',
          autorIdPublicoLocal: idPublicoLocal,
          anonKey: anonKey,
        ),
        throwsA(
          isA<ExcecaoAutenticacao>().having(
            (e) => e.mensagem,
            'mensagem',
            'Senha inválida.',
          ),
        ),
      );

      final resExistente = await cliente.autenticarEmailSenha(
        email: 'a@b.com',
        senha: 'correta',
        autorIdPublicoLocal: idPublicoLocal,
        anonKey: anonKey,
      );
      expect(resExistente.userId, equals('uuid-1'));
      expect(resExistente.autorIdPublicoRemoto, equals('r9siJek3FiG3aZ'));
      expect(resExistente.nomeExibicao, equals('Nome Perfis'));
      expect(resExistente.fotoUrl, equals('https://supabase.co/f1.jpg'));
      expect(resExistente.accessToken, equals('jwt-1'));

      final resNovo = await cliente.autenticarEmailSenha(
        email: 'novo@gmail.com',
        senha: 'correta',
        autorIdPublicoLocal: idPublicoLocal,
        anonKey: anonKey,
      );
      expect(resNovo.userId, equals('uuid-novo'));
      expect(resNovo.nomeExibicao, equals('novo'));

      final resSignup = await cliente.criarConta(
        nome: 'Escaladora',
        email: 'nova@gmail.com',
        senha: 'correta',
        autorIdPublico: idPublicoLocal,
        fotoUrlAtual: 'https://supabase.co/f0.jpg',
        anonKey: anonKey,
      );
      expect(resSignup.userId, equals('uuid-signup'));
      expect(resSignup.nomeExibicao, equals('Escaladora'));
      expect(resSignup.accessToken, equals('jwt-signup'));

      await expectLater(
        () => cliente.criarConta(
          nome: 'Escaladora',
          email: 'erro@gmail.com',
          senha: 'correta',
          autorIdPublico: idPublicoLocal,
          fotoUrlAtual: null,
          anonKey: anonKey,
        ),
        throwsA(
          isA<ExcecaoAutenticacao>().having(
            (e) => e.mensagem,
            'mensagem',
            'Não foi possível criar a conta.',
          ),
        ),
      );
    });

    test('autenticarGoogleOAuth suporta fluxos PKCE e Implicit e trata falhas e timeout', () async {
      final controladorLinks = StreamController<Uri>.broadcast();
      addTearDown(controladorLinks.close);

      final clienteHttp = ClienteHttpAresta.paraTestes(
        MockClient((request) async {
          if (request.url.path.endsWith('/auth/v1/token') &&
              request.url.queryParameters['grant_type'] == 'pkce') {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            if (body['auth_code'] == 'invalido') {
              return http.Response(
                jsonEncode({'error_description': 'Código PKCE expirado.'}),
                400,
              );
            }
            return http.Response(
              jsonEncode({
                'access_token': 'jwt-pkce',
                'user': {
                  'id': 'uuid-pkce',
                  'user_metadata': {
                    'full_name': 'Atleta PKCE',
                    'avatar_url': 'https://lh3.googleusercontent.com/a/pkce.jpg',
                  },
                },
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/auth/v1/user') &&
              request.method == 'GET') {
            if (request.headers['Authorization'] == 'Bearer tok-erro') {
              return http.Response(jsonEncode({'msg': 'Token inválido.'}), 401);
            }
            return http.Response(
              jsonEncode({
                'id': 'uuid-imp',
                'user_metadata': {
                  'name': 'Atleta Implicit',
                  'picture': 'https://lh3.googleusercontent.com/a/imp.jpg',
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

      // 1. Sucesso PKCE via stream de links
      final clientePkce = ClienteSupabaseAutenticacao(
        clienteHttp: clienteHttp,
        obterUrlSupabase: () => urlBase,
        fluxoLinksOAuth: controladorLinks.stream,
        lancadorUrlOAuth: (_) async {
          Future<void>.microtask(() {
            controladorLinks.add(
              Uri.parse('aresta://app.arestaclimb.com/auth-callback?code=ok'),
            );
          });
          return true;
        },
      );
      final resPkce = await clientePkce.autenticarGoogleOAuth(
        autorIdPublicoLocal: idPublicoLocal,
        anonKey: anonKey,
      );
      expect(resPkce.userId, equals('uuid-pkce'));
      expect(resPkce.nomeExibicao, equals('Atleta PKCE'));
      expect(resPkce.fotoUrl, equals('https://lh3.googleusercontent.com/a/pkce.jpg'));

      // 1b. Sucesso PKCE com Apple OAuth (provider=apple)
      Uri? uriAutorizacaoApple;
      final clienteApple = ClienteSupabaseAutenticacao(
        clienteHttp: clienteHttp,
        obterUrlSupabase: () => urlBase,
        fluxoLinksOAuth: controladorLinks.stream,
        lancadorUrlOAuth: (uri) async {
          uriAutorizacaoApple = uri;
          Future<void>.microtask(() {
            controladorLinks.add(
              Uri.parse('aresta://app.arestaclimb.com/auth-callback?code=ok'),
            );
          });
          return true;
        },
      );
      final resApple = await clienteApple.autenticarAppleOAuth(
        autorIdPublicoLocal: idPublicoLocal,
        anonKey: anonKey,
      );
      expect(uriAutorizacaoApple?.queryParameters['provider'], equals('apple'));
      expect(resApple.userId, equals('uuid-pkce'));
      expect(resApple.nomeExibicao, equals('Atleta PKCE'));

      // 2. Sucesso Implicit via lancadorUrlOAuth padrão e processarCallbackOAuth
      late ClienteSupabaseAutenticacao clienteImp;
      UrlLauncherPlatform.instance = _FakeUrlLauncherOAuth((_) {
        Future<void>.microtask(() {
          clienteImp.processarCallbackOAuth(
            Uri.parse(
              'aresta://app.arestaclimb.com/auth-callback#access_token=jwt-imp',
            ),
          );
        });
      });
      clienteImp = ClienteSupabaseAutenticacao(
        clienteHttp: clienteHttp,
        obterUrlSupabase: () => urlBase,
        fluxoLinksOAuth: const Stream<Uri>.empty(),
      );
      final resImp = await clienteImp.autenticarGoogleOAuth(
        autorIdPublicoLocal: idPublicoLocal,
        anonKey: anonKey,
      );
      expect(resImp.userId, equals('uuid-imp'));
      expect(resImp.nomeExibicao, equals('Atleta Implicit'));
      expect(
        clienteImp.processarCallbackOAuth(Uri.parse('https://aresta.cc/abc')),
        isFalse,
      );

      // 3. Erros de navegador, retorno OAuth com erro, retorno vazio, falha PKCE, falha /user e timeout
      final clienteFalhaNav = ClienteSupabaseAutenticacao(
        clienteHttp: clienteHttp,
        fluxoLinksOAuth: const Stream<Uri>.empty(),
        lancadorUrlOAuth: (_) async => false,
      );
      await expectLater(
        () => clienteFalhaNav.autenticarGoogleOAuth(
          autorIdPublicoLocal: idPublicoLocal,
          anonKey: anonKey,
        ),
        throwsA(isA<ExcecaoAutenticacao>()),
      );

      for (final uriErro in [
        'aresta://app.arestaclimb.com/auth-callback?error_description=Cancelado',
        'aresta://app.arestaclimb.com/auth-callback',
        'aresta://app.arestaclimb.com/auth-callback?code=invalido',
        'aresta://app.arestaclimb.com/auth-callback#access_token=tok-erro',
      ]) {
        late ClienteSupabaseAutenticacao c;
        c = ClienteSupabaseAutenticacao(
          clienteHttp: clienteHttp,
          fluxoLinksOAuth: const Stream<Uri>.empty(),
          lancadorUrlOAuth: (_) async {
            Future<void>.microtask(() {
              c.processarCallbackOAuth(Uri.parse(uriErro));
            });
            return true;
          },
        );
        await expectLater(
          () => c.autenticarGoogleOAuth(
            autorIdPublicoLocal: idPublicoLocal,
            anonKey: anonKey,
          ),
          throwsA(isA<ExcecaoAutenticacao>()),
        );
      }

      final clienteTimeout = ClienteSupabaseAutenticacao(
        clienteHttp: clienteHttp,
        fluxoLinksOAuth: const Stream<Uri>.empty(),
        lancadorUrlOAuth: (_) async => true,
        timeoutOAuth: const Duration(milliseconds: 15),
      );
      await expectLater(
        () => clienteTimeout.autenticarGoogleOAuth(
          autorIdPublicoLocal: idPublicoLocal,
          anonKey: anonKey,
        ),
        throwsA(isA<ExcecaoAutenticacao>()),
      );
    });

    test('sincronizarPerfilAtualizado envia avatar ao Storage (quando disponível) e atualiza Auth e public.perfis', () async {
      var storageOk = true;
      final clienteHttp = ClienteHttpAresta.paraTestes(
        MockClient((request) async {
          if (request.url.path.contains('/storage/v1/object/avatars/')) {
            return storageOk
                ? http.Response('{}', 200)
                : http.Response('{}', 404);
          }
          return http.Response('{}', 200);
        }),
      );

      final cliente = ClienteSupabaseAutenticacao(
        clienteHttp: clienteHttp,
        obterUrlSupabase: () => urlBase,
      );

      final dataUri = 'data:image/jpeg;base64,${base64Encode([1, 2, 3])}';
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
        startsWith('$urlBase/storage/v1/object/public/avatars/usr-1/avatar.jpg'),
      );

      storageOk = false;
      final urlFallback = await cliente.sincronizarPerfilAtualizado(
        anonKey: anonKey,
        accessToken: 'jwt-1',
        userId: 'usr-1',
        autorIdPublico: idPublicoLocal,
        nomeFinal: 'Atleta',
        fotoFinal: dataUri,
      );
      expect(urlFallback, equals(dataUri));
    });
  });
}

