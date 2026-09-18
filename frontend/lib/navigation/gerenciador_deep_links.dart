// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firebase/app_logger.dart';
import 'deep_link_navigator_service.dart';

/// Gerenciador de ciclo de vida de Deep Links que escuta eventos nativos do SO (App Links e Universal Links).
///
/// Trata tanto a inicialização a frio (*Cold Start*) ao abrir o aplicativo a partir de um link externo,
/// quanto eventos a quente (*Warm Start*) quando o aplicativo já está em execução em segundo plano.
class GerenciadorDeepLinks {
  final AppLinks _appLinks;
  final DeepLinkNavigatorService _navigatorService;
  StreamSubscription<Uri>? _subscricaoLinks;

  GerenciadorDeepLinks({
    AppLinks? appLinks,
    required DeepLinkNavigatorService navigatorService,
  })  : _appLinks = appLinks ?? AppLinks(),
        _navigatorService = navigatorService;

  /// Inicializa a escuta de links externos, processando o link inicial e ouvindo o stream.
  Future<void> inicializar({BuildContext? context}) async {
    // 1. Trata Cold Start (link que inicializou a abertura do app)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        AppLogger.instance.logInfo('[DeepLinks] Cold Start detectado: $initialUri');
        if (context != null && !context.mounted) {
          await _navigatorService.processarLink(initialUri);
        } else {
          await _navigatorService.processarLink(initialUri, context: context);
        }
      }
    } catch (e, st) {
      if (e is! MissingPluginException) {
        AppLogger.instance.logError(
          '[DeepLinks] Falha ao processar link inicial de Cold Start',
          error: e,
          stackTrace: st,
        );
      }
    }

    // 2. Trata Warm Start (links recebidos com o app já ativo/em segundo plano)
    try {
      _subscricaoLinks = _appLinks.uriLinkStream.listen(
        (uri) async {
          AppLogger.instance.logInfo('[DeepLinks] Warm Start recebido: $uri');
          if (context != null && !context.mounted) {
            await _navigatorService.processarLink(uri);
            return;
          }
          await _navigatorService.processarLink(uri, context: context);
        },
        onError: (e, st) {
          if (e is! MissingPluginException) {
            AppLogger.instance.logError(
              '[DeepLinks] Erro na stream de escuta de deep links',
              error: e,
              stackTrace: st,
            );
          }
        },
      );
    } catch (e, st) {
      if (e is! MissingPluginException) {
        AppLogger.instance.logError(
          '[DeepLinks] Falha ao inicializar stream de deep links',
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  /// Cancela as assinaturas de stream ativas.
  void dispose() {
    try {
      _subscricaoLinks?.cancel();
    } catch (_) {}
    _subscricaoLinks = null;
  }
}
