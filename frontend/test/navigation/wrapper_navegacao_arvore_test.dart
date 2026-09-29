// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/navigation/arvore_navegacao.dart';
import 'package:frontend/navigation/wrapper_navegacao_arvore.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/http/sync_service.dart';

class MockDatasetRepository extends Mock implements DatasetRepository {}

class MockSyncService extends Mock implements SyncService {}

class MockEditorDeCroqui extends Mock implements EditorDeCroqui {}

void main() {
  group('TreeNavigationWrapper Widget Tests', () {
    late MockDatasetRepository mockRepo;
    late MockSyncService mockSync;
    late MockEditorDeCroqui mockEditor;
    late ValueNotifier<SyncStatus> syncStatusNotifier;
    late ValueNotifier<bool> lastSyncWasAutoNotifier;
    late ValueNotifier<int> croquisAtualizadosNotifier;
    late ValueNotifier<String?> croquiAtualizadoNotifier;
    late ValueNotifier<int> homeResetNotifier;

    setUp(() {
      mockRepo = MockDatasetRepository();
      mockSync = MockSyncService();
      mockEditor = MockEditorDeCroqui();

      syncStatusNotifier = ValueNotifier(SyncStatus.updated);
      lastSyncWasAutoNotifier = ValueNotifier(false);
      croquisAtualizadosNotifier = ValueNotifier(0);
      croquiAtualizadoNotifier = ValueNotifier(null);
      homeResetNotifier = ValueNotifier(0);

      when(() => mockSync.syncStatus).thenReturn(syncStatusNotifier);
      when(() => mockSync.lastSyncWasAuto).thenReturn(lastSyncWasAutoNotifier);
      when(() => mockSync.quantidadeCroquisBaixadosAtualizadosNoUltimoSync)
          .thenReturn(croquisAtualizadosNotifier);
      when(() => mockSync.picoAbertoId).thenReturn(ValueNotifier(null));

      when(() => mockRepo.editorDeCroqui).thenReturn(mockEditor);
      when(() => mockRepo.notificadorCroquiAtualizado).thenReturn(croquiAtualizadoNotifier);
      when(() => mockRepo.homeResetTrigger).thenReturn(homeResetNotifier);
      when(() => mockRepo.activeDataset).thenReturn(ValueNotifier(null));
      when(() => mockRepo.gerenciadorSessaoOnline).thenReturn(GerenciadorSessaoOnline());

      when(() => mockEditor.isExperimentalMode).thenReturn(ValueNotifier(false));
      when(() => mockEditor.editorUrl).thenReturn(ValueNotifier(null));
    });

    testWidgets('renderiza com sucesso e provê acesso a of e maybeOf', (tester) async {
      late TreeNavigationWrapperState stateOf;
      TreeNavigationWrapperState? stateMaybeOf;

      await tester.pumpWidget(
        MaterialApp(
          home: TreeNavigationWrapper(
            key: TreeNavigationWrapper.navKey,
            datasetRepo: mockRepo,
            syncService: mockSync,
            child: Builder(
              builder: (context) {
                stateOf = TreeNavigationWrapper.of(context);
                stateMaybeOf = TreeNavigationWrapper.maybeOf(context);
                return const Scaffold(body: Text('Conteúdo Teste'));
              },
            ),
          ),
        ),
      );

      expect(find.text('Conteúdo Teste'), findsOneWidget);
      expect(stateOf, isNotNull);
      expect(stateMaybeOf, isNotNull);
      expect(TreeNavigationWrapper.currentTreeController, isNotNull);
    });

    testWidgets('switchTab altera a navegação através do controlador', (tester) async {
      final controller = TreeNavigationController();

      await tester.pumpWidget(
        MaterialApp(
          home: TreeNavigationWrapper(
            key: TreeNavigationWrapper.navKey,
            datasetRepo: mockRepo,
            syncService: mockSync,
            treeController: controller,
          ),
        ),
      );

      expect(controller.currentNode, isA<HomeNode>());

      TreeNavigationWrapper.switchTab(1);
      await tester.pump(const Duration(milliseconds: 200));
      expect(controller.currentNode, isA<BrowseNode>());

      TreeNavigationWrapper.switchTab(2);
      await tester.pump(const Duration(milliseconds: 200));
      expect(controller.currentNode, isA<MeusCroquisNode>());

      TreeNavigationWrapper.switchTab(3);
      await tester.pump(const Duration(milliseconds: 200));
      expect(controller.currentNode, isA<ComunidadeNode>());
    });
  });
}
