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

      expect(ExtratorCurvasNivelMundo.passoGradePorNivel(0), closeTo(0.025, 1e-6));
      expect(ExtratorCurvasNivelMundo.passoGradePorNivel(1), closeTo(0.008, 1e-6));
      expect(ExtratorCurvasNivelMundo.passoGradePorNivel(2), closeTo(0.0025, 1e-6));

      expect(ExtratorCurvasNivelMundo.intervaloCotaMenorPorNivel(0), equals(100.0));
      expect(ExtratorCurvasNivelMundo.intervaloCotaMenorPorNivel(1), equals(50.0));
      expect(ExtratorCurvasNivelMundo.intervaloCotaMenorPorNivel(2), equals(25.0));

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
        return 760.0 + 620.0 * math.exp(-r2 / 0.00045);
      }

      const janelaA = JanelaGeograficaVisivel(
        minLat: -19.360,
        maxLat: -19.280,
        minLon: -43.660,
        maxLon: -43.580,
      );
      // Pan suave da câmera (< meio quarteirão quantizado): o bloco e os vértices do mundo permanecem IDÊNTICOS
      const janelaPanSuave = JanelaGeograficaVisivel(
        minLat: -19.357,
        maxLat: -19.277,
        minLon: -43.657,
        maxLon: -43.577,
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

