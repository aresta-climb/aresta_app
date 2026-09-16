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

  group('FaixaZoomMapa e Seleção de Marcadores por Faixa de Zoom', () {
    test('obterFaixaZoom deve classificar corretamente as faixas Macro, Regional e Local', () {
      expect(obterFaixaZoom(3.5), equals(FaixaZoomMapa.macro));
      expect(obterFaixaZoom(6.99), equals(FaixaZoomMapa.macro));
      expect(obterFaixaZoom(7.0), equals(FaixaZoomMapa.regional));
      expect(obterFaixaZoom(8.5), equals(FaixaZoomMapa.regional));
      expect(obterFaixaZoom(9.99), equals(FaixaZoomMapa.regional));
      expect(obterFaixaZoom(10.0), equals(FaixaZoomMapa.local));
      expect(obterFaixaZoom(15.0), equals(FaixaZoomMapa.local));
    });

    testWidgets('buildMapMarkers deve usar macroIcon e ignorar textIcons na faixa macro',
        (WidgetTester tester) async {
      final crags = [
        {
          'id': 'crag1',
          'nome': 'Pico 1',
          'latitude': -20.0,
          'longitude': -40.0,
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final macroIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
                final textIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);

                final markers = buildMapMarkers(
                  context: context,
                  crags: crags,
                  downloadingCrags: ValueNotifier<Map<String, double>>({}),
                  onDownload: (_) {},
                  macroIcon: macroIcon,
                  textIcons: {'crag1': textIcon},
                  currentZoom: 5.0, // Faixa Macro
                );

                expect(markers.length, equals(1));
                expect(markers.first.icon, equals(macroIcon),
                    reason: 'Em zoom < 7.0 não deve usar textIcon, e sim macroIcon');

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('buildMapMarkers deve usar regionalIcon e ignorar textIcons na faixa regional',
        (WidgetTester tester) async {
      final crags = [
        {
          'id': 'crag1',
          'nome': 'Pico 1',
          'latitude': -20.0,
          'longitude': -40.0,
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final regionalIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
                final textIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);

                final markers = buildMapMarkers(
                  context: context,
                  crags: crags,
                  downloadingCrags: ValueNotifier<Map<String, double>>({}),
                  onDownload: (_) {},
                  regionalIcon: regionalIcon,
                  textIcons: {'crag1': textIcon},
                  currentZoom: 8.5, // Faixa Regional (7.0 a 10.0)
                );

                expect(markers.length, equals(1));
                expect(markers.first.icon, equals(regionalIcon),
                    reason: 'Em zoom regional (7.0 a 10.0) deve usar regionalIcon sem texto');

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('buildMapMarkers deve usar textIcons na faixa local (zoom >= 10)',
        (WidgetTester tester) async {
      final crags = [
        {
          'id': 'crag1',
          'nome': 'Pico 1',
          'latitude': -20.0,
          'longitude': -40.0,
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final regionalIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
                final textIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);

                final markers = buildMapMarkers(
                  context: context,
                  crags: crags,
                  downloadingCrags: ValueNotifier<Map<String, double>>({}),
                  onDownload: (_) {},
                  regionalIcon: regionalIcon,
                  textIcons: {'crag1': textIcon},
                  currentZoom: 10.5, // Faixa Local (>= 10.0)
                );

                expect(markers.length, equals(1));
                expect(markers.first.icon, equals(textIcon),
                    reason: 'Em zoom local (>= 10.0) deve utilizar o textIcon correspondente');

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
    });
  });
}
