import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/view_functions/browse_functions.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import '../mocks/mock_telemetry_service.dart';

void main() {
  testWidgets('buildBrowseBody passa onOpen corretamente e permite acionar telemetria', (WidgetTester tester) async {
    final mockTelemetry = MockTelemetryService();
    TelemetryService.instance = mockTelemetry;

    final List<Map<String, dynamic>> availableCrags = [
      {
        'id': 'crag1',
        'nome': 'Pico Teste',
        'local': 'Local Teste',
        'isDownloaded': true, // Para mostrar o botão Abrir Croqui
      }
    ];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return buildBrowseBody(
              context,
              availableCrags,
              onSearchChanged: (_) {},
              onDownload: (_) {},
              onOpen: (crag) {
                // Simulando o comportamento definido na page browse.dart
                TelemetryService.instance.logAcaoCroqui(crag['id'], 'abrir_croqui', origem: 'explorar');
              },
            );
          }
        ),
      ),
    ));

    // O card precisa ser expandido para ver o botão "ABRIR CROQUI"
    await tester.tap(find.text('Pico Teste'));
    await tester.pumpAndSettle();

    // Encontra e toca no botão
    final openBtn = find.text('ABRIR CROQUI');
    expect(openBtn, findsOneWidget);
    await tester.tap(openBtn);
    
    // Verifica a telemetria disparada pelo onOpen
    expect(mockTelemetry.recordedEvents, contains('acao_croqui'));
    expect(mockTelemetry.recordedParams['acao_croqui']!['acao'], 'abrir_croqui');
    expect(mockTelemetry.recordedParams['acao_croqui']!['origem'], 'explorar');
  });
}
