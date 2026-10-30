// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import '../../firebase_options.dart';
import 'validador_app.dart';
import 'remote_config.dart';
import 'telemetria.dart';
import 'performance_telemetria.dart';

/// Inicializa os serviços do Firebase e os configura globalmente.
/// Esta função encapsula todo o contato direto com a API core do Firebase.
Future<void> initFirebase({
  Future<void> Function()? inicializadorCore,
  Future<void> Function()? ativadorAppCheck,
  Future<void> Function()? configuradorCrashlytics,
  Future<void> Function()? configuradorAnalytics,
  Future<void> Function()? configuradorPerformance,
  Future<void> Function()? inicializadorRemoteConfig,
}) async {
  // Inicialização básica do Core primeiro (seguro para isolates secundários)
  if (inicializadorCore != null) {
    await inicializadorCore();
  } else if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }

  // Ativação paralela das configurações e integrações locais independentes
  await Future.wait([
    (ativadorAppCheck ?? AppCheckService.instance.activate)(),
    (configuradorCrashlytics ?? initCrashlytics)(),
    (configuradorAnalytics ?? initAnalytics)(),
    (configuradorPerformance ?? initPerformance)(),
  ]);

  // Dispara o carregamento de configurações remotas sem bloquear a inicialização principal
  (inicializadorRemoteConfig ?? RemoteConfigService.instance.initialize)();
}

/// Inicializa e configura o Crashlytics. Extraído para permitir injeção de dependências nos testes.
Future<void> initCrashlytics({
  bool? isDebugMode,
  FirebaseCrashlytics? crashlyticsInstance,
}) async {
  final crashlytics = crashlyticsInstance ?? FirebaseCrashlytics.instance;

  // Crashlytics global handlers - mantido sempre ativo tanto em desenvolvimento quanto em produção
  await crashlytics.setCrashlyticsCollectionEnabled(true);
  FlutterError.onError = crashlytics.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    crashlytics.recordError(error, stack, fatal: true);
    return true;
  };
}

/// Inicializa e configura o Analytics. Extraído para permitir injeção de dependências nos testes.
Future<void> initAnalytics({
  bool? isDebugMode,
  FirebaseAnalytics? analyticsInstance,
}) async {
  await TelemetryService.instance.initialize(
    isDebugMode: isDebugMode,
    analyticsInstance: analyticsInstance,
  );
}

/// Inicializa e configura o Firebase Performance (desativando a coleta em modo debug).
Future<void> initPerformance({
  bool? isDebugMode,
  FirebasePerformance? performanceInstance,
}) async {
  await ServicoPerformance.instancia.inicializar(
    emModoDebug: isDebugMode,
    performanceInstance: performanceInstance,
  );
}
