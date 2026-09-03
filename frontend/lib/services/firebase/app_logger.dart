// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:http/http.dart' as http;

/// Serviço para centralizar logs de erro silenciosos e falhas críticas do aplicativo.
/// No modo de debug, os erros são impressos no console.
/// No modo release, os erros são enviados ao Firebase Crashlytics com o nível de severidade adequado (não-fatal ou crash/fatal).
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
    bool fatal,
  })?
  crashlyticsOverride;

  /// Verifica se o erro ou mensagem descreve uma falha transitória de conectividade ou timeout.
  static bool isFalhaConexaoOuTimeout(dynamic error) {
    if (error == null) return false;

    // 1. Tipos de exceção conhecidos do Dart/HTTP
    if (error is TimeoutException ||
        error is SocketException ||
        error is HttpException ||
        error is HandshakeException ||
        error is CertificateException ||
        error is http.ClientException) {
      return true;
    }

    // 2. Análise por mensagem textual
    final msg = error.toString().toLowerCase();
    return msg.contains('timeout') ||
        msg.contains('timed out') ||
        msg.contains('socketexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('network is unreachable') ||
        msg.contains('connection refused') ||
        msg.contains('connection reset') ||
        msg.contains('connection closed') ||
        msg.contains('connection abort') ||
        msg.contains('no route to host') ||
        msg.contains('handshake') ||
        msg.contains('clientexception') ||
        msg.contains('falha de rede') ||
        msg.contains('sem conexão') ||
        msg.contains('sem conexao');
  }

  /// Registra um erro de operação.
  /// [contextMessage] deve explicar o que falhou (ex: "Falha ao baixar imagem").
  /// [error] é a exceção original, se existir.
  /// [stackTrace] é o rastreamento de pilha associado, se capturado.
  /// [fatal] indica se o erro deve ser tratado com nível de crash no Crashlytics (padrão: false).
  void logError(
    String contextMessage, {
    dynamic error,
    StackTrace? stackTrace,
    bool fatal = false,
  }) {
    final isDebug = debugModeOverride ?? kDebugMode;

    // Sempre imprime no console apenas para debug local.
    final prefixo = fatal ? '💥 [AppLogger CRASH]' : '🛑 [AppLogger]';
    debugPrint('$prefixo $contextMessage');
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
            fatal: fatal,
          );
        } else {
          FirebaseCrashlytics.instance.recordError(
            error ?? Exception(contextMessage),
            stackTrace,
            reason: contextMessage,
            printDetails: false,
            fatal: fatal,
          );
        }
      } catch (e) {
        // Se falhar o envio para o Crashlytics (ex: Firebase não inicializado), loga localmente
        debugPrint('⚠️ [AppLogger] Erro ao enviar log para Crashlytics: $e');
      }
    }
  }

  /// Registra um erro crítico no nível de crash (`fatal: true`) no Firebase Crashlytics.
  /// Deve ser usado para falhas severas de integridade, sincronização offline ou downloads corrompidos.
  void logCrash(
    String contextMessage, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    logError(
      contextMessage,
      error: error,
      stackTrace: stackTrace,
      fatal: true,
    );
  }

  /// Registra uma falha de sincronização ou download de croqui.
  /// Se a falha for decorrente de queda de conexão ou timeout (esperada em ambientes móveis),
  /// o erro NÃO gera crash no Crashlytics (`fatal: false`).
  /// Para qualquer outro erro de integridade (ex: 404, 500, checksum divergente, corrupção),
  /// o erro é registrado como crash fatal (`fatal: true`).
  void logFalhaSyncOuDownload(
    String contextMessage, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    final ehConexaoOuTimeout =
        isFalhaConexaoOuTimeout(error) || isFalhaConexaoOuTimeout(contextMessage);

    if (ehConexaoOuTimeout) {
      logError(
        contextMessage,
        error: error,
        stackTrace: stackTrace,
        fatal: false,
      );
    } else {
      logCrash(
        contextMessage,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
