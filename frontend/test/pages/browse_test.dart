// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/pages/browse.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import '../mocks/mock_telemetry_service.dart';

import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';

class FakeDatasetRepository extends DatasetRepository {
  FakeDatasetRepository(EditorDeCroqui editor) : super(editorDeCroqui: editor);

  @override
  Future<Croqui?> getCroqui(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return null;
  }
}

class FakeSyncService extends SyncService {
  FakeSyncService(DatasetRepository repo) : super(datasetRepository: repo);
  bool mockResult = true;

  @override
  Future<bool> downloadCrag(ResumoCroqui resumo) async {
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

  testWidgets('BrowsePage shows success SnackBar when download succeeds', (
    WidgetTester tester,
  ) async {
    mockRepo.activeDataset.value = TopoDataset(
      availablePicos: [
        {'id': 'pico_1', 'nome': 'Pico Teste', 'url': 'fake.url'},
      ],
      downloadedPicos: [],
    );
    mockRepo.indiceData.value = Indice()
      ..croquis.add(
        ResumoCroqui()
          ..id = 'pico_1'
          ..nome = 'Pico Teste',
      );

    mockSync.mockResult = true;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BrowsePage(datasetRepo: mockRepo, syncService: mockSync),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the card to open the bottom sheet
    await tester.tap(find.text('PICO TESTE'));
    await tester.pumpAndSettle();

    // Tap the download button in the bottom sheet
    await tester.tap(find.text('BAIXAR CROQUI'));

    // Wait for the async function to finish and SnackBar to appear
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Pico Teste baixado'), findsOneWidget);
  });

  testWidgets('BrowsePage shows error SnackBar when download fails', (
    WidgetTester tester,
  ) async {
    mockRepo.activeDataset.value = TopoDataset(
      availablePicos: [
        {'id': 'pico_1', 'nome': 'Pico Teste', 'url': 'fake.url'},
      ],
      downloadedPicos: [],
    );
    mockRepo.indiceData.value = Indice()
      ..croquis.add(
        ResumoCroqui()
          ..id = 'pico_1'
          ..nome = 'Pico Teste',
      );

    mockSync.mockResult = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BrowsePage(datasetRepo: mockRepo, syncService: mockSync),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the card to open the bottom sheet
    await tester.tap(find.text('PICO TESTE'));
    await tester.pumpAndSettle();

    // Tap the download button in the bottom sheet
    await tester.tap(find.text('BAIXAR CROQUI'));

    // Wait for the async function to finish and SnackBar to appear
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Falha ao baixar Pico Teste'), findsOneWidget);
  });

  testWidgets('BrowsePage filters list based on search query', (
    WidgetTester tester,
  ) async {
    mockRepo.activeDataset.value = TopoDataset(
      availablePicos: [
        {'id': 'pico_1', 'nome': 'Pico Alpha', 'url': 'fake1.url'},
        {'id': 'pico_2', 'nome': 'Pico Beta', 'url': 'fake2.url'},
      ],
      downloadedPicos: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BrowsePage(datasetRepo: mockRepo, syncService: mockSync),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PICO ALPHA'), findsOneWidget);
    expect(find.text('PICO BETA'), findsOneWidget);

    // Enter search query
    await tester.enterText(find.byType(TextField), 'Alpha');
    await tester.pump(const Duration(milliseconds: 600)); // wait for debounce
    await tester.pumpAndSettle();

    expect(find.text('PICO ALPHA'), findsOneWidget);
    expect(find.text('PICO BETA'), findsNothing);
  });

  testWidgets(
    'BrowsePage shows CircularProgressIndicator when tapping a downloaded crag',
    (WidgetTester tester) async {
      mockRepo.activeDataset.value = TopoDataset(
        availablePicos: [
          {
            'id': 'pico_1',
            'nome': 'Pico Baixado',
            'url': 'fake.url',
            'isDownloaded': true,
          },
        ],
        downloadedPicos: [
          {'id': 'pico_1', 'nome': 'Pico Baixado'},
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BrowsePage(datasetRepo: mockRepo, syncService: mockSync),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tapping a downloaded crag directly opens it (triggers AppNav.toPico which shows indicator in tests)
      await tester.tap(find.text('PICO BAIXADO'));

      // Pump just ONE frame to see the dialog/indicator
      await tester.pump();

      // The CircularProgressIndicator should be visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Settle to let the dialog close
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'BrowsePage filters sort list by default, alphabetical, and by route count',
    (WidgetTester tester) async {
      mockRepo.activeDataset.value = TopoDataset(
        availablePicos: [
          {
            'id': 'pico_c',
            'nome': 'C Pico',
            'estatisticas': {'totalVias': 10},
          },
          {
            'id': 'pico_a',
            'nome': 'A Pico',
            'estatisticas': {'totalVias': 5},
          },
          {
            'id': 'pico_b',
            'nome': 'B Pico',
            'estatisticas': {'totalVias': 50},
          },
        ],
        downloadedPicos: [],
      );
      mockRepo.indiceData.value = Indice();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BrowsePage(datasetRepo: mockRepo, syncService: mockSync),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Helper to get vertical position of an item
      double getPos(String text) => tester.getTopLeft(find.text(text)).dy;

      // Default order should be the original list order: C, A, B
      expect(
        getPos('C PICO') < getPos('A PICO'),
        true,
        reason: 'Default order: C should be before A',
      );
      expect(
        getPos('A PICO') < getPos('B PICO'),
        true,
        reason: 'Default order: A should be before B',
      );

      // Open filter menu
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      // Select Alphabetical
      await tester.tap(find.text('Alfabético (A-Z)'));
      await tester.pumpAndSettle();

      // Alphabetical order: A, B, C
      expect(
        getPos('A PICO') < getPos('B PICO'),
        true,
        reason: 'Alpha order: A should be before B',
      );
      expect(
        getPos('B PICO') < getPos('C PICO'),
        true,
        reason: 'Alpha order: B should be before C',
      );

      // Open filter menu again
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      // Select Route Count
      await tester.tap(find.text('Por número de escaladas'));
      await tester.pumpAndSettle();

      // Route count order (descending): B (50), C (10), A (5)
      expect(
        getPos('B PICO') < getPos('C PICO'),
        true,
        reason: 'Routes order: B should be before C',
      );
      expect(
        getPos('C PICO') < getPos('A PICO'),
        true,
        reason: 'Routes order: C should be before A',
      );
    },
  );
}
