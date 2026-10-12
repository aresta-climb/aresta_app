// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

/// Define as modalidades de escalada suportadas para registro de ascensões.
///
/// Segue os códigos numéricos alinhados ao esquema físico do banco de dados:
/// * [guiado]: Escalada com corda guiada (proteções costuradas ou móveis colocadas pelo escalador).
/// * [topRope]: Escalada com corda fixa instalada no topo.
/// * [boulder]: Escalada em blocos baixos sem corda.
/// * [solo]: Escalada solo sem corda em falésia.
enum TipoEscalada {
  /// Escalada guiada pelo atleta (código 1).
  guiado(1, 'Guiado'),

  /// Escalada no Top Rope (código 2).
  topRope(2, 'Top Rope'),

  /// Escalada de boulder (código 3).
  boulder(3, 'Boulder'),

  /// Escalada solo sem segurança de corda (código 4).
  solo(4, 'Solo');

  /// Código numérico compacto persistido no banco de dados / PowerSync.
  final int codigo;

  /// Rótulo em português brasileiro para apresentação na interface.
  final String rotulo;

  const TipoEscalada(this.codigo, this.rotulo);

  /// Retorna `true` se a modalidade for bloco / boulder.
  bool get isBoulder => this == TipoEscalada.boulder;

  /// Retorna `true` se a modalidade for via de falésia (com ou sem corda).
  bool get isVia => this != TipoEscalada.boulder;

  /// Converte um código numérico de banco de dados para [TipoEscalada].
  ///
  /// Caso o código seja nulo ou desconhecido, adota [TipoEscalada.guiado]
  /// como padrão esportivo seguro.
  static TipoEscalada fromCodigo(int? codigo) {
    switch (codigo) {
      case 1:
        return TipoEscalada.guiado;
      case 2:
        return TipoEscalada.topRope;
      case 3:
        return TipoEscalada.boulder;
      case 4:
        return TipoEscalada.solo;
      default:
        return TipoEscalada.guiado;
    }
  }

  /// Converte um identificador textual para [TipoEscalada].
  ///
  /// Caso a string seja nula ou desconhecida, adota [TipoEscalada.guiado].
  static TipoEscalada fromString(String? nome) {
    if (nome == null) return TipoEscalada.guiado;
    for (final tipo in TipoEscalada.values) {
      if (tipo.name == nome) {
        return tipo;
      }
    }
    return TipoEscalada.guiado;
  }
}
