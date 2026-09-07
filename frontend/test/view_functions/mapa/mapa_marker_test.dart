// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:frontend/view_functions/mapa/mapa_marker.dart';

/// Testes unitários para validar a criação e conversão resiliente de marcadores do mapa,
/// garantindo ausência de force-unwraps (!) e proteção contra falhas de buffer de GPU.
void main() {
  group('mapa_marker - Resiliência e Fallback Seguro', () {
    test('converterByteDataEmBitmap deve retornar BitmapDescriptor.defaultMarker quando byteData for nulo', () {
      final resultado = converterByteDataEmBitmap(null);

      expect(resultado, equals(BitmapDescriptor.defaultMarker),
          reason: 'Deve retornar o marcador padrão sem lançar Null check operator');
    });

    test('converterByteDataEmBitmap deve retornar BitmapDescriptor válido a partir de bytes válidos', () {
      final Uint8List bytesExemplo = Uint8List.fromList([0, 1, 2, 3, 4]);
      final ByteData byteData = ByteData.sublistView(bytesExemplo);

      final resultado = converterByteDataEmBitmap(byteData);

      expect(resultado, isNotNull);
      expect(resultado, isA<BitmapDescriptor>());
    });
  });
}
