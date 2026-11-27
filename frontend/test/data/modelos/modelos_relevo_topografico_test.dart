// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/modelos_relevo_topografico.dart';

void main() {
  group('GradeElevacaoRegionalOffline', () {
    test('decodifica buffer int16 little-endian, interpola bilinearmente e retorna null fora dos limites', () {
      final bytes = ByteData(8)
        ..setInt16(0, 800, Endian.little)
        ..setInt16(2, 900, Endian.little)
        ..setInt16(4, 1000, Endian.little)
        ..setInt16(6, 1100, Endian.little);
      final grade = GradeElevacaoRegionalOffline.deMapa({
        'lat_min': -20.0,
        'lon_min': -44.0,
        'passo_graus': 0.5,
        'linhas': 2,
        'colunas': 2,
        'cotas_int16_b64': base64Encode(bytes.buffer.asUint8List()),
      });

      expect(grade.latMax, closeTo(-19.5, 1e-6));
      expect(grade.lonMax, closeTo(-43.5, 1e-6));
      expect(grade.amostrarBilinear(-20.0, -44.0), closeTo(800.0, 1e-6));
      expect(grade.amostrarBilinear(-19.75, -43.75), closeTo(950.0, 1e-6));
      expect(grade.amostrarBilinear(-21.0, -44.0), isNull);
      expect(grade.amostrarBilinear(-19.8, -42.0), isNull);

      expect(
        () => GradeElevacaoRegionalOffline.deMapa({'lat_min': -20.0}),
        throwsFormatException,
      );
      expect(
        () => GradeElevacaoRegionalOffline.deMapa({
          'lat_min': -20.0,
          'lon_min': -44.0,
          'passo_graus': 0.5,
          'linhas': 2,
          'colunas': 2,
          'cotas_int16_b64': base64Encode(Uint8List(4)),
        }),
        throwsFormatException,
      );
    });
  });

  group('TileElevacaoTerrarium, CurvaNivelMundo e ConjuntoCurvasNivelMundo', () {
    test('projeta coordenadas Web Mercator, converte RGBA Terrarium e interpola cotas locais', () {
      final rgba = Uint8List(256 * 256 * 4);
      // Codifica 920 m em todos os pixels: 920 + 32768 = 33688 -> R = 131, G = 152, B = 0
      for (var i = 0; i < 256 * 256; i++) {
        rgba[i * 4] = 131;
        rgba[i * 4 + 1] = 152;
        rgba[i * 4 + 2] = 0;
        rgba[i * 4 + 3] = 255;
      }

      final proj = TileElevacaoTerrarium.projetarWebMercator(
        latitude: -18.9186,
        longitude: -48.2772,
        zoom: 10,
      );
      final tile = TileElevacaoTerrarium.deRgba256(
        zoom: 10,
        x: proj.tileX,
        y: proj.tileY,
        rgba: rgba,
      );

      expect(
        tile.chave,
        equals(TileElevacaoTerrarium.calcularChave(10, proj.tileX, proj.tileY)),
      );
      expect(tile.amostrarLocal(proj.localX, proj.localY), closeTo(920.0, 1e-6));
      expect(
        () => TileElevacaoTerrarium.deRgba256(
          zoom: 8,
          x: 0,
          y: 0,
          rgba: Uint8List(16),
        ),
        throwsFormatException,
      );

      const curva = CurvaNivelMundo(
        cotaMetros: 1000,
        ehMestra: true,
        ehEscarpaPico: true,
        verticesLonLat: [Offset(-44.0, -20.0), Offset(-43.9, -19.9)],
        ancoraRotuloLonLat: Offset(-43.95, -19.95),
      );
      const conjunto = ConjuntoCurvasNivelMundo(
        chaveBloco: 42,
        nivelDetalhe: 2,
        versaoDadosElevacao: 1,
        curvas: [curva],
      );
      expect(conjunto.curvas.single.cotaMetros, equals(1000));
    });
  });
}
