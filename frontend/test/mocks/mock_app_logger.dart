import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/firebase/app_logger.dart';

/// Implementação simulada para evitar chamadas reais do Crashlytics durante testes
class MockAppLogger implements AppLogger {
  final List<Map<String, dynamic>> recordedErrors = [];

  @override
  bool? debugModeOverride;

  @override
  Future<void> Function(dynamic, StackTrace?, {bool printDetails, dynamic reason})? crashlyticsOverride;

  @override
  void logError(String contextMessage, {dynamic error, StackTrace? stackTrace}) {
    recordedErrors.add({
      'contextMessage': contextMessage,
      'error': error,
      'stackTrace': stackTrace,
    });
  }
}
