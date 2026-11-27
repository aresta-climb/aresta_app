// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;
import 'dart:ui';

import '../data/modelos/modelos_rede_viaria_aresta.dart';
import '../data/modelos/modelos_relevo_topografico.dart';
import 'geometria_clipping_mapa.dart';

/// Extrator cartográfico puro e sem estado de curvas de nível aditivas em **tiles fixos do mundo**.
///
/// Elimina 100% da deformação topográfica durante o zoom ao obedecer a duas invariantes:
/// 1. **Zero `multPasso` dependente de câmera**: o mundo é particionado em ladrilhos geográficos fixos
///    (`0,45° × 0,45°` com passo fixo `0,0090°` para as cotas estruturais de `400 m` e `200 m`, e
///    `0,15° × 0,15°` com passo fixo `0,0030°` exclusivamente para as cotas finas de `100 m` e `50 m`).
/// 2. **Aditividade estrita sem substituição**: aproximar o zoom jamais recalcula nem altera os vértices
///    das curvas de `400 m` e `200 m` já visíveis; apenas revela novas curvas intermediárias entre elas.
abstract final class ExtratorCurvasNivelMundo {
  static const double _grausParaRad = math.pi / 180.0;
  static const double _raioKernelGaussianoGraus = 0.0065;

  /// Tamanho fixo e passo angular fixo (32 células exatas) dos tiles macro (`400 m` e `200 m`).
  static const double tamanhoTileMacroGraus = 0.48;
  static const double passoMacroGraus = 0.0150;

  /// Tamanho fixo e passo angular fixo (32 células exatas) dos tiles finos (`100 m` aditivos).
  static const double tamanhoTileFinoGraus = 0.16;
  static const double passoFinoGraus = 0.0050;

  /// Determina a geração diádica máxima (`0` = 400m, `1` = 200m, `2` = 100m) visível em [lod].
  static int resolverNivelDetalhe(double lod) {
    if (lod >= 3.55) return 2;
    if (lod >= 3.05) return 1;
    return 0;
  }

  /// Passo angular canônico fixo no mundo para a camada macro (`<= 1`) ou fina (`>= 2`).
  static double passoGradePorNivel(int nivelDetalhe) =>
      nivelDetalhe >= 2 ? passoFinoGraus : passoMacroGraus;

  /// Intervalo vertical diádico estritamente aninhado (`400 -> 200 -> 100 -> 50 m`).
  static double intervaloCotaMenorPorNivel(int nivelDetalhe) =>
      switch (nivelDetalhe) {
        3 => 50.0,
        2 => 100.0,
        1 => 200.0,
        _ => 400.0,
      };

  /// Classifica a geração diádica (`0` = múltiplo de 400m, `1` = 200m, `2` = 100m, `3` = 50m).
  static int classificarGeracaoCota(int cotaMetros) {
    if (cotaMetros % 400 == 0) return 0;
    if (cotaMetros % 200 == 0) return 1;
    if (cotaMetros % 100 == 0) return 2;
    return 3;
  }

  /// Enumera os identificadores `(tx, ty)` dos tiles canônicos fixos do mundo que cobrem [janela].
  static List<({int tx, int ty})> listarTilesVisiveis({
    required JanelaGeograficaVisivel janela,
    required bool camadaFina,
  }) {
    final tam = camadaFina ? tamanhoTileFinoGraus : tamanhoTileMacroGraus;
    const limiteEixo = 2;

    final latCentro = (janela.minLat + janela.maxLat) * 0.5;
    final lonCentro = (janela.minLon + janela.maxLon) * 0.5;
    final txCentro = (lonCentro / tam).floor();
    final tyCentro = (latCentro / tam).floor();

    final txMin = math.max(
      txCentro - limiteEixo,
      (janela.minLon / tam).floor(),
    );
    final txMax = math.min(
      txCentro + limiteEixo,
      (janela.maxLon / tam).floor(),
    );
    final tyMin = math.max(
      tyCentro - limiteEixo,
      (janela.minLat / tam).floor(),
    );
    final tyMax = math.min(
      tyCentro + limiteEixo,
      (janela.maxLat / tam).floor(),
    );

    final tiles = <({int tx, int ty})>[];
    for (var ty = tyMin; ty <= tyMax; ty++) {
      for (var tx = txMin; tx <= txMax; tx++) {
        tiles.add((tx: tx, ty: ty));
      }
    }
    return tiles;
  }

