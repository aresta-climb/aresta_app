import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../../firebase_options.dart';
import 'remote_config_service.dart';

/// Inicializa os serviços do Firebase e os configura globalmente.
/// Esta função encapsula todo o contato direto com a API core do Firebase.
Future<void> initFirebase() async {
  // Inicialização básica
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await initCrashlytics();

  // Dispara o carregamento de configurações remotas sem bloquear a inicialização principal
  RemoteConfigService.instance.initialize();
}

/// Inicializa e configura o Crashlytics. Extraído para permitir injeção de dependências nos testes.
Future<void> initCrashlytics({
  bool? isDebugMode,
  FirebaseCrashlytics? crashlyticsInstance,
}) async {
  final isDebug = isDebugMode ?? kDebugMode;
  final crashlytics = crashlyticsInstance ?? FirebaseCrashlytics.instance;

  // Crashlytics global handlers
  if (isDebug) {
    await crashlytics.setCrashlyticsCollectionEnabled(false);
  }
  FlutterError.onError = crashlytics.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    crashlytics.recordError(error, stack, fatal: true);
    return true;
  };
}
