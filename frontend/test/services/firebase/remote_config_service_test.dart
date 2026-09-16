// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/constants/network_constants.dart';
import 'package:frontend/services/firebase/remote_config_service.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:mocktail/mocktail.dart';
import '../../mocks/mock_app_logger.dart';

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

        // 1. setDefaults chamado com chave da comunidade do WhatsApp
        final capturedDefaults = verify(
          () => mockFirebaseRemoteConfig.setDefaults(captureAny()),
        ).captured;
        expect(capturedDefaults.isNotEmpty, isTrue);
        final defaultsMap = capturedDefaults.first as Map<String, dynamic>;
        expect(
          defaultsMap['whatsapp_community_url'],
          NetworkConstants.kDefaultWhatsappCommunityUrl,
        );

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

    test('initialize deve capturar erros transitórios de rede e registrar como logAviso', () async {
      final mockLogger = MockAppLogger();
      AppLogger.instance = mockLogger;

      when(
        () => mockFirebaseRemoteConfig.setDefaults(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockFirebaseRemoteConfig.setConfigSettings(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockFirebaseRemoteConfig.fetchAndActivate(),
      ).thenThrow(Exception('Simulated network timeout'));

      await expectLater(service.initialize(), completes);

      expect(mockLogger.recordedWarnings, isNotEmpty);
      expect(mockLogger.recordedWarnings.first, contains('offline/timeout'));
      expect(mockLogger.recordedErrors, isEmpty);
    });

    test('initialize deve registrar erros inesperados de configuração via logError', () async {
      final mockLogger = MockAppLogger();
      AppLogger.instance = mockLogger;

      when(
        () => mockFirebaseRemoteConfig.setDefaults(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockFirebaseRemoteConfig.setConfigSettings(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockFirebaseRemoteConfig.fetchAndActivate(),
      ).thenThrow(const FormatException('Configurações inválidas'));

      await expectLater(service.initialize(), completes);

      expect(mockLogger.recordedErrors, isNotEmpty);
      expect(mockLogger.recordedErrors.first['contextMessage'], contains('Erro inesperado ao buscar configurações'));
      expect(mockLogger.recordedErrors.first['stackTrace'], isNotNull);
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

    test('Acessar whatsappCommunityUrl retorna valor do mock', () {
      when(
        () => mockFirebaseRemoteConfig.getString('whatsapp_community_url'),
      ).thenReturn('https://chat.whatsapp.com/custom');
      expect(
        RemoteConfigService.instance.whatsappCommunityUrl,
        'https://chat.whatsapp.com/custom',
      );
    });

    test('Acessar officialServerUrl combina servingBaseUrl com a versão de dados', () {
      when(
        () => mockFirebaseRemoteConfig.getString('serving_base_url'),
      ).thenReturn('https://remote.serving.arestaclimb.com');
      expect(
        RemoteConfigService.instance.officialServerUrl,
        'https://remote.serving.arestaclimb.com/v${NetworkConstants.kDataVersion}',
      );
    });

    test('officialServerUrl e URLs dinâmicas usam valores padrão quando Remote Config vazio ou com erro', () {
      when(() => mockFirebaseRemoteConfig.getString(any())).thenReturn('');

      expect(
        RemoteConfigService.instance.servingBaseUrl,
        NetworkConstants.kDefaultServingBaseUrl,
      );
      expect(
        RemoteConfigService.instance.officialServerUrl,
        NetworkConstants.kDefaultOfficialServerUrl,
      );
      expect(
        RemoteConfigService.instance.feedbackEdgeFunctionUrl,
        NetworkConstants.kDefaultFeedbackEdgeFunctionUrl,
      );
      expect(
        RemoteConfigService.instance.whatsappCommunityUrl,
        NetworkConstants.kDefaultWhatsappCommunityUrl,
      );
    });

    test('Getters tratam exceções retornando valores padrão seguros', () {
      when(() => mockFirebaseRemoteConfig.getBool(any())).thenThrow(Exception('Error'));
      when(() => mockFirebaseRemoteConfig.getInt(any())).thenThrow(Exception('Error'));
      when(() => mockFirebaseRemoteConfig.getString(any())).thenThrow(Exception('Error'));

      expect(RemoteConfigService.instance.getBool('qualquer_bool'), isFalse);
      expect(RemoteConfigService.instance.getInt('qualquer_int'), 0);
      expect(RemoteConfigService.instance.getString('qualquer_string'), '');
      expect(
        RemoteConfigService.instance.servingBaseUrl,
        NetworkConstants.kDefaultServingBaseUrl,
      );
      expect(
        RemoteConfigService.instance.officialServerUrl,
        NetworkConstants.kDefaultOfficialServerUrl,
      );
      expect(
        RemoteConfigService.instance.feedbackEdgeFunctionUrl,
        NetworkConstants.kDefaultFeedbackEdgeFunctionUrl,
      );
      expect(
        RemoteConfigService.instance.whatsappCommunityUrl,
        NetworkConstants.kDefaultWhatsappCommunityUrl,
      );
    });
  });
}
