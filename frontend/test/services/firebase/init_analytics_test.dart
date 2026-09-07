// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import 'package:frontend/services/firebase/init_firebase.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import '../../mocks/mock_app_logger.dart';

class MockFirebaseAnalytics implements FirebaseAnalytics {
  bool? collectionEnabled;

  @override
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    collectionEnabled = enabled;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('initAnalytics', () {
    test(
      'should disable Analytics collection if isDebugMode is true',
      () async {
        final mockAnalytics = MockFirebaseAnalytics();

        await initAnalytics(
          isDebugMode: true,
          analyticsInstance: mockAnalytics,
        );

        expect(mockAnalytics.collectionEnabled, false);
      },
    );

    test(
      'should not disable Analytics collection if isDebugMode is false',
      () async {
        final mockAnalytics = MockFirebaseAnalytics();

        await initAnalytics(
          isDebugMode: false,
          analyticsInstance: mockAnalytics,
        );

        // When not in debug mode, setAnalyticsCollectionEnabled is not called
        expect(mockAnalytics.collectionEnabled, isNull);
      },
    );
  });

  group('TelemetryService.initialize', () {
    setUp(() {
      TelemetryService.resetForTesting();
    });

    test(
      'should disable Analytics collection when isDebugMode is true',
      () async {
        final mockAnalytics = MockFirebaseAnalytics();

        await TelemetryService.instance.initialize(
          isDebugMode: true,
          analyticsInstance: mockAnalytics,
        );

        expect(mockAnalytics.collectionEnabled, false);
      },
    );

    test(
      'should not disable Analytics collection when isDebugMode is false',
      () async {
        final mockAnalytics = MockFirebaseAnalytics();

        await TelemetryService.instance.initialize(
          isDebugMode: false,
          analyticsInstance: mockAnalytics,
        );

        expect(mockAnalytics.collectionEnabled, isNull);
      },
    );

    test(
      'should call logError when setAnalyticsCollectionEnabled throws',
      () async {
        final throwingAnalytics = ThrowingMockFirebaseAnalytics();
        final mockLogger = MockAppLogger();
        AppLogger.instance = mockLogger;

        await TelemetryService.instance.initialize(
          isDebugMode: true,
          analyticsInstance: throwingAnalytics,
        );

        expect(mockLogger.recordedErrors, isNotEmpty);
        expect(
          mockLogger.recordedErrors.first['contextMessage'],
          '⚠️ [Telemetry] Erro ao desativar coleta do Firebase Analytics',
        );
      },
    );
  });
}

class ThrowingMockFirebaseAnalytics implements FirebaseAnalytics {
  @override
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    throw Exception('Simulated setAnalyticsCollectionEnabled failure');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
