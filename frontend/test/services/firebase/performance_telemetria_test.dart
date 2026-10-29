// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:ui';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import 'package:frontend/services/firebase/classificador_dispositivo.dart';
import 'package:frontend/services/firebase/performance_telemetria.dart';
import 'package:frontend/services/firebase/telemetria.dart';
import '../../mocks/mock_app_logger.dart';
import '../../mocks/mock_telemetria.dart';

/// Fake determinístico de [Trace] do Firebase Performance para testes de fronteira.
class FakeTrace implements Trace {
  final String nome;
  bool iniciada = false;
  bool finalizada = false;
  final Map<String, String> atributos = {};
  final Map<String, int> metricas = {};

  FakeTrace(this.nome);

  @override
  Future<void> start() async {
    iniciada = true;
  }

  @override
  Future<void> stop() async {
    finalizada = true;
  }

  @override
  void putAttribute(String name, String value) {
    atributos[name] = value;
  }

  @override
  String? getAttribute(String name) => atributos[name];

  @override
  Map<String, String> getAttributes() => Map.unmodifiable(atributos);

  @override
  void removeAttribute(String name) {
    atributos.remove(name);
  }

  @override
  void setMetric(String name, int value) {
    metricas[name] = value;
  }

  @override
  int getMetric(String name) => metricas[name] ?? 0;

  @override
  void incrementMetric(String name, int value) {
    metricas[name] = (metricas[name] ?? 0) + value;
  }
}

/// Fake determinístico de [FirebasePerformance] para validar o contrato real sem rede.
class FakeFirebasePerformance extends Fake implements FirebasePerformance {
  bool? coletaHabilitada;
  bool lancarErroAoConfigurar = false;
  bool lancarErroNaTrace = false;
  final List<FakeTrace> tracesCriadas = [];

  @override
  Future<void> setPerformanceCollectionEnabled(bool enabled) async {
    if (lancarErroAoConfigurar) {
      throw Exception('Falha simulada no SDK Firebase Performance');
    }
    coletaHabilitada = enabled;
  }

  @override
  Future<bool> isPerformanceCollectionEnabled() async {
    return coletaHabilitada ?? false;
  }

  @override
  Trace newTrace(String name) {
    if (lancarErroNaTrace) {
      throw Exception('Falha simulada ao criar trace');
    }
    final trace = FakeTrace(name);
    tracesCriadas.add(trace);
    return trace;
  }

