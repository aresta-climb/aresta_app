// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../utils/slug_utils.dart';

/// Representa uma rota de deep link decomposta e estruturada a partir de uma URL ou URI.
class RotaDeepLink {
  /// Identificador do pico/croqui (ex: "br_mg_igarape_pedra_grande").
  final String picoId;

  /// Segmentos hierárquicos filhos do pico normalizados em formato de slug.
  final List<String> segmentos;

  const RotaDeepLink({
    required this.picoId,
    required this.segmentos,
  });

  /// Retorna a quantidade de níveis de profundidade após o pico (0 = apenas o pico).
  int get profundidade => segmentos.length;

  /// Primeiro segmento após o pico (geralmente nome de Setor direto ou Grupo).
  String? get primeiroSegmento => segmentos.isNotEmpty ? segmentos[0] : null;

  /// Segundo segmento após o pico (Setor dentro de Grupo OU Via dentro de Setor direto).
  String? get segundoSegmento => segmentos.length > 1 ? segmentos[1] : null;

  /// Terceiro segmento após o pico (Via dentro de Setor pertencente a um Grupo).
  String? get terceiroSegmento => segmentos.length > 2 ? segmentos[2] : null;

  @override
  String toString() => 'RotaDeepLink(picoId: $picoId, segmentos: $segmentos)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RotaDeepLink &&
          runtimeType == other.runtimeType &&
          picoId == other.picoId &&
          _listasIguais(segmentos, other.segmentos);

  @override
  int get hashCode => picoId.hashCode ^ Object.hashAll(segmentos);

  static bool _listasIguais(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Analisador e normalizador de URLs de Deep Links e QR Codes para o Aresta Climb.
class DeepLinkRouteParser {
  DeepLinkRouteParser._();

  /// Domínio oficial de produção para abertura de setores e croquis no app.
  static const String dominioOficial = 'app.arestaclimb.com';

  /// Faz o parsing de uma [entrada] (que pode ser uma [String] ou [Uri]) para uma [RotaDeepLink].
  ///
  /// Retorna `null` se a URL não pertencer ao domínio esperado ou não contiver um identificador de pico.
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

    // Valida o host
    final host = uri.host.toLowerCase();
    if (host != dominioOficial) {
      return null;
    }

    // Extrai os segmentos do caminho ignorando itens vazios
    final segments = uri.pathSegments
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (segments.isEmpty) {
      return null;
    }

    final picoId = segments.first;
    final subSegmentos = segments
        .skip(1)
        .map(slugify)
        .where((s) => s.isNotEmpty)
        .take(3)
        .toList();

    return RotaDeepLink(
      picoId: picoId,
      segmentos: subSegmentos,
    );
  }
}
