import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/constants/network_constants.dart';
import 'package:frontend/services/firebase/remote_config_service.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseRemoteConfig extends Mock implements FirebaseRemoteConfig {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFirebaseRemoteConfig mockFirebaseRemoteConfig;

  setUp(() {
    mockFirebaseRemoteConfig = MockFirebaseRemoteConfig();
    RemoteConfigService.instance.debugRemoteConfig = mockFirebaseRemoteConfig;
  });

  group('NetworkConstants', () {
    test('officialServerUrl combina servingBaseUrl do Remote Config com a versão de dados', () {
      when(() => mockFirebaseRemoteConfig.getString('serving_base_url'))
          .thenReturn('https://serving.arestaclimb.com');

      expect(
        NetworkConstants.officialServerUrl,
        'https://serving.arestaclimb.com/v${NetworkConstants.kDataVersion}',
      );
    });

    test('officialServerUrl reflete alterações dinâmicas do Remote Config', () {
      when(() => mockFirebaseRemoteConfig.getString('serving_base_url'))
          .thenReturn('https://backup-serving.arestaclimb.com');

      expect(
        NetworkConstants.officialServerUrl,
        'https://backup-serving.arestaclimb.com/v${NetworkConstants.kDataVersion}',
      );
    });

    test('feedbackEdgeFunctionUrl resolve do Remote Config', () {
      when(() => mockFirebaseRemoteConfig.getString('feedback_edge_function_url'))
          .thenReturn('https://gawgqiqzptckwghgqypt.supabase.co/functions/v1/app-feedback');

      expect(
        NetworkConstants.feedbackEdgeFunctionUrl,
        'https://gawgqiqzptckwghgqypt.supabase.co/functions/v1/app-feedback',
      );
    });
  });
}