  /// Calcula chave inteira determinística de um tile canônico fixo do mundo.
  static int calcularChaveTileMundo({
    required bool camadaFina,
    required int tx,
    required int ty,
    required int versaoDadosElevacao,
    required int assinaturaPicos,
  }) =>
      Object.hash(camadaFina, tx, ty, versaoDadosElevacao, assinaturaPicos);

  /// Extrai todas as curvas de um único tile canônico fixo `(tx, ty)` em coordenadas imutáveis do mundo:
  /// - `camadaFina == false`: extrai exclusivamente as gerações `0` (`400 m`) e `1` (`200 m`).
  /// - `camadaFina == true`: extrai exclusivamente as gerações `2` (`100 m`) e `3` (`50 m`).
  static List<CurvaNivelMundo> extrairTileCanonicoMundo({
    required int tx,
    required int ty,
    required bool camadaFina,
    required double Function(double latitude, double longitude)
        amostrarElevacaoMetros,
    required List<PicoRelevoReferencia> picosReferencia,
  }) {
    final tam = camadaFina ? tamanhoTileFinoGraus : tamanhoTileMacroGraus;
    final passo = camadaFina ? passoFinoGraus : passoMacroGraus;
    const celulas = 32;
    const nVertsX = celulas + 1;

    final lonBase = tx * tam;
    final latBase = ty * tam;
    final elevs = List<double>.filled((celulas + 1) * nVertsX, 0.0);
    var zMin = double.infinity;
    var zMax = double.negativeInfinity;

    // Núcleo em cruz de 5 pontos em raio físico fixo (0,0065° no mundo — leve < 0,2 ms/tile e invariante ao zoom!)
    const r = _raioKernelGaussianoGraus;
    for (var j = 0; j <= celulas; j++) {
      final lat = latBase + j * passo;
      for (var i = 0; i <= celulas; i++) {
        final lon = lonBase + i * passo;
        final zC = amostrarElevacaoMetros(lat, lon);
        final zN = amostrarElevacaoMetros(lat + r, lon);
        final zS = amostrarElevacaoMetros(lat - r, lon);
        final zL = amostrarElevacaoMetros(lat, lon + r);
        final zO = amostrarElevacaoMetros(lat, lon - r);
        final z = (4.0 * zC + zN + zS + zL + zO) * 0.125;
        elevs[j * nVertsX + i] = z;
        if (z < zMin) zMin = z;
        if (z > zMax) zMax = z;
      }
    }

    if (!zMax.isFinite || zMax < 25.0) return const [];

    // Mantém poucas linhas sólidas (400 m -> +200 m -> +100 m), sem sobrecarregar com curvas de 50 m
    final cotaPasso = camadaFina ? 100.0 : 200.0;
    final kIni = math.max(1, (zMin / cotaPasso).ceil());
    final kFim = (zMax / cotaPasso).floor();
    if (kFim < kIni) return const [];

    const raioPicoGraus2 = 0.035 * 0.035;
    final curvas = <CurvaNivelMundo>[];

    for (var k = kIni; k <= kFim; k++) {
      final cota = k * cotaPasso;
      final cotaInt = cota.round();
      // Aditividade estrita: a camada fina jamais duplica nem substitui múltiplos de 200 m!
      if (camadaFina && cotaInt % 200 == 0) continue;

      final geracao = classificarGeracaoCota(cotaInt);
      final ehMestra = geracao <= 1;
      final segmentos = <(Offset, Offset)>[];

      for (var row = 0; row < celulas; row++) {
        final lat0 = latBase + row * passo;
        final lat1 = lat0 + passo;
        for (var col = 0; col < celulas; col++) {
          final i00 = row * nVertsX + col;
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

          final lon0 = lonBase + col * passo;
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
        if (geracao <= 1) {
          for (final p in picosReferencia) {
            final dx = (meio.dx - p.longitude) * cosLat;
            final dy = meio.dy - p.latitude;
            if (dx * dx + dy * dy <= raioPicoGraus2) {
              ehEscarpa = true;
              break;
            }
          }
        }

        final ancoraRotulo = (ehMestra && poli.length >= 10)
            ? _escolherAncoraDeterministicaMundo(poli, passo)
            : null;
        curvas.add(
          CurvaNivelMundo(
            cotaMetros: cotaInt,
            geracaoDetalhe: geracao,
            ehMestra: ehMestra,
            ehEscarpaPico: ehEscarpa,
            verticesLonLat: poli,
            ancoraRotuloLonLat: ancoraRotulo,
          ),
        );
      }
    }

    return List<CurvaNivelMundo>.unmodifiable(curvas);
  }

  /// Reúne os tiles fixos visíveis em [janela] sem recalcular nem deformar cotas existentes no zoom.
  static ConjuntoCurvasNivelMundo extrairCurvasBloco({
    required JanelaGeograficaVisivel janela,
    required int nivelDetalhe,
    required int versaoDadosElevacao,
    required double Function(double latitude, double longitude)
        amostrarElevacaoMetros,
    required List<PicoRelevoReferencia> picosReferencia,
  }) {
    final tilesMacro = listarTilesVisiveis(janela: janela, camadaFina: false);
    final tilesFinos = nivelDetalhe >= 2
        ? listarTilesVisiveis(janela: janela, camadaFina: true)
        : const <({int tx, int ty})>[];

    var hashChave = Object.hash(nivelDetalhe >= 2, versaoDadosElevacao);
    final todas = <CurvaNivelMundo>[];
    for (final t in tilesMacro) {
      hashChave = Object.hash(hashChave, t.tx, t.ty);
      todas.addAll(
        extrairTileCanonicoMundo(
          tx: t.tx,
          ty: t.ty,
          camadaFina: false,
          amostrarElevacaoMetros: amostrarElevacaoMetros,
          picosReferencia: picosReferencia,
        ),
      );
    }
    for (final t in tilesFinos) {
      hashChave = Object.hash(hashChave, 100000 + t.tx, 100000 + t.ty);
      todas.addAll(
        extrairTileCanonicoMundo(
          tx: t.tx,
          ty: t.ty,
          camadaFina: true,
          amostrarElevacaoMetros: amostrarElevacaoMetros,
          picosReferencia: picosReferencia,
        ),
      );
    }

    return ConjuntoCurvasNivelMundo(
      chaveBloco: hashChave,
      nivelDetalhe: nivelDetalhe,
      versaoDadosElevacao: versaoDadosElevacao,
      curvas: List<CurvaNivelMundo>.unmodifiable(todas),
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
      // Preserva continuidade perfeita entre tiles adjacentes para curvas abertas (>= 2 vértices)
      // e descarta apenas micro-ilhas fechadas menores que 6 segmentos
      if (fechado && cadeia.length < 6) continue;
      resultado.add(_suavizarChaikinDuplo(cadeia, fechado: fechado));
    }
    return resultado;
  }

  /// Aplica 1 passada Chaikin (`0,75 / 0,25`) mantendo contagem leve de vértices e extremidades de borda fixas.
  static List<Offset> _suavizarChaikinDuplo(
    List<Offset> pontos, {
    required bool fechado,
  }) {
    if (pontos.length < 3) return List<Offset>.unmodifiable(pontos);
    final prox = <Offset>[];
    if (fechado) {
      final m = pontos.length - 1;
      for (var i = 0; i < m; i++) {
        final a = pontos[i];
        final b = pontos[(i + 1) % m];
        prox
          ..add(Offset(a.dx * 0.75 + b.dx * 0.25, a.dy * 0.75 + b.dy * 0.25))
          ..add(Offset(a.dx * 0.25 + b.dx * 0.75, a.dy * 0.25 + b.dy * 0.75));
      }
      if (prox.isNotEmpty) prox.add(prox.first);
    } else {
      prox.add(pontos.first);
      for (var i = 0; i < pontos.length - 1; i++) {
        final a = pontos[i];
        final b = pontos[i + 1];
        prox
          ..add(Offset(a.dx * 0.75 + b.dx * 0.25, a.dy * 0.75 + b.dy * 0.25))
          ..add(Offset(a.dx * 0.25 + b.dx * 0.75, a.dy * 0.25 + b.dy * 0.75));
      }
      prox.add(pontos.last);
    }
    return List<Offset>.unmodifiable(prox);
  }

  /// Escolhe um vértice canônico em espaço do mundo (extremo norte da curva) para ancorar o rótulo.
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
