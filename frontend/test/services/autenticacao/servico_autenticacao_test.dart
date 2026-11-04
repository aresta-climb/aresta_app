// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/autenticacao/servico_autenticacao.dart';
import 'package:frontend/services/caderneta/repositorio_caderneta.dart';
import 'package:frontend/services/http/cliente_http_aresta.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    test('expõe instância singleton configurável e estado inicial desautenticado', () {
      final servico = ServicoAutenticacaoLocal.instancia;
      expect(servico.estaAutenticado, isFalse);
      expect(servico.obterPerfil().estaAutenticado, isFalse);
      expect(servico.perfilListenable.value.estaAutenticado, isFalse);

      final custom = ServicoAutenticacaoLocal(repositorio: repositorio);
      ServicoAutenticacaoLocal.instancia = custom;
      expect(identical(ServicoAutenticacaoLocal.instancia, custom), isTrue);

      ServicoAutenticacaoLocal.redefinirParaTestes();
      expect(identical(ServicoAutenticacaoLocal.instancia, custom), isFalse);
    });

    test('entrarComEmailSenha valida formato de e-mail e tamanho mínimo da senha', () async {
      final servico = ServicoAutenticacaoLocal(repositorio: repositorio);

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

    test('entrarComEmailSenha autentica usuário e adota prefixo do e-mail quando perfil usa apelido padrão', () async {
      final servico = ServicoAutenticacaoLocal(repositorio: repositorio);
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
      final servico = ServicoAutenticacaoLocal(repositorio: repositorio);

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

    test('entrarComGoogle autentica com provedor padrão ou customizado e encerrarSessao limpa apenas o userId', () async {
      final servicoPadrao = ServicoAutenticacaoLocal(repositorio: repositorio);
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

      // Quando já possui apelido customizado e usa provedor padrão, preserva o apelido atual
      await repositorio.salvarPerfil(
        repositorio.obterPerfil().copyWith(autorNomePublico: 'Apelido Customizado'),
      );
      final perfilPreservado = await servicoPadrao.entrarComGoogle();
      expect(perfilPreservado.autorNomePublico, equals('Apelido Customizado'));

      // Provedores customizados injetados (ex: Google / Email / Criar Conta)
      final servicoCustom = ServicoAutenticacaoLocal(
        repositorio: repositorio,
        provedorEmailSenha: (email, senha) async => const ResultadoProvedorAutenticacao(
          userId: 'uid-email-custom',
          nomeExibicao: 'Nome Provedor Email',
        ),
        provedorCriarConta: (nome, email, senha) async => ResultadoProvedorAutenticacao(
          userId: 'uid-criar-custom',
          nomeExibicao: nome,
        ),
        provedorGoogle: () async => const ResultadoProvedorAutenticacao(
          userId: 'uid-google-custom',
          nomeExibicao: 'Conta Gmail Real',
        ),
      );

      final p1 = await servicoCustom.entrarComEmailSenha(
        email: 'a@b.com',
        senha: '123456',
      );
      expect(p1.userId, equals('uid-email-custom'));
      expect(p1.autorNomePublico, equals('Nome Provedor Email'));

      final p2 = await servicoCustom.criarContaComEmailSenha(
        nome: 'Conta Nova',
        email: 'a@b.com',
        senha: '123456',
      );
      expect(p2.userId, equals('uid-criar-custom'));
      expect(p2.autorNomePublico, equals('Conta Nova'));

      final p3 = await servicoCustom.entrarComGoogle();
      expect(p3.userId, equals('uid-google-custom'));
      expect(p3.autorNomePublico, equals('Conta Gmail Real'));
    });

    test('integra com Supabase Auth via RemoteConfig (supabaseUrl e supabaseAnonKey) para login e criação de conta preservando autorIdPublico', () async {
      final requisicoes = <http.Request>[];
      final clienteFake = ClienteHttpAresta.paraTestes(
        MockClient((request) async {
          requisicoes.add(request);
          if (request.url.path.endsWith('/auth/v1/token')) {
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
                  'user': {
                    'id': 'uuid-supabase-sem-meta',
                  },
                }),
                200,
              );
            }
            return http.Response(
              jsonEncode({
                'user': {
                  'id': 'uuid-supabase-login-1',
                  'user_metadata': {
                    'autor_nome_publico': 'Escalador Remoto',
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
                'id': 'uuid-supabase-signup-2',
                'user_metadata': body['data'],
              }),
              200,
            );
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

      // 2. Login com sucesso usa user.id e metadados do Supabase
      final perfilLogado = await servicoRemoto.entrarComEmailSenha(
        email: 'atleta@gmail.com',
        senha: 'senhaCorreta',
      );
      expect(perfilLogado.userId, equals('uuid-supabase-login-1'));
      expect(perfilLogado.autorNomePublico, equals('Escalador Remoto'));
      expect(perfilLogado.autorIdPublico, equals(idPublicoLocal));
      expect(requisicoes.last.headers['apikey'], equals('anon-key-remote-config'));

      // 2b. Login sem user_metadata adota prefixo do e-mail
      final perfilSemMeta = await servicoRemoto.entrarComEmailSenha(
        email: 'semmeta@gmail.com',
        senha: 'senhaCorreta',
      );
      expect(perfilSemMeta.userId, equals('uuid-supabase-sem-meta'));
      expect(perfilSemMeta.autorNomePublico, equals('semmeta'));

      // 3. Criação de conta envia autor_id_publico e autor_nome_publico em data para o trigger do Supabase
      final perfilCriado = await servicoRemoto.criarContaComEmailSenha(
        nome: 'Ana Escaladora',
        email: 'ana@gmail.com',
        senha: 'senhaCorreta',
      );
      expect(perfilCriado.userId, equals('uuid-supabase-signup-2'));
      expect(perfilCriado.autorNomePublico, equals('Ana Escaladora'));
      final payloadSignup =
          jsonDecode(requisicoes.last.body) as Map<String, dynamic>;
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
  });
}
