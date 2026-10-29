// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

// ignore_for_file: deprecated_member_use

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import 'package:frontend/services/firebase/validador_app.dart';
import '../../mocks/mock_app_logger.dart';

class FakeFirebaseAppCheck extends Fake implements FirebaseAppCheck {
  AndroidAppCheckProvider? ultimoProviderAndroid;
  AppleAppCheckProvider? ultimoProviderApple;
  bool? ultimoForceRefresh;
  String? tokenParaRetornar = 'fake-jwt-app-check-token';
  Object? erroNoActivate;
  Object? erroNoGetToken;

  @override
  Future<void> activate({
    ReCaptchaV3Provider? webProvider,
    AndroidProvider? androidProvider,
    AppleProvider? appleProvider,
    AndroidAppCheckProvider? providerAndroid,
    AppleAppCheckProvider? providerApple,
    dynamic providerWeb,
    dynamic providerWindows,
  }) async {
    if (erroNoActivate != null) {
      throw erroNoActivate!;
    }
    ultimoProviderAndroid = providerAndroid;
    ultimoProviderApple = providerApple;
  }

  @override
  Future<String?> getToken([bool? forceRefresh]) async {
    ultimoForceRefresh = forceRefresh;
    if (erroNoGetToken != null) {
      throw erroNoGetToken!;
    }
    return tokenParaRetornar;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseAppCheck fakeFirebaseAppCheck;
  late AppCheckService service;
  late MockAppLogger mockLogger;

  setUp(() {
    fakeFirebaseAppCheck = FakeFirebaseAppCheck();
    service = AppCheckService.instance;
    service.debugAppCheck = fakeFirebaseAppCheck;
    mockLogger = MockAppLogger();
    AppLogger.instance = mockLogger;
  });

  group('AppCheckService', () {
    test(
      'activate usa DebugProvider fora do modo release (debug e profile) e PlayIntegrity/AppAttest em release',
      () async {
        await service.activate(emModoRelease: false);
        expect(
          fakeFirebaseAppCheck.ultimoProviderAndroid,
          isA<AndroidDebugProvider>(),
        );
        expect(
          fakeFirebaseAppCheck.ultimoProviderApple,
          isA<AppleDebugProvider>(),
        );

        await service.activate(emModoRelease: true);
        expect(
          fakeFirebaseAppCheck.ultimoProviderAndroid,
          isA<AndroidPlayIntegrityProvider>(),
        );
        expect(
          fakeFirebaseAppCheck.ultimoProviderApple,
          isA<AppleAppAttestProvider>(),
        );
      },
    );

    test('activate captura erros graciosamente sem lançar exceções', () async {
      fakeFirebaseAppCheck.erroNoActivate = Exception(
        'Falha de ativação simulada',
      );

      await expectLater(service.activate(), completes);
      expect(mockLogger.recordedErrors, hasLength(1));
    });

    test('getToken retorna o token com sucesso quando disponível', () async {
      final token = await service.getToken();

      expect(token, 'fake-jwt-app-check-token');
      expect(fakeFirebaseAppCheck.ultimoForceRefresh, isFalse);
    });

    test('getToken com forceRefresh passa true para o SDK', () async {
      fakeFirebaseAppCheck.tokenParaRetornar = 'refreshed-jwt-token';

      final token = await service.getToken(true);

      expect(token, 'refreshed-jwt-token');
      expect(fakeFirebaseAppCheck.ultimoForceRefresh, isTrue);
    });

    test(
      'getToken retorna null e registra logError quando o SDK lança exceção não relacionada a rede',
      () async {
        fakeFirebaseAppCheck.erroNoGetToken = Exception('Token fetch error');

        final token = await service.getToken();

        expect(token, isNull);
        expect(mockLogger.recordedErrors, hasLength(1));
        expect(mockLogger.recordedWarnings, isEmpty);
      },
    );

    test(
      'getToken retorna null e registra logAviso (sem logError) quando a falha for de rede ou indisponibilidade',
      () async {
        fakeFirebaseAppCheck.erroNoGetToken = FirebaseException(
          plugin: 'firebase_app_check',
          code: 'unavailable',
          message: 'Unable to connect to the server.',
        );

        final token = await service.getToken();

        expect(token, isNull);
        expect(mockLogger.recordedWarnings, hasLength(1));
        expect(mockLogger.recordedWarnings.first, contains('AppCheck'));
        expect(mockLogger.recordedErrors, isEmpty);
      },
    );
  });
}
