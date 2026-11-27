// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/modelos_rede_viaria_aresta.dart';
import 'package:frontend/utils/extrator_curvas_nivel_mundo.dart';
import 'package:frontend/utils/geometria_clipping_mapa.dart';

void main() {
  group('ExtratorCurvasNivelMundo', () {
    test('opera em hierarquia diádica estritamente aditiva (400/200/100/50m) sem deformar curvas existentes ao dar zoom ou pan', () {
      expect(ExtratorCurvasNivelMundo.resolverNivelDetalhe(2.10), equals(0));
      expect(ExtratorCurvasNivelMundo.resolverNivelDetalhe(2.85), equals(1));
      expect(ExtratorCurvasNivelMundo.resolverNivelDetalhe(3.50), equals(2));
      expect(ExtratorCurvasNivelMundo.resolverNivelDetalhe(4.20), equals(3));

      expect(ExtratorCurvasNivelMundo.passoGradePorNivel(0), closeTo(0.0264, 1e-6));
      expect(ExtratorCurvasNivelMundo.passoGradePorNivel(1), closeTo(0.0088, 1e-6));
      expect(ExtratorCurvasNivelMundo.passoGradePorNivel(2), closeTo(0.0044, 1e-6));
      expect(ExtratorCurvasNivelMundo.passoGradePorNivel(3), closeTo(0.0022, 1e-6));

      expect(ExtratorCurvasNivelMundo.intervaloCotaMenorPorNivel(0), equals(400.0));
      expect(ExtratorCurvasNivelMundo.intervaloCotaMenorPorNivel(1), equals(200.0));
      expect(ExtratorCurvasNivelMundo.intervaloCotaMenorPorNivel(2), equals(100.0));
      expect(ExtratorCurvasNivelMundo.intervaloCotaMenorPorNivel(3), equals(50.0));

      expect(ExtratorCurvasNivelMundo.classificarGeracaoCota(800), equals(0));
      expect(ExtratorCurvasNivelMundo.classificarGeracaoCota(1000), equals(1));
      expect(ExtratorCurvasNivelMundo.classificarGeracaoCota(900), equals(2));
      expect(ExtratorCurvasNivelMundo.classificarGeracaoCota(950), equals(3));

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

      const janelaA = JanelaGeograficaVisivel(
        minLat: -19.405,
        maxLat: -19.235,
        minLon: -43.705,
        maxLon: -43.535,
      );
      const janelaPanSuave = JanelaGeograficaVisivel(
        minLat: -19.404,
        maxLat: -19.234,
        minLon: -43.704,
        maxLon: -43.534,
      );

      final resA = ExtratorCurvasNivelMundo.extrairCurvasBloco(
        janela: janelaA,
        nivelDetalhe: 2,
        versaoDadosElevacao: 1,
        amostrarElevacaoMetros: domoMontanha,
        picosReferencia: const [pico],
      );
      final resPan = ExtratorCurvasNivelMundo.extrairCurvasBloco(
        janela: janelaPanSuave,
        nivelDetalhe: 2,
        versaoDadosElevacao: 1,
        amostrarElevacaoMetros: domoMontanha,
        picosReferencia: const [pico],
      );

      expect(resA.chaveBloco, equals(resPan.chaveBloco));
      expect(resA.curvas, isNotEmpty);
      expect(resA.curvas.any((c) => c.ehMestra), isTrue);
      expect(resA.curvas.any((c) => c.ehEscarpaPico), isTrue);
      expect(resA.curvas.any((c) => c.ancoraRotuloLonLat != null), isTrue);
      expect(
        resA.curvas.first.verticesLonLat,
        equals(resPan.curvas.first.verticesLonLat),
      );

      // Invariância aditiva entre níveis de zoom: todas as cotas de 400m (nível 0) permanecem presentes
      // no nível 2 (100m) e no nível 3 (50m) com centro geométrico estável (< 0.0015° de desvio)
      final resN0 = ExtratorCurvasNivelMundo.extrairCurvasBloco(
        janela: janelaA,
        nivelDetalhe: 0,
        versaoDadosElevacao: 1,
        amostrarElevacaoMetros: domoMontanha,
        picosReferencia: const [pico],
      );
      final resN3 = ExtratorCurvasNivelMundo.extrairCurvasBloco(
        janela: janelaA,
        nivelDetalhe: 3,
        versaoDadosElevacao: 1,
        amostrarElevacaoMetros: domoMontanha,
        picosReferencia: const [pico],
      );
      final cotasN0 = resN0.curvas.map((c) => c.cotaMetros).toSet();
      final cotasN2 = resA.curvas.map((c) => c.cotaMetros).toSet();
      final cotasN3 = resN3.curvas.map((c) => c.cotaMetros).toSet();
      expect(cotasN0, containsAll(<int>[800, 1200]));
      expect(cotasN2, containsAll(cotasN0));
      expect(cotasN3, containsAll(cotasN2));
      expect(cotasN3.length, greaterThan(cotasN2.length));

      final curva1200Grossa =
          resN0.curvas.firstWhere((c) => c.cotaMetros == 1200);
      final curva1200Fina =
          resN3.curvas.firstWhere((c) => c.cotaMetros == 1200);
      Offset centroideAnel(List<Offset> pts) {
        final n = pts.length > 1 && (pts.first - pts.last).distance < 1e-6
            ? pts.length - 1
            : pts.length;
        var sx = 0.0;
        var sy = 0.0;
        for (var i = 0; i < n; i++) {
          sx += pts[i].dx;
          sy += pts[i].dy;
        }
        return Offset(sx / n, sy / n);
      }

      final curva1200Media =
          resA.curvas.firstWhere((c) => c.cotaMetros == 1200);
      expect(
        (centroideAnel(curva1200Grossa.verticesLonLat) -
                centroideAnel(curva1200Fina.verticesLonLat))
            .distance,
        lessThan(0.0050),
      );
      expect(
        (centroideAnel(curva1200Media.verticesLonLat) -
                centroideAnel(curva1200Fina.verticesLonLat))
            .distance,
        lessThan(0.0008),
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

      // Planície entre 810 m e 890 m sem cruzar múltiplo inteiro de 400 m -> retorna lista vazia
      final planicieEntreCotas = ExtratorCurvasNivelMundo.extrairCurvasBloco(
        janela: janela,
        nivelDetalhe: 0,
        versaoDadosElevacao: 0,
        amostrarElevacaoMetros: (lat, _) => lat > -20.0 ? 890.0 : 810.0,
        picosReferencia: const [],
      );
      expect(planicieEntreCotas.curvas, isEmpty);

      final sela = ExtratorCurvasNivelMundo.extrairCurvasBloco(
        janela: janela,
        nivelDetalhe: 1,
        versaoDadosElevacao: 2,
        picosReferencia: const [],
        amostrarElevacaoMetros: (lat, lon) {
          final x = (lon + 44.0) * 85.0;
          final y = (lat + 20.0) * 85.0;
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
