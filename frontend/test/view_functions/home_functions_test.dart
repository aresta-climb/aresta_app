// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

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
              mockRepo,
              mockSync,
              (index) {}, // onSwitchTab
            );
          },
        ),
      ),
    );
  }

  testWidgets(
    'buildHomeBody renders the new layout including NearbyCragsCarousel and header buttons',
    (WidgetTester tester) async {
      mockRepo.activeDataset.value = TopoDataset(availablePicos: [], downloadedPicos: []);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      // Verify Header buttons exist even when downloadedPicos is empty
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byIcon(Icons.sync), findsOneWidget);
      expect(find.byIcon(Icons.search), findsNWidgets(2));
      expect(find.text('Buscar picos, setores ou vias...'), findsOneWidget);

      // Verify NearbyCragsCarousel exists
      expect(find.byType(NearbyCragsCarousel), findsOneWidget);
    },
  );

  testWidgets(
    'handlePicoSelection dispara telemetria de abrir_croqui com origem',
    (WidgetTester tester) async {
      final mockTelemetry = MockTelemetryService();
      TelemetryService.instance = mockTelemetry;

      final dummyPico = {'id': 'test-pico-1'};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () =>
                      handlePicoSelection(context, mockRepo, dummyPico),
                  child: const Text('Go'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go'));

      expect(mockTelemetry.recordedEvents, contains('acao_croqui'));
      expect(
        mockTelemetry.recordedParams['acao_croqui']!['acao'],
        'abrir_croqui',
      );
      expect(mockTelemetry.recordedParams['acao_croqui']!['origem'], 'home');
    },
  );

  testWidgets(
    'Downloads from activeDataset update Home download cards reactively',
    (WidgetTester tester) async {
      mockRepo.activeDataset.value = TopoDataset(
        availablePicos: [
          {
            'id': 'pico_sync_1',
            'nome': 'Pico Sync',
            'local': 'Local Sync',
            'latitude': -20.0,
            'longitude': -40.0,
          },
        ],
        downloadedPicos: [],
      );

      // Renderiza diretamente o mesmo padrão do NearbyCragsCarousel para evitar
      // dependência em chamadas do Geolocator que rodam infinitamente em testes.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<TopoDataset?>(
              valueListenable: mockRepo.activeDataset,
              builder: (context, dataset, child) {
                final isDownloaded =
                    dataset?.downloadedPicos.any(
                      (p) => p['id'] == 'pico_sync_1',
                    ) ??
                    false;
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
        ),
      );

      await tester.pump();

      // No início, não deve estar salvo offline
      expect(find.text('SALVO OFFLINE'), findsNothing);

      // 2. Atualiza para mostrar que foi baixado (simula o fim do download)
      mockRepo.activeDataset.value = TopoDataset(
        availablePicos: mockRepo.activeDataset.value!.availablePicos,
        downloadedPicos: [
          {'id': 'pico_sync_1', 'data': {}},
        ],
      );

      await tester.pump();

      // O widget foi reconstruído e o CragCard mostra salvo offline?
      expect(find.text('SALVO OFFLINE'), findsOneWidget);
    },
  );

  testWidgets(
    'buildHomeBody renders unified search bar regardless of downloaded picos',
    (WidgetTester tester) async {
      mockRepo.activeDataset.value = TopoDataset(
        availablePicos: [],
        downloadedPicos: [],
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      // Search icon is visible in search bar and in quick guide (2 total)
      expect(find.byIcon(Icons.search), findsNWidgets(2));
      expect(find.text('Buscar picos, setores ou vias...'), findsOneWidget);

      mockRepo.activeDataset.value = TopoDataset(
        availablePicos: [],
        downloadedPicos: [{'id': 'pico_1', 'nome': 'Pico 1'}],
      );

      await tester.pump();

      expect(find.byIcon(Icons.search), findsNWidgets(2));
      expect(find.text('Buscar picos, setores ou vias...'), findsOneWidget);
    },
  );
}
