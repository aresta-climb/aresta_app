import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/feedback/feedback_metadata_collector.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mocktail/mocktail.dart';

class MockAndroidDeviceInfo extends Mock implements AndroidDeviceInfo {}

class MockAndroidBuildVersion extends Mock implements AndroidBuildVersion {}

void main() {
  group('FeedbackMetadataCollector', () {
    test('coleta todos os metadados com sucesso', () async {
      final mockVersion = MockAndroidBuildVersion();
      when(() => mockVersion.release).thenReturn('13');

      final mockDevice = MockAndroidDeviceInfo();
      when(() => mockDevice.brand).thenReturn('Samsung');
      when(() => mockDevice.model).thenReturn('SM-G991B');
      when(() => mockDevice.version).thenReturn(mockVersion);

      final collector = FeedbackMetadataCollector(
        getAppInstanceIdOverride: () async => 'test_instance_id',
        getPackageInfoOverride: () async => PackageInfo(
          appName: 'Test App',
          packageName: 'com.test',
          version: '1.2.3',
          buildNumber: '10',
        ),
        getOSOverride: () => 'android',
        getNavigationTreeOverride: () => 'HomeNode -> SettingsNode',
        getDeviceInfoOverride: () async => mockDevice,
        getConnectivityOverride: () async => [ConnectivityResult.wifi],
        getTimestampOverride: () => DateTime.utc(2026, 6, 16, 12, 0, 0),
      );

      final metadata = await collector.collect();

      expect(metadata.appInstanceId, 'test_instance_id');
      expect(metadata.os, 'android');
      expect(metadata.osVersion, '13');
      expect(metadata.deviceModel, 'Samsung SM-G991B');
      expect(metadata.appVersion, '1.2.3');
      expect(metadata.navigationTree, 'HomeNode -> SettingsNode');
      expect(metadata.screenSize, 'unknown'); // O teste não passa context
      expect(
        metadata.deviceOrientation,
        'unknown',
      ); // O teste não passa context
      expect(metadata.isDarkMode, 'unknown'); // O teste não passa context
      expect(metadata.connectivity, 'wifi');
      expect(
        metadata.submittedAt,
        '16 de junho de 2026 às 09:00:00 (GMT-3)',
      );
      expect(metadata.submittedAtTimestamp, '2026-06-16T09:00:00.000-03:00');
    });

    test('usa valores padrão caso haja falha ou nulos na coleta', () async {
      final collector = FeedbackMetadataCollector(
        getAppInstanceIdOverride: () async => null,
        getPackageInfoOverride: () async => throw Exception('error'),
        getOSOverride: () => throw Exception('error'),
        getNavigationTreeOverride: () => '',
        getDeviceInfoOverride: () async => throw Exception('error'),
        getConnectivityOverride: () async => throw Exception('error'),
        getTimestampOverride: () => throw Exception('error'),
      );

      final metadata = await collector.collect();

      expect(metadata.appInstanceId, 'unknown');
      expect(metadata.os, '');
      expect(metadata.osVersion, 'unknown');
      expect(metadata.deviceModel, 'unknown');
      expect(metadata.appVersion, 'unknown');
      expect(metadata.navigationTree, 'unknown');
      expect(metadata.screenSize, 'unknown');
      expect(metadata.deviceOrientation, 'unknown');
      expect(metadata.isDarkMode, 'unknown');
      expect(metadata.connectivity, 'unknown');
      expect(metadata.submittedAt, 'unknown');
      expect(metadata.submittedAtTimestamp, 'unknown');
    });

    test('aplica globalActiveNodeOverride corretamente', () async {
      FeedbackMetadataCollector.globalActiveNodeOverride = 'NodeSubstituto';

      final collector = FeedbackMetadataCollector(
        getAppInstanceIdOverride: () async => '123',
        getNavigationTreeOverride: () => 'HomeNode -> OriginalNode',
      );

      final metadata = await collector.collect();
      expect(
        metadata.navigationTree,
        'HomeNode -> NodeSubstituto',
      ); // Como o node tree é uma string fixa, o nosso mock é simples

      FeedbackMetadataCollector.globalActiveNodeOverride = null;
    });
  });
}
