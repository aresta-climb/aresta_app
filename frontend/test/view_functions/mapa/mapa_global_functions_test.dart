// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:frontend/view_functions/mapa/mapa_global_functions.dart';

/// Testes para validar a resiliência de buildMapMarkers e funções globais do mapa,
/// prevenindo crashes por operadores bang (!) em entradas nulas ou chaves ausentes.
void main() {
  group('buildMapMarkers - Resiliência e Fallbacks', () {
    testWidgets('buildMapMarkers não deve disparar Null check operator quando textIcons contiver valor nulo',
        (WidgetTester tester) async {
      final crags = [
        {
          'id': 'crag_nulo',
          'nome': 'Pico Nulo',
          'latitude': -20.0,
          'longitude': -40.0,
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                // Simula um dicionário onde a chave existe mas o BitmapDescriptor associado é nulo
                final Map<String, BitmapDescriptor?> textIconsComNulo = {
                  'crag_nulo': null,
                };

                final markers = buildMapMarkers(
                  context: context,
                  crags: crags,
                  downloadingCrags: ValueNotifier<Map<String, double>>({}),
                  onDownload: (_) {},
                  textIcons: textIconsComNulo,
                  currentZoom: 10.0, // Zoom alto que ativa showText
                );

                expect(markers.length, equals(1));
                expect(markers.first.icon, equals(BitmapDescriptor.defaultMarker));

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('buildMapMarkers deve utilizar customIcon ou defaultMarker quando id não estiver em textIcons',
        (WidgetTester tester) async {
      final crags = [
        {
          'id': 'crag_ausente',
          'nome': 'Pico Ausente',
          'latitude': -20.0,
          'longitude': -40.0,
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final markers = buildMapMarkers(
                  context: context,
                  crags: crags,
                  downloadingCrags: ValueNotifier<Map<String, double>>({}),
                  onDownload: (_) {},
                  textIcons: {}, // Dicionário vazio
                  currentZoom: 10.0,
                );

                expect(markers.length, equals(1));
                expect(markers.first.icon, equals(BitmapDescriptor.defaultMarker));

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('showCragModal fecha bottom sheet antes de disparar onOpen',
        (WidgetTester tester) async {
      bool onOpenCalled = false;

      final crag = {
        'id': 'crag1',
        'nome': 'Pico Teste',
        'local': 'Local Teste',
        'latitude': -20.0,
        'longitude': -40.0,
        'isDownloaded': true,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    showCragModal(
                      context: context,
                      crag: crag,
                      downloadingCrags: ValueNotifier<Map<String, double>>({}),
                      onDownload: () {},
                      onOpen: () {
                        onOpenCalled = true;
                      },
                    );
                  },
                  child: const Text('Show Modal'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Modal'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('PICO TESTE'));
      await tester.pumpAndSettle();

      expect(onOpenCalled, isTrue);
    });
  });
}
