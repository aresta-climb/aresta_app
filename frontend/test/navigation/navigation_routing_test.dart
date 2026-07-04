import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/pages/home.dart';
import 'package:frontend/pages/mapao_global.dart';
import 'package:frontend/main.dart';
import 'package:frontend/pages/mapa_interativo.dart';
import 'package:frontend/navigation/navigation_tree.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';

void main() {
  testWidgets('MapaInterativoPage is built with empty setores when a setorContext is provided', (WidgetTester tester) async {
    // 1. Prepare Mock Data
    final editorDeCroqui = EditorDeCroqui();
    final datasetRepo = DatasetRepository(editorDeCroqui: editorDeCroqui);
    final syncService = SyncService(datasetRepository: datasetRepo);

    final croqui = Croqui();
    final pico = Pico()..nome = 'Pico Teste';
    
    final setor1 = Setor()..nome = 'Setor 1';
    final setor2 = Setor()..nome = 'Setor 2';

    pico.setoresOuGrupos.add(SetorOuGrupo()..setor = (ArquivoSetor()..conteudo = setor1));
    pico.setoresOuGrupos.add(SetorOuGrupo()..setor = (ArquivoSetor()..conteudo = setor2));

    final topoDataset = TopoDataset(
      downloadedPicos: [
        {
          'id': 'crag123',
          'data': {
            'pico': pico,
            'croqui': croqui,
          }
        }
      ],
      availablePicos: [],
    );

    // Inject data
    datasetRepo.activeDataset.value = topoDataset;

    // 2. Build the app
    await tester.pumpWidget(
      MaterialApp(
        home: TreeNavigationWrapper(
          datasetRepo: datasetRepo,
          syncService: syncService,
          key: TreeNavigationWrapper.navKey,
        ),
      ),
    );

    // Wait for the home page to build
    await tester.pump(const Duration(seconds: 1));

    // 3. Navigate to MapaInterativoNode with a setorContextNome
    final treeController = TreeNavigationWrapper.currentTreeController!;
    
    treeController.navigateTo(MapaInterativoNode(
      cragId: 'crag123',
      mapaCaminhoImagem: 'test.png',
      setorContextNome: 'Setor 1',
      parent: treeController.currentNode,
    ));

    // Wait for navigation and rebuild
    await tester.pump(const Duration(seconds: 1));

    // 4. Verify MapaInterativoPage is present
    final mapaInterativoFinder = find.byType(MapaInterativoPage);
    expect(mapaInterativoFinder, findsOneWidget);

    // 5. Verify the injected properties
    final MapaInterativoPage page = tester.widget(mapaInterativoFinder);
    
    // As it was navigated WITH a setorContextNome, `setorContext` MUST be injected.
    expect(page.setorContext?.nome, 'Setor 1');
  });

  testWidgets('MapaInterativoPage is built with ALL setores when NO setorContext is provided', (WidgetTester tester) async {
    // 1. Prepare Mock Data
    final editorDeCroqui = EditorDeCroqui();
    final datasetRepo = DatasetRepository(editorDeCroqui: editorDeCroqui);
    final syncService = SyncService(datasetRepository: datasetRepo);

    final croqui = Croqui();
    final pico = Pico()..nome = 'Pico Teste';
    
    final setor1 = Setor()..nome = 'Setor 1';
    final setor2 = Setor()..nome = 'Setor 2';

    pico.setoresOuGrupos.add(SetorOuGrupo()..setor = (ArquivoSetor()..conteudo = setor1));
    pico.setoresOuGrupos.add(SetorOuGrupo()..setor = (ArquivoSetor()..conteudo = setor2));

    final topoDataset = TopoDataset(
      downloadedPicos: [
        {
          'id': 'crag123',
          'data': {
            'pico': pico,
            'croqui': croqui,
          }
        }
      ],
      availablePicos: [],
    );

    datasetRepo.activeDataset.value = topoDataset;

    // 2. Build the app
    await tester.pumpWidget(
      MaterialApp(
        home: TreeNavigationWrapper(
          datasetRepo: datasetRepo,
          syncService: syncService,
          key: TreeNavigationWrapper.navKey,
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 1));

    // 3. Navigate to MapaInterativoNode WITHOUT a setorContextNome
    final treeController = TreeNavigationWrapper.currentTreeController!;
    
    treeController.navigateTo(MapaInterativoNode(
      cragId: 'crag123',
      mapaCaminhoImagem: 'test.png',
      parent: treeController.currentNode,
    ));

    await tester.pump(const Duration(seconds: 1));

    // 4. Verify MapaInterativoPage is present
    final mapaInterativoFinder = find.byType(MapaInterativoPage);
    expect(mapaInterativoFinder, findsOneWidget);

    // 5. Verify the injected properties
    final MapaInterativoPage page = tester.widget(mapaInterativoFinder);
    
    // As it was navigated WITHOUT a setorContextNome (i.e. Mapa Geral), 
    // `setorContext` MUST be null.
    expect(page.setorContext, isNull);
  });

  group('Declarative Navigator TDD', () {
    testWidgets('AppRouter renders Navigator with multiple pages based on tree history', (WidgetTester tester) async {
      final datasetRepo = DatasetRepository(editorDeCroqui: EditorDeCroqui());
      final pico = Pico()..nome = 'Pico Teste';
      datasetRepo.activeDataset.value = TopoDataset(downloadedPicos: [
        {'id': '123', 'data': {'pico': pico, 'croqui': Croqui()}}
      ], availablePicos: []);
      final syncService = SyncService(datasetRepository: datasetRepo);

      await tester.pumpWidget(
        MaterialApp(
          home: TreeNavigationWrapper(
            datasetRepo: datasetRepo,
            syncService: syncService,
            key: TreeNavigationWrapper.navKey,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      final treeController = TreeNavigationWrapper.currentTreeController!;

      // Navigate to a deeper node
      treeController.navigateTo(PicoNode(cragId: '123', parent: treeController.currentNode));
      await tester.pump(const Duration(seconds: 1));

      treeController.navigateTo(SetorNode(cragId: '123', setorNome: 'S1', parent: treeController.currentNode));
      await tester.pump(const Duration(seconds: 1));

      // Find Navigator directly rendered by TreeNavigationWrapper
      final navigatorFinder = find.descendant(
        of: find.byType(TreeNavigationWrapper),
        matching: find.byType(Navigator),
      );

      expect(navigatorFinder, findsOneWidget);
      final navigator = tester.widget<Navigator>(navigatorFinder);
      
      // Should have 3 pages: Home, Pico, Setor
      expect(navigator.pages.length, 3);
      expect(navigator.pages[0].key, const ValueKey('TabsPage'));
      expect(navigator.pages[1].key, const ValueKey('PicoNode(123)'));
      expect(navigator.pages[2].key, const ValueKey('SetorNode(S1)'));
    });

    testWidgets('System back button or Navigator pop triggers treeController.goBack()', (WidgetTester tester) async {
      final datasetRepo = DatasetRepository(editorDeCroqui: EditorDeCroqui());
      final pico = Pico()..nome = 'Pico Teste';
      datasetRepo.activeDataset.value = TopoDataset(downloadedPicos: [
        {'id': '123', 'data': {'pico': pico, 'croqui': Croqui()}}
      ], availablePicos: []);
      final syncService = SyncService(datasetRepository: datasetRepo);

      await tester.pumpWidget(
        MaterialApp(
          home: TreeNavigationWrapper(
            datasetRepo: datasetRepo,
            syncService: syncService,
            key: TreeNavigationWrapper.navKey,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      final treeController = TreeNavigationWrapper.currentTreeController!;

      // Navigate deeper
      treeController.navigateTo(PicoNode(cragId: '123', parent: treeController.currentNode));
      await tester.pump(const Duration(seconds: 1));
      
      expect(treeController.currentNode, isA<PicoNode>());

      // Simulate a Navigator pop (e.g., from an AppBar back button)
      final BuildContext navContext = tester.element(find.descendant(
        of: find.byType(TreeNavigationWrapper),
        matching: find.byType(Navigator),
      ));
      
      Navigator.maybePop(navContext);
      await tester.pump(const Duration(seconds: 1));

      // The treeController should have gone back to HomeNode
      expect(treeController.currentNode, isA<HomeNode>());
    });

    testWidgets('TextNode generates a ModalBottomSheetPage in the Navigator declaratively', (WidgetTester tester) async {
      final datasetRepo = DatasetRepository(editorDeCroqui: EditorDeCroqui());
      final pico = Pico()..nome = 'Pico Teste';
      datasetRepo.activeDataset.value = TopoDataset(downloadedPicos: [
        {'id': '123', 'data': {'pico': pico, 'croqui': Croqui()}}
      ], availablePicos: []);
      final syncService = SyncService(datasetRepository: datasetRepo);

      await tester.pumpWidget(
        MaterialApp(
          home: TreeNavigationWrapper(
            datasetRepo: datasetRepo,
            syncService: syncService,
            key: TreeNavigationWrapper.navKey,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      final treeController = TreeNavigationWrapper.currentTreeController!;

      // Navigate deeper
      treeController.navigateTo(PicoNode(cragId: '123', parent: treeController.currentNode));
      await tester.pump(const Duration(seconds: 1));
      
      final navigatorFinder = find.descendant(
        of: find.byType(TreeNavigationWrapper),
        matching: find.byType(Navigator),
      );
      var navigator = tester.widget<Navigator>(navigatorFinder);
      expect(navigator.pages.length, 2);

      // Navigate to TextNode (Modal)
      treeController.navigateTo(TextNode(title: 'Modal', content: 'Markdown', cragId: '123', parent: treeController.currentNode));
      await tester.pump(const Duration(seconds: 1));

      navigator = tester.widget<Navigator>(navigatorFinder);
      
      // Should now have pushed a new page (TabsPage, PicoNode, ModalBottomSheetPage for TextNode)
      expect(navigator.pages.length, 3);
      expect(navigator.pages[2].key, const ValueKey('TextNode(Modal)'));
    });

    testWidgets('MapaoGlobalNode generates MapaoGlobalPage directly', (WidgetTester tester) async {
      final datasetRepo = DatasetRepository(editorDeCroqui: EditorDeCroqui());
      final syncService = SyncService(datasetRepository: datasetRepo);

      await tester.pumpWidget(
        MaterialApp(
          home: TreeNavigationWrapper(
            datasetRepo: datasetRepo,
            syncService: syncService,
            key: TreeNavigationWrapper.navKey,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      final treeController = TreeNavigationWrapper.currentTreeController!;
      
      treeController.navigateTo(MapaoGlobalNode(
        crags: [],
        parent: treeController.currentNode,
      ));
      await tester.pump(const Duration(seconds: 1));

      expect(treeController.currentNode, isA<MapaoGlobalNode>());
      expect(find.byType(MapaoGlobalPage), findsOneWidget);
    });

    testWidgets('MapaInterativoNode receives grupoContext when passing grupoContextNome', (WidgetTester tester) async {
      final datasetRepo = DatasetRepository(editorDeCroqui: EditorDeCroqui());
      final pico = Pico()..nome = 'Pico Teste';
      final grupo = Grupo()..nome = 'Grupo Teste';
      final mapa = Mapa()..caminhoImagemMapa = 'mapa_setor.png';
      final setor = Setor()..nome = 'Setor Teste'..mapas.add(mapa);
      grupo.setores.add(ArquivoSetor()..conteudo = setor);
      pico.setoresOuGrupos.add(SetorOuGrupo()..grupo = (ArquivoGrupo()..conteudo = grupo));
      
      datasetRepo.activeDataset.value = TopoDataset(downloadedPicos: [
        {'id': '123', 'data': {'pico': pico, 'croqui': Croqui()}}
      ], availablePicos: []);
      final syncService = SyncService(datasetRepository: datasetRepo);

      await tester.pumpWidget(
        MaterialApp(
          home: TreeNavigationWrapper(
            datasetRepo: datasetRepo,
            syncService: syncService,
            key: TreeNavigationWrapper.navKey,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      final treeController = TreeNavigationWrapper.currentTreeController!;
      
      treeController.navigateTo(MapaInterativoNode(
        cragId: '123',
        mapaCaminhoImagem: 'mapa_setor.png',
        setorContextNome: 'Setor Teste',
        grupoContextNome: 'Grupo Teste',
        parent: treeController.currentNode,
      ));
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(MapaInterativoPage), findsOneWidget);
      final page = tester.widget<MapaInterativoPage>(find.byType(MapaInterativoPage));
      expect(page.setorContext?.nome, 'Setor Teste');
      expect(page.grupoContext?.nome, 'Grupo Teste');
    });
  });
}
