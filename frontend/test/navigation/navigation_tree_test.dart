import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/navigation/navigation_tree.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';

void main() {
  group('NavNode path', () {
    test('copyWithMergedAncestor copies TextNode', () {
      final baseNode = HomeNode();
      final textNode = TextNode(title: 'T', content: 'C', cragId: '1', parent: baseNode);
      final newBase = HomeNode();
      final newTextNode = TextNode(title: 'T_old', content: 'C_old', cragId: '1', parent: newBase);

      final copied = textNode.copyWithMergedAncestor(newTextNode) as TextNode;
      expect(copied.title, 'T');
      expect(copied.content, 'C');
      expect(copied.parent, newBase);
    });

    test('copyWithMergedAncestor works for PicoContextNode', () {
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


    test('GPSNode toString()', () {
      const node = GPSNode(cragId: 'pico_santuario', parent: HomeNode());
      expect(node.toString(), 'GPSNode(pico_santuario)');
    });
  });
}
