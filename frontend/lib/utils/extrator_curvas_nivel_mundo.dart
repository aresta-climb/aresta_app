// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;
import 'dart:ui';

import '../data/modelos/modelos_rede_viaria_aresta.dart';
import '../data/modelos/modelos_relevo_topografico.dart';
import 'geometria_clipping_mapa.dart';

/// Extrator cartográfico puro e sem estado de curvas de nível ancoradas em coordenadas fixas do mundo.
///
/// Resolve definitivamente o artefato de ondulação/caleidoscópio ao mover a câmera:
/// 1. Quantiza a grade de amostragem em múltiplos inteiros exatos de `passoGraus` no espaço `(lat, lon)`.
/// 2. Executa *Marching Squares* com desempate assintótico em pontos de sela (nunca cruza curvas em `X`).
/// 3. Conecta arestas vizinhas em polilinhas contínuas e aplica suavização *Chaikin* de 2 estágios.
/// 4. Ancora os rótulos de cota mestra (`800 m`, `1200 m`) em coordenadas fixas do mundo.
abstract final class ExtratorCurvasNivelMundo {
  static const double _grausParaRad = math.pi / 180.0;

  /// Determina a faixa discreta de detalhe (`0`, `1` ou `2`) a partir do `LOD` da câmera.
  static int resolverNivelDetalhe(double lod) {
    if (lod >= 3.55) return 2;
    if (lod >= 2.72) return 1;
    return 0;
  }

  /// Passo angular fixo no mundo (em graus) correspondente a cada [nivelDetalhe].
  static double passoGradePorNivel(int nivelDetalhe) => switch (nivelDetalhe) {
        2 => 0.0025, // ~275 m (paredes, vales e maciços em zoom próximo)
        1 => 0.0080, // ~880 m (escala sub-regional / municipal)
        _ => 0.0250, // ~2,7 km (escala regional)
      };

  /// Intervalo vertical entre curvas secundárias (em metros) para cada [nivelDetalhe].
  static double intervaloCotaMenorPorNivel(int nivelDetalhe) =>
      switch (nivelDetalhe) {
        2 => 25.0, // Secundárias a cada 25 m, mestras a cada 100 m
        1 => 50.0, // Secundárias a cada 50 m, mestras a cada 200 m
        _ => 100.0, // Secundárias a cada 100 m, mestras a cada 400 m
      };

  /// Calcula o bloco quantizado do mundo que cobre [janela], permitindo memoização `O(1)` durante o pan.
  static ({
    int chaveBloco,
    int iMin,
    int iMax,
    int jMin,
    int jMax,
    double passoGraus,
  }) calcularGradeBlocoMundo({
    required JanelaGeograficaVisivel janela,
    required int nivelDetalhe,
  }) {
    final passo = passoGradePorNivel(nivelDetalhe);
    const maxCelulasEixo = 52;
    const meioBloco = maxCelulasEixo ~/ 2;
    const quarteiraoQuantizado = 8;

    final latCentro = (janela.minLat + janela.maxLat) * 0.5;
    final lonCentro = (janela.minLon + janela.maxLon) * 0.5;

    final jCentro = ((latCentro / passo) / quarteiraoQuantizado).round() *
        quarteiraoQuantizado;
    final iCentro = ((lonCentro / passo) / quarteiraoQuantizado).round() *
        quarteiraoQuantizado;

    final spanJ = (((janela.maxLat - janela.minLat) * 0.58) / passo)
        .ceil()
        .clamp(10, meioBloco);
    final spanI = (((janela.maxLon - janela.minLon) * 0.58) / passo)
        .ceil()
        .clamp(10, meioBloco);

    final jMin = jCentro - spanJ;
    final jMax = jCentro + spanJ;
    final iMin = iCentro - spanI;
    final iMax = iCentro + spanI;

    final chave = Object.hash(nivelDetalhe, iMin, iMax, jMin, jMax);
    return (
      chaveBloco: chave,
      iMin: iMin,
      iMax: iMax,
      jMin: jMin,
      jMax: jMax,
      passoGraus: passo,
    );
  }

