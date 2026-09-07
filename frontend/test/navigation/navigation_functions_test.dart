// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:frontend/main.dart';
import 'package:frontend/navigation/navigation_functions.dart';
import 'package:frontend/navigation/navigation_tree.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/editor_croqui.dart';

class FakeDatasetRepository extends Fake implements DatasetRepository {
  @override
  late final ValueNotifier<TopoDataset?> activeDataset;
  @override
  final ValueNotifier<Indice?> indiceData = ValueNotifier(null);
  @override
  final ValueNotifier<int> homeResetTrigger = ValueNotifier(0);
  @override
  final GerenciadorSessaoOnline gerenciadorSessaoOnline = GerenciadorSessaoOnline();
  @override
  final ValueNotifier<String?> notificadorCroquiAtualizado = ValueNotifier(null);
  @override
  late final EditorDeCroqui editorDeCroqui;

  FakeDatasetRepository(this.editorDeCroqui) {
    final via = ViaEsportiva()..nome = 'Via Teste';
    final escalada = Escalada()..viaEsportiva = via;
    final setor = Setor()
      ..nome = 'Setor Teste'
      ..escaladas.add(escalada);
    final arquivoSetor = ArquivoSetor()..conteudo = setor;

    final grupo = Grupo()
      ..nome = 'Grupo Teste'
      ..setores.add(arquivoSetor);
    final arquivoGrupo = ArquivoGrupo()..conteudo = grupo;

    final grupoNode = SetorOuGrupo()..grupo = arquivoGrupo;

    final pico = Pico()..setoresOuGrupos.add(grupoNode);
    final croqui = Croqui();

    activeDataset = ValueNotifier(
      ConjuntoDadosCroqui(
        picosDisponiveis: [],
        picosBaixados: [
          {
            'id': 'test_crag',
            'data': {'pico': pico, 'croqui': croqui},
          },
        ],
      ),
    );
  }

  @override
  bool isPicoDownloaded(String picoId) => false;
}


class FakeSyncService extends Fake implements SyncService {
  @override
  final ValueNotifier<SyncStatus> syncStatus = ValueNotifier(
    SyncStatus.updated,
  );
  @override
  final ValueNotifier<bool> lastSyncWasAuto = ValueNotifier(false);
  @override
  final ValueNotifier<String?> picoAbertoId = ValueNotifier<String?>(null);

  @override
  final ValueNotifier<String?> recargaPendentePicoId =
      ValueNotifier<String?>(null);

  @override
  final ValueNotifier<Map<String, double>> downloadingCrags = ValueNotifier(
    <String, double>{},
  );
}

class FakeEditorDeCroqui extends Fake implements EditorDeCroqui {
  @override
  final ValueNotifier<String?> editorUrl = ValueNotifier<String?>(null);
  @override
  final ValueNotifier<bool> isExperimentalMode = ValueNotifier<bool>(false);
  @override
  final ValueNotifier<bool> isDevModeEnabled = ValueNotifier<bool>(false);
}

