// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/autenticacao/autenticador_nativo.dart';
import 'package:frontend/services/autenticacao/cliente_supabase_autenticacao.dart';
import 'package:frontend/services/autenticacao/servico_autenticacao.dart';
import 'package:frontend/services/caderneta/repositorio_caderneta.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import 'package:frontend/services/http/cliente_http_aresta.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAutenticadorNativo implements AutenticadorNativo {
  CredencialNativaOAuth? google;
  CredencialNativaOAuth? apple;

  _FakeAutenticadorNativo({this.google, this.apple});

  @override
  Future<CredencialNativaOAuth?> solicitarCredencialGoogle({
    required String webClientId,
    Uri? uriAutorizacaoPkce,
    String esquemaCallback = 'aresta',
  }) async => google;

  @override
  Future<CredencialNativaOAuth?> solicitarCredencialApple() async => apple;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RepositorioCadernetaLocal repositorio;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repositorio = RepositorioCadernetaLocal(preferencias: prefs);
    await repositorio.inicializar();
    RepositorioCadernetaLocal.instancia = repositorio;
    ServicoAutenticacaoLocal.redefinirParaTestes();
  });

  tearDown(() {
    ServicoAutenticacaoLocal.redefinirParaTestes();
  });

  group('ServicoAutenticacaoLocal', () {
    test('expõe instância singleton configurável, ExcecaoAutenticacao implementa ExcecaoComStatusHttp e ExcecaoAutenticacaoCancelada formata texto', () async {
      final servico = ServicoAutenticacaoLocal.instancia;
      expect(servico.estaAutenticado, isFalse);
      expect(servico.obterPerfil().estaAutenticado, isFalse);
      expect(servico.perfilListenable.value.estaAutenticado, isFalse);
      await servico.atualizarPerfilRemoto();
      await servico.encerrarSessao();

      const erroComCausa = ExcecaoAutenticacao(
        'Mensagem amigável',
        codigoStatusHttp: 400,
        ehErroUsuario: false,
        causaTecnica: 'HTTP 400 provider_disabled',
      );
      expect(erroComCausa, isA<ExcecaoComStatusHttp>());
      expect(erroComCausa.codigoStatusHttp, equals(400));
      expect(erroComCausa.toString(), contains('HTTP 400 provider_disabled'));
      expect(AppLogger.isFalhaConexaoOuTimeout(erroComCausa), isFalse);

      const erroSemCausa = ExcecaoAutenticacao('Informe e-mail válido.');
      expect(erroSemCausa.toString(), equals('ExcecaoAutenticacao: Informe e-mail válido.'));

      const cancelada = ExcecaoAutenticacaoCancelada();
      expect(cancelada.toString(), contains('ExcecaoAutenticacaoCancelada'));

      final custom = ServicoAutenticacaoLocal(repositorio: repositorio);
      ServicoAutenticacaoLocal.instancia = custom;
      expect(identical(ServicoAutenticacaoLocal.instancia, custom), isTrue);

      ServicoAutenticacaoLocal.redefinirParaTestes();
      expect(identical(ServicoAutenticacaoLocal.instancia, custom), isFalse);
    });

    test('falha explicitamente (Fail-Fast, sem criar conta fictícia usr_*) quando anonKey está vazia', () async {
      final servicoSemChave = ServicoAutenticacaoLocal(
        repositorio: repositorio,
        obterAnonKeySupabase: () => '   ',
      );

      for (final acao in <Future<Object?> Function()>[
        () => servicoSemChave.solicitarCodigoOtpEmail(email: 'ana@aresta.com'),
        () => servicoSemChave.verificarCodigoOtpEmail(
              email: 'ana@aresta.com',
              codigo: '123456',
            ),
        servicoSemChave.entrarComGoogle,
        servicoSemChave.entrarComApple,
      ]) {
        await expectLater(
          acao,
          throwsA(
            isA<ExcecaoAutenticacao>()
                .having((e) => e.ehErroUsuario, 'ehErroUsuario', isFalse)
                .having((e) => e.causaTecnica, 'causaTecnica', isNotNull),
          ),
        );
      }
      expect(servicoSemChave.estaAutenticado, isFalse);
      expect(repositorio.obterPerfil().userId, isNull);
    });

    test('valida formato de e-mail e código numérico de 6 dígitos marcando ehErroUsuario = true', () async {
      final servico = ServicoAutenticacaoLocal(
        repositorio: repositorio,
        obterAnonKeySupabase: () => 'sb_publishable_teste',
      );

      for (final emailInvalido in ['', 'invalido', '@dominio.com', 'a@.com', 'a@b.', 'a@b']) {
        await expectLater(
          () => servico.solicitarCodigoOtpEmail(email: emailInvalido),
          throwsA(
            isA<ExcecaoAutenticacao>()
                .having((e) => e.ehErroUsuario, 'ehErroUsuario', isTrue)
                .having(
                  (e) => e.mensagem,
                  'mensagem',
                  'Informe um endereço de e-mail válido.',
                ),
          ),
        );
      }

      for (final codigoInvalido in ['', '12345', '1234567', '12a456']) {
        await expectLater(
          () => servico.verificarCodigoOtpEmail(
            email: 'ana@aresta.com',
            codigo: codigoInvalido,
          ),
          throwsA(
            isA<ExcecaoAutenticacao>()
                .having((e) => e.ehErroUsuario, 'ehErroUsuario', isTrue)
                .having(
                  (e) => e.mensagem,
                  'mensagem',
                  'Informe o código numérico de 6 dígitos enviado por e-mail.',
                ),
          ),
        );
      }
      expect(servico.estaAutenticado, isFalse);
    });

    test('fluxo OTP de 6 dígitos, Google e Apple preservam NanoID local, adotam nome remoto ou mantêm apelido personalizado e encerram sessão', () async {
      final requisicoes = <http.Request>[];
      final clienteFake = ClienteHttpAresta.paraTestes(
        MockClient((request) async {
          requisicoes.add(request);
          if (request.url.path.endsWith('/auth/v1/otp')) {
            return http.Response('{}', 200);
          }
          if (request.url.path.endsWith('/auth/v1/verify')) {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            if (body['email'] == 'vazio@aresta.com') {
              return http.Response(
                jsonEncode({
                  'access_token': 'jwt-otp-vazio',
                  'user': {
                    'id': 'uuid-otp-vazio',
                    'user_metadata': {'autor_nome_publico': '   '},
                  },
                }),
                200,
              );
            }
            return http.Response(
              jsonEncode({
                'access_token': 'jwt-otp-ok',
                'user': {
                  'id': 'uuid-otp-ok',
                  'user_metadata': <String, dynamic>{},
                },
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/auth/v1/token') &&
              request.url.queryParameters['grant_type'] == 'id_token') {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            if (body['provider'] == 'apple') {
              return http.Response(
                jsonEncode({
                  'access_token': 'jwt-apple-ok',
                  'user': {
                    'id': 'uuid-apple-ok',
                    'user_metadata': <String, dynamic>{},
                  },
                }),
                200,
              );
            }
            return http.Response(
              jsonEncode({
                'access_token': 'jwt-google-ok',
                'user': {
                  'id': 'uuid-google-ok',
                  'user_metadata': {
                    'full_name': 'Marina Google',
                    'avatar_url': 'https://lh3.googleusercontent.com/a/marina.jpg',
                  },
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
          return http.Response('{}', 200);
        }),
      );

      final fakeNativo = _FakeAutenticadorNativo(
        google: const CredencialNativaOAuth(idToken: 'tok-google'),
        apple: const CredencialNativaOAuth(
          idToken: 'tok-apple',
          nonce: 'nonce-1',
        ),
      );
      final clienteSupabase = ClienteSupabaseAutenticacao(
        clienteHttp: clienteFake,
        obterUrlSupabase: () => 'https://yzkhiaoqtxvvcyyuwmqg.supabase.co',
        autenticadorNativo: fakeNativo,
      );
      final servico = ServicoAutenticacaoLocal(
        repositorio: repositorio,
        clienteSupabase: clienteSupabase,
        obterAnonKeySupabase: () => 'sb_publishable_teste',
      );

      final idPublicoOriginal = repositorio.obterPerfil().autorIdPublico;

      // 1. OTP com perfil usando apelido padrão -> adota prefixo do e-mail
      await servico.solicitarCodigoOtpEmail(email: '  lucas.rocha@aresta.com ');
      final perfilOtp = await servico.verificarCodigoOtpEmail(
        email: '  lucas.rocha@aresta.com ',
        codigo: ' 123 456 ',
      );
      expect(servico.estaAutenticado, isTrue);
      expect(perfilOtp.userId, equals('uuid-otp-ok'));
      expect(perfilOtp.autorIdPublico, equals(idPublicoOriginal));
      expect(perfilOtp.autorNomePublico, equals('lucas.rocha'));
      expect(perfilOtp.accessToken, equals('jwt-otp-ok'));

      // 2. Se o escalador já personalizou o apelido local e o provedor Apple só tem fallback genérico, preserva o apelido personalizado
      await repositorio.salvarPerfil(
        perfilOtp.copyWith(
          autorNomePublico: 'Lucas Montanha',
          limparUserId: true,
        ),
      );
      final perfilApple = await servico.entrarComApple();
      expect(perfilApple.userId, equals('uuid-apple-ok'));
      expect(perfilApple.autorNomePublico, equals('Lucas Montanha'));

      // 3. Google trazendo nome real do provedor atualiza quando solicitado
      await servico.encerrarSessao();
      expect(servico.estaAutenticado, isFalse);
      expect(repositorio.obterPerfil().userId, isNull);

      await repositorio.salvarPerfil(
        repositorio.obterPerfil().copyWith(autorNomePublico: 'Escalador Aresta'),
      );
      final perfilGoogle = await servico.entrarComGoogle();
      expect(perfilGoogle.userId, equals('uuid-google-ok'));
      expect(perfilGoogle.autorNomePublico, equals('Marina Google'));
      // Nome em branco nos metadados remotos preserva o nome atual do perfil local
      final perfilNomeBranco = await servico.verificarCodigoOtpEmail(
        email: 'vazio@aresta.com',
        codigo: '123456',
      );
      expect(perfilNomeBranco.autorNomePublico, equals('Marina Google'));
    });

    test('atualizarPerfilRemoto persiste nome e foto localmente e sincroniza com Supabase Storage, Auth e public.perfis', () async {
      final requisicoes = <http.Request>[];
      final clienteFake = ClienteHttpAresta.paraTestes(
        MockClient((request) async {
          requisicoes.add(request);
          if (request.url.path.contains('/storage/v1/object/avatars/')) {
            return http.Response('{"Key":"avatars/usr-1/avatar.webp"}', 200);
          }
          return http.Response('{}', 200);
        }),
      );

      await repositorio.salvarPerfil(
        repositorio.obterPerfil().copyWith(
          userId: 'usr-1',
          autorNomePublico: 'Nome Antigo',
          accessToken: 'jwt-ativo-1',
        ),
      );

      final servico = ServicoAutenticacaoLocal(
        repositorio: repositorio,
        clienteHttp: clienteFake,
        obterUrlSupabase: () => 'https://yzkhiaoqtxvvcyyuwmqg.supabase.co',
        obterAnonKeySupabase: () => 'anon-key-1',
      );

      final dataUri = 'data:image/webp;base64,${base64Encode([1, 2, 3])}';
      final atualizado = await servico.atualizarPerfilRemoto(
        novoNome: 'Novo Nome Supabase',
        novaFotoUrl: dataUri,
      );
      expect(atualizado.autorNomePublico, equals('Novo Nome Supabase'));
      expect(
        atualizado.fotoUrl,
        startsWith(
          'https://yzkhiaoqtxvvcyyuwmqg.supabase.co/storage/v1/object/public/avatars/usr-1/avatar.webp',
        ),
      );
      expect(
        requisicoes.any((r) => r.url.path.endsWith('/auth/v1/user') && r.method == 'PUT'),
        isTrue,
      );

      final apenasNome = await servico.atualizarPerfilRemoto(
        novoNome: 'Apenas Nome',
      );
      expect(apenasNome.autorNomePublico, equals('Apenas Nome'));
    });

    test('garantirSessaoEPerfilSincronizados renova JWT expirado via refreshToken e reconcilia public.perfis', () async {
      var chamadasRefresh = 0;
      var chamadasPerfis = 0;
      final clienteFake = ClienteHttpAresta.paraTestes(
        MockClient((request) async {
          if (request.url.path.endsWith('/auth/v1/token') &&
              request.url.queryParameters['grant_type'] == 'refresh_token') {
            chamadasRefresh++;
            return http.Response(
              jsonEncode({
                'access_token': 'jwt-renovado-$chamadasRefresh',
                'refresh_token': 'refresh-renovado-$chamadasRefresh',
                'user': {
                  'id': 'usr-reconciliado',
                  'user_metadata': <String, dynamic>{},
                },
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/rest/v1/perfis')) {
            chamadasPerfis++;
            if (request.method == 'GET') {
              return http.Response(
                jsonEncode([
                  {
                    'autor_id_publico': 'z9Yx8Wv7Ut6Sr5',
                    'autor_nome_publico': 'Atleta Canônico',
                    'avatar_url': 'https://cdn.aresta.cc/avatar.webp',
                  },
                ]),
                200,
              );
            }
            return http.Response('[]', 201);
          }
          return http.Response('{}', 200);
        }),
      );

      final servico = ServicoAutenticacaoLocal(
        repositorio: repositorio,
        clienteHttp: clienteFake,
        obterUrlSupabase: () => 'https://yzkhiaoqtxvvcyyuwmqg.supabase.co',
        obterAnonKeySupabase: () => 'anon-key-1',
      );

      // 1. Perfil não autenticado -> retorna sem chamadas de rede
      final semConta = await servico.garantirSessaoEPerfilSincronizados();
      expect(semConta.estaAutenticado, isFalse);
      expect(chamadasRefresh, 0);

      // 2. Perfil autenticado sem tokens -> retorna inalterado
      await repositorio.salvarPerfil(
        repositorio.obterPerfil().copyWith(userId: 'usr-reconciliado'),
      );
      final semTokens = await servico.garantirSessaoEPerfilSincronizados();
      expect(semTokens.accessToken, isNull);
      expect(chamadasRefresh, 0);

      // 3. Perfil com accessToken ativo -> reconcilia linha em public.perfis sem renovar token
      await repositorio.salvarPerfil(
        repositorio.obterPerfil().copyWith(
          userId: 'usr-reconciliado',
          accessToken: 'jwt-valido-1',
          refreshToken: 'refresh-valido-1',
        ),
      );
      final reconciliado = await servico.garantirSessaoEPerfilSincronizados();
      expect(chamadasRefresh, 0);
      expect(chamadasPerfis, 1);
      expect(reconciliado.autorIdPublico, 'z9Yx8Wv7Ut6Sr5');
      expect(reconciliado.autorNomePublico, 'Atleta Canônico');
      expect(reconciliado.fotoUrl, 'https://cdn.aresta.cc/avatar.webp');

      // 4. Renovação forçada após HTTP 401 -> obtém novo accessToken e refreshToken
      final renovado = await servico.garantirSessaoEPerfilSincronizados(
        forcarRenovacaoToken: true,
      );
      expect(chamadasRefresh, 1);
      expect(renovado.accessToken, 'jwt-renovado-1');
      expect(renovado.refreshToken, 'refresh-renovado-1');
    });
  });
}
