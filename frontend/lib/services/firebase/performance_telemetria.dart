// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'app_logger.dart';
import 'classificador_dispositivo.dart';
import 'telemetria.dart';

class _SessaoFluidez {
  final Stopwatch cronometro = Stopwatch()..start();
  final List<int> temposUiMs = [];
  final List<int> temposRasterMs = [];
  int framesJank = 0;
}

/// Representa uma trace de performance registrada durante a sessão para diagnóstico e testes.
class RegistroTracePerformance {
  /// Nome normalizado da trace (máx. 32 caracteres).
  final String nome;

  /// Duração medida em milissegundos.
  final int duracaoMs;

  /// Atributos categóricos de fatiamento (*slicing*).
  final Map<String, String> atributos;

  /// Métricas numéricas associadas à trace.
  final Map<String, int> metricas;

  /// Indica se a trace foi efetivamente transmitida ao SDK nativo do Firebase Performance.
  final bool enviadoAoFirebase;

  const RegistroTracePerformance({
    required this.nome,
    required this.duracaoMs,
    required this.atributos,
    required this.metricas,
    required this.enviadoAoFirebase,
  });
}

/// Serviço isolado responsável pela coleta de métricas de performance ponta a ponta
/// (*Time to Interactive*) com dupla emissão para o Firebase Performance e Google Analytics 4 (Looker Studio).
///
/// Em modo de depuração (`kDebugMode == true`), a coleta no SDK nativo do Firebase Performance
/// é estritamente desativada (`setPerformanceCollectionEnabled(false)`) e nenhuma trace é enviada,
/// mantendo apenas o registro informativo local no [AppLogger].
class ServicoPerformance {
  ServicoPerformance._construtorPrivado();

  /// Instância singleton do serviço de performance.
  static ServicoPerformance instancia = ServicoPerformance._construtorPrivado();

  /// Reseta o estado do serviço para isolamento entre testes.
  @visibleForTesting
  static void resetarParaTestes() {
    if (instancia._callbackTimingsRegistrado) {
      SchedulerBinding.instance.removeTimingsCallback(
        instancia.registrarAmostrasFrameTiming,
      );
    }
    instancia = ServicoPerformance._construtorPrivado();
  }

  @visibleForTesting
  FirebasePerformance? debugPerformance;

  bool _coletaAtiva = kReleaseMode;

  /// Indica se o envio de traces para o Firebase Performance está ativo (sempre `false` em modo debug).
  bool get coletaAtiva => _coletaAtiva;

  /// Histórico local das últimas traces registradas na sessão (limitado a 100 entradas).
  final List<RegistroTracePerformance> tracesRegistradas = [];

  Stopwatch? _cronometroColdStart;
  bool _coldStartConcluido = false;
  final Map<String, _SessaoFluidez> _sessoesFluidezAtivas = {};
  bool _callbackTimingsRegistrado = false;

  FirebasePerformance? _obterPerformance([FirebasePerformance? override]) =>
      override ??
      debugPerformance ??
      (AppLogger.firebaseInicializado ? FirebasePerformance.instance : null);

