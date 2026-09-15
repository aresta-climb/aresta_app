// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/view_functions/meus_croquis_functions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('OfflineCragCard renderiza dados tipados de ResumoPico', (
    WidgetTester tester,
  ) async {
    final editor = EditorDeCroqui();
    final repo = DatasetRepository(editorDeCroqui: editor);
    final sync = SyncService(datasetRepository: repo);

    const crag = ResumoPico(
      id: 'pico_offline_1',
      nome: 'Pico das Galinhas',
      local: 'Minas Gerais',
      estatisticas: EstatisticasPico(
        totalSetores: 3,
        totalVias: 25,
      ),
      isDownloaded: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OfflineCragCard(
            crag: crag,
            datasetRepo: repo,
            syncService: sync,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('PICO DAS GALINHAS'), findsOneWidget);
    expect(find.text('MINAS GERAIS'), findsOneWidget);
    expect(find.text('3 setores • 25 escaladas'), findsOneWidget);
    expect(find.text('ABRIR OFFLINE'), findsOneWidget);
  });
}
