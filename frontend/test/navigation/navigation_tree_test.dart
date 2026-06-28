import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/navigation/navigation_tree.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';

void main() {
  group('NavNode path', () {
    test('path returns list of nodes from root to current', () {
      final root = HomeNode();
      final node1 = PicoNode(cragId: '123', parent: root);
      final node2 = SetorNode(cragId: '123', setorNome: 'Setor', parent: node1);
      final node3 = ViaNode(cragId: '123', escaladaNome: 'Via', parent: node2);

      final path = node3.path;

      expect(path.length, 4);
      expect(path[0], isA<HomeNode>());
      expect(path[1], isA<PicoNode>());
      expect(path[2], isA<SetorNode>());
      expect(path[3], isA<ViaNode>());
    });

    test('path returns single node if it has no parent', () {
      final root = HomeNode();
      final path = root.path;

      expect(path.length, 1);
      expect(path[0], isA<HomeNode>());
    });
  });

  group('TreeNavigationController - Infinite Loop Prevention', () {
    test('Navigating between MapaGeral and MapaInterativo should not create an infinite loop', () {
      final controller = TreeNavigationController();
      
      final pico = Pico()..nome = 'Pico Teste';
      final mapa = Mapa();
      
      // Navigate to Home
      expect(controller.currentNode, isA<HomeNode>());
      
      // Navigate to Pico
      final picoNode = PicoNode(cragId: '123', parent: controller.currentNode);
      controller.navigateTo(picoNode);
      expect(controller.currentNode, isA<PicoNode>());
      
      // Navigate to MapaGeral
      final mapaGeralNode = MapaGeralPicoNode(cragId: '123', parent: controller.currentNode);
      controller.navigateTo(mapaGeralNode);
      expect(controller.currentNode, isA<MapaGeralPicoNode>());
      
      // Navigate to MapaInterativo
      final mapaInterativoNode = MapaInterativoNode(cragId: '123', mapaCaminhoImagem: 'test.png', parent: controller.currentNode);
      controller.navigateTo(mapaInterativoNode);
      expect(controller.currentNode, isA<MapaInterativoNode>());
      
      // Simulate clicking back to MapaGeral.
      // Instead of the tree growing (Home -> Pico -> MapaGeral -> MapaInterativo -> MapaGeral),
      // the controller should recognize MapaGeral is an ancestor and truncate the tree.
      final newMapaGeralNode = MapaGeralPicoNode(cragId: '123', parent: controller.currentNode);
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
        parent: controller.currentNode,
      );
      controller.navigateTo(mapaoGlobalNode);
      
      expect(controller.currentNode, isA<MapaoGlobalNode>());
      expect(controller.currentNode.parent, isA<BrowseNode>());
      expect(controller.currentNode.parent?.parent, isA<HomeNode>());
    });
  });

  group('NavNode toString() overrides', () {
    test('HomeNode toString()', () {
      const node = HomeNode();
      expect(node.toString(), 'HomeNode');
    });

    test('BrowseNode toString()', () {
      const node = BrowseNode(HomeNode());
      expect(node.toString(), 'BrowseNode');
    });

    test('MapaoGlobalNode toString()', () {
      const node = MapaoGlobalNode(
        crags: [{'id': 'pico1'}, {'id': 'pico2'}],
        parent: HomeNode(),
      );
      expect(node.toString(), 'MapaoGlobalNode(2 picos)');
    });

    test('SettingsNode toString()', () {
      const node = SettingsNode(HomeNode());
      expect(node.toString(), 'SettingsNode');
    });

    test('PicoNode toString()', () {
      const node = PicoNode(cragId: 'pico_santuario', parent: HomeNode());
      expect(node.toString(), 'PicoNode(pico_santuario)');
    });

    test('SetorNode toString()', () {
      const node = SetorNode(
        cragId: 'pico_santuario',
        setorNome: 'Clube da Luta',
        parent: HomeNode(),
      );
      expect(node.toString(), 'SetorNode(Clube da Luta)');
    });

    test('GrupoNode toString()', () {
      const node = GrupoNode(
        cragId: 'pico_santuario',
        grupoNome: 'Pedra Principal',
        parent: HomeNode(),
      );
      expect(node.toString(), 'GrupoNode(Pedra Principal)');
    });

    test('ViaNode toString()', () {
      const node = ViaNode(
        cragId: 'pico_santuario',
        escaladaNome: 'Via Láctea',
        parent: HomeNode(),
      );
      expect(node.toString(), 'ViaNode(Via Láctea)');
    });

    test('MapaInterativoNode toString()', () {
      const nodeComSetor = MapaInterativoNode(
        cragId: 'pico_santuario',
        mapaCaminhoImagem: 'assets/map.png',
        setorContextNome: 'Clube da Luta',
        parent: HomeNode(),
      );
      expect(nodeComSetor.toString(), 'MapaInterativoNode(map.png)');

      const nodeSemSetor = MapaInterativoNode(
        cragId: 'pico_santuario',
        mapaCaminhoImagem: 'assets/map.png',
        parent: HomeNode(),
      );
      expect(nodeSemSetor.toString(), 'MapaInterativoNode(map.png)');
    });

    test('MapaGeralPicoNode toString()', () {
      const node = MapaGeralPicoNode(cragId: 'pico_santuario', parent: HomeNode());
      expect(node.toString(), 'MapaGeralPicoNode(pico_santuario)');
    });

    test('GPSNode toString()', () {
      const node = GPSNode(cragId: 'pico_santuario', parent: HomeNode());
      expect(node.toString(), 'GPSNode(pico_santuario)');
    });
  });
}