  /// Inicializa e configura a coleta do Firebase Performance respeitando o bloqueio fora de release (`!kReleaseMode`).
  Future<void> inicializar({
    bool? emModoDebug,
    FirebasePerformance? performanceInstance,
  }) async {
    final modoDebug = emModoDebug ?? !kReleaseMode;
    _coletaAtiva = !modoDebug;
    if (performanceInstance != null) {
      debugPerformance = performanceInstance;
    }

    try {
      final perf = _obterPerformance(performanceInstance);
      if (perf == null) {
        AppLogger.instance.logAviso(
          '⏱️ [Performance] Firebase não inicializado. Coleta nativa desativada.',
        );
        return;
      }
      await perf.setPerformanceCollectionEnabled(_coletaAtiva);
      if (modoDebug) {
        AppLogger.instance.logInfo(
          '⏱️ [Performance] Modo debug detectado: coleta do Firebase Performance desativada.',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        '⚠️ [Performance] Erro ao configurar coleta do Firebase Performance',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Inicia o cronômetro global de *Cold Start* logo na entrada de `main()`.
  void iniciarCronometroColdStart([Stopwatch? cronometroCustomizado]) {
    _cronometroColdStart = (cronometroCustomizado ?? Stopwatch())..start();
    _coldStartConcluido = false;
  }

  /// Garante que exista um cronômetro de *Cold Start* ativo caso `MyApp` seja montado diretamente.
  void garantirCronometroColdStartAtivo() {
    if (_cronometroColdStart == null && !_coldStartConcluido) {
      _cronometroColdStart = Stopwatch()..start();
    }
  }

  /// Retorna o tempo decorrido desde o início do *Cold Start* em milissegundos.
  int obterElapsedMsColdStart() {
    return _cronometroColdStart?.elapsedMilliseconds ?? 0;
  }

  /// Encerra o [cronometro] e executa [aoConcluir] após a renderização do frame agendado
  /// (`addPostFrameCallback`), ou imediatamente caso não haja árvore de widgets montada com frame agendado.
  Future<void> concluirMedicaoPosFrame(
    Stopwatch cronometro,
    FutureOr<void> Function(int duracaoMs) aoConcluir,
  ) async {
    final binding = WidgetsBinding.instance;
    if (binding.rootElement != null && binding.hasScheduledFrame) {
      binding.addPostFrameCallback((_) {
        cronometro.stop();
        aoConcluir(cronometro.elapsedMilliseconds);
      });
    } else {
      cronometro.stop();
      await aoConcluir(cronometro.elapsedMilliseconds);
    }
  }

  /// Registra uma trace customizada no Firebase Performance (quando [coletaAtiva] for `true`)
  /// e no log local de diagnóstico.
  Future<void> registrarTrace(
    String nome, {
    required int duracaoMs,
    Map<String, String>? atributos,
    Map<String, int>? metricas,
  }) async {
    final nomeNormalizado = nome.length > 32 ? nome.substring(0, 32) : nome;
    final atributosNormalizados = <String, String>{
      'tier_dispositivo': ClassificadorDispositivo.instancia.tierDispositivo,
      'ram_gb': ClassificadorDispositivo.instancia.ramGb,
    };
    if (atributos != null) {
      for (final entry in atributos.entries) {
        final chave =
            entry.key.length > 40 ? entry.key.substring(0, 40) : entry.key;
        final valor = entry.value.length > 100
            ? entry.value.substring(0, 100)
            : entry.value;
        atributosNormalizados[chave] = valor;
      }
    }

    final metricasNormalizadas = <String, int>{
      'duracao_ms': duracaoMs,
      ...?metricas,
    };

    AppLogger.instance.logInfo(
      '⏱️ [Performance] Trace: $nomeNormalizado | Duração: ${duracaoMs}ms | Atributos: $atributosNormalizados | Métricas: $metricasNormalizadas',
    );

    bool enviado = false;
    if (_coletaAtiva) {
      final perf = _obterPerformance();
      if (perf != null) {
        try {
          final trace = perf.newTrace(nomeNormalizado);
          await trace.start();
          for (final entry in atributosNormalizados.entries) {
            trace.putAttribute(entry.key, entry.value);
          }
          for (final entry in metricasNormalizadas.entries) {
            trace.setMetric(entry.key, entry.value);
          }
          await trace.stop();
          enviado = true;
        } catch (e, stackTrace) {
          AppLogger.instance.logError(
            '⚠️ [Performance] Erro ao enviar trace $nomeNormalizado',
            error: e,
            stackTrace: stackTrace,
          );
        }
      }
    }

    if (tracesRegistradas.length >= 100) {
      tracesRegistradas.removeAt(0);
    }
    tracesRegistradas.add(
      RegistroTracePerformance(
        nome: nomeNormalizado,
        duracaoMs: duracaoMs,
        atributos: atributosNormalizados,
        metricas: metricasNormalizadas,
        enviadoAoFirebase: enviado,
      ),
    );
  }

  /// 1. Registra a conclusão do *Cold Start* até a `HomePage` interativa (`cold_start_home`).
  Future<void> registrarColdStartHome({int? duracaoMsOverride}) async {
    if (_coldStartConcluido && duracaoMsOverride == null) return;
    _coldStartConcluido = true;
    _cronometroColdStart?.stop();
    final duracaoMs =
        duracaoMsOverride ?? (_cronometroColdStart?.elapsedMilliseconds ?? 0);

    await registrarTrace(
      'cold_start_home',
      duracaoMs: duracaoMs,
      atributos: {
        'tipo_start': 'cold_start',
        'destino': 'home',
      },
    );
    await TelemetryService.instance.logPerformanceAberturaApp(
      tipoStart: 'cold_start',
      destino: 'home',
      duracaoMs: duracaoMs,
    );
  }

  /// 2 e 3. Registra a abertura de um Deep Link em *Cold Start* (`cold_start_deep_link`)
  /// ou *Warm Start* (`warm_start_deep_link`) com dupla emissão.
  Future<void> registrarAberturaDeepLink({
    required String idCroqui,
    required String destino,
    required bool sucesso,
    required String tipoStart,
    required int duracaoMs,
    String? modoAcesso,
    String? origemLink,
    bool? abrirMapa,
    String? motivoErro,
    Map<String, String>? parametrosUtm,
    TelemetryService? servicoTelemetria,
  }) async {
    if (tipoStart == 'cold_start') {
      _coldStartConcluido = true;
      _cronometroColdStart?.stop();
    }

    final nomeTrace = tipoStart == 'cold_start'
        ? 'cold_start_deep_link'
        : 'warm_start_deep_link';

    await registrarTrace(
      nomeTrace,
      duracaoMs: duracaoMs,
      atributos: {
        'destino': destino,
        'sucesso': sucesso ? 'true' : 'false',
        'modo_acesso': ?modoAcesso,
        if (abrirMapa != null) 'abrir_mapa': abrirMapa ? 'true' : 'false',
        'origem_link': ?origemLink,
      },
    );

    final telemetria = servicoTelemetria ?? TelemetryService.instance;
    await telemetria.logDeepLinkAberto(
      idCroqui: idCroqui,
      destino: destino,
      sucesso: sucesso,
      tipoStart: tipoStart,
      origemLink: origemLink,
      abrirMapa: abrirMapa,
      motivoErro: motivoErro,
      modoAcesso: modoAcesso,
      duracaoMs: duracaoMs,
      parametrosUtm: parametrosUtm,
    );
  }

  /// 4. Registra a conclusão da Fase 1 do `syncIndex` (`indice.binarypb` + delta do `catalogo.db`).
  Future<void> registrarSyncIndexFase1({
    required int duracaoMs,
    required String statusHttp,
    required String origem,
    required String modo,
  }) async {
    await registrarTrace(
      'sync_index_fase1',
      duracaoMs: duracaoMs,
      atributos: {
        'fase': 'fase1_indice_catalogo',
        'status_http': statusHttp,
        'origem': origem,
        'modo': modo,
      },
    );
    await TelemetryService.instance.logPerformanceSyncIndex(
      fase: 'fase1_indice_catalogo',
      duracaoMs: duracaoMs,
      statusHttp: statusHttp,
      origem: origem,
      modo: modo,
    );
  }

  /// 5. Registra a conclusão da Fase 2 do `syncIndex` (atualização de thumbnails e croquis em segundo plano).
  Future<void> registrarSyncIndexFase2({
    required int duracaoMs,
    required bool teveAtualizacao,
    required int qtdPicosAtualizados,
    required int qtdThumbs,
  }) async {
    await registrarTrace(
      'sync_index_fase2',
      duracaoMs: duracaoMs,
      atributos: {
        'fase': 'fase2_midias_background',
        'teve_atualizacao': teveAtualizacao ? 'true' : 'false',
      },
      metricas: {
        'qtd_picos_atualizados': qtdPicosAtualizados,
        'qtd_thumbs': qtdThumbs,
      },
    );
    await TelemetryService.instance.logPerformanceSyncIndex(
      fase: 'fase2_midias_background',
      duracaoMs: duracaoMs,
      teveAtualizacao: teveAtualizacao,
      qtdPicosAtualizados: qtdPicosAtualizados,
      qtdThumbs: qtdThumbs,
    );
  }

  /// 6. Registra a abertura de um croqui até o primeiro frame da página do pico (`abrir_croqui`).
  Future<void> registrarAbrirCroqui({
    required String idCroqui,
    required String origem,
    required String modoAcesso,
    required bool primeiraVisita,
    required int duracaoMs,
  }) async {
    await registrarTrace(
      'abrir_croqui',
      duracaoMs: duracaoMs,
      atributos: {
        'id_croqui': idCroqui,
        'modo_acesso': modoAcesso,
        'origem': origem,
        'primeira_visita': primeiraVisita ? 'true' : 'false',
      },
    );
    await TelemetryService.instance.logAcaoCroqui(
      idCroqui,
      'abrir_croqui',
      origem: origem,
      modoAcesso: modoAcesso,
      primeiraVisita: primeiraVisita,
      duracaoMs: duracaoMs,
    );
  }

  /// 7. Registra a navegação interna dentro de um croqui (`setor`, `grupo` ou `via`) até o frame interativo.
  Future<void> registrarNavegacaoInternaCroqui({
    required String idCroqui,
    required String destino,
    required String modoAcesso,
    required int duracaoMs,
    String? nomeSetor,
    String? nomeGrupo,
    String? nomeEscalada,
    String? acaoEscalada,
    String? origemEscalada,
  }) async {
    await registrarTrace(
      'navegacao_interna_croqui',
      duracaoMs: duracaoMs,
      atributos: {
        'id_croqui': idCroqui,
        'destino': destino,
        'modo_acesso': modoAcesso,
      },
    );

    if (destino == 'setor') {
      await TelemetryService.instance.logAbrirSetor(
        idCroqui,
        nomeSetor ?? '',
        modoAcesso: modoAcesso,
        duracaoMs: duracaoMs,
      );
    } else if (destino == 'grupo') {
      await TelemetryService.instance.logAbrirGrupo(
        idCroqui,
        nomeGrupo ?? '',
        modoAcesso: modoAcesso,
        duracaoMs: duracaoMs,
      );
    } else if (destino == 'via') {
      await TelemetryService.instance.logAcaoEscalada(
        idCroqui,
        nomeSetor ?? '',
        nomeEscalada ?? '',
        acaoEscalada ?? 'abrir_detalhes',
        origemEscalada ?? 'setor',
        modoAcesso: modoAcesso,
        duracaoMs: duracaoMs,
      );
    }
  }

  /// 8. Registra a abertura e decodificação do primeiro frame de um mapa interativo (`abrir_mapa_interativo`).
  Future<void> registrarAbrirMapaInterativo({
    required String idCroqui,
    required String nomeSetor,
    required String modoAcesso,
    required String origemImagem,
    required int duracaoMs,
    bool enviarEventoAnalytics = true,
  }) async {
    await registrarTrace(
      'abrir_mapa_interativo',
      duracaoMs: duracaoMs,
      atributos: {
        'id_croqui': idCroqui,
        'modo_acesso': modoAcesso,
        'origem_imagem': origemImagem,
      },
    );
    if (enviarEventoAnalytics) {
      await TelemetryService.instance.logAbrirMapa(
        idCroqui,
        nomeSetor,
        modoAcesso: modoAcesso,
        origemImagem: origemImagem,
        duracaoMs: duracaoMs,
      );
    }
  }

  /// Inicia o monitoramento de fluidez de quadros (`FrameTiming`) para a sessão da [tela].
  void iniciarMonitoramentoFluidez(String tela) {
    _sessoesFluidezAtivas[tela] = _SessaoFluidez();
    if (!_callbackTimingsRegistrado) {
      _callbackTimingsRegistrado = true;
      SchedulerBinding.instance.addTimingsCallback(
        registrarAmostrasFrameTiming,
      );
    }
  }

  /// Callback receptor de [FrameTiming] do [SchedulerBinding], registrando tempos de UI e Raster
  /// nas sessões de tela ativas.
  void registrarAmostrasFrameTiming(List<FrameTiming> timings) {
    for (final timing in timings) {
      final int uiMs = timing.buildDuration.inMilliseconds;
      final int rasterMs = timing.rasterDuration.inMilliseconds;
      final bool teveJank = uiMs > 16 || rasterMs > 16;
      for (final sessao in _sessoesFluidezAtivas.values) {
        sessao.temposUiMs.add(uiMs);
        sessao.temposRasterMs.add(rasterMs);
        if (teveJank) {
          sessao.framesJank++;
        }
      }
    }
  }

  /// Encerra o monitoramento de fluidez da [tela] e emite a trace e o evento `fluidez_sessao_tela`
  /// caso pelo menos um quadro tenha sido renderizado durante a sessão.
  Future<void> encerrarMonitoramentoFluidez(
    String tela, {
    String? idCroqui,
  }) async {
    final sessao = _sessoesFluidezAtivas.remove(tela);
    if (_sessoesFluidezAtivas.isEmpty && _callbackTimingsRegistrado) {
      _callbackTimingsRegistrado = false;
      SchedulerBinding.instance.removeTimingsCallback(
        registrarAmostrasFrameTiming,
      );
    }
    if (sessao == null || sessao.temposUiMs.isEmpty) {
      return;
    }

    sessao.cronometro.stop();
    final int totalFrames = sessao.temposUiMs.length;
    final int framesJank = sessao.framesJank;
    final int taxaJankPct = ((framesJank * 100) / totalFrames).round();
    sessao.temposUiMs.sort();
    sessao.temposRasterMs.sort();
    final int indiceP95 =
        ((totalFrames * 0.95).ceil() - 1).clamp(0, totalFrames - 1);
    final int p95UiMs = sessao.temposUiMs[indiceP95];
    final int p95RasterMs = sessao.temposRasterMs[indiceP95];
    final int duracaoSessaoMs = sessao.cronometro.elapsedMilliseconds;

    await registrarTrace(
      'fluidez_sessao_tela',
      duracaoMs: duracaoSessaoMs,
      atributos: {
        'tela': tela,
        'id_croqui': ?idCroqui,
      },
      metricas: {
        'total_frames': totalFrames,
        'frames_jank': framesJank,
        'taxa_jank_pct': taxaJankPct,
        'p95_ui_ms': p95UiMs,
        'p95_raster_ms': p95RasterMs,
      },
    );
    await TelemetryService.instance.logFluidezSessaoTela(
      tela: tela,
      idCroqui: idCroqui,
      duracaoMs: duracaoSessaoMs,
      totalFrames: totalFrames,
      framesJank: framesJank,
      taxaJankPct: taxaJankPct,
      p95UiMs: p95UiMs,
      p95RasterMs: p95RasterMs,
    );
  }
}
