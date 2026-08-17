import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/services/firebase/init_firebase.dart';

class MockFirebaseCrashlytics implements FirebaseCrashlytics {
  bool collectionEnabled = true;

  @override
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {
    collectionEnabled = enabled;
  }

  @override
  Future<void> recordFlutterFatalError(
    FlutterErrorDetails flutterErrorDetails,
  ) async {}

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
    Iterable<Object> information = const [],
    bool? printDetails,
    bool fatal = false,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('initCrashlytics', () {
    test(
      'should disable Crashlytics collection if isDebugMode is true',
      () async {
        final mockCrashlytics = MockFirebaseCrashlytics();

        await initCrashlytics(
          isDebugMode: true,
          crashlyticsInstance: mockCrashlytics,
        );

        expect(mockCrashlytics.collectionEnabled, false);
      },
    );

    test(
      'should not disable Crashlytics collection if isDebugMode is false',
      () async {
        final mockCrashlytics = MockFirebaseCrashlytics();
        mockCrashlytics.collectionEnabled = true;

        await initCrashlytics(
          isDebugMode: false,
          crashlyticsInstance: mockCrashlytics,
        );

        // Verify that it remains true (since we don't explicitly call setCrashlyticsCollectionEnabled(true))
        expect(mockCrashlytics.collectionEnabled, true);
      },
    );
  });
}
