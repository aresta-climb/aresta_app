// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:ui' show Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/utils/geometria_clipping_mapa.dart';

void main() {
  group('GeometriaClippingMapa', () {
    test('calcula janela geográfica visível assimétrica em 3D inclinado e simétrica em 2D', () {
      final j3D = GeometriaClippingMapa.calcularJanelaVisivelCamera(
        modo3D: true,
        latitudeCentral: -20.0,
        longitudeCentral: -44.0,
        lod: 4.2,
        raioAparentePx: 710000.0,
        escala2D: 1.0,
        tamanhoTela: const Size(400, 800),
      );
      expect(j3D.minLat, lessThan(-20.0));
      expect(j3D.maxLat, greaterThan(-20.0));
      // Com inclinação perspectiva 3D, o horizonte norte abrange mais graus que a base sul
      expect(j3D.maxLat - (-20.0), greaterThan((-20.0) - j3D.minLat));

      final j2D = GeometriaClippingMapa.calcularJanelaVisivelCamera(
        modo3D: false,
        latitudeCentral: -20.0,
        longitudeCentral: -44.0,
        lod: 3.0,
        raioAparentePx: 100000.0,
        escala2D: 85000.0,
        tamanhoTela: const Size(400, 800),
      );
      expect((-20.0 - j2D.minLat), closeTo(j2D.maxLat - (-20.0), 1e-6));
    });

    test('recorta polígonos via Sutherland-Hodgman nos 4 semiplanos e descarta polígonos externos ou degenerados', () {
      const janela = JanelaGeograficaVisivel(
        minLon: -44.2,
        maxLon: -43.8,
        minLat: -20.2,
        maxLat: -19.8,
      );

      expect(
        GeometriaClippingMapa.recortarPoligonoNoRetangulo(
          anelLonLat: const [Offset(-44.0, -20.0), Offset(-43.9, -19.9)],
          janela: janela,
        ),
        isEmpty,
      );

      // Polígono gigante que envolve toda a janela deve resultar exatamente nos 4 cantos da janela
      final recortado = GeometriaClippingMapa.recortarPoligonoNoRetangulo(
        anelLonLat: const [
          Offset(-46.0, -22.0),
          Offset(-42.0, -22.0),
          Offset(-42.0, -18.0),
          Offset(-46.0, -18.0),
        ],
        janela: janela,
      );
      expect(recortado, hasLength(4));
      for (final p in recortado) {
        expect(p.dx, inInclusiveRange(janela.minLon - 1e-6, janela.maxLon + 1e-6));
        expect(p.dy, inInclusiveRange(janela.minLat - 1e-6, janela.maxLat + 1e-6));
      }

      // Polígonos totalmente fora em cada um dos 4 lados retornam lista vazia
      for (final deslocamento in const [
        Offset(-2.0, 0.0),
        Offset(2.0, 0.0),
        Offset(0.0, -2.0),
        Offset(0.0, 2.0),
      ]) {
        final fora = GeometriaClippingMapa.recortarPoligonoNoRetangulo(
          anelLonLat: [
            const Offset(-44.1, -20.1) + deslocamento,
            const Offset(-43.9, -20.1) + deslocamento,
            const Offset(-44.0, -19.9) + deslocamento,
          ],
          janela: janela,
        );
        expect(fora, isEmpty);
      }
    });

    test('subdivide rodovias longas preservando continuidade no centro da janela mesmo com extremidades distantes e corta antimeridiano', () {
      const janelaZoomMaximo = JanelaGeograficaVisivel(
        minLon: -43.96,
        maxLon: -43.92,
        minLat: -19.94,
        maxLat: -19.90,
      );

      expect(
        GeometriaClippingMapa.subdividirERecortarPolilinha(
          verticesLonLat: const [Offset(-43.94, -19.92)],
          janela: janelaZoomMaximo,
          passoMaxGraus: 0.002,
        ),
        isEmpty,
      );

      // Rodovia reta com vértices a 40 km de distância em cada lado, cruzando pelo meio do zoom máximo
      final cadeias = GeometriaClippingMapa.subdividirERecortarPolilinha(
        verticesLonLat: const [
          Offset(-44.40, -19.92),
          Offset(-43.50, -19.92),
        ],
        janela: janelaZoomMaximo,
        passoMaxGraus: 0.01,
      );
      expect(cadeias, hasLength(1));
      expect(cadeias.single.length, greaterThanOrEqualTo(4));

      // Salto no antimeridiano (±180°) e segmento fora da janela não geram linhas espúrias
      final antimeridiano = GeometriaClippingMapa.subdividirERecortarPolilinha(
        verticesLonLat: const [
          Offset(179.5, -19.92),
          Offset(-179.5, -19.92),
          Offset(-48.0, -22.0),
          Offset(-47.5, -22.0),
        ],
        janela: const JanelaGeograficaVisivel(
          minLon: -180.0,
          maxLon: 180.0,
          minLat: -25.0,
          maxLat: -15.0,
        ),
        passoMaxGraus: 0.5,
      );
      expect(antimeridiano, hasLength(1));
    });
  });
}
