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

    test('Should record error in mock instance with required stackTrace', () {
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

    test('logCrash deve registrar erro com fatal = true e stackTrace na instância mock', () {
      final exception = Exception('Falha crítica de download');
      final stack = StackTrace.fromString('stack crash mock');

      AppLogger.instance.logCrash(
        'Falha no download offline',
        error: exception,
        stackTrace: stack,
      );

      expect(mockLogger.recordedErrors.length, 1);
      expect(
        mockLogger.recordedErrors.first['contextMessage'],
        'Falha no download offline',
      );
      expect(mockLogger.recordedErrors.first['error'], exception);
      expect(mockLogger.recordedErrors.first['stackTrace'], stack);
      expect(mockLogger.recordedErrors.first['fatal'], isTrue);
    });

    test('logInfo deve registrar mensagem informativa no MockAppLogger', () {
      AppLogger.instance.logInfo('Live reload conectado');

      expect(mockLogger.recordedInfos.length, 1);
      expect(mockLogger.recordedInfos.first, 'Live reload conectado');
    });

    test('logAviso deve registrar aviso no MockAppLogger', () {
      AppLogger.instance.logAviso(
        'Aviso de rede lenta',
      );

      expect(mockLogger.recordedWarnings.length, 1);
      expect(mockLogger.recordedWarnings.first, 'Aviso de rede lenta');
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
        StackTrace? capturedStack;

        final stack = StackTrace.fromString('stack trace de producao');

        // Injeta comportamento mock do Crashlytics
        AppLogger.instance.crashlyticsOverride =
            (
              exception,
              st, {
              reason,
              printDetails = false,
              fatal = false,
            }) async {
              crashlyticsCalled = true;
              capturedException = exception;
              capturedReason = reason;
              capturedStack = st;
            };

        AppLogger.instance.logError(
          'Erro de produção fake',
          error: Exception('Crash'),
          stackTrace: stack,
        );

        expect(crashlyticsCalled, isTrue);
        expect(capturedReason, 'Erro de produção fake');
        expect(capturedException.toString(), contains('Crash'));
        expect(capturedStack, stack);
      },
    );

    test(
      'logCrash deve enviar erro para Crashlytics com fatal = true e stackTrace',
      () async {
        AppLogger.resetForTesting();
        AppLogger.instance.debugModeOverride = false;

        bool crashlyticsCalled = false;
        bool? capturedFatal;
        String? capturedReason;
        StackTrace? capturedStack;

        final stack = StackTrace.fromString('stack crash real');

        AppLogger.instance.crashlyticsOverride =
            (
              exception,
              st, {
              reason,
              printDetails = false,
              fatal = false,
            }) async {
              crashlyticsCalled = true;
              capturedReason = reason;
              capturedFatal = fatal;
              capturedStack = st;
            };

        AppLogger.instance.logCrash(
          'Falha crítica no sync offline',
          error: Exception('Checksum mismatch'),
          stackTrace: stack,
        );

        expect(crashlyticsCalled, isTrue);
        expect(capturedReason, 'Falha crítica no sync offline');
        expect(capturedFatal, isTrue);
        expect(capturedStack, stack);
      },
    );

    test('logInfo deve registrar breadcrumb no Crashlytics em modo release', () {
      AppLogger.resetForTesting();
      AppLogger.instance.debugModeOverride = false;

      String? loggedMessage;
      AppLogger.instance.crashlyticsLogOverride = (msg) {
        loggedMessage = msg;
      };

      AppLogger.instance.logInfo('Iniciando download do croqui pico_1');

      expect(loggedMessage, 'Iniciando download do croqui pico_1');
    });

    test('logAviso deve registrar exclusivamente breadcrumb no Crashlytics em release sem chamar recordError', () {
      AppLogger.resetForTesting();
      AppLogger.instance.debugModeOverride = false;

      String? loggedMessage;
      AppLogger.instance.crashlyticsLogOverride = (msg) {
        loggedMessage = msg;
      };

      bool errorReported = false;
      AppLogger.instance.crashlyticsOverride = (
        exception,
        st, {
        reason,
        printDetails = false,
        fatal = false,
      }) async {
        errorReported = true;
      };

      AppLogger.instance.logAviso(
        'Instabilidade momentânea',
      );

      expect(loggedMessage, '⚠️ AVISO: Instabilidade momentânea');
      expect(errorReported, isFalse, reason: 'logAviso nunca deve acionar recordError no Crashlytics');
    });

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
      'logFalhaSyncOuDownload deve delegar para logAviso (breadcrumb) e NÃO gerar issue no Crashlytics se for falha de conexão ou timeout',
      () async {
        AppLogger.resetForTesting();
        AppLogger.instance.debugModeOverride = false;

        String? loggedBreadcrumb;
        AppLogger.instance.crashlyticsLogOverride = (msg) {
          loggedBreadcrumb = msg;
        };

        bool errorReported = false;
        final stack = StackTrace.fromString('stack timeout');

        AppLogger.instance.crashlyticsOverride = (
          exception,
          st, {
          reason,
          printDetails = false,
          fatal = false,
        }) async {
          errorReported = true;
        };

        AppLogger.instance.logFalhaSyncOuDownload(
          'Falha ao baixar fotos do croqui',
          error: TimeoutException('Conexão instável'),
          stackTrace: stack,
        );

        expect(errorReported, isFalse, reason: 'Timeouts não devem gerar issues no Crashlytics');
        expect(loggedBreadcrumb, contains('Falha ao baixar fotos do croqui'));
      },
    );

    test(
      'logFalhaSyncOuDownload DEVE gerar crash (fatal = true) se for erro de integridade, 404, 500 ou hash',
      () async {
        AppLogger.resetForTesting();
        AppLogger.instance.debugModeOverride = false;

        bool? capturedFatal;
        String? capturedReason;
        final stack = StackTrace.fromString('stack integridade');

        AppLogger.instance.crashlyticsOverride =
            (
              exception,
              st, {
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
          stackTrace: stack,
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

    test('logFalhaSyncOuDownload registra HTTP 504 como logAviso (breadcrumb) sem gerar issue no Crashlytics', () async {
      AppLogger.resetForTesting();
      AppLogger.instance.debugModeOverride = false;

      String? loggedBreadcrumb;
      AppLogger.instance.crashlyticsLogOverride = (msg) {
        loggedBreadcrumb = msg;
      };

      bool errorReported = false;
      final stack = StackTrace.fromString('stack 504');

      AppLogger.instance.crashlyticsOverride = (
        exception,
        st, {
        reason,
        printDetails = false,
        fatal = false,
      }) async {
        errorReported = true;
      };

      AppLogger.instance.logFalhaSyncOuDownload(
        'Falha ao baixar imagem de setor: HTTP 504 ao baixar https://serving.arestaclimb.com/.../crag_sector_13.webp',
        error: 'HTTP 504 ao baixar https://serving.arestaclimb.com/.../crag_sector_13.webp',
        stackTrace: stack,
      );

      expect(errorReported, isFalse,
          reason: 'Erros HTTP 504 transitórios não devem gerar issue no Crashlytics');
      expect(loggedBreadcrumb, contains('504'));
    });
  });
}
