import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/view_functions/home_functions.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import '../mocks/mock_telemetry_service.dart';

void main() {
  late DatasetRepository mockRepo;
  late EditorDeCroqui mockEditor;
  late SyncService mockSync;

  setUp(() {
    mockEditor = EditorDeCroqui();
    mockRepo = DatasetRepository(editorDeCroqui: mockEditor);
    mockSync = SyncService(datasetRepository: mockRepo);
    mockSync.syncStatus.value = SyncStatus.updated;
  });

  Widget buildTestableWidget(List<Map<String, dynamic>> downloadedPicos) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return buildHomeBody(
              context,
              mockRepo,
              mockSync,
              downloadedPicos,
              ValueNotifier<Map<String, double>>({}), // downloadingCrags
              onAddCrag: () {},
            );
          },
        ),
      ),
    );
  }

  testWidgets('buildHomeBody shows "Explorar guias" and hides dropdown when no guides downloaded', (WidgetTester tester) async {
    // Rendereiza o widget com lista vazia
    await tester.pumpWidget(buildTestableWidget([]));
    await tester.pumpAndSettle();

    // Deve mostrar "Nenhum guia baixado ainda."
    expect(find.text('Nenhum guia baixado ainda.'), findsOneWidget);

    // Deve mostrar o botão "Explorar guias"
    final explorarGuiasFinder = find.widgetWithText(ElevatedButton, 'Explorar guias');
    expect(explorarGuiasFinder, findsOneWidget);

    // NÃO deve mostrar o dropdown "Todos os guias baixados"
    expect(find.text('Todos os guias baixados'), findsNothing);
  });

  testWidgets('buildHomeBody shows dropdown and hides "Explorar guias" when guides are downloaded', (WidgetTester tester) async {
    // Um pico fictício baixado
    final dummyPico = {
      'id': 'test-pico-1',
      'nome': 'Pico de Teste',
      'local': 'Local de Teste',
    };

    await tester.pumpWidget(buildTestableWidget([dummyPico]));
    await tester.pumpAndSettle();

    // NÃO deve mostrar "Nenhum guia baixado ainda."
    expect(find.text('Nenhum guia baixado ainda.'), findsNothing);

    // NÃO deve mostrar o botão "Explorar guias"
    final explorarGuiasFinder = find.widgetWithText(ElevatedButton, 'Explorar guias');
    expect(explorarGuiasFinder, findsNothing);

    // Deve mostrar o dropdown "Todos os guias baixados"
    expect(find.text('Todos os guias baixados'), findsOneWidget);
  });

  testWidgets('handlePicoSelection dispara telemetria de abrir_croqui com origem', (WidgetTester tester) async {
    final mockTelemetry = MockTelemetryService();
    TelemetryService.instance = mockTelemetry;

    final dummyPico = {
      'id': 'test-pico-1',
    };

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(builder: (context) {
      return ElevatedButton(
        onPressed: () => handlePicoSelection(context, mockRepo, dummyPico),
        child: const Text('Go'),
      );
    }))));

    await tester.tap(find.text('Go'));
    
    expect(mockTelemetry.recordedEvents, contains('acao_croqui'));
    expect(mockTelemetry.recordedParams['acao_croqui']!['acao'], 'abrir_croqui');
    expect(mockTelemetry.recordedParams['acao_croqui']!['origem'], 'home');
  });

  testWidgets('buildSyncBadge exibe texto correto para noNewUpdates', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: buildSyncBadge(SyncStatus.noNewUpdates),
        ),
      ),
    );

    expect(find.text('Sem atualizações'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });
  testWidgets('buildPicosCarousel mantém Opacity 1.0 e clicável para pico já baixado que está atualizando', (WidgetTester tester) async {
    final mockTelemetry = MockTelemetryService();
    TelemetryService.instance = mockTelemetry;
    
    final dummyPico = {
      'id': 'test-pico-update',
      'nome': 'Pico Atualizando',
      'local': 'Local Atualizando',
    };

    final downloadingCrags = ValueNotifier<Map<String, double>>({
      'test-pico-update': 0.5, // Está baixando/atualizando
    });

    bool wasTapped = false;

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(builder: (context) {
      return buildPicosCarousel(
        [dummyPico],
        downloadingCrags,
        onAddCrag: () {},
        onPicoSelect: (pico) {
          wasTapped = true;
        },
      );
    }))));

    // O GestureDetector deve estar ativo (onTap != null). 
    // Podemos tentar clicar e verificar se chamou o callback.
    await tester.tap(find.text('Pico Atualizando'));
    expect(wasTapped, isTrue);
  });
}
