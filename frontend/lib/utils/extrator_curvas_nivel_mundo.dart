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
        2 => 0.0035, // ~385 m (maciços e vales amplos sem ruído sub-grade)
        1 => 0.0100, // ~1,1 km (escala sub-regional / municipal)
        _ => 0.0280, // ~3,1 km (escala regional)
      };

  /// Intervalo vertical limpo entre linhas de contorno (em metros) para cada [nivelDetalhe],
  /// priorizando poucas linhas sólidas e informativas em vez de micro-curvas poluídas.
  static double intervaloCotaMenorPorNivel(int nivelDetalhe) =>
      switch (nivelDetalhe) {
        2 => 100.0, // Zoom próximo: cotas redondas a cada 100 m (mestras a cada 200 m)
        1 => 150.0, // Escala municipal: cotas a cada 150 m (mestras a cada 300 m)
        _ => 250.0, // Escala regional: cotas a cada 250 m (mestras a cada 500 m)
      };

  /// Calcula o bloco quantizado do mundo que cobre integralmente [janela] (incluindo o sul próximo
  /// à câmera inclinada em 3D, como a Serra do Curral em BH), mantendo memoização `O(1)` durante o pan.
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
    final passoBase = passoGradePorNivel(nivelDetalhe);
    const maxCelulasEixo = 68;
    const quarteiraoQuantizado = 6;

    final spanLat = (janela.maxLat - janela.minLat).clamp(0.01, 16.0);
    final spanLon = (janela.maxLon - janela.minLon).clamp(0.01, 20.0);
    final multPasso = math.max(
      1,
      (math.max(spanLat, spanLon) / (passoBase * (maxCelulasEixo - 12))).ceil(),
    );
    final passo = passoBase * multPasso;

    final jMinBruto = (janela.minLat / passo).floor() - 2;
    final jMaxBruto = (janela.maxLat / passo).ceil() + 2;
    final iMinBruto = (janela.minLon / passo).floor() - 2;
    final iMaxBruto = (janela.maxLon / passo).ceil() + 2;

    final jMin =
        (jMinBruto / quarteiraoQuantizado).floor() * quarteiraoQuantizado;
    final jMax = math.min(
      jMin + maxCelulasEixo,
      (jMaxBruto / quarteiraoQuantizado).ceil() * quarteiraoQuantizado,
    );
    final iMin =
        (iMinBruto / quarteiraoQuantizado).floor() * quarteiraoQuantizado;
    final iMax = math.min(
      iMin + maxCelulasEixo,
      (iMaxBruto / quarteiraoQuantizado).ceil() * quarteiraoQuantizado,
    );

    final chave = Object.hash(nivelDetalhe, multPasso, iMin, iMax, jMin, jMax);
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
    const multiploMestra = 2;

    final nVertsX = cols + 1;
    var elevs = List<double>.filled((rows + 1) * nVertsX, 0.0);
    for (var r = 0; r <= rows; r++) {
      final lat = (bloco.jMin + r) * passo;
      for (var c = 0; c <= cols; c++) {
        final lon = (bloco.iMin + c) * passo;
        elevs[r * nVertsX + c] = amostrarElevacaoMetros(lat, lon);
      }
    }

    // Filtro espacial Gaussiano separável [1, 2, 1]/4 (2 passadas) para eliminar serrilhados e
    // micro-bolhas de dossel/pedreira do SRTM, preservando apenas cristas e vales estruturais.
    elevs = _suavizarGradeGaussiana(elevs, rows: rows, cols: cols, passadas: 2);

    var zGlobalMin = double.infinity;
    var zGlobalMax = double.negativeInfinity;
    for (final z in elevs) {
      if (z < zGlobalMin) zGlobalMin = z;
      if (z > zGlobalMax) zGlobalMax = z;
    }

    if (!zGlobalMax.isFinite || zGlobalMax < 25.0) {
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

    // Limita estritamente a no máximo 6 níveis verticais limpos e sólidos na tela
    final saltoNiveis = math.max(1, ((kFim - kIni + 1) / 6).ceil());
    final raioPicoGraus = nivelDetalhe == 2 ? 0.032 : (nivelDetalhe == 1 ? 0.050 : 0.090);
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

          Offset interpSul() => Offset(
                lon0 + _fracao(z00, z10, cota) * passo,
                lat0,
              );
          Offset interpLeste() => Offset(
                lon1,
                lat0 + _fracao(z10, z11, cota) * passo,
              );
          Offset interpNorte() => Offset(
                lon0 + _fracao(z01, z11, cota) * passo,
                lat1,
              );
          Offset interpOeste() => Offset(
                lon0,
                lat0 + _fracao(z00, z01, cota) * passo,
              );

          switch (mascara) {
            case 1:
            case 14:
              segmentos.add((interpOeste(), interpSul()));
            case 2:
            case 13:
              segmentos.add((interpSul(), interpLeste()));
            case 3:
            case 12:
              segmentos.add((interpOeste(), interpLeste()));
            case 4:
            case 11:
              segmentos.add((interpLeste(), interpNorte()));
            case 6:
            case 9:
              segmentos.add((interpSul(), interpNorte()));
            case 7:
            case 8:
              segmentos.add((interpOeste(), interpNorte()));
            case 5:
              final media = (z00 + z10 + z11 + z01) * 0.25;
              if (media >= cota) {
                segmentos
                  ..add((interpOeste(), interpNorte()))
                  ..add((interpSul(), interpLeste()));
              } else {
                segmentos
                  ..add((interpOeste(), interpSul()))
                  ..add((interpLeste(), interpNorte()));
              }
            case 10:
              final media = (z00 + z10 + z11 + z01) * 0.25;
              if (media >= cota) {
                segmentos
                  ..add((interpOeste(), interpSul()))
                  ..add((interpLeste(), interpNorte()));
              } else {
                segmentos
                  ..add((interpOeste(), interpNorte()))
                  ..add((interpSul(), interpLeste()));
              }
          }
        }
      }

      if (segmentos.isEmpty) continue;
      final polilinhas = _costurarESuavizarPolilinhas(segmentos, passo);
      for (final poli in polilinhas) {
        if (poli.length < 3) continue;
        final meio = poli[poli.length ~/ 2];
        final cosLat = math.max(0.35, math.cos(meio.dy * _grausParaRad));
        var ehEscarpa = false;
        if (ehMestra) {
          for (final p in picosReferencia) {
            final dx = (meio.dx - p.longitude) * cosLat;
            final dy = meio.dy - p.latitude;
            if (dx * dx + dy * dy <= raioPicoGraus2) {
              ehEscarpa = true;
              break;
            }
          }
        }

        final ancoraRotulo = (ehMestra && poli.length >= 9)
            ? _escolherAncoraDeterministicaMundo(poli, passo)
            : null;
        curvas.add(
          CurvaNivelMundo(
            cotaMetros: cotaInt,
            ehMestra: ehMestra,
            ehEscarpaPico: ehEscarpa,
            verticesLonLat: poli,
            ancoraRotuloLonLat: ancoraRotulo,
          ),
        );
      }
    }

    return ConjuntoCurvasNivelMundo(
      chaveBloco: bloco.chaveBloco,
      nivelDetalhe: nivelDetalhe,
      versaoDadosElevacao: versaoDadosElevacao,
      curvas: List<CurvaNivelMundo>.unmodifiable(curvas),
    );
  }

  static double _fracao(double z1, double z2, double cota) {
    final denom = z2 - z1;
    if (denom.abs() < 1e-6) return 0.5;
    return ((cota - z1) / denom).clamp(0.02, 0.98);
  }

  static List<List<Offset>> _costurarESuavizarPolilinhas(
    List<(Offset, Offset)> segmentos,
    double passoGraus,
  ) {
    final escalaChave = 2048.0 / passoGraus;
    int chavePonto(Offset p) {
      final qx = (p.dx * escalaChave).round() + 500000000;
      final qy = (p.dy * escalaChave).round() + 500000000;
      return qx * 1000000007 + qy;
    }

    final n = segmentos.length;
    final usado = List<bool>.filled(n, false);
    final porVertice = <int, List<int>>{};
    for (var i = 0; i < n; i++) {
      final ka = chavePonto(segmentos[i].$1);
      final kb = chavePonto(segmentos[i].$2);
      (porVertice[ka] ??= <int>[]).add(i);
      (porVertice[kb] ??= <int>[]).add(i);
    }

    int? proximoSegmento(int chaveExtremidade) {
      final candidatos = porVertice[chaveExtremidade];
      if (candidatos == null) return null;
      for (final idx in candidatos) {
        if (!usado[idx]) return idx;
      }
      return null;
    }

    final resultado = <List<Offset>>[];
    for (var i = 0; i < n; i++) {
      if (usado[i]) continue;
      usado[i] = true;

      final frente = <Offset>[segmentos[i].$1, segmentos[i].$2];
      while (true) {
        final kFim = chavePonto(frente.last);
        final prox = proximoSegmento(kFim);
        if (prox == null) break;
        usado[prox] = true;
        final seg = segmentos[prox];
        final ka = chavePonto(seg.$1);
        frente.add(ka == kFim ? seg.$2 : seg.$1);
      }

      final tras = <Offset>[];
      while (true) {
        final kIni = chavePonto(tras.isEmpty ? frente.first : tras.last);
        final prox = proximoSegmento(kIni);
        if (prox == null) break;
        usado[prox] = true;
        final seg = segmentos[prox];
        final ka = chavePonto(seg.$1);
        tras.add(ka == kIni ? seg.$2 : seg.$1);
      }

      final cadeia = <Offset>[
        for (var t = tras.length - 1; t >= 0; t--) tras[t],
        ...frente,
      ];
      final fechado = cadeia.length >= 4 &&
          (cadeia.first - cadeia.last).distanceSquared <
              (passoGraus * 0.08) * (passoGraus * 0.08);
      // Descarta fragmentos curtos e micro-anéis isolados de topo de morro para manter visual limpo
      final minVerticesBrutos = fechado ? 9 : 6;
      if (cadeia.length >= minVerticesBrutos) {
        resultado.add(_suavizarChaikin(cadeia, fechado: fechado));
      }
    }
    return resultado;
  }

  static List<double> _suavizarGradeGaussiana(
    List<double> entrada, {
    required int rows,
    required int cols,
    required int passadas,
  }) {
    final nVertsX = cols + 1;
    var atual = entrada;
    for (var p = 0; p < passadas; p++) {
      final horiz = List<double>.filled(atual.length, 0.0);
      for (var r = 0; r <= rows; r++) {
        final base = r * nVertsX;
        for (var c = 0; c <= cols; c++) {
          final cEsq = c > 0 ? c - 1 : 0;
          final cDir = c < cols ? c + 1 : cols;
          horiz[base + c] =
              (atual[base + cEsq] + 2.0 * atual[base + c] + atual[base + cDir]) *
                  0.25;
        }
      }
      final vert = List<double>.filled(atual.length, 0.0);
      for (var r = 0; r <= rows; r++) {
        final rSul = r > 0 ? r - 1 : 0;
        final rNorte = r < rows ? r + 1 : rows;
        final bSul = rSul * nVertsX;
        final bCen = r * nVertsX;
        final bNor = rNorte * nVertsX;
        for (var c = 0; c <= cols; c++) {
          vert[bCen + c] =
              (horiz[bSul + c] + 2.0 * horiz[bCen + c] + horiz[bNor + c]) *
                  0.25;
        }
      }
      atual = vert;
    }
    return atual;
  }

  /// Aplica 3 iterações de corte de cantos *Chaikin* para gerar curvas topográficas contínuas sem quinas.
  static List<Offset> _suavizarChaikin(
    List<Offset> pontos, {
    required bool fechado,
  }) {
    var atual = pontos;
    for (var iter = 0; iter < 3; iter++) {
      if (atual.length < 3) break;
      final prox = <Offset>[];
      if (fechado) {
        final m = atual.length - 1;
        for (var i = 0; i < m; i++) {
          final a = atual[i];
          final b = atual[(i + 1) % m];
          prox
            ..add(Offset(a.dx * 0.75 + b.dx * 0.25, a.dy * 0.75 + b.dy * 0.25))
            ..add(Offset(a.dx * 0.25 + b.dx * 0.75, a.dy * 0.25 + b.dy * 0.75));
        }
        if (prox.isNotEmpty) prox.add(prox.first);
      } else {
        prox.add(atual.first);
        for (var i = 0; i < atual.length - 1; i++) {
          final a = atual[i];
          final b = atual[i + 1];
          prox
            ..add(Offset(a.dx * 0.75 + b.dx * 0.25, a.dy * 0.75 + b.dy * 0.25))
            ..add(Offset(a.dx * 0.25 + b.dx * 0.75, a.dy * 0.25 + b.dy * 0.75));
        }
        prox.add(atual.last);
      }
      atual = prox;
    }
    return List<Offset>.unmodifiable(atual);
  }

  /// Escolhe um vértice canônico em espaço do mundo (ex.: extremo norte da curva) para que
  /// a etiqueta `800 m` jamais salte entre vértices quando a câmera se move.
  static Offset _escolherAncoraDeterministicaMundo(
    List<Offset> poli,
    double passo,
  ) {
    var melhor = poli[poli.length ~/ 2];
    for (var i = 2; i < poli.length - 2; i++) {
      final p = poli[i];
      if (p.dy > melhor.dy + passo * 0.01) {
        melhor = p;
      }
    }
    return melhor;
  }
}
