// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;
import 'modelos_fenomenos_clima.dart';

export 'modelos_fenomenos_clima.dart';

/// Registro individual de precipitação diária acumulada associado a um pico específico.
class EventoChuvaPico {
  final DateTime data;
  final double milimetros;
  final String? bolhaId;

  const EventoChuvaPico({
    required this.data,
    required this.milimetros,
    this.bolhaId,
  });

  factory EventoChuvaPico.deMapa(Map<String, dynamic> mapa) {
    final dataTxt = mapa['data'];
    final mm = mapa['mm'];
    if (dataTxt is! String || mm is! num) {
      throw const FormatException('EventoChuvaPico inválido.');
    }
    final parsed = DateTime.tryParse(dataTxt);
    if (parsed == null) {
      throw const FormatException('Data inválida em EventoChuvaPico.');
    }
    return EventoChuvaPico(
      data: DateTime.utc(parsed.year, parsed.month, parsed.day),
      milimetros: mm.toDouble(),
      bolhaId: mapa['bolha_id'] as String?,
    );
  }

  Map<String, dynamic> paraMapa() => <String, dynamic>{
        'data': _formatarDataIsoCurta(data),
        'mm': milimetros,
        if (bolhaId != null) 'bolha_id': bolhaId,
      };
}

/// Cotas altimétricas e grade DEM local extraídas de satélite (NASA SRTM 30m / NASADEM).
class CotaAltimetricaPico {
  final int altitudeBaseMetros;
  final int altitudePicoMetros;
  final int? altitudePontoMetros;
  final int dimensaoGradeDem;
  final double raioGradeDemGraus;
  final List<int> gradeDemMetros;

  const CotaAltimetricaPico({
    required this.altitudeBaseMetros,
    required this.altitudePicoMetros,
    this.altitudePontoMetros,
    this.dimensaoGradeDem = 0,
    this.raioGradeDemGraus = 0.024,
    this.gradeDemMetros = const [],
  });

  /// Retorna nova instância preservando a grade DEM de [anterior] caso esta instância não traga grade.
  CotaAltimetricaPico preservandoGradeSeAusente(
    CotaAltimetricaPico? anterior,
  ) {
    if (gradeDemMetros.isNotEmpty ||
        anterior == null ||
        anterior.gradeDemMetros.isEmpty) {
      return this;
    }
    return CotaAltimetricaPico(
      altitudeBaseMetros: altitudeBaseMetros,
      altitudePicoMetros: altitudePicoMetros,
      altitudePontoMetros: altitudePontoMetros ?? anterior.altitudePontoMetros,
      dimensaoGradeDem: anterior.dimensaoGradeDem,
      raioGradeDemGraus: anterior.raioGradeDemGraus,
      gradeDemMetros: anterior.gradeDemMetros,
    );
  }

  factory CotaAltimetricaPico.deMapa(Map<String, dynamic> mapa) {
    final base = mapa['altitude_base_m'];
    final pico = mapa['altitude_pico_m'];
    if (base is! num ||
        pico is! num ||
        base < -50 ||
        pico > 4500 ||
        pico < base) {
      throw const FormatException(
        'CotaAltimetricaPico fora dos limites válidos.',
      );
    }

    final pontoRaw = mapa['altitude_ponto_m'];
    final ponto = pontoRaw is num ? pontoRaw.round() : null;

    var dimGrade = 0;
    var raioGraus = 0.024;
    var grade = const <int>[];

    final gradeBruta = mapa['grade_dem_m'];
    if (gradeBruta != null) {
      if (gradeBruta is! List || gradeBruta.length < 4) {
        throw const FormatException(
          'Grade DEM inválida em CotaAltimetricaPico.',
        );
      }
      final dimRaw = mapa['dimensao_grade'];
      dimGrade = dimRaw is num
          ? dimRaw.round()
          : math.sqrt(gradeBruta.length).round();
      if (dimGrade < 2 || dimGrade * dimGrade != gradeBruta.length) {
        throw const FormatException(
          'Dimensão da grade DEM incompatível com o número de amostras.',
        );
      }
      final raioRaw = mapa['raio_grade_graus'];
      if (raioRaw != null) {
        if (raioRaw is! num || raioRaw <= 0) {
          throw const FormatException('Raio angular da grade DEM inválido.');
        }
        raioGraus = raioRaw.toDouble();
      }
      final convertida = <int>[];
      for (final item in gradeBruta) {
        if (item is! num) {
          throw const FormatException('Amostra não numérica na grade DEM.');
        }
        convertida.add(item.round());
      }
      grade = List<int>.unmodifiable(convertida);
    }

    return CotaAltimetricaPico(
      altitudeBaseMetros: base.round(),
      altitudePicoMetros: pico.round(),
      altitudePontoMetros: ponto,
      dimensaoGradeDem: dimGrade,
      raioGradeDemGraus: raioGraus,
      gradeDemMetros: grade,
    );
  }

  Map<String, dynamic> paraMapa() => <String, dynamic>{
        'altitude_base_m': altitudeBaseMetros,
        'altitude_pico_m': altitudePicoMetros,
        if (altitudePontoMetros != null)
          'altitude_ponto_m': altitudePontoMetros,
        if (gradeDemMetros.isNotEmpty) ...<String, dynamic>{
          'dimensao_grade': dimensaoGradeDem,
          'raio_grade_graus': raioGradeDemGraus,
          'grade_dem_m': gradeDemMetros,
        },
      };
}

/// Estado conservador resultante calculado para um pico na data civil atual do dispositivo.
class EstadoUmidadePico {
  final NivelUmidadePico nivel;
  final int diasParaSecar;
  final int diasDesdeChuva;
  final DateTime? dataUltimaChuva;
  final double milimetrosEvento;
  final String? bolhaIdAssociada;

  const EstadoUmidadePico({
    required this.nivel,
    required this.diasParaSecar,
    this.diasDesdeChuva = 0,
    this.dataUltimaChuva,
    this.milimetrosEvento = 0.0,
    this.bolhaIdAssociada,
  });

  const EstadoUmidadePico.seco()
      : nivel = NivelUmidadePico.seco,
        diasParaSecar = 0,
        diasDesdeChuva = 0,
        dataUltimaChuva = null,
        milimetrosEvento = 0.0,
        bolhaIdAssociada = null;

