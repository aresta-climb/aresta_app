import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/navigation/navigation_tree.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/main.dart';
import 'package:frontend/services/editor_croqui.dart';

void main() {
  group('Mapa Geral Pico Functions', () {
    testWidgets('FAB in MapaGeralPico returns to previous node using AppNav.back (preventing infinite loop)', (WidgetTester tester) async {
      // Setup mock environment
      final editor = EditorDeCroqui();
      final repo = DatasetRepository(editorDeCroqui: editor);
      final sync = SyncService(datasetRepository: repo);

      final Setor testSetor = Setor()
        ..nome = 'Setor de Teste'
        ..mapas.add(Mapa(caminhoImagemMapa: 'test.jpg'));

      final Pico testPico = Pico()..nome = 'Pico de Teste';
      final arquivoSetor = ArquivoSetor()..conteudo = testSetor;
      testPico.setoresOuGrupos.add(SetorOuGrupo()..setor = arquivoSetor);
      
      final Croqui testCroqui = Croqui();
      final testCragId = 'crag_test';
      
      repo.activeDataset.value = TopoDataset(
        downloadedPicos: [
          {
            'id': testCragId,
            'data': {'pico': testPico, 'croqui': testCroqui},
          }
        ],
        availablePicos: [],
      );
      // Criamos botões para a seção "Mapa Geral" para evitar exceptions no parser de markdown
      final markdownMap = ArquivoMarkdown()..conteudo = 'Este é o mapa geral';
      final botaoCapa = Botao()
        ..texto = 'Capa Mapa'
        ..destino = (DestinoBotao()..secaoTextual = markdownMap);
      testCroqui.botoes.add(botaoCapa);

      // Pump the app
      await tester.pumpWidget(
        MaterialApp(
          home: TreeNavigationWrapper(
            datasetRepo: repo,
            syncService: sync,
          ),
        ),
      );
      
      // Wait for initial render
      await tester.pump(const Duration(seconds: 1));

      // Get the tree controller via a descendant element
      final BuildContext childContext = tester.element(find.byType(Scaffold).first);
      final controller = TreeNavigationWrapper.of(childContext).treeController;

      // Ensure we are at Home
      expect(controller.currentNode, isA<HomeNode>());

      // Simulate navigation: Home -> MapaInterativo -> MapaGeralPico
      final mapaInterativoNode = MapaInterativoNode(
        cragId: testCragId,
        mapaCaminhoImagem: testSetor.mapas.first.caminhoImagemMapa,
        setorContextNome: testSetor.nome,
        parent: controller.currentNode,
      );
      controller.navigateTo(mapaInterativoNode);
      await tester.pump(const Duration(seconds: 1));

      final mapaGeralNode = MapaGeralPicoNode(
        cragId: testCragId,
        returnToSetorNome: testSetor.nome,
        parent: controller.currentNode,
      );
      controller.navigateTo(mapaGeralNode);
      await tester.pump(const Duration(seconds: 1));

      // Verify current state
      expect(controller.currentNode, isA<MapaGeralPicoNode>());
      expect(controller.currentNode.parent, isA<MapaInterativoNode>());

      // Find the FAB by its label
      final fabFinder = find.widgetWithText(FloatingActionButton, 'Voltar para o Mapa do Setor');
      expect(fabFinder, findsOneWidget);

      // Tap the FAB
      await tester.tap(fabFinder);
      await tester.pump(const Duration(seconds: 1));

      // Verify the stack popped back correctly rather than growing
      expect(controller.currentNode, isA<MapaInterativoNode>());
      
      // Crucially, its parent MUST NOT be MapaGeralPicoNode, but HomeNode.
      // If it pushed a new node, the parent would be MapaGeralPicoNode, creating the loop.
      expect(controller.currentNode.parent, isA<HomeNode>());
    });
  });
}
