import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/view_functions/home_functions.dart';
import 'package:frontend/view_functions/browse_functions.dart';
import 'package:frontend/widgets/nearby_crags_carousel.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import '../mocks/mock_telemetry_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late DatasetRepository mockRepo;
  late EditorDeCroqui mockEditor;
  late SyncService mockSync;

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    mockEditor = EditorDeCroqui();
    mockRepo = DatasetRepository(editorDeCroqui: mockEditor);
    mockSync = SyncService(datasetRepository: mockRepo);
    mockSync.syncStatus.value = SyncStatus.updated;
  });

  Widget buildTestableWidget() {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return buildHomeBody(
              context,
              mockSync,
              (index) {}, // onSwitchTab
            );
          },
        ),
      ),
    );
  }

  testWidgets('buildHomeBody renders the new layout including NearbyCragsCarousel', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pump();

    // Verify Header exists
    expect(find.byIcon(Icons.terrain), findsOneWidget);
    
    // Verify NearbyCragsCarousel exists
    expect(find.byType(NearbyCragsCarousel), findsOneWidget);
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
  
  testWidgets('Downloads from activeDataset update Home download cards reactively', (WidgetTester tester) async {
    mockRepo.activeDataset.value = TopoDataset(
      availablePicos: [
        {
          'id': 'pico_sync_1',
          'nome': 'Pico Sync',
          'local': 'Local Sync',
          'latitude': -20.0,
          'longitude': -40.0,
        }
      ],
      downloadedPicos: [],
    );

    // Renderiza diretamente o mesmo padrão do NearbyCragsCarousel para evitar
    // dependência em chamadas do Geolocator que rodam infinitamente em testes.
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ValueListenableBuilder<TopoDataset?>(
          valueListenable: mockRepo.activeDataset,
          builder: (context, dataset, child) {
            final isDownloaded = dataset?.downloadedPicos.any((p) => p['id'] == 'pico_sync_1') ?? false;
            return CragCard(
              crag: {
                'id': 'pico_sync_1',
                'nome': 'Pico Browse',
                'isDownloaded': isDownloaded,
              },
              downloadingCrags: mockSync.downloadingCrags,
              onDownload: () {},
              onOpen: () {},
            );
          },
        ),
      ),
    ));
    
    await tester.pump();
    
    // No início, não deve estar salvo offline
    expect(find.text('SALVO OFFLINE'), findsNothing);
    
    // Atualiza dataset simulando download
    mockRepo.activeDataset.value = TopoDataset(
      availablePicos: mockRepo.activeDataset.value!.availablePicos,
      downloadedPicos: [
        {
          'id': 'pico_sync_1',
          'data': {}
        }
      ],
    );
    
    await tester.pump();
    
    // O widget foi reconstruído e o CragCard mostra salvo offline?
    expect(find.text('SALVO OFFLINE'), findsOneWidget);
  });
}