  /// Extrai polilinhas topográficas suaves em coordenadas fixas do mundo usando [amostrarElevacaoMetros].
  static ConjuntoCurvasNivelMundo extrairCurvasBloco({
    required JanelaGeograficaVisivel janela,
    required int nivelDetalhe,
    required int versaoDadosElevacao,
    required double Function(double latitude, double longitude)
        amostrarElevacaoMetros,
    required List<PicoRelevoReferencia> picosReferencia,
  }) {
    final bloco = calcularGradeBlocoMundo(
      janela: janela,
      nivelDetalhe: nivelDetalhe,
    );
    final cols = bloco.iMax - bloco.iMin;
    final rows = bloco.jMax - bloco.jMin;
    final passo = bloco.passoGraus;
    final cotaPasso = intervaloCotaMenorPorNivel(nivelDetalhe);
    const multiploMestra = 4;

    final nVertsX = cols + 1;
    final elevs = List<double>.filled((rows + 1) * nVertsX, 0.0);
    var zGlobalMin = double.infinity;
    var zGlobalMax = double.negativeInfinity;

    for (var r = 0; r <= rows; r++) {
      final lat = (bloco.jMin + r) * passo;
      for (var c = 0; c <= cols; c++) {
        final lon = (bloco.iMin + c) * passo;
        final z = amostrarElevacaoMetros(lat, lon);
        elevs[r * nVertsX + c] = z;
        if (z < zGlobalMin) zGlobalMin = z;
        if (z > zGlobalMax) zGlobalMax = z;
      }
    }

    if (!zGlobalMax.isFinite || zGlobalMax < 25.0 || (zGlobalMax - zGlobalMin) < cotaPasso * 0.5) {
      return ConjuntoCurvasNivelMundo(
        chaveBloco: bloco.chaveBloco,
        nivelDetalhe: nivelDetalhe,
        versaoDadosElevacao: versaoDadosElevacao,
        curvas: const [],
      );
    }

    final kIni = math.max(1, (zGlobalMin / cotaPasso).ceil());
    final kFim = (zGlobalMax / cotaPasso).floor();
    if (kFim < kIni) {
      return ConjuntoCurvasNivelMundo(
        chaveBloco: bloco.chaveBloco,
        nivelDetalhe: nivelDetalhe,
        versaoDadosElevacao: versaoDadosElevacao,
        curvas: const [],
      );
    }

    final saltoNiveis = math.max(1, ((kFim - kIni + 1) / 22).ceil());
    final raioPicoGraus = nivelDetalhe == 2 ? 0.028 : (nivelDetalhe == 1 ? 0.045 : 0.085);
    final raioPicoGraus2 = raioPicoGraus * raioPicoGraus;
    final curvas = <CurvaNivelMundo>[];

    for (var k = kIni; k <= kFim; k++) {
      final ehMestra = k % multiploMestra == 0;
      if (!ehMestra && (k - kIni) % saltoNiveis != 0) continue;
      final cota = k * cotaPasso;
      final cotaInt = cota.round();
      final segmentos = <(Offset, Offset)>[];

      for (var r = 0; r < rows; r++) {
        final lat0 = (bloco.jMin + r) * passo;
        final lat1 = lat0 + passo;
        for (var c = 0; c < cols; c++) {
          final i00 = r * nVertsX + c;
          final z00 = elevs[i00];
          final z10 = elevs[i00 + 1];
          final z11 = elevs[i00 + nVertsX + 1];
          final z01 = elevs[i00 + nVertsX];

          var mascara = 0;
          if (z00 >= cota) mascara |= 1;
          if (z10 >= cota) mascara |= 2;
          if (z11 >= cota) mascara |= 4;
          if (z01 >= cota) mascara |= 8;
          if (mascara == 0 || mascara == 15) continue;

          final lon0 = (bloco.iMin + c) * passo;
          final lon1 = lon0 + passo;

