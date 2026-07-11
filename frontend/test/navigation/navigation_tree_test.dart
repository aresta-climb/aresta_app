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
      final node2 = GrupoNode(cragId: '123', grupoNome: 'Grupo', parent: node1);
      final node3 = SetorNode(cragId: '123', setorNome: 'Setor', parent: node2);
      final node4 = ViaNode(cragId: '123', escaladaNome: 'Via', grupoNome: 'Grupo', parent: node3);

      final path = node4.path;

      expect(path.length, 5);
      expect(path[0], isA<HomeNode>());
      expect(path[1], isA<PicoNode>());
      expect(path[2], isA<GrupoNode>());
      expect(path[3], isA<SetorNode>());
      expect(path[4], isA<ViaNode>());
      expect((path[4] as ViaNode).grupoNome, 'Grupo');
    });

    test('path returns single node if it has no parent', () {
      final root = HomeNode();
      final path = root.path;

      expect(path.length, 1);
      expect(path[0], isA<HomeNode>());
    });

    test('copyWithMergedAncestor works for MapasCarrosselNode', () {
      final baseNode = HomeNode();
      final node = MapasCarrosselNode(
        cragId: '1',
        initialIndex: 0,
        mapas: const [CarrosselItemData(mapaCaminhoImagem: 'a')],
        parent: baseNode,
      );

      final newBase = HomeNode();
      final newNode = MapasCarrosselNode(
        cragId: '1',
        initialIndex: 1, // different
        mapas: const [CarrosselItemData(mapaCaminhoImagem: 'b')], // different
        parent: newBase,
      );

      final copied = node.copyWithMergedAncestor(newNode) as MapasCarrosselNode;
      // Should copy the data from the old node, but the parent from the new node
      expect(copied.cragId, '1');
      expect(copied.initialIndex, 0);
      expect(copied.mapas.first.mapaCaminhoImagem, 'a');
      expect(copied.parent, newBase);
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
    
    test('Navigating to MapaGlobal should set BrowseNode as parent', () {
      final controller = TreeNavigationController();
      
      // Navigate to Home
      expect(controller.currentNode, isA<HomeNode>());
      
      // Navigate to Browse
      final browseNode = BrowseNode(controller.currentNode);
      controller.navigateTo(browseNode);
      expect(controller.currentNode, isA<BrowseNode>());
      
      // Navigate to MapaGlobal
      final mapaGlobalNode = MapaGlobalNode(
        crags: [],
        parent: controller.currentNode,
      );
      controller.navigateTo(mapaGlobalNode);
      
      expect(controller.currentNode, isA<MapaGlobalNode>());
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

    test('MapaGlobalNode toString()', () {
      const node = MapaGlobalNode(
        crags: [{'id': 'pico1'}, {'id': 'pico2'}],
        parent: HomeNode(),
      );
      expect(node.toString(), 'MapaGlobalNode(2 picos)');
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

    test('MapasCarrosselNode toString()', () {
      final node = MapasCarrosselNode(
        cragId: 'pico_santuario',
        initialIndex: 0,
        mapas: const [
          CarrosselItemData(mapaCaminhoImagem: 'assets/map1.png'),
          CarrosselItemData(mapaCaminhoImagem: 'assets/map2.png'),
        ],
        parent: HomeNode(),
      );
      expect(node.toString(), 'MapasCarrosselNode(2 mapas, inicial: 0)');
    });

    test('GPSNode toString()', () {
      const node = GPSNode(cragId: 'pico_santuario', parent: HomeNode());
      expect(node.toString(), 'GPSNode(pico_santuario)');
    });
  });
}
