// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/services.dart';
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

  group('mapa_marker - Dimensionamento e Truncamento de Marcadores', () {
    test('calcularDimensoesMarcador deve limitar largura com texto longo e aplicar reticências', () {
      const String nomeLongo = 'Parque Natural Municipal das Andorinhas';
      final dimensoes = calcularDimensoesMarcador(
        texto: nomeLongo,
        tamanhoPino: 32,
        larguraMaximaTexto: 100.0,
      );

      // Largura do balão deve ser limitada pela largura máxima de texto mais padding (8*2)
      expect(dimensoes.larguraBalao, lessThanOrEqualTo(100.0 + 16.0));
      expect(dimensoes.larguraCanvas, greaterThanOrEqualTo(dimensoes.larguraBalao));
      expect(dimensoes.alturaCanvas, greaterThan(32));
      expect(dimensoes.tamanhoFonte, inInclusiveRange(10.0, 12.0));
    });

    test('calcularDimensoesMarcador deve manter largura compacta para nomes curtos', () {
      const String nomeCurto = 'Cipó';
      final dimensoes = calcularDimensoesMarcador(
        texto: nomeCurto,
        tamanhoPino: 32,
        larguraMaximaTexto: 100.0,
      );

      expect(dimensoes.larguraBalao, lessThan(80.0));
    });

    testWidgets('createCustomMarkerBitmap deve gerar marcador com tamanhos das faixas de zoom compactas', (tester) async {
      await tester.runAsync(() async {
        final mockBundle = MockAssetBundle();
        mockBundle.addAsset('assets/logo_app.png', pngBytes1x1);

        final bitmapMacro = await createCustomMarkerBitmap('assets/logo_app.png', size: 20, bundle: mockBundle);
        final bitmapRegional = await createCustomMarkerBitmap('assets/logo_app.png', size: 26, bundle: mockBundle);
        final bitmapLocal = await createCustomMarkerBitmap('assets/logo_app.png', size: 32, bundle: mockBundle);
        final bitmapSemImagem = await createCustomMarkerBitmap('', size: 20);

        expect(bitmapMacro, isNotNull);
        expect(bitmapRegional, isNotNull);
        expect(bitmapLocal, isNotNull);
        expect(bitmapSemImagem, isNotNull);
      });
    });

    testWidgets('createCustomMarkerBitmapWithText deve gerar marcador contido com texto', (tester) async {
      await tester.runAsync(() async {
        final mockBundle = MockAssetBundle();
        mockBundle.addAsset('assets/logo_app.png', pngBytes1x1);

        final bitmapComTexto = await createCustomMarkerBitmapWithText(
          'assets/logo_app.png',
          'Parque Natural Municipal das Andorinhas',
          size: 32,
          larguraMaximaTexto: 100.0,
          bundle: mockBundle,
        );
        final bitmapTextoSemImagem = await createCustomMarkerBitmapWithText(
          '',
          'Cipó',
          size: 32,
          larguraMaximaTexto: 100.0,
        );

        expect(bitmapComTexto, isNotNull);
        expect(bitmapTextoSemImagem, isNotNull);
      });
    });
  });
}

class MockAssetBundle extends Fake implements AssetBundle {
  final Map<String, ByteData> assets = {};

  void addAsset(String key, List<int> bytes) {
    assets[key] = ByteData.view(Uint8List.fromList(bytes).buffer);
  }

  @override
  Future<ByteData> load(String key) async {
    final asset = assets[key];
    if (asset != null) return asset;
    throw Exception('Asset not found: $key');
  }
}

final Uint8List pngBytes1x1 = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);


