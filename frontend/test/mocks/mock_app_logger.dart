// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:frontend/services/firebase/app_logger.dart';

/// Implementação simulada para evitar chamadas reais do Crashlytics/Sentry durante testes
class MockAppLogger implements AppLogger {
  final List<Map<String, dynamic>> recordedErrors = [];
  final List<String> recordedInfos = [];
  final List<String> recordedWarnings = [];

  @override
  bool? debugModeOverride;

  @override
  bool? ignorarAmbienteDeTestesOverride;

  @override
  Future<void> Function(
    dynamic,
    StackTrace?, {
    bool printDetails,
    dynamic reason,
    bool fatal,
  })?
  crashlyticsOverride;

  @override
  void Function(String)? crashlyticsLogOverride;

  @override
  void Function(Breadcrumb)? sentryBreadcrumbOverride;

  @override
  Future<void> Function(
    dynamic, {
    StackTrace? stackTrace,
    String? reason,
    bool fatal,
    Map<String, Map<String, dynamic>>? contextosExtras,
  })?
  sentryCaptureOverride;

  @override
  void logInfo(String mensagem) {
    recordedInfos.add(mensagem);
  }

  @override
  void logAviso(String mensagem) {
    recordedWarnings.add(mensagem);
  }

  @override
  void logError(
    String contextMessage, {
    dynamic error,
    required StackTrace stackTrace,
    bool fatal = false,
    Map<String, Map<String, dynamic>>? contextosExtras,
  }) {
    recordedErrors.add({
      'contextMessage': contextMessage,
      'error': error,
      'stackTrace': stackTrace,
      'fatal': fatal,
      'contextosExtras': contextosExtras,
    });
  }

  @override
  void logCrash(
    String contextMessage, {
    dynamic error,
    required StackTrace stackTrace,
    Map<String, Map<String, dynamic>>? contextosExtras,
  }) {
    logError(
      contextMessage,
      error: error,
      stackTrace: stackTrace,
      fatal: true,
      contextosExtras: contextosExtras,
    );
  }

  @override
  void logFalhaSyncOuDownload(
    String contextMessage, {
    dynamic error,
    required StackTrace stackTrace,
  }) {
    final ehConexaoOuTimeout =
        AppLogger.isFalhaConexaoOuTimeout(error) || AppLogger.isFalhaConexaoOuTimeout(contextMessage);

    if (ehConexaoOuTimeout) {
      final detalhe = error != null ? ' ($error)' : '';
      logAviso('$contextMessage$detalhe');
    } else {
      logCrash(
        contextMessage,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
