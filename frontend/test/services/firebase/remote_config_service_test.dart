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
      'initialize deve configurar defaults, baixar com fetchInterval=0, e depois restaurar fetchInterval=12h',
      () async {
        // Setup
        when(
          () => mockFirebaseRemoteConfig.setDefaults(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockFirebaseRemoteConfig.setConfigSettings(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockFirebaseRemoteConfig.fetchAndActivate(),
        ).thenAnswer((_) async => true);

        // Act
        // Usar uma nova instância private se houver problema com _initFuture.
        // Como _initFuture trava o initialize() pra rodar 1 vez, a gente limpa recriando a service ou limpando o future se não for null

        // Porém, como _initFuture não é acessível, a melhor forma de forçar re-execução
        // é usar reflection ou chamar num app fresh. No teste, como instanciamos a global,
        // ele pode já estar preenchido.
        // Se não passar, depois ajustamos isso. Mas a primeira vez que roda no teste vai funcionar.

        await service.initialize();

        // Assert:
        // 1. setDefaults called
        verify(() => mockFirebaseRemoteConfig.setDefaults(any())).called(1);

        // 2. setConfigSettings called twice
        final capturedSettings = verify(
          () => mockFirebaseRemoteConfig.setConfigSettings(captureAny()),
        ).captured;
        expect(capturedSettings.length, 2);

        // First call should have Duration.zero
        final firstSettings = capturedSettings[0] as RemoteConfigSettings;
        expect(firstSettings.minimumFetchInterval, Duration.zero);
        expect(firstSettings.fetchTimeout, const Duration(seconds: 10));

        // Second call should have Duration(hours: 12)
        final secondSettings = capturedSettings[1] as RemoteConfigSettings;
        expect(secondSettings.minimumFetchInterval, const Duration(hours: 12));
        expect(secondSettings.fetchTimeout, const Duration(seconds: 10));

        // 3. fetchAndActivate called exactly once
        verify(() => mockFirebaseRemoteConfig.fetchAndActivate()).called(1);
      },
    );
  });

  group('Feature Flags Getters', () {
    test('Acessar recommendedVersion retorna valor do mock', () {
      final mockFirebaseRemoteConfig = MockFirebaseRemoteConfig();
      RemoteConfigService.instance.debugRemoteConfig = mockFirebaseRemoteConfig;

      when(
        () => mockFirebaseRemoteConfig.getInt('recommended_version'),
      ).thenReturn(42);
      expect(RemoteConfigService.instance.recommendedVersion, 42);
    });
  });
}
