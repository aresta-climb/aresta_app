// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

/// Representa as estatísticas consolidadas de escalada de um pico.
///
/// Encapsula quantitativos de vias, setores e modalidades de escalada
/// para exibição nos cartões de catálogo, tela de busca e detalhes.
class EstatisticasPico {
  /// Quantidade total de escaladas cadastradas.
  final int totalVias;

  /// Quantidade total de setores catalogados.
  final int totalSetores;

  /// Quantidade de vias na modalidade esportiva.
  final int totalEsportivas;

  /// Quantidade de vias na modalidade tradicional/móvel.
  final int totalMoveis;

  /// Quantidade de linhas de boulder.
  final int totalBoulders;

  /// Quantidade de vias com múltiplas enfiadas (bigwall/paredão).
  final int totalMultiplasEnfiadas;

  /// Quantidade de linhas de highline.
  final int totalHighlines;

  /// Tamanho total estimado para download em bytes, se computado.
  final int? tamanhoDownloadBytes;

  const EstatisticasPico({
    this.totalVias = 0,
    this.totalSetores = 0,
    this.totalEsportivas = 0,
    this.totalMoveis = 0,
    this.totalBoulders = 0,
    this.totalMultiplasEnfiadas = 0,
    this.totalHighlines = 0,
    this.tamanhoDownloadBytes,
  });

  /// Converte para um mapa para manter compatibilidade com códigos legados.
  Map<String, dynamic> paraMapa() {
    return {
      'totalVias': totalVias,
      'totalSetores': totalSetores,
      'totalEsportivas': totalEsportivas,
      'totalMoveis': totalMoveis,
      'totalBoulders': totalBoulders,
      'totalMultiplasEnfiadas': totalMultiplasEnfiadas,
      'totalHighlines': totalHighlines,
      'tamanhoDownloadBytes': tamanhoDownloadBytes,
    };
  }

  /// Instancia o objeto a partir de um mapa de dados legado.
  factory EstatisticasPico.deMapa(Map<String, dynamic> mapa) {
    return EstatisticasPico(
      totalVias: (mapa['totalVias'] as num?)?.toInt() ?? 0,
      totalSetores: (mapa['totalSetores'] as num?)?.toInt() ?? 0,
      totalEsportivas: (mapa['totalEsportivas'] as num?)?.toInt() ?? 0,
      totalMoveis: (mapa['totalMoveis'] as num?)?.toInt() ?? 0,
      totalBoulders: (mapa['totalBoulders'] as num?)?.toInt() ?? 0,
      totalMultiplasEnfiadas:
          (mapa['totalMultiplasEnfiadas'] as num?)?.toInt() ?? 0,
      totalHighlines: (mapa['totalHighlines'] as num?)?.toInt() ?? 0,
      tamanhoDownloadBytes:
          (mapa['tamanhoDownloadBytes'] as num?)?.toInt(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EstatisticasPico &&
          runtimeType == other.runtimeType &&
          totalVias == other.totalVias &&
          totalSetores == other.totalSetores &&
          totalEsportivas == other.totalEsportivas &&
          totalMoveis == other.totalMoveis &&
          totalBoulders == other.totalBoulders &&
          totalMultiplasEnfiadas == other.totalMultiplasEnfiadas &&
          totalHighlines == other.totalHighlines &&
          tamanhoDownloadBytes == other.tamanhoDownloadBytes;

  @override
  int get hashCode => Object.hash(
        totalVias,
        totalSetores,
        totalEsportivas,
        totalMoveis,
        totalBoulders,
        totalMultiplasEnfiadas,
        totalHighlines,
        tamanhoDownloadBytes,
      );

  @override
  String toString() =>
      'EstatisticasPico(totalVias: $totalVias, totalSetores: $totalSetores)';
}
