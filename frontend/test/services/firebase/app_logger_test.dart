// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import '../../mocks/mock_app_logger.dart';

void main() {
  group('AppLogger Mock Tests', () {
    late MockAppLogger mockLogger;

    setUp(() {
      mockLogger = MockAppLogger();
      AppLogger.instance = mockLogger;
    });

    test('Should record error in mock instance', () {
      final exception = Exception('Falha grave');
      final stack = StackTrace.fromString('linha 1, arquivo teste.dart');

      AppLogger.instance.logError(
        'Erro de teste',
        error: exception,
        stackTrace: stack,
      );

      expect(mockLogger.recordedErrors.length, 1);
      expect(
        mockLogger.recordedErrors.first['contextMessage'],
        'Erro de teste',
      );
      expect(mockLogger.recordedErrors.first['error'], exception);
      expect(mockLogger.recordedErrors.first['stackTrace'], stack);
    });
  });

  group('AppLogger Real Instance Tests (With Overrides)', () {
    test(
      'Should send error to Crashlytics when debug mode is disabled',
      () async {
        AppLogger.resetForTesting();

        // Simula modo release (debug false)
        AppLogger.instance.debugModeOverride = false;

        bool crashlyticsCalled = false;
        dynamic capturedException;
        String? capturedReason;

        // Injeta comportamento mock do Crashlytics
        AppLogger.instance.crashlyticsOverride =
            (
              exception,
              stack, {
              reason,
              printDetails = false,
              fatal = false,
            }) async {
              crashlyticsCalled = true;
              capturedException = exception;
              capturedReason = reason;
            };

        AppLogger.instance.logError(
          'Erro de produção fake',
          error: Exception('Crash'),
        );

        expect(crashlyticsCalled, isTrue);
        expect(capturedReason, 'Erro de produção fake');
        expect(capturedException.toString(), contains('Crash'));
      },
    );
  });
}
