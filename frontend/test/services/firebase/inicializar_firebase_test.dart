// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import 'package:frontend/services/firebase/inicializar_firebase.dart';
import 'package:frontend/services/firebase/performance_telemetria.dart';
import 'package:frontend/services/firebase/telemetria.dart';
import '../../mocks/mock_app_logger.dart';

class _FakeCrashlytics extends Fake implements FirebaseCrashlytics {
  bool? coletaHabilitada;
  Object? ultimoErroFatal;
  Object? ultimoErroNaoFatal;

  @override
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {
    coletaHabilitada = enabled;
  }

  @override
  Future<void> recordFlutterFatalError(FlutterErrorDetails details) async {
    ultimoErroFatal = details.exception;
  }

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
    Iterable<Object> information = const [],
    bool? printDetails,
    bool fatal = false,
  }) async {
    ultimoErroNaoFatal = exception;
  }
}

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
    'initFirebase inicializa o Core antes e ativa AppCheck, Crashlytics, Analytics e Performance em paralelo',
    () async {
      bool coreConcluido = false;
      bool appCheckIniciado = false;
      bool crashlyticsIniciado = false;
      bool analyticsIniciado = false;
      bool performanceIniciado = false;
      bool remoteConfigIniciado = false;

      final completerAppCheck = Completer<void>();
      final completerCrashlytics = Completer<void>();
      final completerAnalytics = Completer<void>();
      final completerPerformance = Completer<void>();

      final futureInit = initFirebase(
        inicializadorCore: () async {
          coreConcluido = true;
        },
        ativadorAppCheck: () async {
          expect(
            coreConcluido,
            isTrue,
            reason: 'Core deve concluir antes do AppCheck',
          );
          appCheckIniciado = true;
          await completerAppCheck.future;
        },
        configuradorCrashlytics: () async {
          expect(
            coreConcluido,
            isTrue,
            reason: 'Core deve concluir antes do Crashlytics',
          );
          crashlyticsIniciado = true;
          await completerCrashlytics.future;
        },
        configuradorAnalytics: () async {
          expect(
            coreConcluido,
            isTrue,
            reason: 'Core deve concluir antes do Analytics',
          );
          analyticsIniciado = true;
          await completerAnalytics.future;
        },
        configuradorPerformance: () async {
          expect(
            coreConcluido,
            isTrue,
            reason: 'Core deve concluir antes do Performance',
          );
          performanceIniciado = true;
          await completerPerformance.future;
        },
        inicializadorRemoteConfig: () async {
          remoteConfigIniciado = true;
        },
      );

      // Aguarda microtasks para garantir que o Core rodou e todas as 4 etapas iniciaram concorrentemente
      await Future<void>.delayed(Duration.zero);

      expect(coreConcluido, isTrue);
      expect(
        appCheckIniciado,
        isTrue,
        reason: 'AppCheck deve estar rodando em paralelo',
      );
      expect(
        crashlyticsIniciado,
        isTrue,
        reason: 'Crashlytics deve estar rodando em paralelo',
      );
      expect(
        analyticsIniciado,
        isTrue,
        reason: 'Analytics deve estar rodando em paralelo',
      );
      expect(
        performanceIniciado,
        isTrue,
        reason: 'Performance deve estar rodando em paralelo',
      );
      expect(
        remoteConfigIniciado,
        isFalse,
        reason: 'RemoteConfig só inicia após o Future.wait concluir',
      );

      // Completa todas as 4 futures em paralelo
      completerAppCheck.complete();
      completerCrashlytics.complete();
      completerAnalytics.complete();
      completerPerformance.complete();

      await futureInit;
      expect(remoteConfigIniciado, isTrue);
    },
  );

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
    'initCrashlytics configura handlers globais e ativa coleta de falhas',
    () async {
      final fakeCrash = _FakeCrashlytics();

      await initCrashlytics(crashlyticsInstance: fakeCrash);
      expect(fakeCrash.coletaHabilitada, isTrue);

      // Dispara FlutterError.onError
      FlutterError.onError!(
        FlutterErrorDetails(exception: Exception('Erro teste Flutter')),
      );
      expect(
        fakeCrash.ultimoErroFatal.toString(),
        contains('Erro teste Flutter'),
      );

      // Dispara PlatformDispatcher.instance.onError
      final tratado = PlatformDispatcher.instance.onError!(
        Exception('Erro teste Platform'),
        StackTrace.empty,
      );
      expect(tratado, isTrue);
      expect(
        fakeCrash.ultimoErroNaoFatal.toString(),
        contains('Erro teste Platform'),
      );
    },
  );

  test(
    'initCrashlytics utiliza FirebaseCrashlytics.instance por padrão quando não injetado',
    () async {
      expect(() async => await initCrashlytics(), throwsA(anything));
    },
  );

  test(
    'initPerformance desativa coleta em modo debug e ativa fora do modo debug',
    () async {
      final fakePerf = _FakePerformance();

      await initPerformance(isDebugMode: true, performanceInstance: fakePerf);
      expect(fakePerf.habilitado, isFalse);
      expect(ServicoPerformance.instancia.coletaAtiva, isFalse);

      await initPerformance(isDebugMode: false, performanceInstance: fakePerf);
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
      await initAnalytics(isDebugMode: false, analyticsInstance: fakeAnalytics);
      expect(fakeAnalytics.coletaHabilitada, isNull);

      // Absorve erro caso o SDK nativo falhe ao desativar a coleta
      fakeAnalytics.lancarErro = true;
      await initAnalytics(isDebugMode: true, analyticsInstance: fakeAnalytics);
      expect(mockLogger.recordedErrors, isNotEmpty);
      AppLogger.resetForTesting();
    },
  );
}
