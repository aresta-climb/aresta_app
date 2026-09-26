// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';

/// Metadados de sessão retornados pelo endpoint `/info` do servidor de prévia do editor.
class MetadadosPrevia {
  /// URL local para conexão direta via LAN (Direct LAN).
  final String? localUrl;

  const MetadadosPrevia({this.localUrl});

  /// Instancia o modelo a partir do JSON bruto retornado pelo servidor.
  factory MetadadosPrevia.deJson(String jsonStr) {
    try {
      final decodificado = jsonDecode(jsonStr);
      if (decodificado is Map) {
        return MetadadosPrevia(
          localUrl: decodificado['local_url']?.toString(),
        );
      }
    } catch (_) {}
    return const MetadadosPrevia();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MetadadosPrevia &&
          runtimeType == other.runtimeType &&
          localUrl == other.localUrl;

  @override
  int get hashCode => localUrl.hashCode;

  @override
  String toString() => 'MetadadosPrevia(localUrl: $localUrl)';
}
