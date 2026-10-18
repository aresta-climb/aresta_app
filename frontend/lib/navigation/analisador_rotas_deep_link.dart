// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../utils/gerador_uid.dart';

/// Representa uma rota de deep link decomposta e estruturada a partir de uma URL ou URI.
///
/// Toda rota válida resolve para um identificador universal estável ([uid], NanoID 14c Base62),
/// podendo indicar modo de abertura direto no mapa ([abrirMapa]) e origem de telemetria ([origemLink]).
class RotaDeepLink {
  /// Identificador universal estável (NanoID 14c Base62) do elemento de escalada.
  final String uid;

  /// Quando `true`, solicita que a navegação abra diretamente o Mapa Interativo focado na entidade.
  final bool abrirMapa;

  /// Origem semântica do link para fins de telemetria (`'qrcode'`, `'compartilhamento'` ou `null`).
  final String? origemLink;

  /// Parâmetros de consulta (query parameters) preservados da URL (ex: `utm_source`, `utm_medium`).
  final Map<String, String> parametros;

  const RotaDeepLink({
    required this.uid,
    this.abrirMapa = false,
    this.origemLink,
    this.parametros = const {},
  });

  /// Indica que a rota é direcionada por identificador universal opaco (NanoID 14c).
  bool get isPorUid => true;

  @override
  String toString() =>
      'RotaDeepLink(uid: $uid, abrirMapa: $abrirMapa, origemLink: $origemLink, parametros: $parametros)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RotaDeepLink &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          abrirMapa == other.abrirMapa &&
          origemLink == other.origemLink &&
          _mapasIguais(parametros, other.parametros);

  @override
  int get hashCode =>
      uid.hashCode ^
      abrirMapa.hashCode ^
      origemLink.hashCode ^
      Object.hashAllUnordered(
        parametros.entries.map((e) => Object.hash(e.key, e.value)),
      );

  static bool _mapasIguais(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}

/// Analisador e normalizador de URLs de Deep Links e QR Codes para o Aresta Climb.
///
/// Suporta o protocolo compacto `https://aresta.cc` ($\le 35$ caracteres para QR Code Version 3-H)
/// e o mapeamento estático das 8 placas físicas legadas em `app.arestaclimb.com`.
class DeepLinkRouteParser {
  // coverage:ignore-start
  DeepLinkRouteParser._();
  // coverage:ignore-end

  /// Domínio oficial encurtador e canônico para QR Codes físicos e compartilhamentos.
  static const String dominioCanonico = 'aresta.cc';

  /// Domínio legado mantido para as 8 placas físicas de Igarapé.
  static const String dominioLegado = 'app.arestaclimb.com';

  /// Domínios válidos reconhecidos para deep links.
  static const Set<String> dominiosValidos = {
    dominioCanonico,
    'www.aresta.cc',
    dominioLegado,
  };

  /// Domínio oficial mantido para retrocompatibilidade de referência pública.
  static const String dominioOficial = dominioCanonico;

  /// Mapeamento estático imutável das 8 placas físicas legadas existentes no mundo real
  /// (`https://app.arestaclimb.com/br_mg_igarape_pedra_grande/...`) para seus respectivos UIDs.
  static const Map<String, String> mapaRotasLegadasPlacas = <String, String>{
    'br_mg_igarape_pedra_grande/bloco_democracia': 'sQ7YgEG6ONsPXt',
    'br_mg_igarape_pedra_grande/bloco_viva_o_climb': 'xNOT4evG3tUx7A',
    'br_mg_igarape_pedra_grande/grupo_sherpa': 'cqT5nqQ4pvPub7',
    'br_mg_igarape_pedra_grande/setor_estacionamento': 'hv7YWgTBQGyWOX',
    'br_mg_igarape_pedra_grande/setor_familia_i': 'ZTPu3KeCXIJisV',
    'br_mg_igarape_pedra_grande/setor_familia_ii': '4GJDAcwWEJb4Ca',
    'br_mg_igarape_pedra_grande/bloco_fugitivos_i': '7TPrkAyBIkfebu',
    'br_mg_igarape_pedra_grande/bloco_fugitivos_ii': 'jPzv6byW0dO0Gj',
  };

  /// Faz o parsing de uma [entrada] (que pode ser uma [String] ou [Uri]) para uma [RotaDeepLink].
  ///
  /// Retorna `null` se a URL não pertencer aos domínios suportados ou não contiver um UID/rota legada válida.
  static RotaDeepLink? parse(dynamic entrada) {
    if (entrada == null) return null;

    Uri? uri;
    if (entrada is Uri) {
      uri = entrada;
    } else if (entrada is String) {
      final texto = entrada.trim();
      if (texto.isEmpty) return null;

      final urlFormatada = texto.contains('://') ? texto : 'https://$texto';
      uri = Uri.tryParse(urlFormatada);
    }

    if (uri == null) return null;

    final host = uri.host.toLowerCase();
    if (!dominiosValidos.contains(host)) {
      return null;
    }

    final segments = uri.pathSegments
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (segments.isEmpty) {
      return null;
    }

    final parametros = Map<String, String>.from(uri.queryParameters);

    // Caso 1: /<uid> direto (sem prefixo de fonte e sem modo mapa)
    if (segments.length == 1 && validarUid(segments.first)) {
      return RotaDeepLink(
        uid: segments.first,
        parametros: parametros,
      );
    }

    // Caso 2: /<prefixo>/<uid> compacto ou uma das 8 placas físicas legadas
    if (segments.length == 2) {
      final primeiro = segments[0];
      final segundo = segments[1];

      if (validarUid(segundo)) {
        switch (primeiro) {
          case 'm':
            return RotaDeepLink(
              uid: segundo,
              abrirMapa: true,
              parametros: parametros,
            );
          case 's':
            return RotaDeepLink(
              uid: segundo,
              origemLink: 'compartilhamento',
              parametros: parametros,
            );
          case 'sm':
          case 'ms':
            return RotaDeepLink(
              uid: segundo,
              abrirMapa: true,
              origemLink: 'compartilhamento',
              parametros: parametros,
            );
          case 'q':
            return RotaDeepLink(
              uid: segundo,
              origemLink: 'qrcode',
              parametros: parametros,
            );
          case 'qm':
          case 'mq':
            return RotaDeepLink(
              uid: segundo,
              abrirMapa: true,
              origemLink: 'qrcode',
              parametros: parametros,
            );
        }
      }

      final chaveLegada = '${primeiro.toLowerCase()}/${segundo.toLowerCase()}';
      final uidLegado = mapaRotasLegadasPlacas[chaveLegada];
      if (uidLegado != null) {
        return RotaDeepLink(
          uid: uidLegado,
          origemLink: 'qrcode',
          parametros: parametros,
        );
      }
    }

    return null;
  }
}
