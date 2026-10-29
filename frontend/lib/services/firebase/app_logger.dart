// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../http/cliente_http_aresta.dart';

/// Serviço para centralizar logs de erro silenciosos, falhas críticas e mensagens informativas do aplicativo.
/// No modo de debug, as mensagens e erros são impressos no console local para facilidade de diagnóstico.
/// Tanto em desenvolvimento quanto em produção (release):
/// - Mensagens informativas e avisos são registrados como breadcrumbs via [FirebaseCrashlytics.instance.log]
///   e [Sentry.addBreadcrumb].
/// - Erros operacionais e falhas fatais são enviados ao Firebase Crashlytics e ao Sentry com [StackTrace] obrigatório.
class AppLogger {
  AppLogger._privateConstructor();
  static AppLogger instance = AppLogger._privateConstructor();

  @visibleForTesting
  static void resetForTesting() {
    instance = AppLogger._privateConstructor();
  }

  @visibleForTesting
  bool? debugModeOverride;

  /// Permite exercitar em testes unitários os caminhos de verificação de inicialização
  /// (`false`) ou de chamada direta aos SDKs nativos (`true`).
  @visibleForTesting
  bool? ignorarAmbienteDeTestesOverride;

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

  @visibleForTesting
  void Function(Breadcrumb)? sentryBreadcrumbOverride;

  @visibleForTesting
  Future<void> Function(
    dynamic, {
    StackTrace? stackTrace,
    String? reason,
    bool fatal,
  })?
  sentryCaptureOverride;

  /// Indica se a execução atual está rodando sob o ambiente de testes do Flutter (`flutter test`).
  static bool get estaEmAmbienteDeTestes =>
      Platform.environment.containsKey('FLUTTER_TEST');

