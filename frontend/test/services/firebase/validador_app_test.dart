// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

// ignore_for_file: deprecated_member_use

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import 'package:frontend/services/firebase/validador_app.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:mocktail/mocktail.dart';
import '../../mocks/mock_app_logger.dart';

class MockFirebaseAppCheck extends Mock implements FirebaseAppCheck {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(const AndroidDebugProvider());
    registerFallbackValue(const AppleDebugProvider());
  });

  late MockFirebaseAppCheck mockFirebaseAppCheck;
  late AppCheckService service;
  late MockAppLogger mockLogger;

  setUp(() {
    mockFirebaseAppCheck = MockFirebaseAppCheck();
    service = AppCheckService.instance;
    service.debugAppCheck = mockFirebaseAppCheck;
    mockLogger = MockAppLogger();
    AppLogger.instance = mockLogger;
  });

  group('AppCheckService', () {
    test('activate deve chamar activate no FirebaseAppCheck subjacente', () async {
      when(
        () => mockFirebaseAppCheck.activate(
          providerAndroid: any(named: 'providerAndroid'),
          providerApple: any(named: 'providerApple'),
        ),
      ).thenAnswer((_) async {});

      await service.activate(
        providerAndroid: const AndroidDebugProvider(),
        providerApple: const AppleDebugProvider(),
      );

      verify(
        () => mockFirebaseAppCheck.activate(
          providerAndroid: const AndroidDebugProvider(),
          providerApple: const AppleDebugProvider(),
        ),
      ).called(1);
    });

    test('activate captura erros graciosamente sem lançar exceções', () async {
      when(
        () => mockFirebaseAppCheck.activate(
          providerAndroid: any(named: 'providerAndroid'),
          providerApple: any(named: 'providerApple'),
        ),
      ).thenThrow(Exception('Falha de ativação simulada'));

      await expectLater(service.activate(), completes);
    });

    test('getToken retorna o token com sucesso quando disponível', () async {
      when(() => mockFirebaseAppCheck.getToken(any()))
          .thenAnswer((_) async => 'fake-jwt-app-check-token');

      final token = await service.getToken();

      expect(token, 'fake-jwt-app-check-token');
      verify(() => mockFirebaseAppCheck.getToken(false)).called(1);
    });

    test('getToken com forceRefresh passa true para o SDK', () async {
      when(() => mockFirebaseAppCheck.getToken(any()))
          .thenAnswer((_) async => 'refreshed-jwt-token');

      final token = await service.getToken(true);

      expect(token, 'refreshed-jwt-token');
      verify(() => mockFirebaseAppCheck.getToken(true)).called(1);
    });

    test('getToken retorna null e registra logError quando o SDK lança exceção não relacionada a rede', () async {
      when(() => mockFirebaseAppCheck.getToken(any()))
          .thenThrow(Exception('Token fetch error'));

      final token = await service.getToken();

      expect(token, isNull);
      expect(mockLogger.recordedErrors, hasLength(1));
      expect(mockLogger.recordedWarnings, isEmpty);
    });

    test('getToken retorna null e registra logAviso (sem logError) quando a falha for de rede ou indisponibilidade', () async {
      when(() => mockFirebaseAppCheck.getToken(any())).thenThrow(
        FirebaseException(
          plugin: 'firebase_app_check',
          code: 'unavailable',
          message: 'Unable to connect to the server.',
        ),
      );

      final token = await service.getToken();

      expect(token, isNull);
      expect(mockLogger.recordedWarnings, hasLength(1));
      expect(mockLogger.recordedWarnings.first, contains('AppCheck'));
      expect(mockLogger.recordedErrors, isEmpty);
    });
  });
}
