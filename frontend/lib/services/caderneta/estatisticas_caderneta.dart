// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../../data/modelos/cadena.dart';
import '../../data/modelos/tipo_ascensao.dart';
import 'compilador_estatisticas.dart';

/// Consolidação analítica e métricas de desempenho esportivo da caderneta do escalador.
///
/// Apresenta dados agregados de ascensões, taxas de encadenamento rápido (À Vista e Flash)
/// e a distribuição em pirâmide de graduação para vias de falésia e blocos de boulder.
class EstatisticasCaderneta {
  /// Quantidade total de registros efetuados (cadenas e tentativas combinadas).
  final int totalAscensoes;

  /// Quantidade de vias ou boulders encadenados com sucesso ([TipoAscensao.isCadena] == true).
  final int totalCadenas;

  /// Quantidade de tentativas sem cadena registradas.
  final int totalTentativas;

  /// Distribuição das ascensões agrupadas por cada estilo esportivo.
  final Map<TipoAscensao, int> contagemPorEstilo;

  /// Pirâmide de graduação de vias (grau formatado -> quantidade de cadenas),
  /// ordenada do grau mais fácil para o mais desafiador.
  final Map<String, int> piramideVias;

  /// Pirâmide de graduação de boulders (grau V -> quantidade de cadenas),
  /// ordenada do grau mais fácil para o mais desafiador.
  final Map<String, int> piramideBoulders;

  /// Maior grau conquistado em via com sucesso.
  final String? maiorGrauVia;

  /// Maior grau conquistado em boulder com sucesso.
  final String? maiorGrauBoulder;

  /// Porcentagem de cadenas conquistadas no primeiro contato (À Vista + Flash)
  /// em relação ao total de cadenas conquistadas (0.0 a 100.0%).
  final double taxaAVistaFlash;

  /// Construtor imutável com todos os campos de estatística esportiva.
  const EstatisticasCaderneta({
    required this.totalAscensoes,
    required this.totalCadenas,
    required this.totalTentativas,
    required this.contagemPorEstilo,
    required this.piramideVias,
    required this.piramideBoulders,
    this.maiorGrauVia,
    this.maiorGrauBoulder,
    required this.taxaAVistaFlash,
  });

  /// Cria uma instância zerada para quando não houver ascensões registradas.
  factory EstatisticasCaderneta.vazia() => const EstatisticasCaderneta(
    totalAscensoes: 0,
    totalCadenas: 0,
    totalTentativas: 0,
    contagemPorEstilo: {},
    piramideVias: {},
    piramideBoulders: {},
    maiorGrauVia: null,
    maiorGrauBoulder: null,
    taxaAVistaFlash: 0.0,
  );

  /// Processa a lista de [cadenas] e compila as estatísticas consolidadas delegando
  /// a lógica de cálculo ao [CompiladorEstatisticasCaderneta].
  factory EstatisticasCaderneta.calcular(
    List<Cadena> cadenas, {
    String? Function(String escaladaUid)? obterGrauDaVia,
  }) => CompiladorEstatisticasCaderneta.compilar(
    cadenas,
    obterGrauDaVia: obterGrauDaVia,
  );

  /// Retorna uma cópia das estatísticas com campos seletivamente substituídos.
  EstatisticasCaderneta copyWith({
    int? totalAscensoes,
    int? totalCadenas,
    int? totalTentativas,
    Map<TipoAscensao, int>? contagemPorEstilo,
    Map<String, int>? piramideVias,
    Map<String, int>? piramideBoulders,
    String? maiorGrauVia,
    String? maiorGrauBoulder,
    double? taxaAVistaFlash,
  }) {
    return EstatisticasCaderneta(
      totalAscensoes: totalAscensoes ?? this.totalAscensoes,
      totalCadenas: totalCadenas ?? this.totalCadenas,
      totalTentativas: totalTentativas ?? this.totalTentativas,
      contagemPorEstilo: contagemPorEstilo ?? this.contagemPorEstilo,
      piramideVias: piramideVias ?? this.piramideVias,
      piramideBoulders: piramideBoulders ?? this.piramideBoulders,
      maiorGrauVia: maiorGrauVia ?? this.maiorGrauVia,
      maiorGrauBoulder: maiorGrauBoulder ?? this.maiorGrauBoulder,
      taxaAVistaFlash: taxaAVistaFlash ?? this.taxaAVistaFlash,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EstatisticasCaderneta) return false;

    if (other.totalAscensoes != totalAscensoes ||
        other.totalCadenas != totalCadenas ||
        other.totalTentativas != totalTentativas ||
        other.maiorGrauVia != maiorGrauVia ||
        other.maiorGrauBoulder != maiorGrauBoulder ||
        (other.taxaAVistaFlash - taxaAVistaFlash).abs() > 0.001) {
      return false;
    }

    if (other.piramideVias.length != piramideVias.length) return false;
    for (final key in piramideVias.keys) {
      if (other.piramideVias[key] != piramideVias[key]) return false;
    }

    if (other.piramideBoulders.length != piramideBoulders.length) return false;
    for (final key in piramideBoulders.keys) {
      if (other.piramideBoulders[key] != piramideBoulders[key]) return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(
    totalAscensoes,
    totalCadenas,
    totalTentativas,
    maiorGrauVia,
    maiorGrauBoulder,
    taxaAVistaFlash.round(),
  );

  @override
  String toString() {
    return 'EstatisticasCaderneta(totalAscensoes: $totalAscensoes, totalCadenas: $totalCadenas, maiorVia: $maiorGrauVia, maiorBoulder: $maiorGrauBoulder)';
  }
}
