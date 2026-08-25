// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/pages/home.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import '../mocks/mock_telemetry_service.dart';

class MockDatasetRepository extends Mock implements DatasetRepository {}

class MockSyncService extends Mock implements SyncService {}

void main() {
  setUpAll(() {
    TelemetryService.instance = MockTelemetryService();
  });

  Widget createTestWidget(DatasetRepository repo, SyncService syncService) {
    return MaterialApp(
      home: HomePage(
        datasetRepo: repo,
        syncService: syncService,
        onSwitchTab: (_) {},
      ),
    );
  }

  testWidgets(
    'HomePage pull-to-refresh quando não há croquis baixados mostra snackbar adequado',
    (tester) async {
      final mockRepo = MockDatasetRepository();
      final mockSync = MockSyncService();
      final ValueNotifier<TopoDataset?> activeDataset = ValueNotifier(
        TopoDataset(availablePicos: [], downloadedPicos: []),
      );

      when(() => mockRepo.activeDataset).thenReturn(activeDataset);
      when(() => mockSync.isNetworkDisabled()).thenAnswer((_) async => false);
      when(
        () => mockSync.syncStatus,
      ).thenReturn(ValueNotifier(SyncStatus.updated));
      when(() => mockSync.downloadingCrags).thenReturn(ValueNotifier({}));

      await tester.pumpWidget(createTestWidget(mockRepo, mockSync));
      await tester.pump(); // Render first frame

      // Puxa para atualizar
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, 300),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1)); // Wait for refresh logic

      expect(
        find.text('Nenhum croqui baixado para atualizar.'),
        findsOneWidget,
      );
      verifyNever(() => mockSync.syncIndex(auto: false));
    },
  );

  testWidgets(
    'HomePage pull-to-refresh aciona sincronização se houver croquis baixados',
    (tester) async {
      final mockRepo = MockDatasetRepository();
      final mockSync = MockSyncService();
      final ValueNotifier<TopoDataset?> activeDataset = ValueNotifier(
        TopoDataset(
          availablePicos: [],
          downloadedPicos: [
            {'id': '1', 'nome': 'Pico 1'},
          ],
        ),
      );

      when(() => mockRepo.activeDataset).thenReturn(activeDataset);
      when(() => mockSync.isNetworkDisabled()).thenAnswer((_) async => false);
      when(
        () => mockSync.syncIndex(auto: false),
      ).thenAnswer((_) async => <String>[]);
      when(
        () => mockSync.syncStatus,
      ).thenReturn(ValueNotifier(SyncStatus.justUpdated));
      when(() => mockSync.downloadingCrags).thenReturn(ValueNotifier({}));

      await tester.pumpWidget(createTestWidget(mockRepo, mockSync));
      await tester.pump(); // Render first frame

      // Puxa para atualizar
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, 300),
      );

      // Aguarda animação do RefreshIndicator
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Croquis foram atualizados!'), findsOneWidget);
      verify(() => mockSync.syncIndex(auto: false)).called(1);
    },
  );
}
