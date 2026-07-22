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

      // Na home (não há PageListenableBuilder com cragId='test_pico_1'),
      // O popup "Croqui Atualizado" NÃO deve ser exibido.
      expect(find.text('Croqui Atualizado'), findsNothing);
    });

    testWidgets('Fluxo 5.2: Bloqueio e recarga opcional para pico ativo', (
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

      // Como o pico está aberto, o pico_aberto_id deve ser 'test_pico_1'
      expect(syncService.pico_aberto_id.value, 'test_pico_1');

      // Simulamos o término do download no SyncService
      syncService.recarga_pendente_pico_id.value = 'test_pico_1';
      await tester.pump(const Duration(milliseconds: 500));

      // O popup DEVE aparecer agora
      expect(find.text('Croqui Atualizado'), findsOneWidget);

      // O usuário clica em recarregar
      await tester.tap(find.text('RECARREGAR'));
      await tester.pump(const Duration(milliseconds: 500));

      // O popup deve sumir (pois o pendingId foi setado pra null em commitPendenciasAtomaticas)
      expect(find.text('Croqui Atualizado'), findsNothing);
    });
  });
}
