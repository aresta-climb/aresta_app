// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/firebase/app_logger.dart';

/// Implementação simulada para evitar chamadas reais do Crashlytics durante testes
class MockAppLogger implements AppLogger {
  final List<Map<String, dynamic>> recordedErrors = [];
  final List<String> recordedInfos = [];
  final List<String> recordedWarnings = [];

  @override
  bool? debugModeOverride;

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
  }) {
    recordedErrors.add({
      'contextMessage': contextMessage,
      'error': error,
      'stackTrace': stackTrace,
      'fatal': fatal,
    });
  }

  @override
  void logCrash(
    String contextMessage, {
    dynamic error,
    required StackTrace stackTrace,
  }) {
    logError(
      contextMessage,
      error: error,
      stackTrace: stackTrace,
      fatal: true,
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
