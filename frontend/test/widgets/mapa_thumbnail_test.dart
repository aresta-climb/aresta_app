// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/mapa_thumbnail.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import '../mocks/mock_telemetry_service.dart';

final Uint8List kTransparentImage = Uint8List.fromList([
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

void main() {
  testWidgets('MapaThumbnail calls logAbrirMapa on tap', (tester) async {
    final mockTelemetry = MockTelemetryService();
    TelemetryService.instance = mockTelemetry;

    final mapa = Mapa()
      ..caminhoImagemMapa = 'teste.png'
      ..larguraMapa = 100
      ..alturaMapa = 100;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapaThumbnail(
            mapas: [mapa],
            cragId: 'crag1',
            nomeContexto: 'Contexto Teste',
            imageProviderOverride: MemoryImage(kTransparentImage),
          ),
        ),
      ),
    );

    // Pump to resolve FutureBuilder
    await tester.pumpAndSettle();

    // Tap on the generated button
    await tester.tap(find.text('Abrir Mapa Interativo'));
    await tester.pumpAndSettle();

    expect(mockTelemetry.recordedEvents, contains('abrir_mapa'));
    expect(
      mockTelemetry.recordedParams['abrir_mapa']!['nome_setor'],
      'Contexto Teste',
    );
  });

  testWidgets('MapaThumbnail renders multiple maps text correctly', (tester) async {
    final mapa1 = Mapa()
      ..caminhoImagemMapa = 'teste1.png'
      ..larguraMapa = 100
      ..alturaMapa = 100;
      
    final mapa2 = Mapa()
      ..caminhoImagemMapa = 'teste2.png'
      ..larguraMapa = 100
      ..alturaMapa = 100;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapaThumbnail(
            mapas: [mapa1, mapa2],
            cragId: 'crag1',
            nomeContexto: 'Contexto Teste',
            imageProviderOverride: MemoryImage(kTransparentImage),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Mapas Interativos (2)'), findsOneWidget);
    expect(find.text('Abrir Mapa Interativo'), findsNothing);
  });
}