  /// Verifica se o SDK do Firebase foi devidamente inicializado pela aplicação (`initFirebase`).
  static bool get firebaseInicializado {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Determina se o envio para o Crashlytics pode ser realizado com segurança.
  /// Nunca tenta acessar canais nativos do Crashlytics durante testes automatizados
  /// sem override explícito ou quando o Firebase não tiver sido inicializado.
  bool _podeAcessarCrashlytics({bool ehLog = false}) {
    if (ehLog && crashlyticsLogOverride != null) return true;
    if (!ehLog && crashlyticsOverride != null) return true;
    if (ignorarAmbienteDeTestesOverride == true) return true;

    // Em testes automatizados, previne chamadas a plugins nativos não inicializados
    if (ignorarAmbienteDeTestesOverride == null && estaEmAmbienteDeTestes) {
      return false;
    }

    // Em execução real de dev ou release, só acessa se o Firebase estiver inicializado
    return firebaseInicializado;
  }

  /// Determina se o envio para o Sentry pode ser realizado.
  bool _podeAcessarSentry({bool ehBreadcrumb = false}) {
    if (ehBreadcrumb && sentryBreadcrumbOverride != null) return true;
    if (!ehBreadcrumb && sentryCaptureOverride != null) return true;
    if (ignorarAmbienteDeTestesOverride == true) return true;
    if (ignorarAmbienteDeTestesOverride == null && estaEmAmbienteDeTestes) {
      return false;
    }
    return Sentry.isEnabled;
  }

  /// Registra um breadcrumb no Sentry (ou no override de teste configurado).
  void _registrarBreadcrumbSentry(String mensagem, SentryLevel nivel) {
    if (!_podeAcessarSentry(ehBreadcrumb: true)) return;

    try {
      final breadcrumb = Breadcrumb(
        message: mensagem,
        level: nivel,
        timestamp: DateTime.now().toUtc(),
      );
      if (sentryBreadcrumbOverride != null) {
        sentryBreadcrumbOverride!(breadcrumb);
      } else {
        Sentry.addBreadcrumb(breadcrumb);
      }
    } catch (e) {
      debugPrint('⚠️ [AppLogger] Erro ao enviar breadcrumb para Sentry: $e');
    }
  }

  /// Configura o escopo do evento Sentry com nível de severidade e contexto da falha.
  @visibleForTesting
  static void configurarEscopoSentry(
    Scope scope,
    String contextMessage, {
    required bool fatal,
  }) {
    scope.level = fatal ? SentryLevel.fatal : SentryLevel.error;
    scope.setContexts('contexto_erro', {
      'mensagem': contextMessage,
      'fatal': fatal,
    });
  }

  /// Registra uma exceção no Sentry (ou no override de teste configurado).
  void _registrarExcecaoSentry(
    String contextMessage, {
    required dynamic excecao,
    required StackTrace stackTrace,
    required bool fatal,
  }) {
    if (!_podeAcessarSentry(ehBreadcrumb: false)) return;

    try {
      if (sentryCaptureOverride != null) {
        sentryCaptureOverride!(
          excecao,
          stackTrace: stackTrace,
          reason: contextMessage,
          fatal: fatal,
        );
      } else {
        Sentry.captureException(
          excecao,
          stackTrace: stackTrace,
          withScope: (scope) => configurarEscopoSentry(
            scope,
            contextMessage,
            fatal: fatal,
          ),
        );
      }
    } catch (e) {
      debugPrint('⚠️ [AppLogger] Erro ao enviar exceção para Sentry: $e');
    }
  }

  /// Registra uma mensagem informativa de ciclo de vida ou operação.
  /// No modo debug, imprime no console local com prefixo informativo.
  /// Registra a mensagem como breadcrumb no Firebase Crashlytics e no Sentry tanto em desenvolvimento quanto em produção.
  void logInfo(String mensagem) {
    final isDebug = debugModeOverride ?? !kReleaseMode;
    if (isDebug) {
      debugPrint('ℹ️ [AppLogger] $mensagem');
    }

    _registrarBreadcrumbSentry(mensagem, SentryLevel.info);

    if (!_podeAcessarCrashlytics(ehLog: true)) return;

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

  /// Registra uma mensagem de aviso operacional.
  /// No modo debug, imprime no console local com prefixo de aviso.
  /// Registra a mensagem exclusivamente como breadcrumb contextual no Firebase Crashlytics e no Sentry.
  /// Não abre issues/tickets no painel do Crashlytics ou Sentry, preservando a lista de issues para erros reais.
  void logAviso(String mensagem) {
    final isDebug = debugModeOverride ?? !kReleaseMode;
    if (isDebug) {
      debugPrint('⚠️ [AppLogger AVISO] $mensagem');
    }

    final textoLog = '⚠️ AVISO: $mensagem';
    _registrarBreadcrumbSentry(textoLog, SentryLevel.warning);

    if (!_podeAcessarCrashlytics(ehLog: true)) return;

    try {
      if (crashlyticsLogOverride != null) {
        crashlyticsLogOverride!(textoLog);
      } else {
        FirebaseCrashlytics.instance.log(textoLog);
      }
    } catch (e) {
      debugPrint('⚠️ [AppLogger] Erro ao enviar aviso para Crashlytics: $e');
    }
  }

  /// Verifica se o erro ou mensagem descreve uma falha transitória de conectividade,
  /// timeout de socket, instabilidade de gateway/servidor (HTTP 502, 503, 504, 429) ou
  /// falha de transporte nos SDKs nativos do Firebase (Installations, Remote Config e App Check)
  /// quando o dispositivo encontra-se offline.
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
        error is ClientException) {
      return true;
    }

    // 3. Códigos padronizados de indisponibilidade/rede em FirebaseException
    if (error is FirebaseException) {
      final codigo = error.code.toLowerCase();
      if (codigo == 'unavailable' ||
          codigo == 'network-request-failed' ||
          codigo == 'network_error' ||
          codigo == 'deadline-exceeded' ||
          codigo == 'throttled') {
        return true;
      }
    }

    // 4. Análise por mensagem textual
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

    // Mensagens nativas de falha de transporte dos SDKs do Firebase (Android/iOS via Pigeon)
    if (msg.contains('firebase installations failed to get installation auth token') ||
        msg.contains('error while calling the backend') ||
        msg.contains('unable to connect to the server') ||
        msg.contains('fetch failed') ||
        msg.contains('fetch throttled') ||
        msg.contains('network-request-failed') ||
        msg.contains('network_error') ||
        msg.contains('network error') ||
        msg.contains('unavailable')) {
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

  /// Registra um erro de operação no Firebase Crashlytics e no Sentry.
  /// [contextMessage] deve explicar o que falhou (ex: "Falha ao baixar imagem").
  /// [error] é a exceção original capturada.
  /// [stackTrace] é o rastreamento de pilha associado, estritamente obrigatório para diagnóstico.
  /// [fatal] indica se o erro deve ser tratado com nível de crash fatal (padrão: false).
  void logError(
    String contextMessage, {
    dynamic error,
    required StackTrace stackTrace,
    bool fatal = false,
  }) {
    // Sempre imprime no console apenas para debug local.
    final prefixo = fatal ? '💥 [AppLogger CRASH]' : '🛑 [AppLogger]';
    debugPrint('$prefixo $contextMessage');
    if (error != null) debugPrint('Exception: $error');
    debugPrint('Stack: $stackTrace');

    final excecaoEfetiva = error ?? Exception(contextMessage);

    _registrarExcecaoSentry(
      contextMessage,
      excecao: excecaoEfetiva,
      stackTrace: stackTrace,
      fatal: fatal,
    );

    if (!_podeAcessarCrashlytics(ehLog: false)) return;

    // Envia o erro pro Crashlytics tanto em desenvolvimento quanto em produção
    try {
      if (crashlyticsOverride != null) {
        crashlyticsOverride!(
          excecaoEfetiva,
          stackTrace,
          reason: contextMessage,
          printDetails: false,
          fatal: fatal,
        );
      } else {
        FirebaseCrashlytics.instance.recordError(
          excecaoEfetiva,
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

  /// Registra um erro crítico no nível de crash (`fatal: true`) no Firebase Crashlytics e no Sentry.
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
  /// o erro é registrado como aviso/breadcrumb contextual ([logAviso]) sem abrir issues no Crashlytics ou Sentry.
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
