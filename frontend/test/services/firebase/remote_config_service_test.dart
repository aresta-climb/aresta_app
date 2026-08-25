// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/firebase/remote_config_service.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseRemoteConfig extends Mock implements FirebaseRemoteConfig {}

class FakeRemoteConfigSettings extends Fake implements RemoteConfigSettings {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeRemoteConfigSettings());
  });

  group('RemoteConfigService Initialize', () {
    late RemoteConfigService service;
    late MockFirebaseRemoteConfig mockFirebaseRemoteConfig;

    setUp(() {
      mockFirebaseRemoteConfig = MockFirebaseRemoteConfig();
      service = RemoteConfigService.instance;
      service.debugRemoteConfig = mockFirebaseRemoteConfig;
      service.clearInitFuture();
    });

    test(
      'initialize deve configurar defaults e rodar fetch sem bloquear o chamador, notificando ouvintes ao concluir',
      () async {
        when(
          () => mockFirebaseRemoteConfig.setDefaults(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockFirebaseRemoteConfig.setConfigSettings(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockFirebaseRemoteConfig.fetchAndActivate(),
        ).thenAnswer((_) async => true);

        bool notified = false;
        service.addListener(() {
          notified = true;
        });

        await service.initialize();

        // 1. setDefaults chamado
        verify(() => mockFirebaseRemoteConfig.setDefaults(any())).called(1);

        // 2. setConfigSettings chamado com intervalo saudável de cache (12 horas)
        final capturedSettings = verify(
          () => mockFirebaseRemoteConfig.setConfigSettings(captureAny()),
        ).captured;
        expect(capturedSettings.isNotEmpty, isTrue);
        final settings = capturedSettings.first as RemoteConfigSettings;
        expect(settings.minimumFetchInterval, const Duration(hours: 12));
        expect(settings.fetchTimeout, const Duration(seconds: 10));

        // 3. fetchAndActivate chamado
        verify(() => mockFirebaseRemoteConfig.fetchAndActivate()).called(1);

        // 4. Ouvintes notificados
        expect(notified, isTrue);
      },
    );

    test('initialize deve capturar erros de rede silenciosamente sem quebrar', () async {
      when(
        () => mockFirebaseRemoteConfig.setDefaults(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockFirebaseRemoteConfig.setConfigSettings(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockFirebaseRemoteConfig.fetchAndActivate(),
      ).thenThrow(Exception('Simulated network timeout'));

      // Não deve lançar exceção
      await expectLater(service.initialize(), completes);
    });
  });

  group('Feature Flags Getters', () {
    late MockFirebaseRemoteConfig mockFirebaseRemoteConfig;

    setUp(() {
      mockFirebaseRemoteConfig = MockFirebaseRemoteConfig();
      RemoteConfigService.instance.debugRemoteConfig = mockFirebaseRemoteConfig;
    });

    test('Acessar recommendedVersion retorna valor do mock', () {
      when(
        () => mockFirebaseRemoteConfig.getInt('recommended_version'),
      ).thenReturn(42);
      expect(RemoteConfigService.instance.recommendedVersion, 42);
    });

    test('Acessar softMinVersion retorna valor do mock', () {
      when(
        () => mockFirebaseRemoteConfig.getInt('soft_min_version'),
      ).thenReturn(15);
      expect(RemoteConfigService.instance.softMinVersion, 15);
    });

    test('Acessar hardMinVersion retorna valor do mock', () {
      when(
        () => mockFirebaseRemoteConfig.getInt('hard_min_version'),
      ).thenReturn(20);
      expect(RemoteConfigService.instance.hardMinVersion, 20);
    });

    test('Acessar storeUrlIos retorna valor do mock', () {
      when(
        () => mockFirebaseRemoteConfig.getString('store_url_ios'),
      ).thenReturn('https://custom.app.store');
      expect(RemoteConfigService.instance.storeUrlIos, 'https://custom.app.store');
    });

    test('Acessar feedbackEdgeFunctionUrl retorna valor do mock', () {
      when(
        () => mockFirebaseRemoteConfig.getString('feedback_edge_function_url'),
      ).thenReturn('https://remote.supabase.co/functions/v1/app-feedback');
      expect(
        RemoteConfigService.instance.feedbackEdgeFunctionUrl,
        'https://remote.supabase.co/functions/v1/app-feedback',
      );
    });

    test('Acessar servingBaseUrl retorna valor do mock', () {
      when(
        () => mockFirebaseRemoteConfig.getString('serving_base_url'),
      ).thenReturn('https://remote.serving.arestaclimb.com');
      expect(
        RemoteConfigService.instance.servingBaseUrl,
        'https://remote.serving.arestaclimb.com',
      );
    });

    test('Getters tratam exceções retornando valores padrão seguros', () {
      when(() => mockFirebaseRemoteConfig.getBool(any())).thenThrow(Exception('Error'));
      when(() => mockFirebaseRemoteConfig.getInt(any())).thenThrow(Exception('Error'));
      when(() => mockFirebaseRemoteConfig.getString(any())).thenThrow(Exception('Error'));

      expect(RemoteConfigService.instance.getBool('qualquer_bool'), isFalse);
      expect(RemoteConfigService.instance.getInt('qualquer_int'), 0);
      expect(RemoteConfigService.instance.getString('qualquer_string'), '');
    });
  });
}
