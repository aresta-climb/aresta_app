import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/navigation/navigation_tree.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';

void main() {
  group('TreeNavigationController - Infinite Loop Prevention', () {
    test('Navigating between MapaGeral and MapaInterativo should not create an infinite loop', () {
      final controller = TreeNavigationController();
      
      final pico = Pico()..nome = 'Pico Teste';
      final mapa = Mapa();
      
      // Navigate to Home
      expect(controller.currentNode, isA<HomeNode>());
      
      // Navigate to Pico
      final croqui = Croqui();
      final picoNode = PicoNode(cragId: '123', pico: pico, croqui: croqui, parent: controller.currentNode);
      controller.navigateTo(picoNode);
      expect(controller.currentNode, isA<PicoNode>());
      
      // Navigate to MapaGeral
      final mapaGeralNode = MapaGeralPicoNode(cragId: '123', pico: pico, croqui: croqui, parent: controller.currentNode);
      controller.navigateTo(mapaGeralNode);
      expect(controller.currentNode, isA<MapaGeralPicoNode>());
      
      // Navigate to MapaInterativo
      final mapaInterativoNode = MapaInterativoNode(cragId: '123', mapa: mapa, escaladas: [], setores: [], parent: controller.currentNode);
      controller.navigateTo(mapaInterativoNode);
      expect(controller.currentNode, isA<MapaInterativoNode>());
      
      // Simulate clicking back to MapaGeral.
      // Instead of the tree growing (Home -> Pico -> MapaGeral -> MapaInterativo -> MapaGeral),
      // the controller should recognize MapaGeral is an ancestor and truncate the tree.
      final newMapaGeralNode = MapaGeralPicoNode(cragId: '123', pico: pico, croqui: croqui, parent: controller.currentNode);
      controller.navigateTo(newMapaGeralNode);
      
      // The current node should be MapaGeralPicoNode
      expect(controller.currentNode, isA<MapaGeralPicoNode>());
      
      // The parent of the current node should be PicoNode (truncating MapaInterativo from the stack)
      expect(controller.currentNode.parent, isA<PicoNode>());
      
      // If it hadn't truncated, the parent would have been MapaInterativoNode.
      // This confirms the infinite loop is prevented.
    });

    test('Navigating to MapaoGlobal should set BrowseNode as parent', () {
      final controller = TreeNavigationController();
      
      // Navigate to Home
      expect(controller.currentNode, isA<HomeNode>());
      
      // Navigate to Browse
      final browseNode = BrowseNode(controller.currentNode);
      controller.navigateTo(browseNode);
      expect(controller.currentNode, isA<BrowseNode>());
      
      // Navigate to MapaoGlobal
      final mapaoGlobalNode = MapaoGlobalNode(
        crags: [],
        downloadingCrags: {},
        onDownload: (_) {},
        parent: controller.currentNode,
      );
      controller.navigateTo(mapaoGlobalNode);
      
      expect(controller.currentNode, isA<MapaoGlobalNode>());
      expect(controller.currentNode.parent, isA<BrowseNode>());
      expect(controller.currentNode.parent?.parent, isA<HomeNode>());
    });
  });
}
