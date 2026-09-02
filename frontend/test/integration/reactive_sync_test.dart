// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/main.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/navigation/navigation_tree.dart';
import 'package:frontend/services/editor_croqui.dart';

void main() {
  group('Fluxo de Atualização Reativa e Silenciosa (Tasks 5.1 e 5.2)', () {
    late DatasetRepository datasetRepo;
    late SyncService syncService;

    setUp(() {
      datasetRepo = DatasetRepository(editorDeCroqui: EditorDeCroqui());
      // Setup mock initial dataset
      final pico = Pico()..nome = 'Pico Teste';
      final croqui = Croqui();
      datasetRepo.activeDataset.value = TopoDataset(
        downloadedPicos: [
          {
            'id': 'test_pico_1',
            'data': {'pico': pico, 'croqui': croqui},
            'isDownloaded': true,
          },
        ],
        availablePicos: [],
      );

      syncService = SyncService(datasetRepository: datasetRepo);
    });

    testWidgets('Fluxo 5.1: Atualização silenciosa no background', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TreeNavigationWrapper(
            datasetRepo: datasetRepo,
            syncService: syncService,
          ),
        ),
      );

      // Espera inicializar
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // O usuário está na Home, então o pico_aberto_id deve ser null.
      expect(syncService.pico_aberto_id.value, isNull);

      // Simulamos uma pendência retida no SyncService mesmo sem o pico estar aberto
      // (Isso não deveria acontecer, pois ela seria commitada imediatamente se o pico não estivesse aberto, mas vamos simular)

      // Quando estamos na home e há uma pendência, não deve aparecer popup
      syncService.recarga_pendente_pico_id.value = 'test_pico_1';
      await tester.pump(const Duration(milliseconds: 500));

      // Na home, o popup "Croqui Atualizado" nunca é exibido
      expect(find.text('Croqui Atualizado'), findsNothing);
    });

    testWidgets('Fluxo 5.2: Atualização reativa e contínua para pico ativo', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TreeNavigationWrapper(
            datasetRepo: datasetRepo,
            syncService: syncService,
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      // Navegar para o pico e torná-lo ativo
      final wrapperState =
          tester.state<State<TreeNavigationWrapper>>(
                find.byType(TreeNavigationWrapper),
              )
              as dynamic;
      final TreeNavigationController treeController =
          wrapperState.treeController;

      treeController.navigateTo(
        PicoNode(cragId: 'test_pico_1', parent: const HomeNode()),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('PICO TESTE'), findsOneWidget);

      // Simula atualização no dataset diretamente (atualização contínua/seamless)
      final picoV2 = Pico()..nome = 'Pico Teste V2';
      final croquiV2 = Croqui();
      datasetRepo.activeDataset.value = TopoDataset(
        downloadedPicos: [
          {
            'id': 'test_pico_1',
            'data': {'pico': picoV2, 'croqui': croquiV2},
            'isDownloaded': true,
          },
        ],
        availablePicos: [],
      );

      await tester.pump(const Duration(milliseconds: 500));

      // A página atualizou instantaneamente sem popups ou bloqueios
      expect(find.text('PICO TESTE V2'), findsOneWidget);
      expect(find.text('Croqui Atualizado'), findsNothing);
    });
  });
}
