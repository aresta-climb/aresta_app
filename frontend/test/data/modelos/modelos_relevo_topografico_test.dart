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

