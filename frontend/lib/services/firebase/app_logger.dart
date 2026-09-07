// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:http/http.dart' as http;

/// Serviço para centralizar logs de erro silenciosos, falhas críticas e mensagens informativas do aplicativo.
/// No modo de debug, as mensagens e erros são impressos no console local.
/// No modo release:
/// - Mensagens informativas e avisos são registrados como breadcrumbs via [FirebaseCrashlytics.instance.log].
/// - Erros operacionais e falhas fatais são enviados ao Firebase Crashlytics com [StackTrace] obrigatório.
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

  @visibleForTesting
  void Function(String)? crashlyticsLogOverride;

  /// Registra uma mensagem informativa de ciclo de vida ou operação.
  /// No modo debug, imprime no console local com prefixo informativo.
  /// No modo release, registra a mensagem como breadcrumb no Firebase Crashlytics via [FirebaseCrashlytics.instance.log].
  void logInfo(String mensagem) {
    final isDebug = debugModeOverride ?? kDebugMode;
    if (isDebug) {
      debugPrint('ℹ️ [AppLogger] $mensagem');
    } else {
      try {
        if (crashlyticsLogOverride != null) {
          crashlyticsLogOverride!(mensagem);
        } else {
          FirebaseCrashlytics.instance.log(mensagem);
        }
      } catch (e) {
        debugPrint('⚠️ [AppLogger] Erro ao enviar log para Crashlytics: $e');
      }
    }
  }

  /// Registra uma mensagem de aviso operacional.
  /// No modo debug, imprime no console local com prefixo de aviso.
  /// No modo release, registra a mensagem exclusivamente como breadcrumb contextual no Firebase Crashlytics via [FirebaseCrashlytics.instance.log].
  /// Não abre issues/tickets no painel do Crashlytics, preservando a lista de issues para erros reais que exigem correção.
  void logAviso(String mensagem) {
    final isDebug = debugModeOverride ?? kDebugMode;
    if (isDebug) {
      debugPrint('⚠️ [AppLogger AVISO] $mensagem');
    } else {
      try {
        final textoLog = '⚠️ AVISO: $mensagem';
        if (crashlyticsLogOverride != null) {
          crashlyticsLogOverride!(textoLog);
        } else {
          FirebaseCrashlytics.instance.log(textoLog);
        }
      } catch (e) {
        debugPrint('⚠️ [AppLogger] Erro ao enviar aviso para Crashlytics: $e');
      }
    }
  }

  /// Verifica se o erro ou mensagem descreve uma falha transitória de conectividade,
  /// timeout de socket ou instabilidade de gateway/servidor (HTTP 502, 503, 504, 429).
  static bool isFalhaConexaoOuTimeout(dynamic error) {
    if (error == null) return false;

    // 1. Códigos numéricos diretos de status HTTP transitório
    if (error is int) {
      return error == 502 || error == 503 || error == 504 || error == 429;
    }

    // 2. Tipos de exceção conhecidos do Dart/HTTP
    if (error is TimeoutException ||
        error is SocketException ||
        error is HttpException ||
        error is HandshakeException ||
        error is CertificateException ||
        error is http.ClientException) {
      return true;
    }

    // 3. Análise por mensagem textual
    final msg = error.toString().toLowerCase();

    // Códigos de erro HTTP transitórios (Gateway/CDN/Rate-limit)
    if (msg.contains('504') ||
        msg.contains('502') ||
        msg.contains('503') ||
        msg.contains('429') ||
        msg.contains('gateway timeout') ||
        msg.contains('bad gateway') ||
        msg.contains('service unavailable') ||
        msg.contains('too many requests')) {
      return true;
    }

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

  /// Registra um erro de operação no Firebase Crashlytics.
  /// [contextMessage] deve explicar o que falhou (ex: "Falha ao baixar imagem").
  /// [error] é a exceção original capturada.
  /// [stackTrace] é o rastreamento de pilha associado, estritamente obrigatório para diagnóstico no Crashlytics.
  /// [fatal] indica se o erro deve ser tratado com nível de crash no Crashlytics (padrão: false).
  void logError(
    String contextMessage, {
    dynamic error,
    required StackTrace stackTrace,
    bool fatal = false,
  }) {
    final isDebug = debugModeOverride ?? kDebugMode;

    // Sempre imprime no console apenas para debug local.
    final prefixo = fatal ? '💥 [AppLogger CRASH]' : '🛑 [AppLogger]';
    debugPrint('$prefixo $contextMessage');
    if (error != null) debugPrint('Exception: $error');
    debugPrint('Stack: $stackTrace');

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
    required StackTrace stackTrace,
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
  /// o erro é registrado como aviso/breadcrumb contextual ([logAviso]) sem abrir issues no Crashlytics.
  /// Para qualquer outro erro de integridade (ex: 404, 500, checksum divergente, corrupção),
  /// o erro é registrado como crash fatal (`fatal: true`).
  void logFalhaSyncOuDownload(
    String contextMessage, {
    dynamic error,
    required StackTrace stackTrace,
  }) {
    final ehConexaoOuTimeout =
        isFalhaConexaoOuTimeout(error) || isFalhaConexaoOuTimeout(contextMessage);

    if (ehConexaoOuTimeout) {
      final detalhe = error != null ? ' ($error)' : '';
      logAviso('$contextMessage$detalhe');
    } else {
      logCrash(
        contextMessage,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
