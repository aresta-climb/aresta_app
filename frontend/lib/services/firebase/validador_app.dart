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

  /// Inicializa e ativa o Firebase App Check com os provedores adequados para release e debug/profile.
  ///
  /// Fora de builds de release (`!kReleaseMode`, o que inclui `--debug` e `--profile`), utiliza
  /// o provedor de depuração para evitar falhas de atestação `403` no Play Integrity causadas
  /// pela assinatura com `debug.keystore` durante sessões locais do Flutter DevTools.
  Future<void> activate({
    AndroidAppCheckProvider? providerAndroid,
    AppleAppCheckProvider? providerApple,
    bool? emModoRelease,
  }) async {
    final isRelease = emModoRelease ?? kReleaseMode;
    try {
      await _appCheck.activate(
        providerAndroid: providerAndroid ??
            (isRelease
                ? const AndroidPlayIntegrityProvider()
                : const AndroidDebugProvider()),
        providerApple: providerApple ??
            (isRelease
                ? const AppleAppAttestProvider()
                : const AppleDebugProvider()),
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
  ///
  /// Falhas transitórias de conectividade (ex: dispositivo offline ao tentar renovar token)
  /// são registradas apenas como aviso/breadcrumb via [AppLogger.instance.logAviso],
  /// evitando falsos positivos de erro não-fatal no Crashlytics.
  Future<String?> getToken([bool forceRefresh = false]) async {
    try {
      final token = await _appCheck.getToken(forceRefresh);
      return token;
    } catch (e, stackTrace) {
      if (AppLogger.isFalhaConexaoOuTimeout(e)) {
        AppLogger.instance.logAviso(
          '🛡️ [AppCheck] Falha de conexão ao obter token do App Check (offline/timeout): $e',
        );
      } else {
        AppLogger.instance.logError(
          '🛡️ [AppCheck] Não foi possível obter o token do App Check',
          error: e,
          stackTrace: stackTrace,
        );
      }
      return null;
    }
  }
}
