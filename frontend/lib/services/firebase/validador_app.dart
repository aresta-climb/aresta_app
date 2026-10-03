// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'app_logger.dart';

/// Serviço responsável por gerenciar a atestação de integridade do aplicativo via Firebase App Check.
///
/// Encapsula a inicialização e obtenção de tokens JWT do Play Integrity (Android),
/// App Attest (iOS) e Debug Provider durante o desenvolvimento.
class AppCheckService {
  AppCheckService._privateConstructor();

  /// Instância singleton global mutável para permitir injeção de dependência/mocks nos testes.
  static AppCheckService instance = AppCheckService._privateConstructor();

  @visibleForTesting
  FirebaseAppCheck? debugAppCheck;

  FirebaseAppCheck get _appCheck => debugAppCheck ?? FirebaseAppCheck.instance;

  /// Inicializa e ativa o Firebase App Check com os provedores adequados para release e debug.
  Future<void> activate({
    AndroidProvider? androidProvider,
    AppleProvider? appleProvider,
  }) async {
    try {
      // ignore: deprecated_member_use
      await _appCheck.activate(
        // ignore: deprecated_member_use
        androidProvider: androidProvider ??
            (kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity),
        // ignore: deprecated_member_use
        appleProvider: appleProvider ??
            (kDebugMode ? AppleProvider.debug : AppleProvider.appAttest),
      );
      AppLogger.instance.logInfo('🛡️ [AppCheck] Firebase App Check ativado com sucesso.');
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        '🛡️ [AppCheck] Erro ao ativar Firebase App Check',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Obtém o token JWT atual do App Check. Retorna `null` se falhar ou estiver em ambiente não atestado.
  Future<String?> getToken([bool forceRefresh = false]) async {
    try {
      final token = await _appCheck.getToken(forceRefresh);
      return token;
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        '🛡️ [AppCheck] Não foi possível obter o token do App Check',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
