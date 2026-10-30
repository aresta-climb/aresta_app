// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import 'package:frontend/services/http/cliente_http_aresta.dart';
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

    test('Deve enviar erro para Crashlytics mesmo quando modo debug está ativado (debugModeOverride = true)', () async {
      AppLogger.resetForTesting();
      AppLogger.instance.debugModeOverride = true;

      bool crashlyticsCalled = false;
      dynamic capturedException;
      String? capturedReason;
      StackTrace? capturedStack;

      final stack = StackTrace.fromString('stack trace de desenvolvimento');

      AppLogger.instance.crashlyticsOverride = (
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
        'Erro em modo desenvolvimento',
        error: Exception('Falha dev'),
        stackTrace: stack,
      );

      expect(crashlyticsCalled, isTrue);
      expect(capturedReason, 'Erro em modo desenvolvimento');
      expect(capturedException.toString(), contains('Falha dev'));
      expect(capturedStack, stack);
    });

    test('logCrash deve enviar erro fatal para Crashlytics mesmo quando debugModeOverride = true', () async {
      AppLogger.resetForTesting();
      AppLogger.instance.debugModeOverride = true;

      bool crashlyticsCalled = false;
      bool? capturedFatal;
      String? capturedReason;
      StackTrace? capturedStack;

      final stack = StackTrace.fromString('stack crash dev');

      AppLogger.instance.crashlyticsOverride = (
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
        'Falha crítica em dev',
        error: Exception('Erro grave'),
        stackTrace: stack,
      );

      expect(crashlyticsCalled, isTrue);
      expect(capturedReason, 'Falha crítica em dev');
      expect(capturedFatal, isTrue);
      expect(capturedStack, stack);
    });

    test('logInfo deve registrar breadcrumb no Crashlytics quando modo debug está ativado (debugModeOverride = true)', () {
      AppLogger.resetForTesting();
      AppLogger.instance.debugModeOverride = true;

      String? loggedMessage;
      AppLogger.instance.crashlyticsLogOverride = (msg) {
        loggedMessage = msg;
      };

      AppLogger.instance.logInfo('Info em ambiente dev');

      expect(loggedMessage, 'Info em ambiente dev');
    });

    test('logAviso deve registrar breadcrumb no Crashlytics quando modo debug está ativado (debugModeOverride = true)', () {
      AppLogger.resetForTesting();
      AppLogger.instance.debugModeOverride = true;

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

      AppLogger.instance.logAviso('Aviso em ambiente dev');

      expect(loggedMessage, '⚠️ AVISO: Aviso em ambiente dev');
      expect(errorReported, isFalse);
    });

    test('Não deve tentar acessar FirebaseCrashlytics.instance nativo em ambiente de teste quando overrides forem nulos', () {
      AppLogger.resetForTesting();
      expect(AppLogger.instance.crashlyticsOverride, isNull);
      expect(AppLogger.instance.crashlyticsLogOverride, isNull);

      expect(() => AppLogger.instance.logInfo('Info sem Firebase'), returnsNormally);
      expect(() => AppLogger.instance.logAviso('Aviso sem Firebase'), returnsNormally);
      expect(
        () => AppLogger.instance.logError(
          'Erro sem Firebase',
          stackTrace: StackTrace.current,
        ),
        returnsNormally,
      );
    });

    test('isFalhaConexaoOuTimeout identifica corretamente exceções de rede e timeout', () {
      expect(AppLogger.isFalhaConexaoOuTimeout(const SocketException('Failed host lookup')), isTrue);
      expect(AppLogger.isFalhaConexaoOuTimeout(const HttpException('Connection closed')), isTrue);
      expect(AppLogger.isFalhaConexaoOuTimeout(const HandshakeException('Handshake failed')), isTrue);
      expect(AppLogger.isFalhaConexaoOuTimeout(TimeoutException('Timed out')), isTrue);
      expect(AppLogger.isFalhaConexaoOuTimeout(ClientException('Connection reset by peer')), isTrue);
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

    test('isFalhaConexaoOuTimeout reconhece falhas de rede nativas de SDKs do Firebase (Remote Config, Installations e App Check)', () {
      expect(
        AppLogger.isFalhaConexaoOuTimeout(
          FirebaseException(
            plugin: 'firebase_remote_config',
            code: 'internal',
            message: 'Firebase Installations failed to get installation auth token for fetch.',
          ),
        ),
        isTrue,
      );
      expect(
        AppLogger.isFalhaConexaoOuTimeout(
          FirebaseException(
            plugin: 'firebase_remote_config',
            code: 'internal',
            message: 'The client had an error while calling the backend!',
          ),
        ),
        isTrue,
      );
      expect(
        AppLogger.isFalhaConexaoOuTimeout(
          FirebaseException(
            plugin: 'firebase_remote_config',
            code: 'internal',
            message: 'Unable to connect to the server. Check your connection and try again.',
          ),
        ),
        isTrue,
      );
      expect(
        AppLogger.isFalhaConexaoOuTimeout(
          FirebaseException(
            plugin: 'firebase_remote_config',
            code: 'internal',
            message: 'Fetch failed: server returned error.',
          ),
        ),
        isTrue,
      );
      expect(
        AppLogger.isFalhaConexaoOuTimeout(
          FirebaseException(
            plugin: 'firebase_app_check',
            code: 'unavailable',
            message: 'Service unavailable',
          ),
        ),
        isTrue,
      );
      expect(
        AppLogger.isFalhaConexaoOuTimeout(
          FirebaseException(
            plugin: 'firebase_auth',
            code: 'network-request-failed',
            message: 'A network error has occurred.',
          ),
        ),
        isTrue,
      );
      expect(
        AppLogger.isFalhaConexaoOuTimeout(
          FirebaseException(
            plugin: 'firebase_remote_config',
            code: 'throttled',
            message: 'Fetch throttled.',
          ),
        ),
        isTrue,
      );

      // Exceções do Firebase não relacionadas a conectividade/indisponibilidade devem retornar false
      expect(
        AppLogger.isFalhaConexaoOuTimeout(
          FirebaseException(
            plugin: 'firebase_core',
            code: 'permission-denied',
            message: 'Missing or insufficient permissions.',
          ),
        ),
        isFalse,
      );
    });

    test(
      'logInfo e logAviso devem enviar breadcrumbs simultaneamente para o Crashlytics e para o Sentry',
      () {
        AppLogger.resetForTesting();
        AppLogger.instance.debugModeOverride = false;

        final logsCrashlytics = <String>[];
        final breadcrumbsSentry = <Breadcrumb>[];

        AppLogger.instance.crashlyticsLogOverride = logsCrashlytics.add;
        AppLogger.instance.sentryBreadcrumbOverride = breadcrumbsSentry.add;

        AppLogger.instance.logInfo('Catálogo sincronizado com sucesso');
        AppLogger.instance.logAviso('Latência elevada na CDN');

        expect(logsCrashlytics, [
          'Catálogo sincronizado com sucesso',
          '⚠️ AVISO: Latência elevada na CDN',
        ]);
        expect(breadcrumbsSentry.length, 2);
        expect(breadcrumbsSentry[0].message, 'Catálogo sincronizado com sucesso');
        expect(breadcrumbsSentry[0].level, SentryLevel.info);
        expect(breadcrumbsSentry[1].message, '⚠️ AVISO: Latência elevada na CDN');
        expect(breadcrumbsSentry[1].level, SentryLevel.warning);
      },
    );

    test(
      'logError e logCrash devem enviar exceções com StackTrace simultaneamente para o Crashlytics e para o Sentry',
      () async {
        AppLogger.resetForTesting();
        AppLogger.instance.debugModeOverride = false;

        final errosCrashlytics = <Map<String, dynamic>>[];
        final errosSentry = <Map<String, dynamic>>[];

        AppLogger.instance.crashlyticsOverride =
            (exception, st, {reason, printDetails = false, fatal = false}) async {
          errosCrashlytics.add({
            'exception': exception,
            'stackTrace': st,
            'reason': reason,
            'fatal': fatal,
          });
        };

        AppLogger.instance.sentryCaptureOverride =
            (exception, {stackTrace, reason, fatal = false, contextosExtras}) async {
          errosSentry.add({
            'exception': exception,
            'stackTrace': stackTrace,
            'reason': reason,
            'fatal': fatal,
          });
        };

        final stackNaoFatal = StackTrace.fromString('stack nao fatal');
        final stackFatal = StackTrace.fromString('stack fatal');

        AppLogger.instance.logError(
          'Falha ao decodificar manifesto local',
          error: const FormatException('Protobuf truncado'),
          stackTrace: stackNaoFatal,
        );

        AppLogger.instance.logCrash(
          'Corrupção detectada no arquivo de índice',
          error: null,
          stackTrace: stackFatal,
        );

        expect(errosCrashlytics.length, 2);
        expect(errosSentry.length, 2);

        expect(errosSentry[0]['reason'], 'Falha ao decodificar manifesto local');
        expect(errosSentry[0]['stackTrace'], stackNaoFatal);
        expect(errosSentry[0]['fatal'], isFalse);

        expect(errosSentry[1]['reason'], 'Corrupção detectada no arquivo de índice');
        expect(errosSentry[1]['stackTrace'], stackFatal);
        expect(errosSentry[1]['fatal'], isTrue);
        expect(
          errosSentry[1]['exception'].toString(),
          contains('Corrupção detectada no arquivo de índice'),
        );
      },
    );

    test(
      'logFalhaSyncOuDownload não deve abrir issue no Sentry nem no Crashlytics quando for falha de conexão ou timeout',
      () {
        AppLogger.resetForTesting();
        AppLogger.instance.debugModeOverride = false;

        final breadcrumbsSentry = <Breadcrumb>[];
        var capturouExcecaoSentry = false;

        AppLogger.instance.sentryBreadcrumbOverride = breadcrumbsSentry.add;
        AppLogger.instance.sentryCaptureOverride =
            (exception, {stackTrace, reason, fatal = false, contextosExtras}) async {
          capturouExcecaoSentry = true;
        };

        AppLogger.instance.logFalhaSyncOuDownload(
          'Falha ao baixar imagem',
          error: const SocketException('Sem rota para o host'),
          stackTrace: StackTrace.fromString('stack socket'),
        );

        expect(capturouExcecaoSentry, isFalse);
        expect(breadcrumbsSentry.length, 1);
        expect(breadcrumbsSentry.first.level, SentryLevel.warning);
        expect(breadcrumbsSentry.first.message, contains('Sem rota para o host'));
      },
    );

    test(
      'Executa caminhos nativos de fallback com segurança quando ignorarAmbienteDeTestesOverride está ativo',
      () async {
        AppLogger.resetForTesting();
        AppLogger.instance.debugModeOverride = false;
        AppLogger.instance.ignorarAmbienteDeTestesOverride = false;

        // Com ignorarAmbienteDeTestesOverride = false e sem SDK inicializado, consulta firebaseInicializado / Sentry.isEnabled
        expect(() => AppLogger.instance.logInfo('Checagem estado inicializado'), returnsNormally);
        expect(
          () => AppLogger.instance.logError(
            'Checagem erro estado inicializado',
            stackTrace: StackTrace.fromString('stack'),
          ),
          returnsNormally,
        );

        AppLogger.resetForTesting();
        AppLogger.instance.debugModeOverride = true;
        AppLogger.instance.ignorarAmbienteDeTestesOverride = true;

        expect(AppLogger.firebaseInicializado, isFalse);

        // Quando callbacks de override lançam erro ou SDK nativo não está inicializado,
        // o AppLogger deve capturar internamente sem propagar exceção para a aplicação
        AppLogger.instance.crashlyticsLogOverride = (_) => throw StateError('Falha simulada Crashlytics log');
        AppLogger.instance.sentryBreadcrumbOverride = (_) => throw StateError('Falha simulada Sentry breadcrumb');
        AppLogger.instance.crashlyticsOverride = (_, _, {reason, printDetails = false, fatal = false}) =>
            throw StateError('Falha simulada Crashlytics recordError');
        AppLogger.instance.sentryCaptureOverride = (_, {stackTrace, reason, fatal = false, contextosExtras}) =>
            throw StateError('Falha simulada Sentry capture');

        expect(() => AppLogger.instance.logInfo('Teste resiliência info'), returnsNormally);
        expect(() => AppLogger.instance.logAviso('Teste resiliência aviso'), returnsNormally);
        expect(
          () => AppLogger.instance.logError(
            'Teste resiliência erro',
            stackTrace: StackTrace.fromString('stack resiliencia'),
          ),
          returnsNormally,
        );

        // Exercita chamadas diretas ao SDK Sentry com Hub inicializado em memória
        await Sentry.init((options) {
          options.dsn = 'https://examplePublicKey@o0.ingest.sentry.io/0';
        });
        addTearDown(() async => await Sentry.close());

        AppLogger.resetForTesting();
        AppLogger.instance.debugModeOverride = false;
        AppLogger.instance.ignorarAmbienteDeTestesOverride = true;

        expect(() => AppLogger.instance.logInfo('Breadcrumb direto Sentry'), returnsNormally);
        expect(() => AppLogger.instance.logAviso('Aviso direto Sentry'), returnsNormally);
        expect(
          () => AppLogger.instance.logError(
            'Erro direto Sentry',
            error: Exception('Exceção direta'),
            stackTrace: StackTrace.fromString('stack direta'),
            fatal: true,
          ),
          returnsNormally,
        );
      },
    );

    test(
      'Constantes centralizadas de modo de compilação refletem kModoDesenvolvimento e kModoReleaseOficial',
      () {
        expect(kReleaseLocal, isFalse);
        expect(kModoReleaseOficial, isFalse);
        expect(kModoDesenvolvimento, isTrue);
        expect(kModoDesenvolvimento, equals(!kModoReleaseOficial));
      },
    );

    test(
      'configurarEscopoSentry, logError e logCrash anexam contextosExtras no Scope do Sentry preservando contexto_erro e breadcrumbs',
      () async {
        final options = SentryOptions(
          dsn: 'https://examplePublicKey@o0.ingest.sentry.io/0',
        );
        final scope = Scope(options);
        final receitaMock = <String, dynamic>{
          'seed': 849201,
          'dataset': 'toxico',
          'passos_minimos': [
            {'acao': 'tap', 'alvo': 'BackButton'},
          ],
        };

        AppLogger.configurarEscopoSentry(
          scope,
          'Crash encontrado pelo Robô Caótico',
          fatal: true,
          contextosExtras: {'receita_robo_caotico': receitaMock},
        );

        expect(scope.level, SentryLevel.fatal);
        expect(scope.contexts['contexto_erro'], {
          'mensagem': 'Crash encontrado pelo Robô Caótico',
          'fatal': true,
        });
        expect(scope.contexts['receita_robo_caotico'], receitaMock);

        // Verifica também via logCrash / logError com sentryCaptureOverride e MockAppLogger
        AppLogger.resetForTesting();
        Map<String, Map<String, dynamic>>? contextosCapturados;
        AppLogger.instance.sentryCaptureOverride = (
          exception, {
          stackTrace,
          reason,
          fatal = false,
          contextosExtras,
        }) async {
          contextosCapturados = contextosExtras;
        };

        AppLogger.instance.logCrash(
          'Crash no robô caótico',
          error: StateError('Elemento desmontado'),
          stackTrace: StackTrace.fromString('stack robo'),
          contextosExtras: {'receita_robo_caotico': receitaMock},
        );

        expect(contextosCapturados, isNotNull);
        expect(contextosCapturados!['receita_robo_caotico'], receitaMock);

        final mockLogger = MockAppLogger();
        AppLogger.instance = mockLogger;
        AppLogger.instance.logCrash(
          'Crash mock com receita',
          error: StateError('Erro'),
          stackTrace: StackTrace.fromString('stack'),
          contextosExtras: {'receita_robo_caotico': receitaMock},
        );
        expect(
          mockLogger.recordedErrors.last['contextosExtras'],
          {'receita_robo_caotico': receitaMock},
        );
      },
    );
  });
}
