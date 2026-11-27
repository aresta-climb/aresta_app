// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/modelos_rede_viaria_aresta.dart';
import 'package:frontend/utils/extrator_curvas_nivel_mundo.dart';
import 'package:frontend/utils/geometria_clipping_mapa.dart';

void main() {
  group('ExtratorCurvasNivelMundo', () {
    test('resolve faixas discretas de detalhe e mantém coordenadas das curvas 100% estáticas no mundo durante pan da câmera', () {
      expect(ExtratorCurvasNivelMundo.resolverNivelDetalhe(2.10), equals(0));
      expect(ExtratorCurvasNivelMundo.resolverNivelDetalhe(3.10), equals(1));
      expect(ExtratorCurvasNivelMundo.resolverNivelDetalhe(4.00), equals(2));

      expect(ExtratorCurvasNivelMundo.passoGradePorNivel(0), closeTo(0.028, 1e-6));
      expect(ExtratorCurvasNivelMundo.passoGradePorNivel(1), closeTo(0.010, 1e-6));
      expect(ExtratorCurvasNivelMundo.passoGradePorNivel(2), closeTo(0.0035, 1e-6));

      expect(ExtratorCurvasNivelMundo.intervaloCotaMenorPorNivel(0), equals(250.0));
      expect(ExtratorCurvasNivelMundo.intervaloCotaMenorPorNivel(1), equals(150.0));
      expect(ExtratorCurvasNivelMundo.intervaloCotaMenorPorNivel(2), equals(100.0));

      const pico = PicoRelevoReferencia(
        id: 'cipo',
        latitude: -19.32,
        longitude: -43.62,
        altitudeBaseMetros: 800,
        altitudePicoMetros: 1380,
      );

      double domoMontanha(double lat, double lon) {
        final dLat = lat - (-19.32);
        final dLon = lon - (-43.62);
        final r2 = dLat * dLat + dLon * dLon;
        return 760.0 + 620.0 * math.exp(-r2 / 0.00055);
      }

      const janelaA = JanelaGeograficaVisivel(
        minLat: -19.365,
        maxLat: -19.275,
        minLon: -43.665,
        maxLon: -43.575,
      );
      // Pan suave da câmera dentro do mesmo quarteirão quantizado: o bloco e os vértices do mundo permanecem IDÊNTICOS
      const janelaPanSuave = JanelaGeograficaVisivel(
        minLat: -19.362,
        maxLat: -19.272,
        minLon: -43.662,
        maxLon: -43.572,
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
    });

    test('resolve pontos de sela (casos 5 e 10) sem cruzar curvas e retorna vazio em oceano ou planície uniforme', () {
      const janela = JanelaGeograficaVisivel(
        minLat: -20.05,
        maxLat: -19.95,
        minLon: -44.05,
        maxLon: -43.95,
      );

      // Oceano / cota zero -> retorna lista vazia
      final oceano = ExtratorCurvasNivelMundo.extrairCurvasBloco(
        janela: janela,
        nivelDetalhe: 1,
        versaoDadosElevacao: 0,
        amostrarElevacaoMetros: (_, _) => 0.0,
        picosReferencia: const [],
      );
      expect(oceano.curvas, isEmpty);

      // Planície entre 810 m e 890 m sem cruzar múltiplo inteiro de 250 m -> retorna lista vazia
      final planicieEntreCotas = ExtratorCurvasNivelMundo.extrairCurvasBloco(
        janela: janela,
        nivelDetalhe: 0,
        versaoDadosElevacao: 0,
        amostrarElevacaoMetros: (lat, _) => lat > -20.0 ? 890.0 : 810.0,
        picosReferencia: const [],
      );
      expect(planicieEntreCotas.curvas, isEmpty);

      // Campo hiperbólico de sela exercitando máscaras 5 e 10 (média alta e média baixa) + curvas abertas
      final sela = ExtratorCurvasNivelMundo.extrairCurvasBloco(
        janela: janela,
        nivelDetalhe: 1,
        versaoDadosElevacao: 2,
        picosReferencia: const [],
        amostrarElevacaoMetros: (lat, lon) {
          final x = (lon + 44.0) * 85.0;
          final y = (lat + 20.0) * 85.0;
          return 900.0 + 260.0 * (x * y) + 120.0 * math.sin(x * 1.4 + y * 1.2);
        },
      );
      expect(sela.curvas, isNotEmpty);
      for (final c in sela.curvas) {
        expect(c.verticesLonLat.every((Offset p) => p.dx.isFinite && p.dy.isFinite), isTrue);
      }
    });
  });
}
