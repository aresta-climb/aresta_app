// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/modelos_rede_viaria_aresta.dart';
import 'package:frontend/utils/extrator_curvas_nivel_mundo.dart';
import 'package:frontend/utils/geometria_clipping_mapa.dart';

void main() {
  group('ExtratorCurvasNivelMundo', () {
    test('extrai tiles canônicos fixos do mundo com zero deformação de vértices ao variar janela ou nível de zoom', () {
      expect(ExtratorCurvasNivelMundo.resolverNivelDetalhe(2.10), equals(0));
      expect(ExtratorCurvasNivelMundo.resolverNivelDetalhe(2.85), equals(1));
      expect(ExtratorCurvasNivelMundo.resolverNivelDetalhe(3.50), equals(2));
      expect(ExtratorCurvasNivelMundo.resolverNivelDetalhe(4.20), equals(3));

      expect(
        ExtratorCurvasNivelMundo.passoGradePorNivel(0),
        closeTo(ExtratorCurvasNivelMundo.passoMacroGraus, 1e-6),
      );
      expect(
        ExtratorCurvasNivelMundo.passoGradePorNivel(1),
        closeTo(ExtratorCurvasNivelMundo.passoMacroGraus, 1e-6),
      );
      expect(
        ExtratorCurvasNivelMundo.passoGradePorNivel(2),
        closeTo(ExtratorCurvasNivelMundo.passoFinoGraus, 1e-6),
      );
      expect(
        ExtratorCurvasNivelMundo.passoGradePorNivel(3),
        closeTo(ExtratorCurvasNivelMundo.passoFinoGraus, 1e-6),
      );

      expect(ExtratorCurvasNivelMundo.intervaloCotaMenorPorNivel(0), equals(400.0));
      expect(ExtratorCurvasNivelMundo.intervaloCotaMenorPorNivel(1), equals(200.0));
      expect(ExtratorCurvasNivelMundo.intervaloCotaMenorPorNivel(2), equals(100.0));
      expect(ExtratorCurvasNivelMundo.intervaloCotaMenorPorNivel(3), equals(50.0));

      expect(ExtratorCurvasNivelMundo.classificarGeracaoCota(800), equals(0));
      expect(ExtratorCurvasNivelMundo.classificarGeracaoCota(1000), equals(1));
      expect(ExtratorCurvasNivelMundo.classificarGeracaoCota(900), equals(2));
      expect(ExtratorCurvasNivelMundo.classificarGeracaoCota(950), equals(3));

      final k1 = ExtratorCurvasNivelMundo.calcularChaveTileMundo(
        camadaFina: false,
        tx: -98,
        ty: -44,
        versaoDadosElevacao: 1,
        assinaturaPicos: 7,
      );
      final k2 = ExtratorCurvasNivelMundo.calcularChaveTileMundo(
        camadaFina: true,
        tx: -98,
        ty: -44,
        versaoDadosElevacao: 1,
        assinaturaPicos: 7,
      );
      expect(k1, isNot(equals(k2)));

      const pico = PicoRelevoReferencia(
        id: 'cipo',
        latitude: -19.32,
        longitude: -43.62,
        altitudeBaseMetros: 740,
        altitudePicoMetros: 1460,
      );

      double domoMontanha(double lat, double lon) {
        final dLat = lat - (-19.32);
        final dLon = lon - (-43.62);
        final r2 = dLat * dLat + dLon * dLon;
        return 680.0 + 820.0 * math.exp(-r2 / 0.0028);
      }

      const janelaAmpla = JanelaGeograficaVisivel(
        minLat: -19.42,
        maxLat: -19.22,
        minLon: -43.72,
        maxLon: -43.52,
      );
      // Mesmo após vários milímetros/níveis de zoom reduzindo a janela pela metade,
      // os vértices de 800m, 1000m, 1200m e 1400m permanecem BIT-A-BIT IDÊNTICOS!
      const janelaAproximada = JanelaGeograficaVisivel(
        minLat: -19.37,
        maxLat: -19.27,
        minLon: -43.67,
        maxLon: -43.57,
      );

      final resLonge = ExtratorCurvasNivelMundo.extrairCurvasBloco(
        janela: janelaAmpla,
        nivelDetalhe: 0,
        versaoDadosElevacao: 1,
        amostrarElevacaoMetros: domoMontanha,
        picosReferencia: const [pico],
      );
      final resPerto = ExtratorCurvasNivelMundo.extrairCurvasBloco(
        janela: janelaAproximada,
        nivelDetalhe: 3,
        versaoDadosElevacao: 1,
        amostrarElevacaoMetros: domoMontanha,
        picosReferencia: const [pico],
      );

      expect(resLonge.curvas, isNotEmpty);
      expect(resPerto.curvas.length, greaterThan(resLonge.curvas.length));
      expect(resPerto.curvas.any((c) => c.ehMestra), isTrue);
      expect(resPerto.curvas.any((c) => c.ehEscarpaPico), isTrue);
      expect(resPerto.curvas.any((c) => c.ancoraRotuloLonLat != null), isTrue);
      expect(resPerto.curvas.any((c) => c.geracaoDetalhe == 2), isTrue);
      expect(resPerto.curvas.any((c) => c.geracaoDetalhe == 3), isTrue);

      final curva1200Longe =
          resLonge.curvas.firstWhere((c) => c.cotaMetros == 1200);
      final curva1200Perto =
          resPerto.curvas.firstWhere((c) => c.cotaMetros == 1200);
      // Invariância exata bit-a-bit: ZERO deformação ao mudar zoom ou tamanho da janela!
      expect(
        curva1200Perto.verticesLonLat,
        equals(curva1200Longe.verticesLonLat),
      );
    });

    test('resolve pontos de sela (casos 5 e 10) sem cruzar curvas e retorna vazio em oceano ou planície uniforme', () {
      const janela = JanelaGeograficaVisivel(
        minLat: -20.05,
        maxLat: -19.95,
        minLon: -44.05,
        maxLon: -43.95,
      );

      final oceano = ExtratorCurvasNivelMundo.extrairCurvasBloco(
        janela: janela,
        nivelDetalhe: 1,
        versaoDadosElevacao: 0,
        amostrarElevacaoMetros: (_, _) => 0.0,
        picosReferencia: const [],
      );
      expect(oceano.curvas, isEmpty);

      final planicieEntreCotas = ExtratorCurvasNivelMundo.extrairCurvasBloco(
        janela: janela,
        nivelDetalhe: 0,
        versaoDadosElevacao: 0,
        amostrarElevacaoMetros: (lat, _) => lat > -20.0 ? 940.0 : 860.0,
        picosReferencia: const [],
      );
      expect(planicieEntreCotas.curvas, isEmpty);

      final sela = ExtratorCurvasNivelMundo.extrairCurvasBloco(
        janela: janela,
        nivelDetalhe: 2,
        versaoDadosElevacao: 2,
        picosReferencia: const [],
        amostrarElevacaoMetros: (lat, lon) {
          final x = (lon + 44.0) * 40.0;
          final y = (lat + 20.0) * 40.0;
          return 1000.0 + 320.0 * (x * y) + 140.0 * math.sin(x * 1.4 + y * 1.2);
        },
      );
      expect(sela.curvas, isNotEmpty);
      for (final c in sela.curvas) {
        expect(
          c.verticesLonLat.every((Offset p) => p.dx.isFinite && p.dy.isFinite),
          isTrue,
        );
      }
    });
  });
}
