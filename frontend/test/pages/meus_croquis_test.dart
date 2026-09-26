// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/pages/meus_croquis.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/view_functions/meus_croquis_functions.dart';
import 'package:frontend/view_functions/view_models/meus_croquis_view_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatasetRepository repositorio;
  late SyncService servicoSync;

  setUp(() {
    final editor = EditorDeCroqui();
    repositorio = DatasetRepository(editorDeCroqui: editor);
    servicoSync = SyncService(datasetRepository: repositorio);
  });

  Widget buildTestWidget({MeusCroquisViewModel? viewModel}) {
    return MaterialApp(
      home: Theme(
        data: ThemeData(extensions: [AppColors.dark]),
        child: MeusCroquisPage(
          datasetRepo: repositorio,
          syncService: servicoSync,
          viewModel: viewModel,
        ),
      ),
    );
  }

  group('MeusCroquisPage', () {
    testWidgets('exibe mensagem quando não há croquis salvos offline', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('MEUS CROQUIS'), findsOneWidget);
      expect(find.text('ARMAZENAMENTO OFFLINE'), findsOneWidget);
      expect(find.text('Nenhum croqui salvo offline ainda.'), findsOneWidget);
      expect(find.byType(OfflineCragCard), findsNothing);
    });

    testWidgets('renderiza OfflineCragCard quando há croquis salvos offline', (
      WidgetTester tester,
    ) async {
      repositorio.activeDataset.value = TopoDataset(
        availablePicos: [],
        croquisBaixados: [
          Croqui(
            id: 'croqui_1',
            nome: 'Pico da Neblina',
            picos: [
              Pico(
                estado: 'Amazonas',
                precomputados: PrecomputadosPico(totalSetores: 2, totalEscaladas: 10),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Nenhum croqui salvo offline ainda.'), findsNothing);
      expect(find.byType(OfflineCragCard), findsOneWidget);
      expect(find.text('PICO DA NEBLINA'), findsOneWidget);
      expect(find.text('AMAZONAS'), findsOneWidget);
    });

    testWidgets('renderiza com ViewModel customizado injetado', (
      WidgetTester tester,
    ) async {
      final vmCustomizado = MeusCroquisViewModel(
        datasetRepo: repositorio,
        syncService: servicoSync,
      );

      await tester.pumpWidget(buildTestWidget(viewModel: vmCustomizado));
      await tester.pumpAndSettle();

      expect(find.text('MEUS CROQUIS'), findsOneWidget);
      expect(find.text('Nenhum croqui salvo offline ainda.'), findsOneWidget);
    });
  });
}
