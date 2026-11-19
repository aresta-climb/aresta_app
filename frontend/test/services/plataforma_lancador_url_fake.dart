// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// Biblioteca `test-only` determinística de [UrlLauncherPlatform] para validar
/// aberturas de links externos sem depender do navegador do sistema operacional.
class PlataformaLancadorUrlFake extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  /// Histórico de URLs acionadas na sessão de teste.
  final List<String> urlsAbertas = [];

  /// Define o valor retornado por [launchUrl] quando [erroSimulado] é nulo.
  bool resultadoSimulado = true;

  /// Quando preenchido, lança esta exceção deterministicamente ao abrir qualquer URL.
  Object? erroSimulado;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => resultadoSimulado;

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) => launchUrl(url, const LaunchOptions());

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    if (erroSimulado != null) {
      throw erroSimulado!;
    }
    urlsAbertas.add(url);
    return resultadoSimulado;
  }
}
