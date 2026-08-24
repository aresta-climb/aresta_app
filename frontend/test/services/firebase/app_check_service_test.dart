// ignore_for_file: deprecated_member_use

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/firebase/app_check_service.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAppCheck extends Mock implements FirebaseAppCheck {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(AndroidProvider.debug);
    registerFallbackValue(AppleProvider.debug);
  });

  late MockFirebaseAppCheck mockFirebaseAppCheck;
  late AppCheckService service;

  setUp(() {
    mockFirebaseAppCheck = MockFirebaseAppCheck();
    service = AppCheckService.instance;
    service.debugAppCheck = mockFirebaseAppCheck;
  });

  group('AppCheckService', () {
    test('activate deve chamar activate no FirebaseAppCheck subjacente', () async {
      when(
        () => mockFirebaseAppCheck.activate(
          androidProvider: any(named: 'androidProvider'),
          appleProvider: any(named: 'appleProvider'),
        ),
      ).thenAnswer((_) async {});

      await service.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
      );

      verify(
        () => mockFirebaseAppCheck.activate(
          androidProvider: AndroidProvider.debug,
          appleProvider: AppleProvider.debug,
        ),
      ).called(1);
    });

    test('activate captura erros graciosamente sem lançar exceções', () async {
      when(
        () => mockFirebaseAppCheck.activate(
          androidProvider: any(named: 'androidProvider'),
          appleProvider: any(named: 'appleProvider'),
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

    test('getToken retorna null quando o SDK lança exceção (ex: ambiente não cadastrado)', () async {
      when(() => mockFirebaseAppCheck.getToken(any()))
          .thenThrow(Exception('Token fetch error'));

      final token = await service.getToken();

      expect(token, isNull);
    });
  });
}
