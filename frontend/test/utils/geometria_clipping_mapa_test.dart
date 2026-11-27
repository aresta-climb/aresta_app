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

