import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/pages/browse.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/sync_service.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import '../mocks/mock_telemetry_service.dart';

import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';

class FakeDatasetRepository extends DatasetRepository {
  FakeDatasetRepository(EditorDeCroqui editor) : super(editorDeCroqui: editor);

  @override
  Future<Croqui?> getCroqui(String id) async {
    // Return null to simulate failure and trigger the SnackBar,
    // or return a dummy Croqui. Returning null is fine to test the loading indicator.
    await Future.delayed(const Duration(milliseconds: 100));
    return null;
  }
}

class FakeSyncService extends SyncService {
  FakeSyncService(DatasetRepository repo) : super(datasetRepository: repo);
  bool mockResult = true;

  @override
  Future<bool> downloadCrag(Map<String, dynamic> crag) async {
    return mockResult;
  }
}

void main() {
  late FakeDatasetRepository mockRepo;
  late FakeSyncService mockSync;
  late EditorDeCroqui mockEditor;
  late MockTelemetryService mockTelemetry;

  setUp(() {
    mockEditor = EditorDeCroqui();
    mockRepo = FakeDatasetRepository(mockEditor);
    mockSync = FakeSyncService(mockRepo);
    
    mockTelemetry = MockTelemetryService();
    TelemetryService.instance = mockTelemetry;
  });

  testWidgets('BrowsePage shows success SnackBar when download succeeds', (WidgetTester tester) async {
    mockRepo.activeDataset.value = TopoDataset(
      availablePicos: [
        {'id': 'pico_1', 'nome': 'Pico Teste', 'url': 'fake.url'}
      ],
      downloadedPicos: [],
    );

    mockSync.mockResult = true;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BrowsePage(datasetRepo: mockRepo, syncService: mockSync),
      ),
    ));

    // Tap the item to expand
    await tester.tap(find.text('Pico Teste'));
    await tester.pumpAndSettle();

    // Tap the download icon
    final downloadButton = find.byIcon(Icons.download_rounded);
    expect(downloadButton, findsOneWidget);
    await tester.tap(downloadButton);
    
    // Wait for the async function to finish and SnackBar to appear
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Pico Teste baixado com sucesso!'), findsOneWidget);
  });

  testWidgets('BrowsePage shows error SnackBar when download fails', (WidgetTester tester) async {
    mockRepo.activeDataset.value = TopoDataset(
      availablePicos: [
        {'id': 'pico_1', 'nome': 'Pico Teste', 'url': 'fake.url'}
      ],
      downloadedPicos: [],
    );

    mockSync.mockResult = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BrowsePage(datasetRepo: mockRepo, syncService: mockSync),
      ),
    ));

    // Tap the item to expand
    await tester.tap(find.text('Pico Teste'));
    await tester.pumpAndSettle();

    // Tap the download icon
    final downloadButton = find.byIcon(Icons.download_rounded);
    expect(downloadButton, findsOneWidget);
    await tester.tap(downloadButton);
    
    // Wait for the async function to finish and SnackBar to appear
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Falha ao baixar Pico Teste'), findsOneWidget);
  });

  testWidgets('BrowsePage filters list based on search query', (WidgetTester tester) async {
    mockRepo.activeDataset.value = TopoDataset(
      availablePicos: [
        {'id': 'pico_1', 'nome': 'Pico Alpha', 'url': 'fake1.url'},
        {'id': 'pico_2', 'nome': 'Pico Beta', 'url': 'fake2.url'},
      ],
      downloadedPicos: [],
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BrowsePage(datasetRepo: mockRepo, syncService: mockSync),
      ),
    ));

    await tester.pumpAndSettle();

    expect(find.text('Pico Alpha'), findsOneWidget);
    expect(find.text('Pico Beta'), findsOneWidget);

    // Enter search query
    await tester.enterText(find.byType(TextField), 'Alpha');
    await tester.pumpAndSettle();

    expect(find.text('Pico Alpha'), findsOneWidget);
    expect(find.text('Pico Beta'), findsNothing);
  });

  testWidgets('BrowsePage shows CircularProgressIndicator when tapping a downloaded crag', (WidgetTester tester) async {
    mockRepo.activeDataset.value = TopoDataset(
      availablePicos: [
        {'id': 'pico_1', 'nome': 'Pico Baixado', 'url': 'fake.url', 'isDownloaded': true}
      ],
      downloadedPicos: [
        {'id': 'pico_1', 'nome': 'Pico Baixado', 'url': 'fake.url', 'isDownloaded': true}
      ],
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BrowsePage(datasetRepo: mockRepo, syncService: mockSync),
      ),
    ));

    await tester.pumpAndSettle();

    // Tap the item to expand it
    await tester.tap(find.text('Pico Baixado'));
    await tester.pumpAndSettle();

    // Now tap the 'ABRIR CROQUI' button
    await tester.tap(find.text('ABRIR CROQUI'));
    
    // Pump just ONE frame to see the dialog
    await tester.pump();

    // The CircularProgressIndicator should be visible
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    
    // Settle to let the dialog close
    await tester.pumpAndSettle();
  });
}
