// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/cadena.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';
import 'package:frontend/data/modelos/tipo_escalada.dart';
import 'package:frontend/services/autenticacao/servico_autenticacao.dart';
import 'package:frontend/services/caderneta/cliente_cadenas_supabase.dart';
import 'package:frontend/services/caderneta/repositorio_caderneta.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../autenticacao/servico_autenticacao_fake.dart';
import 'cliente_cadenas_supabase_fake.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RepositorioCadernetaLocal repositorio;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repositorio = RepositorioCadernetaLocal(preferencias: prefs);
    await repositorio.inicializar();
  });

  group('RepositorioCadernetaLocal', () {
    test('inicializa com perfil padrão gerado e caderneta vazia', () {
      expect(repositorio.cadenasNotifier.value, isEmpty);
      final perfil = repositorio.obterPerfil();
      expect(perfil.autorIdPublico.length, 14);
      expect(perfil.autorNomePublico, 'Escalador Aresta');
      expect(repositorio.perfilNotifier.value, equals(perfil));
    });

    test(
      'salva uma nova cadena, persiste e notifica o cadenasNotifier',
      () async {
        final cadena = Cadena.criar(
          escaladaUid: 'via-1234567890',
          dataAscensao: DateTime(2026, 9, 15),
          tipoAscensao: TipoAscensao.flash,
          tipoEscalada: TipoEscalada.guiado,
          notasPrivadas: 'Costurou leve',
        );

        bool notificado = false;
        repositorio.cadenasNotifier.addListener(() {
          notificado = true;
        });

        await repositorio.salvarCadena(cadena);

        expect(notificado, isTrue);
        expect(repositorio.cadenasNotifier.value.length, 1);
        expect(repositorio.cadenasNotifier.value.first, equals(cadena));

        // Testa persistência recarregando novo repositório com o mesmo prefs
        final prefs = await SharedPreferences.getInstance();
        final novoRepositorio = RepositorioCadernetaLocal(preferencias: prefs);
        await novoRepositorio.inicializar();
        expect(novoRepositorio.cadenasNotifier.value.length, 1);
        expect(novoRepositorio.cadenasNotifier.value.first.id, cadena.id);
      },
    );

    test(
      'atualiza uma cadena existente quando o mesmo id é salvo novamente',
      () async {
        final cadenaOriginal = Cadena.criar(
          escaladaUid: 'via-1234567890',
          dataAscensao: DateTime(2026, 9, 15),
          tipoAscensao: TipoAscensao.tentativa,
        );

        await repositorio.salvarCadena(cadenaOriginal);
        expect(
          repositorio.cadenasNotifier.value.first.tipoAscensao,
          TipoAscensao.tentativa,
        );

        final cadenaAtualizada = cadenaOriginal.copyWith(
          tipoAscensao: TipoAscensao.trabalhado,
          notasPrivadas: 'Encadenada na segunda tentativa',
        );

        await repositorio.salvarCadena(cadenaAtualizada);
        expect(repositorio.cadenasNotifier.value.length, 1);
        expect(
          repositorio.cadenasNotifier.value.first.tipoAscensao,
          TipoAscensao.trabalhado,
        );
        expect(
          repositorio.cadenasNotifier.value.first.notasPrivadas,
          'Encadenada na segunda tentativa',
        );
      },
    );

    test('exclui uma cadena pelo id e atualiza o estado reativo', () async {
      final c1 = Cadena.criar(
        escaladaUid: 'via-1',
        dataAscensao: DateTime(2026, 9, 1),
      );
      final c2 = Cadena.criar(
        escaladaUid: 'via-2',
        dataAscensao: DateTime(2026, 9, 2),
      );

      await repositorio.salvarCadena(c1);
      await repositorio.salvarCadena(c2);
      expect(repositorio.cadenasNotifier.value.length, 2);

      await repositorio.excluirCadena(c1.id);
      expect(repositorio.cadenasNotifier.value.length, 1);
      expect(repositorio.cadenasNotifier.value.first.id, c2.id);
    });

    test(
      'obterCadenasPorEscalada retorna ascensões ordenadas por data descrescente',
      () async {
        final c1 = Cadena.criar(
          escaladaUid: 'via-alvo',
          dataAscensao: DateTime(2026, 8, 10),
          tipoAscensao: TipoAscensao.tentativa,
        );
        final c2 = Cadena.criar(
          escaladaUid: 'via-alvo',
          dataAscensao: DateTime(2026, 9, 20),
          tipoAscensao: TipoAscensao.trabalhado,
        );
        final cOutra = Cadena.criar(
          escaladaUid: 'outra-via',
          dataAscensao: DateTime(2026, 9, 25),
        );

        await repositorio.salvarCadena(c1);
        await repositorio.salvarCadena(c2);
        await repositorio.salvarCadena(cOutra);

        final resultados = repositorio.obterCadenasPorEscalada('via-alvo');
        expect(resultados.length, 2);
        // c2 (20/09) deve vir antes de c1 (10/08)
        expect(resultados.first.id, c2.id);
        expect(resultados.last.id, c1.id);
      },
    );

    test(
      'obterMelhorAscensao prioriza estilo esportivo e data recente',
      () async {
        expect(repositorio.obterMelhorAscensao('inexistente'), isNull);

        final tentativa = Cadena.criar(
          escaladaUid: 'via-destaque',
          dataAscensao: DateTime(2026, 9, 10),
          tipoAscensao: TipoAscensao.tentativa,
        );
        final trabalhado = Cadena.criar(
          escaladaUid: 'via-destaque',
          dataAscensao: DateTime(2026, 9, 12),
          tipoAscensao: TipoAscensao.trabalhado,
        );
        final flash = Cadena.criar(
          escaladaUid: 'via-destaque',
          dataAscensao: DateTime(2026, 9, 5),
          tipoAscensao: TipoAscensao.flash,
        );

        await repositorio.salvarCadena(tentativa);
        expect(
          repositorio.obterMelhorAscensao('via-destaque')?.tipoAscensao,
          TipoAscensao.tentativa,
        );

        await repositorio.salvarCadena(trabalhado);
        expect(
          repositorio.obterMelhorAscensao('via-destaque')?.tipoAscensao,
          TipoAscensao.trabalhado,
        );

        await repositorio.salvarCadena(flash);
        // Mesmo com data anterior, Flash tem maior prioridade visual
        expect(
          repositorio.obterMelhorAscensao('via-destaque')?.tipoAscensao,
          TipoAscensao.flash,
        );

        // Em caso de empate de prioridade esportiva, escolhe a data mais recente
        final flashMaisRecente = Cadena.criar(
          escaladaUid: 'via-destaque',
          dataAscensao: DateTime(2026, 9, 25),
          tipoAscensao: TipoAscensao.flash,
        );
        await repositorio.salvarCadena(flashMaisRecente);
        expect(
          repositorio.obterMelhorAscensao('via-destaque')?.id,
          flashMaisRecente.id,
        );
      },
    );

    test('salvarPerfil persiste e notifica perfilNotifier', () async {
      final perfilOriginal = repositorio.obterPerfil();
      final novoPerfil = perfilOriginal.copyWith(
        autorNomePublico: 'Mestre da Fenda',
      );

      bool perfilNotificado = false;
      repositorio.perfilNotifier.addListener(() {
        perfilNotificado = true;
      });

      await repositorio.salvarPerfil(novoPerfil);

      expect(perfilNotificado, isTrue);
      expect(repositorio.obterPerfil().autorNomePublico, 'Mestre da Fenda');
      expect(
        repositorio.perfilNotifier.value.autorNomePublico,
        'Mestre da Fenda',
      );
    });

    test(
      'calcularEstatisticas compila os dados cadastrados no repositório',
      () async {
        await repositorio.salvarCadena(
          Cadena.criar(
            escaladaUid: 'via-1',
            dataAscensao: DateTime(2026, 9, 1),
            tipoAscensao: TipoAscensao.aVista,
          ),
        );

        final stats = repositorio.calcularEstatisticas(
          obterGrauDaVia: (_) => '7a',
        );

        expect(stats.totalCadenas, 1);
        expect(stats.maiorGrauVia, '7a');
      },
    );

    test(
      'recupera graciosamente caso json de perfil ou cadenas esteja corrompido',
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('aresta_perfil_escalador_v1', '{invalido json');
        await prefs.setString('aresta_cadenas_v1', 'not a json list');

        final repoCorrompido = RepositorioCadernetaLocal(preferencias: prefs);
        await repoCorrompido.inicializar();

        expect(
          repoCorrompido.obterPerfil().autorNomePublico,
          'Escalador Aresta',
        );
        expect(repoCorrompido.cadenasNotifier.value, isEmpty);
      },
    );

    test('instancia singleton é acessível e configurável para testes', () {
      final padrao = RepositorioCadernetaLocal.instancia;
      expect(padrao, isNotNull);

      RepositorioCadernetaLocal.instancia = repositorio;
      expect(RepositorioCadernetaLocal.instancia, equals(repositorio));

      // Restaura para não vazar estado entre outros testes
      RepositorioCadernetaLocal.instancia = null;
    });

    test('sincroniza cadenas locais pré-login, fila offline (upsert/delete), renovação 401 e limpeza de conta excluída', () async {
      final prefs = await SharedPreferences.getInstance();
      final clienteFake = ClienteCadenasFake();

      // Nuvem já possui 1 cadena salva anteriormente em outro aparelho
      final cadenaOutroAparelho = Cadena(
        id: '11111111-1111-4111-8111-111111111111',
        userId: 'uuid-atleta-1',
        escaladaUid: 'm8Kq2L1x9Y7zWq',
        dataAscensao: DateTime(2026, 8, 1),
        tipoAscensao: TipoAscensao.aVista,
      );
      clienteFake.semearCadenas('uuid-atleta-1', [cadenaOutroAparelho]);

      var renovacoes401 = 0;
      late RepositorioCadernetaLocal repoSinc;
      repoSinc = RepositorioCadernetaLocal(
        preferencias: prefs,
        clienteCadenas: clienteFake,
        aoRenovarSessaoExpirada: () async {
          renovacoes401++;
          final novo = repoSinc.obterPerfil().copyWith(
            accessToken: 'jwt-renovado-$renovacoes401',
          );
          await repoSinc.salvarPerfil(novo);
          return novo;
        },
      );
      await repoSinc.inicializar();

      // 1. Escalador usa o app offline sem conta e registra 1 cadena com NanoID válido
      final cadenaPreLogin = Cadena.criar(
        escaladaUid: 'x8siJek3FiG3aB',
        dataAscensao: DateTime(2026, 9, 10),
        tipoAscensao: TipoAscensao.flash,
        notasPrivadas: 'Anotada antes de criar conta',
      );
      await repoSinc.salvarCadena(cadenaPreLogin);
      expect(clienteFake.cadenasDaConta('uuid-atleta-1'), hasLength(1));

      // 2. Faz login -> sincronizarComNuvem envia a cadena pré-login e baixa a do outro aparelho
      await repoSinc.salvarPerfil(
        repoSinc.obterPerfil().copyWith(
          userId: 'uuid-atleta-1',
          accessToken: 'jwt-inicial',
          refreshToken: 'refresh-inicial',
        ),
      );
      await repoSinc.sincronizarComNuvem();
      expect(repoSinc.cadenasNotifier.value, hasLength(2));
      expect(clienteFake.cadenasDaConta('uuid-atleta-1'), hasLength(2));

      // 3. Sem sinal na rocha: cria nova cadena e exclui a antiga -> retidas na fila offline em disco
      clienteFake.erroSimulado = const SocketException('Sem sinal na falésia');
      final cadenaOffline = Cadena.criar(
        escaladaUid: 'p9Rt3M2y0Z8aXr',
        dataAscensao: DateTime(2026, 10, 12),
        tipoAscensao: TipoAscensao.trabalhado,
      );
      await repoSinc.salvarCadena(cadenaOffline);
      await repoSinc.excluirCadena(cadenaOutroAparelho.id);
      expect(repoSinc.cadenasNotifier.value.map((c) => c.id), equals([cadenaOffline.id, cadenaPreLogin.id]));
      // Na nuvem ainda não refletiu porque estava offline
      expect(
        clienteFake.cadenasDaConta('uuid-atleta-1').map((c) => c.id),
        contains(cadenaOutroAparelho.id),
      );

      // 4. Falha na retentativa após 401 preserva fila em disco; depois reabre com renovador padrão (ServicoAutenticacaoLocal.instancia)
      clienteFake.erroSimulado = null;
      clienteFake.filaErros.addAll([
        const ExcecaoHttpCadenas(
          codigoStatusHttp: 401,
          message: 'JWT expired',
        ),
        const SocketException('Queda durante retentativa'),
      ]);
      await repoSinc.sincronizarComNuvem();
      expect(renovacoes401, 1);

      clienteFake.filaErros.add(
        const ExcecaoHttpCadenas(
          codigoStatusHttp: 401,
          message: 'JWT expired novamente',
        ),
      );
      final repoReaberto = RepositorioCadernetaLocal(
        preferencias: prefs,
        clienteCadenas: clienteFake,
      );
      final authPadraoFake = ServicoAutenticacaoFake(repositorio: repoReaberto);
      ServicoAutenticacaoLocal.instancia = authPadraoFake;
      addTearDown(ServicoAutenticacaoLocal.redefinirParaTestes);

      await repoReaberto.inicializar();
      await repoReaberto.sincronizarComNuvem();

      expect(authPadraoFake.totalRenovacoesToken, greaterThanOrEqualTo(1));
      final naNuvem = clienteFake.cadenasDaConta('uuid-atleta-1');
      expect(
        naNuvem.map((c) => c.id),
        equals([cadenaOffline.id, cadenaPreLogin.id]),
      );

      // Erro HTTP definitivo 500 registra erro sem derrubar o app
      clienteFake.filaErros.add(
        const ExcecaoHttpCadenas(
          codigoStatusHttp: 500,
          message: 'Erro interno',
        ),
      );
      await repoReaberto.sincronizarComNuvem();

      // 5. Exclusão definitiva da conta limpa cadenas locais, filas e gera novo perfil anônimo limpo
      final idPublicoAntigo = repoReaberto.obterPerfil().autorIdPublico;
      await repoReaberto.limparDadosContaExcluida();
      expect(repoReaberto.cadenasNotifier.value, isEmpty);
      expect(repoReaberto.obterPerfil().estaAutenticado, isFalse);
      expect(repoReaberto.obterPerfil().autorIdPublico, isNot(equals(idPublicoAntigo)));
    });
  });
}
