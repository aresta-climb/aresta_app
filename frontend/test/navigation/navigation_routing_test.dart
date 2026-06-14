import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
    
    // As it was navigated WITH a setorContextNome, `setores` MUST be empty
    // to prevent cross-sector id collisions.
    expect(page.setores, isEmpty);
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
    // `setores` MUST contain all sectors of the Pico.
    expect(page.setores.length, 2);
    expect(page.setores[0].conteudo.nome, 'Setor 1');
    expect(page.setores[1].conteudo.nome, 'Setor 2');
    expect(page.setorContext, isNull);
  });
}
