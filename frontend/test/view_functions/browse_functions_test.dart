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
              {},
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

  testWidgets('buildBrowseBody exibe animação de download quando o pico está em downloadingCrags', (WidgetTester tester) async {
    final List<Map<String, dynamic>> availableCrags = [
      {
        'id': 'crag_dl',
        'nome': 'Pico Baixando',
        'local': 'Local DL',
        'isDownloaded': false,
      }
    ];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return buildBrowseBody(
              context,
              availableCrags,
              {'crag_dl': 0.5}, // Simula que está baixando com 50%
              onSearchChanged: (_) {},
              onDownload: (_) {},
            );
          }
        ),
      ),
    ));

    await tester.tap(find.text('Pico Baixando'));
    await tester.pump(const Duration(milliseconds: 500));

    // O botão BAIXAR não deve estar presente de forma clicável, mas a animação sim.
    // Como trocamos o conteúdo do botão, vamos procurar o CircularProgressIndicator.
    // Existem vários, então vamos focar no ElevatedButton.
    final loadingIndicator = find.descendant(
      of: find.byType(ElevatedButton),
      matching: find.byType(LinearProgressIndicator),
    );

    expect(loadingIndicator, findsOneWidget);
  });

  testWidgets('buildBrowseBody exibe a descrição curta do pico caso exista', (WidgetTester tester) async {
    final List<Map<String, dynamic>> availableCrags = [
      {
        'id': 'crag_desc',
        'nome': 'Pico Descrição',
        'local': 'Local Desc',
        'descricao': 'Esta é a descrição curta e bacana do pico.',
        'isDownloaded': false,
      }
    ];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return buildBrowseBody(
              context,
              availableCrags,
              {},
              onSearchChanged: (_) {},
              onDownload: (_) {},
            );
          }
        ),
      ),
    ));

    // A descrição fica dentro do expanded (segundo filho do AnimatedCrossFade)
    // Logo, o texto já existe na árvore.
    expect(find.text('Esta é a descrição curta e bacana do pico.'), findsOneWidget);

    await tester.tap(find.text('Pico Descrição'));
    await tester.pump(const Duration(milliseconds: 500));

    // Ainda deve existir após a expansão
    expect(find.text('Esta é a descrição curta e bacana do pico.'), findsOneWidget);
  });
}
