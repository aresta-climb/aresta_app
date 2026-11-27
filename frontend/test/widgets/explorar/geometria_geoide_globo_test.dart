// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/explorar/geometria_geoide_globo.dart';

void main() {
  group('GeometriaGeoideGlobo', () {
    test('calcula raio do Geoide Terrestre refletindo achatamento polar e anomalias EGM96', () {
      expect(PontoProjetadoTela.oculto.visivel, isFalse);

      final rNovaGuine = GeometriaGeoideGlobo.raioNormalizadoGeoide(
        latitude: -5.0,
        longitude: 146.0,
      );
      final rIndico = GeometriaGeoideGlobo.raioNormalizadoGeoide(
        latitude: 4.0,
        longitude: 79.0,
      );
      final rPoloNorte = GeometriaGeoideGlobo.raioNormalizadoGeoide(
        latitude: 90.0,
        longitude: 0.0,
      );

      expect(rNovaGuine, greaterThan(rIndico));
      expect(rNovaGuine, greaterThan(rPoloNorte));
    });

    test('constrói silhueta fechada do Geoide e atenua ondulação em zooms locais', () {
      final silhuetaOrbital = GeometriaGeoideGlobo.construirSilhuetaGeoide(
        tamanhoTela: const Size(400, 800),
        centroVerticalOpticoPx: 360.0,
        raioAparentePx: 150.0,
        latitudeCentral: -18.5,
        longitudeCentral: -44.5,
        lod: 0.2,
      );
      final metricas = silhuetaOrbital.computeMetrics().toList();
      expect(metricas, hasLength(1));
      expect(metricas.single.isClosed, isTrue);
      expect(silhuetaOrbital.getBounds().width, greaterThan(280.0));
    });

    test('agrupa picos por UF, previne colisão de rótulos e normaliza longitudes', () {
      final clusters = GeometriaGeoideGlobo.agruparPorEstado([
        (id: 'p1', uf: 'MG', lat: -20.0, lon: -44.0),
        (id: 'p2', uf: 'MG', lat: -19.0, lon: -43.0),
        (id: 'p3', uf: '', lat: -22.9, lon: -43.2),
      ]);
      expect(clusters.map((c) => c.uf).toSet(), equals({'MG', 'BR'}));
      final mg = clusters.firstWhere((c) => c.uf == 'MG');
      expect(mg.quantidade, equals(2));
      expect(mg.primeiroPicoId, equals('p1'));

      final semColisao = GeometriaGeoideGlobo.selecionarIdsSemColisaoRotulos([
        (
          id: 'cidade_colidente',
          nome: 'Belo Horizonte',
          posicao: const Offset(100, 100),
          prioritario: false,
        ),
        (
          id: 'ancora_pico',
          nome: 'Serra do Curral',
          posicao: const Offset(104, 102),
          prioritario: true,
        ),
        (
          id: 'cidade_distante',
          nome: 'Ouro Preto',
          posicao: const Offset(280, 240),
          prioritario: false,
        ),
      ]);
      expect(semColisao, equals({'ancora_pico', 'cidade_distante'}));

      expect(GeometriaGeoideGlobo.smoothstep(0.0, 1.0, 0.5), closeTo(0.5, 1e-6));
      expect(GeometriaGeoideGlobo.normalizarLongitude(190.0), closeTo(-170.0, 1e-6));
      expect(GeometriaGeoideGlobo.normalizarLongitude(-190.0), closeTo(170.0, 1e-6));
    });
  });
}
