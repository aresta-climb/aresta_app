// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/services/firebase/inicializar_firebase.dart';

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
      'deve manter a coleta do Crashlytics ativada mesmo quando isDebugMode for true',
      () async {
        final mockCrashlytics = MockFirebaseCrashlytics();
        mockCrashlytics.collectionEnabled = false;

        await initCrashlytics(
          isDebugMode: true,
          crashlyticsInstance: mockCrashlytics,
        );

        expect(mockCrashlytics.collectionEnabled, true);
      },
    );

    test(
      'deve manter a coleta do Crashlytics ativada quando isDebugMode for false',
      () async {
        final mockCrashlytics = MockFirebaseCrashlytics();
        mockCrashlytics.collectionEnabled = false;

        await initCrashlytics(
          isDebugMode: false,
          crashlyticsInstance: mockCrashlytics,
        );

        expect(mockCrashlytics.collectionEnabled, true);
      },
    );
  });
}
