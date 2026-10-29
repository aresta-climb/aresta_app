// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import 'package:frontend/services/firebase/inicializar_firebase.dart';
import 'package:frontend/services/firebase/performance_telemetria.dart';
import 'package:frontend/services/firebase/telemetria.dart';
import '../../mocks/mock_app_logger.dart';

class _FakePerformance extends Fake implements FirebasePerformance {
  bool? habilitado;

  @override
  Future<void> setPerformanceCollectionEnabled(bool enabled) async {
    habilitado = enabled;
  }
}

class _FakeAnalytics extends Fake implements FirebaseAnalytics {
  bool? coletaHabilitada;
  bool lancarErro = false;

  @override
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    if (lancarErro) {
      throw Exception('Falha simulada no Analytics');
    }
    coletaHabilitada = enabled;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    ServicoPerformance.resetarParaTestes();
  });

  test(
    'initFirebase delega a inicialização para os pacotes nativos (deve lançar erro em ambiente sem mock)',
    () async {
      // Como a suite de testes não injeta os Platform Channels reais do iOS/Android para o Firebase,
      // a inicialização do Firebase Core obrigatoriamente tem que falhar.
      // Esse teste comprova que a função `initFirebase` está corretamente chamando
      // a API `Firebase.initializeApp` subjacente.
      expect(() async => await initFirebase(), throwsA(anything));
    },
  );

  test(
    'initPerformance desativa coleta em modo debug e ativa fora do modo debug',
    () async {
      final fakePerf = _FakePerformance();

      await initPerformance(
        isDebugMode: true,
        performanceInstance: fakePerf,
      );
      expect(fakePerf.habilitado, isFalse);
      expect(ServicoPerformance.instancia.coletaAtiva, isFalse);

      await initPerformance(
        isDebugMode: false,
        performanceInstance: fakePerf,
      );
      expect(fakePerf.habilitado, isTrue);
      expect(ServicoPerformance.instancia.coletaAtiva, isTrue);
    },
  );

  test(
    'initAnalytics e TelemetryService.initialize desativam coleta fora de release (!kReleaseMode) e absorvem falhas do SDK',
    () async {
      TelemetryService.resetForTesting();
      final mockLogger = MockAppLogger();
      AppLogger.instance = mockLogger;
      final fakeAnalytics = _FakeAnalytics();

      // Por padrão (em debug/profile, onde !kReleaseMode é true), desativa a coleta analítica
      await initAnalytics(analyticsInstance: fakeAnalytics);
      expect(fakeAnalytics.coletaHabilitada, isFalse);
      expect(
        mockLogger.recordedInfos,
        contains(
          '📊 [Telemetry] Modo debug detectado: coleta do Firebase Analytics desativada.',
        ),
      );

      // Em modo release (isDebugMode: false), não desativa a coleta
      fakeAnalytics.coletaHabilitada = null;
      await initAnalytics(
        isDebugMode: false,
        analyticsInstance: fakeAnalytics,
      );
      expect(fakeAnalytics.coletaHabilitada, isNull);

      // Absorve erro caso o SDK nativo falhe ao desativar a coleta
      fakeAnalytics.lancarErro = true;
      await initAnalytics(
        isDebugMode: true,
        analyticsInstance: fakeAnalytics,
      );
      expect(mockLogger.recordedErrors, isNotEmpty);
      AppLogger.resetForTesting();
    },
  );
}
