// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/services.dart';

/// Configuração estritamente validada para execução de smoke test pós-build em CI.
///
/// Impõe que o servidor de orquestração utilize protocolo HTTP puro sobre endereços
/// exclusivos de loopback local (`127.0.0.1`, `localhost` ou `10.0.2.2`), recusando
/// qualquer host externo ou token vazio (Fail-Fast).
class ConfiguracaoSmokeCi {
  /// Nome do canal de plataforma exposto apenas em compilações de smoke de emulador/simulador.
  static const String nomeCanalPadrao = 'app.escalada.croquis/smoke_ci';

  /// Conjunto imutável de hosts de loopback permitidos para comunicação com o orquestrador local.
  static const Set<String> hostsLoopbackPermitidos = <String>{
    '127.0.0.1',
    'localhost',
    '10.0.2.2',
  };

  static const MethodChannel _canalPadrao = MethodChannel(nomeCanalPadrao);

  /// URI base normalizada do micro-servidor local de smoke test.
  final Uri uriBase;

  /// Token efêmero único gerado pelo orquestrador para autenticar relatórios da sessão.
  final String token;

  const ConfiguracaoSmokeCi._({
    required this.uriBase,
    required this.token,
  });

  /// Valida estritamente [servidorUrl] e [token], lançando [FormatException] se qualquer invariante falhar.
  factory ConfiguracaoSmokeCi.validar({
    required String servidorUrl,
    required String token,
  }) {
    final tokenLimpo = token.trim();
    if (tokenLimpo.isEmpty) {
      throw const FormatException(
        'Token efêmero de smoke test ausente ou em branco.',
      );
    }

    final urlLimpa = servidorUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (urlLimpa.isEmpty) {
      throw const FormatException('URL do servidor de smoke test vazia.');
    }

    final uri = Uri.tryParse(urlLimpa);
    if (uri == null ||
        uri.scheme != 'http' ||
        !uri.hasPort ||
        uri.port <= 0 ||
        !hostsLoopbackPermitidos.contains(uri.host.toLowerCase())) {
      throw FormatException(
        'Endereço de servidor de smoke test rejeitado fora de loopback local: $servidorUrl',
      );
    }

    return ConfiguracaoSmokeCi._(
      uriBase: Uri(
        scheme: 'http',
        host: uri.host.toLowerCase(),
        port: uri.port,
      ),
      token: tokenLimpo,
    );
  }

  /// Consulta o canal nativo e retorna a [ConfiguracaoSmokeCi] validada, ou lança [StateError] se inativo.
  static Future<ConfiguracaoSmokeCi> exigirDoCanalNativo({
    MethodChannel canal = _canalPadrao,
  }) async {
    Map<String, dynamic>? mapa;
    try {
      mapa = await canal.invokeMapMethod<String, dynamic>(
        'obterConfiguracaoSmoke',
      );
    } on MissingPluginException {
      throw StateError(
        'Canal nativo de smoke test indisponível neste binário/ambiente.',
      );
    }

    if (mapa == null || mapa['ativo'] != true) {
      throw StateError(
        'Modo de smoke test não está ativo na inicialização nativa.',
      );
    }

    return ConfiguracaoSmokeCi.validar(
      servidorUrl: (mapa['servidorUrl'] as String?) ?? '',
      token: (mapa['token'] as String?) ?? '',
    );
  }

  /// Constrói o endpoint local para emissão de `id_token` OIDC vinculado ao `nonce`.
  Uri construirUriOidcToken() => uriBase.replace(path: '/__smoke__/oidc-token');

  /// Constrói o endpoint local para entrega do relatório estruturado da jornada de smoke.
  Uri construirUriRelatorio() => uriBase.replace(path: '/__smoke__/relatorio');
}