void main() {
  late FakeDatasetRepository mockRepo;
  late FakeSyncService mockSync;
  late FakeEditorDeCroqui mockEditor;

  setUp(() {
    mockEditor = FakeEditorDeCroqui();
    mockRepo = FakeDatasetRepository(mockEditor);
    mockSync = FakeSyncService();
  });

  group('AppNav tests', () {
    testWidgets('toVia pushes ViaNode to the TreeNavigationController', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TreeNavigationWrapper(
            key: TreeNavigationWrapper.navKey,
            datasetRepo: mockRepo,
            syncService: mockSync,
          ),
        ),
      );
      await tester.pump();

      final BuildContext context = tester.element(find.byType(Scaffold).first);
      final controller =
          TreeNavigationWrapper.navKey.currentState!.treeController;

      // Navigate to PicoNode to establish context
      controller.navigateTo(PicoNode(cragId: 'test_crag', parent: HomeNode()));
      await tester.pump();

      final escalada = Escalada()
        ..viaEsportiva = (ViaEsportiva()..nome = 'Via Teste');
      final setor = Setor()..nome = 'Setor Teste';
      final grupo = Grupo()..nome = 'Grupo Teste';

      AppNav.toVia(context, escalada: escalada, setor: setor, grupo: grupo);

      final currentNode = controller.currentNode;
      expect(currentNode, isA<ViaNode>());

      final viaNode = currentNode as ViaNode;
      expect(viaNode.escaladaNome, 'Via Teste');
      expect(viaNode.setorNome, 'Setor Teste');
      expect(viaNode.grupoNome, 'Grupo Teste');
      expect(viaNode.cragId, 'test_crag');
    });

    testWidgets('toSetor pushes SetorNode to the TreeNavigationController', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TreeNavigationWrapper(
            key: TreeNavigationWrapper.navKey,
            datasetRepo: mockRepo,
            syncService: mockSync,
          ),
        ),
      );
      await tester.pump();

      final BuildContext context = tester.element(find.byType(Scaffold).first);
      final controller =
          TreeNavigationWrapper.navKey.currentState!.treeController;

      // Navigate to PicoNode to establish context
      controller.navigateTo(PicoNode(cragId: 'test_crag', parent: HomeNode()));
      await tester.pump();

      final setor = Setor()..nome = 'Setor Teste';

      AppNav.toSetor(context, setor: setor);

      final currentNode = controller.currentNode;
      expect(currentNode, isA<SetorNode>());

      final setorNode = currentNode as SetorNode;
      expect(setorNode.setorNome, 'Setor Teste');
      expect(setorNode.cragId, 'test_crag');
    });

    testWidgets(
      'toMapas pushes MapasCarrosselNode to the TreeNavigationController',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: TreeNavigationWrapper(
              key: TreeNavigationWrapper.navKey,
              datasetRepo: mockRepo,
              syncService: mockSync,
            ),
          ),
        );
        await tester.pump();

        final BuildContext context = tester.element(
          find.byType(Scaffold).first,
        );
        final controller =
            TreeNavigationWrapper.navKey.currentState!.treeController;

        // Navigate to PicoNode to establish context
        controller.navigateTo(
          PicoNode(cragId: 'test_crag', parent: HomeNode()),
        );
        await tester.pump();

        AppNav.toMapas(
          context,
          cragId: 'test_crag',
          initialIndex: 1,
          mapas: const [
            CarrosselItemData(
              mapaCaminhoImagem: 'assets/map1.png',
              initialSelectedId: 'a',
            ),
            CarrosselItemData(
              mapaCaminhoImagem: 'assets/map2.png',
              initialSelectedId: 'b',
            ),
          ],
        );

        final currentNode = controller.currentNode;
        expect(currentNode, isA<MapasCarrosselNode>());

        final carrosselNode = currentNode as MapasCarrosselNode;
        expect(carrosselNode.cragId, 'test_crag');
        expect(carrosselNode.initialIndex, 1);
        expect(carrosselNode.mapas.length, 2);
        expect(carrosselNode.mapas[0].initialSelectedId, 'a');
      },
    );

    testWidgets(
      'AppNav must resolve controller via TreeNavigationWrapper.currentTreeController when called from dialog/overlay context',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: TreeNavigationWrapper(
              key: TreeNavigationWrapper.navKey,
              datasetRepo: mockRepo,
              syncService: mockSync,
            ),
          ),
        );
        await tester.pump();

        final BuildContext context = tester.element(
          find.byType(Scaffold).first,
        );

        late BuildContext dialogContext;
        showDialog(
          context: context,
          builder: (ctx) {
            dialogContext = ctx;
            return const AlertDialog(title: Text('Overlay'));
          },
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Chama AppNav usando o contexto do diálogo
        AppNav.toPico(dialogContext, cragId: 'test_crag');
        await tester.pump();

        final controller = TreeNavigationWrapper.currentTreeController;
        expect(controller?.currentNode, isA<PicoNode>());
        expect((controller?.currentNode as PicoNode).cragId, 'test_crag');
      },
    );
  });
}
