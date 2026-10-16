// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../utils/gerador_uid.dart';
import '../utils/utilitarios_slug.dart';

/// Representa uma rota de deep link decomposta e estruturada a partir de uma URL ou URI.
///
/// Pode representar uma rota canônica por identificador universal opaco ([uid], como NanoID 14c)
/// ou uma rota hierárquica legada por slug de pico ([picoId]) e subsegmentos.
class RotaDeepLink {
  /// Identificador do pico/croqui (ex: "br_mg_igarape_pedra_grande").
  /// Nulo quando a rota é baseada exclusivamente em UID canônico opaco ([uid]).
  final String? picoId;

  /// Identificador universal estável (NanoID 14c Base62) do elemento de escalada.
  /// Preenchido quando o link segue o padrão canônico físico (ex: "https://aresta.cc/x8siJek3FiG3aB").
  final String? uid;

  /// Segmentos hierárquicos filhos do pico normalizados em formato de slug.
  final List<String> segmentos;

  /// Parâmetros de consulta (query parameters) preservados da URL (ex: parâmetros UTM).
  final Map<String, String> parametros;

  const RotaDeepLink({
    this.picoId,
    this.uid,
    this.segmentos = const [],
    this.parametros = const {},
  }) : assert(picoId != null || uid != null, 'RotaDeepLink deve conter picoId ou uid');

  /// Indica se a rota é direcionada por identificador universal opaco (NanoID 14c).
  bool get isPorUid => uid != null;

  /// Retorna a quantidade de níveis de profundidade após o pico (0 = apenas o pico ou rota por UID).
  int get profundidade => segmentos.length;

  /// Primeiro segmento após o pico (geralmente nome de Setor direto ou Grupo).
  String? get primeiroSegmento => segmentos.isNotEmpty ? segmentos[0] : null;

  /// Segundo segmento após o pico (Setor dentro de Grupo OU Via dentro de Setor direto).
  String? get segundoSegmento => segmentos.length > 1 ? segmentos[1] : null;

  /// Terceiro segmento após o pico (Via dentro de Setor pertencente a um Grupo).
  String? get terceiroSegmento => segmentos.length > 2 ? segmentos[2] : null;

  @override
  String toString() =>
      'RotaDeepLink(picoId: $picoId, uid: $uid, segmentos: $segmentos, parametros: $parametros)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RotaDeepLink &&
          runtimeType == other.runtimeType &&
          picoId == other.picoId &&
          uid == other.uid &&
          _listasIguais(segmentos, other.segmentos) &&
          _mapasIguais(parametros, other.parametros);

  @override
  int get hashCode =>
      picoId.hashCode ^
      uid.hashCode ^
      Object.hashAll(segmentos) ^
      Object.hashAll(parametros.entries);

  static bool _listasIguais(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _mapasIguais(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}

/// Analisador e normalizador de URLs de Deep Links e QR Codes para o Aresta Climb.
class DeepLinkRouteParser {
  DeepLinkRouteParser._();

  /// Domínio oficial encurtador e canônico para QR Codes físicos nas falésias.
  static const String dominioCanonico = 'aresta.cc';

  /// Domínio legado para links e rotas web.
  static const String dominioLegado = 'app.arestaclimb.com';

  /// Domínios válidos reconhecidos para deep links.
  static const Set<String> dominiosValidos = {
    dominioCanonico,
    'www.aresta.cc',
    dominioLegado,
  };

  /// Domínio oficial mantido para retrocompatibilidade de referência pública.
  static const String dominioOficial = dominioLegado;

  /// Faz o parsing de uma [entrada] (que pode ser uma [String] ou [Uri]) para uma [RotaDeepLink].
  ///
  /// Retorna `null` se a URL não pertencer aos domínios suportados ou não contiver caminho válido.
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

    // Valida o host contra os domínios permitidos
    final host = uri.host.toLowerCase();
    if (!dominiosValidos.contains(host)) {
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

    final parametros = Map<String, String>.from(uri.queryParameters);

    // Caso 1: Rota canônica física por NanoID 14c (aresta.cc/<nanoid>)
    if (segments.length == 1 && validarUid(segments.first)) {
      return RotaDeepLink(
        uid: segments.first,
        parametros: parametros,
      );
    }

    // Caso 2: Rota hierárquica (picoId + subsegmentos de grupo/setor/via)
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
      parametros: parametros,
    );
  }
}
