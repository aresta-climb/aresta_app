import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../../firebase_options.dart';
import 'remote_config_service.dart';
import 'telemetry_service.dart';

/// Inicializa os serviços do Firebase e os configura globalmente.
/// Esta função encapsula todo o contato direto com a API core do Firebase.
Future<void> initFirebase() async {
  // Inicialização básica
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Crashlytics global handlers
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Dispara o carregamento de configurações remotas sem bloquear a inicialização principal
  RemoteConfigService.instance.initialize();
}
