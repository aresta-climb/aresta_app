// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/autenticacao/servico_autenticacao.dart';
import 'package:frontend/services/caderneta/repositorio_caderneta.dart';
import 'package:frontend/services/http/cliente_http_aresta.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    test('expõe instância singleton configurável e estado inicial desautenticado', () async {
      final servico = ServicoAutenticacaoLocal.instancia;
      expect(servico.estaAutenticado, isFalse);
      expect(servico.obterPerfil().estaAutenticado, isFalse);
      expect(servico.perfilListenable.value.estaAutenticado, isFalse);
      await servico.atualizarPerfilRemoto();

      final custom = ServicoAutenticacaoLocal(
        repositorio: repositorio,
        obterAnonKeySupabase: () => '',
      );
      ServicoAutenticacaoLocal.instancia = custom;
      expect(identical(ServicoAutenticacaoLocal.instancia, custom), isTrue);

      ServicoAutenticacaoLocal.redefinirParaTestes();
      expect(identical(ServicoAutenticacaoLocal.instancia, custom), isFalse);
    });

    test('entrarComEmailSenha valida formato de e-mail e tamanho mínimo da senha', () async {
      final servico = ServicoAutenticacaoLocal(
        repositorio: repositorio,
        obterAnonKeySupabase: () => '',
      );

      await expectLater(
        () => servico.entrarComEmailSenha(email: 'invalido', senha: '123456'),
        throwsA(
          isA<ExcecaoAutenticacao>().having(
            (e) => e.toString(),
            'mensagem',
            contains('Informe um endereço de e-mail válido.'),
          ),
        ),
      );

      await expectLater(
        () => servico.entrarComEmailSenha(
          email: 'ana@gmail.com',
          senha: '123',
        ),
        throwsA(
          isA<ExcecaoAutenticacao>().having(
            (e) => e.mensagem,
            'mensagem',
            'A senha deve ter pelo menos 6 caracteres.',
          ),
        ),
      );
      expect(servico.estaAutenticado, isFalse);
    });

    test('entrarComEmailSenha autentica usuário em modo offline e adota prefixo do e-mail quando perfil usa apelido padrão', () async {
      final servico = ServicoAutenticacaoLocal(
        repositorio: repositorio,
        obterAnonKeySupabase: () => '',
      );
      final idPublicoOriginal = repositorio.obterPerfil().autorIdPublico;

      final perfil = await servico.entrarComEmailSenha(
        email: '  lucas.rocha@gmail.com ',
        senha: 'senhaSegura123',
      );

      expect(servico.estaAutenticado, isTrue);
      expect(perfil.estaAutenticado, isTrue);
      expect(perfil.autorIdPublico, equals(idPublicoOriginal));
      expect(perfil.autorNomePublico, equals('lucas.rocha'));

      // Se o escalador já personalizou o nome antes de entrar, preserva o nome personalizado
      await repositorio.salvarPerfil(
        perfil.copyWith(autorNomePublico: 'Lucas Escalador', limparUserId: true),
      );
      final relogado = await servico.entrarComEmailSenha(
        email: 'outro@gmail.com',
        senha: 'senhaSegura123',
      );
      expect(relogado.autorNomePublico, equals('Lucas Escalador'));
    });

    test('criarContaComEmailSenha valida nome, e-mail e senha e persiste novo perfil autenticado', () async {
      final servico = ServicoAutenticacaoLocal(
        repositorio: repositorio,
        obterAnonKeySupabase: () => '',
      );

      await expectLater(
        () => servico.criarContaComEmailSenha(
          nome: '   ',
          email: 'marina@gmail.com',
          senha: '123456',
        ),
        throwsA(
          isA<ExcecaoAutenticacao>().having(
            (e) => e.mensagem,
            'mensagem',
            'Informe seu nome ou apelido de escalador.',
          ),
        ),
      );

      final perfil = await servico.criarContaComEmailSenha(
        nome: '  Marina Bastos  ',
        email: 'marina@gmail.com',
        senha: '123456',
      );

      expect(servico.estaAutenticado, isTrue);
      expect(perfil.estaAutenticado, isTrue);
      expect(perfil.autorNomePublico, equals('Marina Bastos'));
    });

    test('entrarComGoogle autentica com provedor offline ou customizado e encerrarSessao limpa userId e accessToken', () async {
      final servicoPadrao = ServicoAutenticacaoLocal(
        repositorio: repositorio,
        obterAnonKeySupabase: () => '',
      );
      final idPublicoOriginal = repositorio.obterPerfil().autorIdPublico;

      final perfilGoogle = await servicoPadrao.entrarComGoogle();
      expect(servicoPadrao.estaAutenticado, isTrue);
      expect(perfilGoogle.userId, startsWith('usr_google_'));
      expect(perfilGoogle.autorIdPublico, equals(idPublicoOriginal));
      expect(perfilGoogle.autorNomePublico, equals('Escalador Google'));

      await servicoPadrao.encerrarSessao();
      expect(servicoPadrao.estaAutenticado, isFalse);
      expect(repositorio.obterPerfil().userId, isNull);
      expect(repositorio.obterPerfil().autorIdPublico, equals(idPublicoOriginal));
      expect(repositorio.obterPerfil().autorNomePublico, equals('Escalador Google'));

      // Quando já possui apelido customizado e usa provedor offline, preserva o apelido atual
      await repositorio.salvarPerfil(
        repositorio.obterPerfil().copyWith(autorNomePublico: 'Apelido Customizado'),
      );
      final perfilPreservado = await servicoPadrao.entrarComGoogle();
      expect(perfilPreservado.autorNomePublico, equals('Apelido Customizado'));

      // Login offline com Apple quando perfil usa apelido padrão
      await repositorio.salvarPerfil(
        repositorio.obterPerfil().copyWith(
          autorNomePublico: 'Escalador Aresta',
          limparUserId: true,
        ),
      );
      final perfilAppleOffline = await servicoPadrao.entrarComApple();
      expect(perfilAppleOffline.userId, startsWith('usr_apple_'));
      expect(perfilAppleOffline.autorNomePublico, equals('Escalador Apple'));

      // Provedores customizados injetados (ex: Google / Apple / Email / Criar Conta)
      final servicoCustom = ServicoAutenticacaoLocal(
        repositorio: repositorio,
        obterAnonKeySupabase: () => '',
        provedorEmailSenha: (email, senha) async => const ResultadoProvedorAutenticacao(
          userId: 'uid-email-custom',
          nomeExibicao: 'Nome Provedor Email',
          fotoUrl: 'https://exemplo.com/email.jpg',
          accessToken: 'tok-email',
        ),
        provedorCriarConta: (nome, email, senha) async => ResultadoProvedorAutenticacao(
          userId: 'uid-criar-custom',
          nomeExibicao: nome,
          accessToken: 'tok-criar',
        ),
        provedorGoogle: () async => const ResultadoProvedorAutenticacao(
          userId: 'uid-google-custom',
          nomeExibicao: 'Conta Gmail Real',
          fotoUrl: 'https://lh3.googleusercontent.com/a/gmail.jpg',
          accessToken: 'tok-google',
        ),
        provedorApple: () async => const ResultadoProvedorAutenticacao(
          userId: 'uid-apple-custom',
          nomeExibicao: 'Conta Apple Real',
          accessToken: 'tok-apple',
        ),
      );

      final p1 = await servicoCustom.entrarComEmailSenha(
        email: 'a@b.com',
        senha: '123456',
      );
      expect(p1.userId, equals('uid-email-custom'));
      expect(p1.autorNomePublico, equals('Nome Provedor Email'));
      expect(p1.fotoUrl, equals('https://exemplo.com/email.jpg'));
      expect(p1.accessToken, equals('tok-email'));

      final p2 = await servicoCustom.criarContaComEmailSenha(
        nome: 'Conta Nova',
        email: 'a@b.com',
        senha: '123456',
      );
      expect(p2.userId, equals('uid-criar-custom'));
      expect(p2.autorNomePublico, equals('Conta Nova'));
      expect(p2.accessToken, equals('tok-criar'));

      final p3 = await servicoCustom.entrarComGoogle();
      expect(p3.userId, equals('uid-google-custom'));
      expect(p3.autorNomePublico, equals('Conta Gmail Real'));
      expect(p3.fotoUrl, equals('https://lh3.googleusercontent.com/a/gmail.jpg'));
      expect(p3.accessToken, equals('tok-google'));

      final p4 = await servicoCustom.entrarComApple();
      expect(p4.userId, equals('uid-apple-custom'));
      expect(p4.autorNomePublico, equals('Conta Apple Real'));
      expect(p4.accessToken, equals('tok-apple'));
    });

    test('integra com Supabase Auth e tabela public.perfis para login e criação de conta por e-mail e senha', () async {
      final requisicoes = <http.Request>[];
      final clienteFake = ClienteHttpAresta.paraTestes(
        MockClient((request) async {
          requisicoes.add(request);
          if (request.url.path.endsWith('/auth/v1/token') &&
              request.url.queryParameters['grant_type'] == 'password') {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            if (body['password'] == 'senhaErrada') {
              return http.Response(
                jsonEncode({'error_description': 'Credenciais inválidas'}),
                400,
              );
            }
            if (body['email'] == 'semmeta@gmail.com') {
              return http.Response(
                jsonEncode({
                  'access_token': 'jwt-sem-meta',
                  'user': {
                    'id': 'uuid-supabase-sem-meta',
                  },
                }),
                200,
              );
            }
            return http.Response(
              jsonEncode({
                'access_token': 'jwt-login-1',
                'user': {
                  'id': 'uuid-supabase-login-1',
                  'user_metadata': {
                    'autor_nome_publico': 'Escalador Remoto',
                    'avatar_url': 'https://supabase.co/avatar1.jpg',
                  },
                },
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/auth/v1/signup')) {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            if (body['email'] == 'duplicado@gmail.com') {
              return http.Response(
                jsonEncode({'msg': 'Este e-mail já está cadastrado.'}),
                422,
              );
            }
            return http.Response(
              jsonEncode({
                'access_token': 'jwt-signup-2',
                'user': {
                  'id': 'uuid-supabase-signup-2',
                  'user_metadata': body['data'],
                },
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/rest/v1/perfis')) {
            if (request.method == 'GET') {
              if (request.url.queryParameters['user_id'] ==
                  'eq.uuid-supabase-login-1') {
                return http.Response(
                  jsonEncode([
                    {
                      'autor_id_publico': 'r9siJek3FiG3aZ',
                      'autor_nome_publico': 'Escalador Remoto Perfis',
                      'avatar_url': 'https://supabase.co/avatar_perfis.jpg',
                    },
                  ]),
                  200,
                );
              }
              return http.Response(jsonEncode([]), 200);
            }
            return http.Response(jsonEncode([{}]), 201);
          }
          if (request.url.path.endsWith('/auth/v1/user')) {
            return http.Response(jsonEncode({}), 200);
          }
          return http.Response('{}', 404);
        }),
      );

      final idPublicoLocal = repositorio.obterPerfil().autorIdPublico;
      final servicoRemoto = ServicoAutenticacaoLocal(
        repositorio: repositorio,
        clienteHttp: clienteFake,
        obterAnonKeySupabase: () => 'anon-key-remote-config',
      );

      // 1. Login com falha de credenciais retorna ExcecaoAutenticacao amigável
      await expectLater(
        () => servicoRemoto.entrarComEmailSenha(
          email: 'atleta@gmail.com',
          senha: 'senhaErrada',
        ),
        throwsA(
          isA<ExcecaoAutenticacao>().having(
            (e) => e.mensagem,
            'mensagem',
            'Credenciais inválidas',
          ),
        ),
      );

      // 2. Login com sucesso sincroniza dados da tabela public.perfis e preserva accessToken
      final perfilLogado = await servicoRemoto.entrarComEmailSenha(
        email: 'atleta@gmail.com',
        senha: 'senhaCorreta',
      );
      expect(perfilLogado.userId, equals('uuid-supabase-login-1'));
      expect(perfilLogado.autorIdPublico, equals('r9siJek3FiG3aZ'));
      expect(perfilLogado.autorNomePublico, equals('Escalador Remoto Perfis'));
      expect(perfilLogado.fotoUrl, equals('https://supabase.co/avatar_perfis.jpg'));
      expect(perfilLogado.accessToken, equals('jwt-login-1'));

      // 2b. Login sem user_metadata e sem linha prévia em public.perfis cria linha em public.perfis
      await repositorio.salvarPerfil(
        repositorio.obterPerfil().copyWith(autorIdPublico: idPublicoLocal),
      );
      final perfilSemMeta = await servicoRemoto.entrarComEmailSenha(
        email: 'semmeta@gmail.com',
        senha: 'senhaCorreta',
      );
      expect(perfilSemMeta.userId, equals('uuid-supabase-sem-meta'));
      expect(perfilSemMeta.autorNomePublico, equals('semmeta'));

      // 3. Criação de conta envia autor_id_publico e autor_nome_publico no signup e sincroniza public.perfis
      final perfilCriado = await servicoRemoto.criarContaComEmailSenha(
        nome: 'Ana Escaladora',
        email: 'ana@gmail.com',
        senha: 'senhaCorreta',
      );
      expect(perfilCriado.userId, equals('uuid-supabase-signup-2'));
      expect(perfilCriado.autorNomePublico, equals('Ana Escaladora'));
      expect(perfilCriado.accessToken, equals('jwt-signup-2'));

      final reqSignup = requisicoes.firstWhere(
        (r) => r.url.path.endsWith('/auth/v1/signup'),
      );
      final payloadSignup = jsonDecode(reqSignup.body) as Map<String, dynamic>;
      expect(
        (payloadSignup['data'] as Map<String, dynamic>)['autor_id_publico'],
        equals(idPublicoLocal),
      );
      expect(
        (payloadSignup['data'] as Map<String, dynamic>)['autor_nome_publico'],
        equals('Ana Escaladora'),
      );

      // 4. Erro no signup repassa mensagem do servidor
      await expectLater(
        () => servicoRemoto.criarContaComEmailSenha(
          nome: 'Ana',
          email: 'duplicado@gmail.com',
          senha: 'senhaCorreta',
        ),
        throwsA(
          isA<ExcecaoAutenticacao>().having(
            (e) => e.mensagem,
            'mensagem',
            'Este e-mail já está cadastrado.',
          ),
        ),
      );
    });

    test('entrarComGoogle realiza fluxo OAuth PKCE e Implicit no Supabase sincronizando nome e foto de perfil', () async {
      final controladorLinks = StreamController<Uri>.broadcast();
      addTearDown(controladorLinks.close);

      Uri? urlAbertaNoNavegador;
      final requisicoes = <http.Request>[];

      final clienteFake = ClienteHttpAresta.paraTestes(
        MockClient((request) async {
          requisicoes.add(request);
          if (request.url.path.endsWith('/auth/v1/token') &&
              request.url.queryParameters['grant_type'] == 'pkce') {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            if (body['auth_code'] == 'codigo-invalido') {
              return http.Response(
                jsonEncode({'error_description': 'Código PKCE inválido.'}),
                400,
              );
            }
            return http.Response(
              jsonEncode({
                'access_token': 'jwt-google-pkce',
                'user': {
                  'id': 'uuid-google-123',
                  'email': 'escalador.google@gmail.com',
                  'user_metadata': {
                    'full_name': 'Pedro Google',
                    'avatar_url': 'https://lh3.googleusercontent.com/a/pedro.jpg',
                  },
                },
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/auth/v1/user') &&
              request.method == 'GET') {
            if (request.headers['Authorization'] == 'Bearer tok-invalido') {
              return http.Response(
                jsonEncode({'msg': 'Token inválido.'}),
                401,
              );
            }
            return http.Response(
              jsonEncode({
                'id': 'uuid-google-implicit',
                'email': 'implicit@gmail.com',
                'user_metadata': {
                  'name': 'Camila Implicit',
                  'picture': 'https://lh3.googleusercontent.com/a/camila.jpg',
                },
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/auth/v1/user') &&
              request.method == 'PUT') {
            return http.Response(jsonEncode({}), 200);
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

      final servico = ServicoAutenticacaoLocal(
        repositorio: repositorio,
        clienteHttp: clienteFake,
        obterUrlSupabase: () => 'https://yzkhiaoqtxvvcyyuwmqg.supabase.co',
        obterAnonKeySupabase: () => 'anon-key-supabase',
        fluxoLinksOAuth: controladorLinks.stream,
        lancadorUrlOAuth: (uri) async {
          urlAbertaNoNavegador = uri;
          // Simula retorno do navegador com código PKCE
          Future<void>.microtask(() {
            controladorLinks.add(
              Uri.parse(
                'aresta://app.arestaclimb.com/auth-callback?code=codigo-pkce-valido',
              ),
            );
          });
          return true;
        },
      );

      // 1. Fluxo PKCE completo via stream de links
      final perfilPkce = await servico.entrarComGoogle();
      expect(urlAbertaNoNavegador, isNotNull);
      expect(
        urlAbertaNoNavegador!.queryParameters['provider'],
        equals('google'),
      );
      expect(
        urlAbertaNoNavegador!.queryParameters['redirect_to'],
        equals(ServicoAutenticacaoLocal.urlRedirecionamentoOAuth),
      );
      expect(
        urlAbertaNoNavegador!.queryParameters['code_challenge_method'],
        equals('s256'),
      );
      expect(perfilPkce.userId, equals('uuid-google-123'));
      expect(perfilPkce.autorNomePublico, equals('Pedro Google'));
      expect(
        perfilPkce.fotoUrl,
        equals('https://lh3.googleusercontent.com/a/pedro.jpg'),
      );
      expect(perfilPkce.accessToken, equals('jwt-google-pkce'));

      // Confirma que gravou na tabela public.perfis
      final postPerfis = requisicoes.where(
        (r) => r.url.path.endsWith('/rest/v1/perfis') && r.method == 'POST',
      );
      expect(postPerfis, isNotEmpty);

      // 1b. Fluxo PKCE com Apple via ServicoAutenticacaoLocal
      final perfilApplePkce = await servico.entrarComApple();
      expect(
        urlAbertaNoNavegador!.queryParameters['provider'],
        equals('apple'),
      );
      expect(perfilApplePkce.userId, equals('uuid-google-123'));
      expect(perfilApplePkce.accessToken, equals('jwt-google-pkce'));

      // 2. Fluxo Implicit (#access_token=...) acionado via processarCallbackOAuth e lancadorUrlOAuth padrão
      late ServicoAutenticacaoLocal servicoImplicit;
      UrlLauncherPlatform.instance = _FakeUrlLauncherOAuth((_) {
        Future<void>.microtask(() {
          servicoImplicit.processarCallbackOAuth(
            Uri.parse(
              'aresta://app.arestaclimb.com/auth-callback#access_token=jwt-implicit&token_type=bearer',
            ),
          );
        });
      });
      servicoImplicit = ServicoAutenticacaoLocal(
        repositorio: repositorio,
        clienteHttp: clienteFake,
        obterUrlSupabase: () => 'https://yzkhiaoqtxvvcyyuwmqg.supabase.co',
        obterAnonKeySupabase: () => 'anon-key-supabase',
        fluxoLinksOAuth: const Stream<Uri>.empty(),
      );

      final perfilImplicit = await servicoImplicit.entrarComGoogle();
      expect(perfilImplicit.userId, equals('uuid-google-implicit'));
      expect(perfilImplicit.autorNomePublico, equals('Camila Implicit'));
      expect(
        perfilImplicit.fotoUrl,
        equals('https://lh3.googleusercontent.com/a/camila.jpg'),
      );
      expect(perfilImplicit.accessToken, equals('jwt-implicit'));

      // Links comuns que não são de callback OAuth retornam false em processarCallbackOAuth
      expect(
        servicoImplicit.processarCallbackOAuth(
          Uri.parse('https://aresta.cc/pQ9mRt2Kx1Vw8L'),
        ),
        isFalse,
      );
    });

    test('entrarComGoogle trata erros de abertura de navegador, cancelamento OAuth, erro de troca de token e timeout', () async {
      final clienteErro = ClienteHttpAresta.paraTestes(
        MockClient((request) async {
          if (request.url.path.endsWith('/auth/v1/token')) {
            return http.Response(
              jsonEncode({'error_description': 'Código PKCE expirado.'}),
              400,
            );
          }
          if (request.url.path.endsWith('/auth/v1/user')) {
            return http.Response(
              jsonEncode({'msg': 'Sessão inválida.'}),
              401,
            );
          }
          return http.Response('{}', 400);
        }),
      );

      // 1. Falha ao abrir o navegador externo
      final servicoFalhaNav = ServicoAutenticacaoLocal(
        repositorio: repositorio,
        clienteHttp: clienteErro,
        obterAnonKeySupabase: () => 'anon-key',
        fluxoLinksOAuth: const Stream<Uri>.empty(),
        lancadorUrlOAuth: (_) async => false,
      );
      await expectLater(
        () => servicoFalhaNav.entrarComGoogle(),
        throwsA(
          isA<ExcecaoAutenticacao>().having(
            (e) => e.mensagem,
            'mensagem',
            contains('Não foi possível abrir o navegador'),
          ),
        ),
      );

      // 2. Callback OAuth com error_description
      late ServicoAutenticacaoLocal servicoErroCallback;
      servicoErroCallback = ServicoAutenticacaoLocal(
        repositorio: repositorio,
        clienteHttp: clienteErro,
        obterAnonKeySupabase: () => 'anon-key',
        fluxoLinksOAuth: const Stream<Uri>.empty(),
        lancadorUrlOAuth: (_) async {
          Future<void>.microtask(() {
            servicoErroCallback.processarCallbackOAuth(
              Uri.parse(
                'aresta://app.arestaclimb.com/auth-callback?error=access_denied&error_description=Acesso+negado+pelo+usuario',
              ),
            );
          });
          return true;
        },
      );
      await expectLater(
        () => servicoErroCallback.entrarComGoogle(),
        throwsA(
          isA<ExcecaoAutenticacao>().having(
            (e) => e.mensagem,
            'mensagem',
            contains('Acesso negado pelo usuario'),
          ),
        ),
      );

      // 3. Callback sem code nem access_token
      late ServicoAutenticacaoLocal servicoCallbackVazio;
      servicoCallbackVazio = ServicoAutenticacaoLocal(
        repositorio: repositorio,
        clienteHttp: clienteErro,
        obterAnonKeySupabase: () => 'anon-key',
        fluxoLinksOAuth: const Stream<Uri>.empty(),
        lancadorUrlOAuth: (_) async {
          Future<void>.microtask(() {
            servicoCallbackVazio.processarCallbackOAuth(
              Uri.parse('aresta://app.arestaclimb.com/auth-callback'),
            );
          });
          return true;
        },
      );
      await expectLater(
        () => servicoCallbackVazio.entrarComGoogle(),
        throwsA(
          isA<ExcecaoAutenticacao>().having(
            (e) => e.mensagem,
            'mensagem',
            contains('incompleta'),
          ),
        ),
      );

      // 4. Erro HTTP ao trocar código PKCE
      late ServicoAutenticacaoLocal servicoErroPkce;
      servicoErroPkce = ServicoAutenticacaoLocal(
        repositorio: repositorio,
        clienteHttp: clienteErro,
        obterAnonKeySupabase: () => 'anon-key',
        fluxoLinksOAuth: const Stream<Uri>.empty(),
        lancadorUrlOAuth: (_) async {
          Future<void>.microtask(() {
            servicoErroPkce.processarCallbackOAuth(
              Uri.parse(
                'aresta://app.arestaclimb.com/auth-callback?code=codigo-expirado',
              ),
            );
          });
          return true;
        },
      );
      await expectLater(
        () => servicoErroPkce.entrarComGoogle(),
        throwsA(
          isA<ExcecaoAutenticacao>().having(
            (e) => e.mensagem,
            'mensagem',
            'Código PKCE expirado.',
          ),
        ),
      );

      // 5. Erro HTTP ao consultar /auth/v1/user no fluxo implicit
      late ServicoAutenticacaoLocal servicoErroUser;
      servicoErroUser = ServicoAutenticacaoLocal(
        repositorio: repositorio,
        clienteHttp: clienteErro,
        obterAnonKeySupabase: () => 'anon-key',
        fluxoLinksOAuth: const Stream<Uri>.empty(),
        lancadorUrlOAuth: (_) async {
          Future<void>.microtask(() {
            servicoErroUser.processarCallbackOAuth(
              Uri.parse(
                'aresta://app.arestaclimb.com/auth-callback#access_token=tok-invalido',
              ),
            );
          });
          return true;
        },
      );
      await expectLater(
        () => servicoErroUser.entrarComGoogle(),
        throwsA(
          isA<ExcecaoAutenticacao>().having(
            (e) => e.mensagem,
            'mensagem',
            'Sessão inválida.',
          ),
        ),
      );

      // 6. Timeout ao aguardar callback OAuth
      final servicoTimeout = ServicoAutenticacaoLocal(
        repositorio: repositorio,
        clienteHttp: clienteErro,
        obterAnonKeySupabase: () => 'anon-key',
        fluxoLinksOAuth: const Stream<Uri>.empty(),
        lancadorUrlOAuth: (_) async => true,
        timeoutOAuth: const Duration(milliseconds: 20),
      );
      await expectLater(
        () => servicoTimeout.entrarComGoogle(),
        throwsA(
          isA<ExcecaoAutenticacao>().having(
            (e) => e.mensagem,
            'mensagem',
            contains('Tempo esgotado'),
          ),
        ),
      );
    });

    test('atualizarPerfilRemoto persiste nome e foto localmente e sincroniza com Supabase Storage, Auth e public.perfis', () async {
      final requisicoes = <http.Request>[];
      var storageDisponivel = true;

      final clienteFake = ClienteHttpAresta.paraTestes(
        MockClient((request) async {
          requisicoes.add(request);
          if (request.url.path.contains('/storage/v1/object/avatars/')) {
            if (!storageDisponivel) {
              return http.Response('{"error":"Bucket not found"}', 404);
            }
            return http.Response('{"Key":"avatars/usr-1/avatar.jpg"}', 200);
          }
          if (request.url.path.endsWith('/auth/v1/user')) {
            return http.Response('{}', 200);
          }
          if (request.url.path.endsWith('/rest/v1/perfis')) {
            return http.Response('[{}]', 200);
          }
          return http.Response('{}', 404);
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

      final bytesBase64 = base64Encode([0xFF, 0xD8, 0xFF, 0xD9]);
      final dataUri = 'data:image/jpeg;base64,$bytesBase64';

      // 1. Quando o bucket avatars existe no Supabase Storage, converte Data URI para URL pública do Storage
      final atualizadoStorage = await servico.atualizarPerfilRemoto(
        novoNome: 'Novo Nome Supabase',
        novaFotoUrl: dataUri,
      );
      expect(atualizadoStorage.autorNomePublico, equals('Novo Nome Supabase'));
      expect(
        atualizadoStorage.fotoUrl,
        startsWith(
          'https://yzkhiaoqtxvvcyyuwmqg.supabase.co/storage/v1/object/public/avatars/usr-1/avatar.jpg',
        ),
      );
      expect(
        requisicoes.any((r) => r.url.path.endsWith('/auth/v1/user') && r.method == 'PUT'),
        isTrue,
      );
      expect(
        requisicoes.any((r) => r.url.path.endsWith('/rest/v1/perfis') && r.method == 'POST'),
        isTrue,
      );

      // 2. Quando o bucket avatars ainda não existe (404), preserva a Data URI no Auth e em public.perfis
      storageDisponivel = false;
      final atualizadoDataUri = await servico.atualizarPerfilRemoto(
        novaFotoUrl: dataUri,
      );
      expect(atualizadoDataUri.fotoUrl, equals(dataUri));

      // 3. Quando apenas o nome é atualizado, preserva a foto atual
      final atualizadoApenasNome = await servico.atualizarPerfilRemoto(
        novoNome: 'Apenas Nome',
      );
      expect(atualizadoApenasNome.autorNomePublico, equals('Apenas Nome'));
      expect(atualizadoApenasNome.fotoUrl, equals(dataUri));
    });
  });
}
