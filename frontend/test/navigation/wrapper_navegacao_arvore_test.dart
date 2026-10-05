// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:feedback/feedback.dart';
import 'package:frontend/application_managers/feedback/caso_uso_enviar_feedback.dart';
import 'package:frontend/navigation/arvore_navegacao.dart';
import 'package:frontend/navigation/wrapper_navegacao_arvore.dart';
import 'package:frontend/services/firebase/telemetria.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/http/sync_service.dart';
import '../mocks/mock_telemetria.dart';

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

    testWidgets('navegar para ControlesNode não gera Unknown Node nem quebra Navigator', (tester) async {
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
      await tester.pump();

      controller.navigateTo(ControlesNode(cragId: 'pedra_bela', parent: controller.currentNode));
      await tester.pump();

      expect(find.text('Unknown Node'), findsNothing);
    });

    testWidgets('registra telemetria de cancelar_feedback ao fechar feedback sem envio', (tester) async {
      final mockTelemetry = MockTelemetryService();
      TelemetryService.instance = mockTelemetry;
      SubmitFeedbackUseCase.ultimoEnvioConcluido = false;

      late BuildContext buildContext;
      await tester.pumpWidget(
        MaterialApp(
          home: BetterFeedback(
            child: TreeNavigationWrapper(
              key: TreeNavigationWrapper.navKey,
              datasetRepo: mockRepo,
              syncService: mockSync,
              child: Builder(
                builder: (context) {
                  buildContext = context;
                  return const Scaffold(body: Text('Base'));
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Abre o feedback
      BetterFeedback.of(buildContext).show((_) {});
      await tester.pumpAndSettle();
      expect(SubmitFeedbackUseCase.isFeedbackOpen.value, isTrue);

      // Fecha o feedback sem enviar (descarte do usuário)
      BetterFeedback.of(buildContext).hide();
      await tester.pumpAndSettle();

      expect(mockTelemetry.recordedEvents, contains('acao_feedback'));
      final params = mockTelemetry.recordedParams['acao_feedback']!;
      expect(params['acao'], 'cancelar_feedback');
      expect(params['origem'], 'descarte_usuario');

      TelemetryService.resetForTesting();
    });

    testWidgets('não registra cancelar_feedback quando envio for concluído com sucesso', (tester) async {
      final mockTelemetry = MockTelemetryService();
      TelemetryService.instance = mockTelemetry;

      late BuildContext buildContext;
      await tester.pumpWidget(
        MaterialApp(
          home: BetterFeedback(
            child: TreeNavigationWrapper(
              key: TreeNavigationWrapper.navKey,
              datasetRepo: mockRepo,
              syncService: mockSync,
              child: Builder(
                builder: (context) {
                  buildContext = context;
                  return const Scaffold(body: Text('Base'));
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Abre o feedback
      BetterFeedback.of(buildContext).show((_) {});
      await tester.pumpAndSettle();

      // Simula submissão bem-sucedida
      SubmitFeedbackUseCase.ultimoEnvioConcluido = true;
      mockTelemetry.clear();

      // Fecha o feedback
      BetterFeedback.of(buildContext).hide();
      await tester.pumpAndSettle();

      expect(mockTelemetry.recordedEvents, isNot(contains('acao_feedback')));

      TelemetryService.resetForTesting();
    });
  });
}

