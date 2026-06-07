import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Serviço para centralizar logs de erro silenciosos do aplicativo.
/// No modo de debug, os erros são impressos no console.
/// No modo release, os erros são enviados ao Firebase Crashlytics como falhas não-fatais.
class AppLogger {
  AppLogger._privateConstructor();
  static AppLogger instance = AppLogger._privateConstructor();

  @visibleForTesting
  static void resetForTesting() {
    instance = AppLogger._privateConstructor();
  }

  @visibleForTesting
  bool? debugModeOverride;

  @visibleForTesting
  Future<void> Function(
    dynamic,
    StackTrace?, {
    dynamic reason,
    bool printDetails,
  })?
  crashlyticsOverride;

  /// Registra um erro de forma não fatal.
  /// [contextMessage] deve explicar o que falhou (ex: "Falha ao baixar imagem").
  /// [error] é a exceção original, se existir.
  /// [stackTrace] é o rastreamento de pilha associado, se capturado.
  void logError(
    String contextMessage, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    final isDebug = debugModeOverride ?? kDebugMode;

    // Sempre imprime no console apenas para debug local.
    debugPrint('🛑 [AppLogger] $contextMessage');
    if (error != null) debugPrint('Exception: $error');
    if (stackTrace != null) debugPrint('Stack: $stackTrace');

    if (!isDebug) {
      // Envia o erro pro Crashlytics (Release/Profile mode)
      try {
        if (crashlyticsOverride != null) {
          crashlyticsOverride!(
            error ?? Exception(contextMessage),
            stackTrace,
            reason: contextMessage,
            printDetails: false,
          );
        } else {
          FirebaseCrashlytics.instance.recordError(
            error ?? Exception(contextMessage),
            stackTrace,
            reason: contextMessage,
            printDetails: false,
          );
        }
      } catch (e) {
        // Se falhar o envio para o Crashlytics (ex: Firebase não inicializado), loga localmente
        debugPrint('⚠️ [AppLogger] Erro ao enviar log para Crashlytics: $e');
      }
    }
  }
}
