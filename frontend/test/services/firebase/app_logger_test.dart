// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:io';
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

    test('logCrash deve registrar erro com fatal = true na instância mock', () {
      final exception = Exception('Falha crítica de download');

      AppLogger.instance.logCrash(
        'Falha no download offline',
        error: exception,
      );

      expect(mockLogger.recordedErrors.length, 1);
      expect(
        mockLogger.recordedErrors.first['contextMessage'],
        'Falha no download offline',
      );
      expect(mockLogger.recordedErrors.first['error'], exception);
      expect(mockLogger.recordedErrors.first['fatal'], isTrue);
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

    test(
      'logCrash deve enviar erro para Crashlytics com fatal = true',
      () async {
        AppLogger.resetForTesting();
        AppLogger.instance.debugModeOverride = false;

        bool crashlyticsCalled = false;
        bool? capturedFatal;
        String? capturedReason;

        AppLogger.instance.crashlyticsOverride =
            (
              exception,
              stack, {
              reason,
              printDetails = false,
              fatal = false,
            }) async {
              crashlyticsCalled = true;
              capturedReason = reason;
              capturedFatal = fatal;
            };

        AppLogger.instance.logCrash(
          'Falha crítica no sync offline',
          error: Exception('Checksum mismatch'),
        );

        expect(crashlyticsCalled, isTrue);
        expect(capturedReason, 'Falha crítica no sync offline');
        expect(capturedFatal, isTrue);
      },
    );

    test('isFalhaConexaoOuTimeout identifica corretamente exceções de rede e timeout', () {
      expect(AppLogger.isFalhaConexaoOuTimeout(const SocketException('Failed host lookup')), isTrue);
      expect(AppLogger.isFalhaConexaoOuTimeout(const HttpException('Connection closed')), isTrue);
      expect(AppLogger.isFalhaConexaoOuTimeout(const HandshakeException('Handshake failed')), isTrue);
      expect(AppLogger.isFalhaConexaoOuTimeout(TimeoutException('Timed out')), isTrue);
      expect(AppLogger.isFalhaConexaoOuTimeout('Exceção ao baixar: TimeoutException after 0:00:30'), isTrue);
      expect(AppLogger.isFalhaConexaoOuTimeout('SocketException: Network is unreachable'), isTrue);
      expect(AppLogger.isFalhaConexaoOuTimeout(Exception('Falha de rede')), isTrue);

      // Não são falhas de rede/timeout
      expect(AppLogger.isFalhaConexaoOuTimeout(Exception('Checksum SHA-256 mismatch')), isFalse);
      expect(AppLogger.isFalhaConexaoOuTimeout('HTTP 404 ao baixar arquivo'), isFalse);
      expect(AppLogger.isFalhaConexaoOuTimeout('HTTP 500 Erro Interno'), isFalse);
      expect(AppLogger.isFalhaConexaoOuTimeout(const FileSystemException('No space')), isFalse);
    });

    test(
      'logFalhaSyncOuDownload NÃO deve gerar crash (fatal = false) se for falha de conexão ou timeout',
      () async {
        AppLogger.resetForTesting();
        AppLogger.instance.debugModeOverride = false;

        bool? capturedFatal;

        AppLogger.instance.crashlyticsOverride =
            (
              exception,
              stack, {
              reason,
              printDetails = false,
              fatal = false,
            }) async {
              capturedFatal = fatal;
            };

        AppLogger.instance.logFalhaSyncOuDownload(
          'Falha ao baixar fotos do croqui',
          error: TimeoutException('Conexão instável'),
        );

        expect(capturedFatal, isFalse);
      },
    );

    test(
      'logFalhaSyncOuDownload DEVE gerar crash (fatal = true) se for erro de integridade, 404, 500 ou hash',
      () async {
        AppLogger.resetForTesting();
        AppLogger.instance.debugModeOverride = false;

        bool? capturedFatal;
        String? capturedReason;

        AppLogger.instance.crashlyticsOverride =
            (
              exception,
              stack, {
              reason,
              printDetails = false,
              fatal = false,
            }) async {
              capturedFatal = fatal;
              capturedReason = reason;
            };

        AppLogger.instance.logFalhaSyncOuDownload(
          'Falha definitiva no download do croqui pico_1',
          error: 'Checksum SHA-256 inválido para setor_1.webp',
        );

        expect(capturedFatal, isTrue);
        expect(capturedReason, contains('pico_1'));
      },
    );

    test('isFalhaConexaoOuTimeout identifica códigos de erro transitórios HTTP 502, 503, 504, 429 e Gateway Timeout', () {
      expect(AppLogger.isFalhaConexaoOuTimeout('HTTP 504 ao baixar https://serving.arestaclimb.com/crags/1/crag_sector_13.webp'), isTrue);
      expect(AppLogger.isFalhaConexaoOuTimeout('504 Gateway Timeout'), isTrue);
      expect(AppLogger.isFalhaConexaoOuTimeout('HTTP 502 Bad Gateway'), isTrue);
      expect(AppLogger.isFalhaConexaoOuTimeout('HTTP 503 Service Unavailable'), isTrue);
      expect(AppLogger.isFalhaConexaoOuTimeout('HTTP 429 Too Many Requests'), isTrue);
      expect(AppLogger.isFalhaConexaoOuTimeout(504), isTrue);
      expect(AppLogger.isFalhaConexaoOuTimeout(502), isTrue);
      expect(AppLogger.isFalhaConexaoOuTimeout(503), isTrue);
      expect(AppLogger.isFalhaConexaoOuTimeout(429), isTrue);

      // Erros não transitórios devem continuar retornando false
      expect(AppLogger.isFalhaConexaoOuTimeout('HTTP 404 Not Found'), isFalse);
      expect(AppLogger.isFalhaConexaoOuTimeout('HTTP 500 Internal Server Error'), isFalse);
      expect(AppLogger.isFalhaConexaoOuTimeout(404), isFalse);
      expect(AppLogger.isFalhaConexaoOuTimeout(500), isFalse);
    });

    test('logFalhaSyncOuDownload registra HTTP 504 com fatal = false', () async {
      AppLogger.resetForTesting();
      AppLogger.instance.debugModeOverride = false;

      bool? capturedFatal;
      dynamic capturedException;

      AppLogger.instance.crashlyticsOverride = (
        exception,
        stack, {
        reason,
        printDetails = false,
        fatal = false,
      }) async {
        capturedFatal = fatal;
        capturedException = exception;
      };

      AppLogger.instance.logFalhaSyncOuDownload(
        'Falha ao baixar imagem de setor: HTTP 504 ao baixar https://serving.arestaclimb.com/.../crag_sector_13.webp',
        error: 'HTTP 504 ao baixar https://serving.arestaclimb.com/.../crag_sector_13.webp',
      );

      expect(capturedFatal, isFalse,
          reason: 'Erros HTTP 504 transitórios não devem ser marcados como fatal');
      expect(capturedException.toString(), contains('504'));
    });
  });
}