  @override
  HttpMetric newHttpMetric(String url, HttpMethod httpMethod) {
    throw UnimplementedError();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebasePerformance fakePerformance;
  late MockTelemetryService mockTelemetry;
  late MockAppLogger mockLogger;

  setUp(() {
    ServicoPerformance.resetarParaTestes();
    fakePerformance = FakeFirebasePerformance();
    mockTelemetry = MockTelemetryService();
    mockLogger = MockAppLogger();
    TelemetryService.instance = mockTelemetry;
    AppLogger.instance = mockLogger;
  });

  tearDown(() {
    ServicoPerformance.resetarParaTestes();
    AppLogger.resetForTesting();
  });

  group('ServicoPerformance - Bloqueio Estrito em Modo Debug', () {
    test(
      'desativa coleta do Firebase Performance e não envia traces quando emModoDebug é true',
      () async {
        await ServicoPerformance.instancia.inicializar(
          emModoDebug: true,
          performanceInstance: fakePerformance,
        );

        expect(ServicoPerformance.instancia.coletaAtiva, isFalse);
        expect(fakePerformance.coletaHabilitada, isFalse);

        await ServicoPerformance.instancia.registrarColdStartHome(
          duracaoMsOverride: 420,
        );

        // Não deve criar nenhuma trace no SDK nativo em modo debug
        expect(fakePerformance.tracesCriadas, isEmpty);
        // Mas registra no histórico local de diagnóstico e no AppLogger
        expect(ServicoPerformance.instancia.tracesRegistradas, hasLength(1));
        expect(
          ServicoPerformance.instancia.tracesRegistradas.first.enviadoAoFirebase,
          isFalse,
        );
      },
    );

    test(
      'ativa coleta do Firebase Performance e envia traces quando emModoDebug é false',
      () async {
        await ServicoPerformance.instancia.inicializar(
          emModoDebug: false,
          performanceInstance: fakePerformance,
        );

        expect(ServicoPerformance.instancia.coletaAtiva, isTrue);
        expect(fakePerformance.coletaHabilitada, isTrue);

        await ServicoPerformance.instancia.registrarColdStartHome(
          duracaoMsOverride: 510,
        );

        expect(fakePerformance.tracesCriadas, hasLength(1));
        final trace = fakePerformance.tracesCriadas.first;
        expect(trace.nome, equals('cold_start_home'));
        expect(trace.iniciada, isTrue);
        expect(trace.finalizada, isTrue);
        expect(trace.atributos['tipo_start'], equals('cold_start'));
        expect(trace.atributos['destino'], equals('home'));
        expect(trace.metricas['duracao_ms'], equals(510));

        expect(
          mockTelemetry.recordedEvents,
          contains('performance_abertura_app'),
        );
        expect(
          mockTelemetry.recordedParams['performance_abertura_app']!['duracao_ms'],
          equals(510),
        );
      },
    );

    test(
      'absorve falhas do SDK ao inicializar ou criar trace registrando logError sem quebrar o app',
      () async {
        fakePerformance.lancarErroAoConfigurar = true;
        await ServicoPerformance.instancia.inicializar(
          emModoDebug: false,
          performanceInstance: fakePerformance,
        );
        expect(mockLogger.recordedErrors, isNotEmpty);

        mockLogger.recordedErrors.clear();
        fakePerformance.lancarErroNaTrace = true;
        await ServicoPerformance.instancia.registrarTrace(
          'trace_com_falha',
          duracaoMs: 100,
        );
        expect(mockLogger.recordedErrors, isNotEmpty);
      },
    );
  });

  group('ServicoPerformance - Dupla Emissão das 8 Métricas e Truncamento', () {
    setUp(() async {
      await ServicoPerformance.instancia.inicializar(
        emModoDebug: false,
        performanceInstance: fakePerformance,
      );
    });

    test('trunca nomes de traces (>32 chars) e valores de atributos (>100 chars)', () async {
      final valorLongo = 'a' * 130;
      await ServicoPerformance.instancia.registrarTrace(
        'nome_de_trace_muito_longo_acima_de_trinta_e_dois_caracteres',
        duracaoMs: 150,
        atributos: {
          'chave_muito_longa_acima_de_quarenta_caracteres_limite': valorLongo,
        },
      );

      final trace = fakePerformance.tracesCriadas.single;
      expect(trace.nome.length, equals(32));
      final chaveTruncada = 'chave_muito_longa_acima_de_quarenta_caracteres_limite'.substring(0, 40);
      expect(trace.atributos[chaveTruncada]?.length, equals(100));
    });

    test('registrarColdStartHome é idempotente na sessão de abertura', () async {
      ServicoPerformance.instancia.iniciarCronometroColdStart();
      await ServicoPerformance.instancia.registrarColdStartHome();
      await ServicoPerformance.instancia.registrarColdStartHome();

      expect(fakePerformance.tracesCriadas, hasLength(1));
      expect(fakePerformance.tracesCriadas.single.nome, equals('cold_start_home'));
    });

    test('registrarAberturaDeepLink emite cold_start_deep_link e warm_start_deep_link com modo_acesso e duracao_ms', () async {
      await ServicoPerformance.instancia.registrarAberturaDeepLink(
        idCroqui: 'br_mg_igarape_pedra_grande',
        destino: 'via',
        sucesso: true,
        tipoStart: 'cold_start',
        duracaoMs: 890,
        modoAcesso: 'offline',
        origemLink: 'qrcode',
        abrirMapa: true,
        parametrosUtm: {'utm_source': 'placa'},
      );

      expect(fakePerformance.tracesCriadas.last.nome, equals('cold_start_deep_link'));
      expect(fakePerformance.tracesCriadas.last.atributos['modo_acesso'], equals('offline'));
      expect(fakePerformance.tracesCriadas.last.metricas['duracao_ms'], equals(890));
      expect(mockTelemetry.recordedParams['deep_link_aberto']!['duracao_ms'], equals(890));
      expect(mockTelemetry.recordedParams['deep_link_aberto']!['modo_acesso'], equals('offline'));

      await ServicoPerformance.instancia.registrarAberturaDeepLink(
        idCroqui: 'br_mg_igarape_pedra_grande',
        destino: 'setor',
        sucesso: true,
        tipoStart: 'warm_start',
        duracaoMs: 110,
        modoAcesso: 'memoria',
      );

      expect(fakePerformance.tracesCriadas.last.nome, equals('warm_start_deep_link'));
      expect(fakePerformance.tracesCriadas.last.atributos['modo_acesso'], equals('memoria'));
      expect(mockTelemetry.recordedParams['deep_link_aberto']!['duracao_ms'], equals(110));
    });

    test('registrarSyncIndexFase1 e registrarSyncIndexFase2 emitem traces e eventos fatiados', () async {
      await ServicoPerformance.instancia.registrarSyncIndexFase1(
        duracaoMs: 95,
        statusHttp: '304',
        origem: 'auto',
        modo: 'oficial',
      );

      final traceFase1 = fakePerformance.tracesCriadas.last;
      expect(traceFase1.nome, equals('sync_index_fase1'));
      expect(traceFase1.atributos['status_http'], equals('304'));
      expect(traceFase1.atributos['origem'], equals('auto'));
      expect(traceFase1.atributos['modo'], equals('oficial'));
      expect(
        mockTelemetry.recordedParams['performance_sync_index']!['status_http'],
        equals('304'),
      );

      await ServicoPerformance.instancia.registrarSyncIndexFase2(
        duracaoMs: 1420,
        teveAtualizacao: true,
        qtdPicosAtualizados: 2,
        qtdThumbs: 5,
      );

      final traceFase2 = fakePerformance.tracesCriadas.last;
      expect(traceFase2.nome, equals('sync_index_fase2'));
      expect(traceFase2.atributos['teve_atualizacao'], equals('true'));
      expect(traceFase2.metricas['qtd_picos_atualizados'], equals(2));
      expect(traceFase2.metricas['qtd_thumbs'], equals(5));
      expect(
        mockTelemetry.recordedParams['performance_sync_index']!['qtd_thumbs'],
        equals(5),
      );
    });

    test('registrarAbrirCroqui, registrarNavegacaoInternaCroqui e registrarAbrirMapaInterativo emitem traces e eventos GA4', () async {
      await ServicoPerformance.instancia.registrarAbrirCroqui(
        idCroqui: 'pico_1',
        origem: 'explorar',
        modoAcesso: 'temp_cache',
        primeiraVisita: true,
        duracaoMs: 45,
      );
      expect(fakePerformance.tracesCriadas.last.nome, equals('abrir_croqui'));
      expect(fakePerformance.tracesCriadas.last.atributos['modo_acesso'], equals('temp_cache'));
      expect(mockTelemetry.recordedParams['acao_croqui']!['duracao_ms'], equals(45));
      expect(mockTelemetry.recordedParams['acao_croqui']!['modo_acesso'], equals('temp_cache'));

      await ServicoPerformance.instancia.registrarNavegacaoInternaCroqui(
        idCroqui: 'pico_1',
        destino: 'setor',
        modoAcesso: 'offline',
        duracaoMs: 18,
        nomeSetor: 'Setor Principal',
      );
      expect(fakePerformance.tracesCriadas.last.nome, equals('navegacao_interna_croqui'));
      expect(mockTelemetry.recordedParams['abrir_setor']!['duracao_ms'], equals(18));
      expect(mockTelemetry.recordedParams['abrir_setor']!['modo_acesso'], equals('offline'));

      await ServicoPerformance.instancia.registrarNavegacaoInternaCroqui(
        idCroqui: 'pico_1',
        destino: 'grupo',
        modoAcesso: 'online',
        duracaoMs: 22,
        nomeGrupo: 'Grupo Norte',
      );
      expect(mockTelemetry.recordedParams['abrir_grupo']!['duracao_ms'], equals(22));
      expect(mockTelemetry.recordedParams['abrir_grupo']!['modo_acesso'], equals('online'));

      await ServicoPerformance.instancia.registrarNavegacaoInternaCroqui(
        idCroqui: 'pico_1',
        destino: 'via',
        modoAcesso: 'offline',
        duracaoMs: 15,
        nomeSetor: 'Setor Principal',
        nomeEscalada: 'Via Clássica',
        acaoEscalada: 'abrir_detalhes',
        origemEscalada: 'setor',
      );
      expect(mockTelemetry.recordedParams['acao_escalada']!['duracao_ms'], equals(15));
      expect(mockTelemetry.recordedParams['acao_escalada']!['modo_acesso'], equals('offline'));

      await ServicoPerformance.instancia.registrarAbrirMapaInterativo(
        idCroqui: 'pico_1',
        nomeSetor: 'Setor Principal',
        modoAcesso: 'offline',
        origemImagem: 'downloads',
        duracaoMs: 64,
      );
      expect(fakePerformance.tracesCriadas.last.nome, equals('abrir_mapa_interativo'));
      expect(fakePerformance.tracesCriadas.last.atributos['origem_imagem'], equals('downloads'));
      expect(mockTelemetry.recordedParams['abrir_mapa']!['duracao_ms'], equals(64));
      expect(mockTelemetry.recordedParams['abrir_mapa']!['origem_imagem'], equals('downloads'));
    });

    testWidgets('concluirMedicaoPosFrame aguarda o post-frame callback quando há frame agendado', (tester) async {
      bool concluido = false;
      final cronometro = Stopwatch()..start();

      await tester.pumpWidget(const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(),
      ));

      // Agenda um frame e registra a medição pós-frame
      WidgetsBinding.instance.scheduleFrame();
      ServicoPerformance.instancia.concluirMedicaoPosFrame(cronometro, (duracaoMs) {
        concluido = true;
      });

      expect(concluido, isFalse);
      await tester.pump();
      expect(concluido, isTrue);
    });

    test(
      'anexa automaticamente tier_dispositivo e ram_gb do ClassificadorDispositivo em todas as traces',
      () async {
        ClassificadorDispositivo.instancia.classificar(ramTotalMb: 3072);

        await ServicoPerformance.instancia.registrarColdStartHome(
          duracaoMsOverride: 380,
        );

        final trace = fakePerformance.tracesCriadas.last;
        expect(trace.atributos['tier_dispositivo'], equals('baixo'));
        expect(trace.atributos['ram_gb'], equals('3'));
      },
    );

    test(
      'monitora FrameTiming na sessão da tela e emite fluidez_sessao_tela com P95 e taxa de jank',
      () async {
        ClassificadorDispositivo.instancia.classificar(ramTotalMb: 3072);

        ServicoPerformance.instancia.iniciarMonitoramentoFluidez(
          'mapa_interativo',
        );

        // Gera 4 quadros: 3 rápidos (UI 5ms, Raster 6ms) e 1 com jank (UI 24ms, Raster 20ms)
        FrameTiming criarFrame({required int uiMs, required int rasterMs}) {
          return FrameTiming(
            vsyncStart: 0,
            buildStart: 0,
            buildFinish: uiMs * 1000,
            rasterStart: uiMs * 1000,
            rasterFinish: (uiMs + rasterMs) * 1000,
            rasterFinishWallTime: (uiMs + rasterMs) * 1000,
          );
        }

        ServicoPerformance.instancia.registrarAmostrasFrameTiming([
          criarFrame(uiMs: 5, rasterMs: 6),
          criarFrame(uiMs: 6, rasterMs: 7),
          criarFrame(uiMs: 8, rasterMs: 9),
          criarFrame(uiMs: 24, rasterMs: 20),
        ]);

        await ServicoPerformance.instancia.encerrarMonitoramentoFluidez(
          'mapa_interativo',
          idCroqui: 'pico_jank',
        );

        final trace = fakePerformance.tracesCriadas.last;
        expect(trace.nome, equals('fluidez_sessao_tela'));
        expect(trace.atributos['tela'], equals('mapa_interativo'));
        expect(trace.atributos['id_croqui'], equals('pico_jank'));
        expect(trace.atributos['tier_dispositivo'], equals('baixo'));
        expect(trace.atributos['ram_gb'], equals('3'));
        expect(trace.metricas['total_frames'], equals(4));
        expect(trace.metricas['frames_jank'], equals(1));
        expect(trace.metricas['taxa_jank_pct'], equals(25));
        expect(trace.metricas['p95_ui_ms'], equals(24));
        expect(trace.metricas['p95_raster_ms'], equals(20));

        expect(
          mockTelemetry.recordedEvents,
          contains('fluidez_sessao_tela'),
        );
        final params = mockTelemetry.recordedParams['fluidez_sessao_tela']!;
        expect(params['tela'], equals('mapa_interativo'));
        expect(params['id_croqui'], equals('pico_jank'));
        expect(params['total_frames'], equals(4));
        expect(params['frames_jank'], equals(1));
        expect(params['taxa_jank_pct'], equals(25));
        expect(params['p95_ui_ms'], equals(24));
        expect(params['p95_raster_ms'], equals(20));
      },
    );

    test(
      'encerrarMonitoramentoFluidez não emite trace nem evento quando nenhum quadro foi renderizado na sessão',
      () async {
        ServicoPerformance.instancia.iniciarMonitoramentoFluidez(
          'mapa_interativo',
        );
        await ServicoPerformance.instancia.encerrarMonitoramentoFluidez(
          'mapa_interativo',
        );

        expect(fakePerformance.tracesCriadas, isEmpty);
        expect(
          mockTelemetry.recordedEvents,
          isNot(contains('fluidez_sessao_tela')),
        );
      },
    );
  });
}
