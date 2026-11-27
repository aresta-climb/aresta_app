// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

/// Grade regular imutável de elevação regional SRTM embarcada offline (`int16` em metros),
/// cobrindo os estados de escalada sem depender de ondas procedurais sintéticas.
class GradeElevacaoRegionalOffline {
  final double latMin;
  final double lonMin;
  final double passoGraus;
  final int linhas;
  final int colunas;
  final Int16List cotasMetros;

  const GradeElevacaoRegionalOffline({
    required this.latMin,
    required this.lonMin,
    required this.passoGraus,
    required this.linhas,
    required this.colunas,
    required this.cotasMetros,
  });

  double get latMax => latMin + (linhas - 1) * passoGraus;
  double get lonMax => lonMin + (colunas - 1) * passoGraus;

  factory GradeElevacaoRegionalOffline.deMapa(Map<String, dynamic> mapa) {
    final latMin = mapa['lat_min'];
    final lonMin = mapa['lon_min'];
    final passo = mapa['passo_graus'];
    final linhas = mapa['linhas'];
    final colunas = mapa['colunas'];
    final b64 = mapa['cotas_int16_b64'];
    if (latMin is! num ||
        lonMin is! num ||
        passo is! num ||
        passo <= 0 ||
        linhas is! num ||
        colunas is! num ||
        linhas < 2 ||
        colunas < 2 ||
        b64 is! String ||
        b64.isEmpty) {
      throw const FormatException('GradeElevacaoRegionalOffline inválida.');
    }

    final nLin = linhas.round();
    final nCol = colunas.round();
    final bytes = base64Decode(b64);
    if (bytes.length != nLin * nCol * 2) {
      throw const FormatException(
        'Tamanho do buffer int16 incompatível em GradeElevacaoRegionalOffline.',
      );
    }
    final bd = ByteData.sublistView(bytes);
    final cotas = Int16List(nLin * nCol);
    for (var i = 0; i < cotas.length; i++) {
      cotas[i] = bd.getInt16(i * 2, Endian.little);
    }

    return GradeElevacaoRegionalOffline(
      latMin: latMin.toDouble(),
      lonMin: lonMin.toDouble(),
      passoGraus: passo.toDouble(),
      linhas: nLin,
      colunas: nCol,
      cotasMetros: cotas,
    );
  }

  /// Amostra bilinearmente a altitude real em metros ou retorna `null` fora da cobertura regional.
  double? amostrarBilinear(double latitude, double longitude) {
    final gy = (latitude - latMin) / passoGraus;
    final gx = (longitude - lonMin) / passoGraus;
    if (gy < 0.0 ||
        gy > (linhas - 1).toDouble() ||
        gx < 0.0 ||
        gx > (colunas - 1).toDouble()) {
      return null;
    }

    final j0 = gy.floor().clamp(0, linhas - 1);
    final i0 = gx.floor().clamp(0, colunas - 1);
    final j1 = math.min(linhas - 1, j0 + 1);
    final i1 = math.min(colunas - 1, i0 + 1);
    final fy = gy - j0;
    final fx = gx - i0;

