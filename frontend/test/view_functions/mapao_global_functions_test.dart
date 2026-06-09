/// Testes unitários para as funções visuais do Mapão Global.
///
/// Valida se a função [buildMapMarkers] extrai e processa adequadamente os
/// dados dos croquis para gerar a coleção de marcadores, garantindo que
/// picos com coordenadas inválidas ou vazias sejam ignorados. Também checa
/// a injeção do GoogleMap na árvore pela função de build.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:frontend/view_functions/mapao_global_functions.dart';

void main() {
  testWidgets('buildMapMarkers creates markers correctly', (WidgetTester tester) async {
    final crags = [
      {
        'id': 'crag1',
        'nome': 'Pico 1',
        'local': 'Local 1',
        'latitude': -20.0,
        'longitude': -40.0,
      },
      {
        'id': 'crag2',
        'nome': 'Pico 2',
        'local': 'Local 2',
      }, // Ignora se está sem localização
    ];

    Set<Marker> markers = {};

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) {
          markers = buildMapMarkers(
            context: context,
            crags: crags,
            downloadingCrags: {},
            onDownload: (_) {},
          );
          return Container();
        },
      ),
    ));

    expect(markers.length, 1);
    expect(markers.first.markerId.value, 'crag1');
    expect(markers.first.position.latitude, -20.0);
    expect(markers.first.position.longitude, -40.0);
    expect(markers.first.infoWindow.title, 'Pico 1');
    expect(markers.first.infoWindow.snippet, 'Local 1');
  });

  testWidgets('buildMapaoGlobalMap renders GoogleMap', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: buildMapaoGlobalMap(
          initialTarget: const LatLng(0, 0),
          markers: {},
        ),
      ),
    ));

    expect(find.byType(GoogleMap), findsOneWidget);
  });
}
