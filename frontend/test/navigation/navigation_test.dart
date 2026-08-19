import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/navigation/navigation_tree.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';

void main() {
  group('Testes da Árvore de Navegação (Tree Navigation)', () {
    late TreeNavigationController controller;
    late Pico pico;
    late Setor setor;
    late Escalada escalada;
    late Croqui croqui;
    const String cragId = 'crag_test_123';

    setUp(() {
      controller = TreeNavigationController();
      pico = Pico()..nome = 'Pico do Corcovado';
      setor = Setor()..nome = 'Setor Principal';
      escalada = Escalada(viaEsportiva: ViaEsportiva(nome: 'Via Lactea'));
      croqui = Croqui();
    });

    test('Deve inicializar com HomeNode como nó inicial', () {
      expect(controller.currentNode, isA<HomeNode>());
      expect(controller.currentNode.parent, isNull);
    });

    test('Deve navegar e avançar na hierarquia normalmente', () {
      // Home -> Pico
      final picoNode = PicoNode(cragId: cragId, parent: controller.currentNode);
      controller.navigateTo(picoNode);
      expect(controller.currentNode, picoNode);
      expect(controller.currentNode.parent, isA<HomeNode>());

      // Pico -> Setor
      final setorNode = SetorNode(
        setorNome: setor.nome,
        cragId: cragId,
        parent: controller.currentNode,
      );
      controller.navigateTo(setorNode);
      expect(controller.currentNode, setorNode);
      expect(controller.currentNode.parent, picoNode);
    });

    test('Deve retroceder (goBack) corretamente na hierarquia linear', () {
      final home = controller.currentNode;

      final picoNode = PicoNode(cragId: cragId, parent: home);
      controller.navigateTo(picoNode);

      final setorNode = SetorNode(
        setorNome: setor.nome,
        cragId: cragId,
        parent: picoNode,
      );
      controller.navigateTo(setorNode);

      // Volta para Pico
      expect(controller.goBack(), isTrue);
      expect(controller.currentNode, picoNode);

      // Volta para Home
      expect(controller.goBack(), isTrue);
      expect(controller.currentNode, home);

      // Tenta voltar a partir da Home (raiz)
      expect(controller.goBack(), isFalse);
      expect(controller.currentNode, home);
    });

    test(
      'Deve evitar loops e atalhos redundantes (via -> mapa -> via -> mapa) através de rewind',
      () {
        final home = controller.currentNode;

        final picoNode = PicoNode(cragId: cragId, parent: home);
        controller.navigateTo(picoNode);

        final setorNode = SetorNode(
          setorNome: setor.nome,
          cragId: cragId,
          parent: picoNode,
        );
        controller.navigateTo(setorNode);

        final viaNode = ViaNode(
          escaladaNome: escalada.viaEsportiva.nome,
          setorNome: setor.nome,
          cragId: cragId,
          parent: setorNode,
        );
        controller.navigateTo(viaNode);

        // Estado atual: Home -> Pico -> Setor -> Via
        expect(controller.currentNode, viaNode);

        // Simula o usuário abrindo o Mapa/Setor novamente a partir da página da Via.
        // O parent do novo SetorNode seria o viaNode se continuássemos empilhando.
        final setorNodeRepetido = SetorNode(
          setorNome: setor.nome,
          cragId: cragId,
          parent: viaNode,
        );
        controller.navigateTo(setorNodeRepetido);

        // VERIFICAÇÃO 1: O nó atual deve ser o original (setorNode), pulando o ciclo redundante!
        // Como o SetorNode é recriado no rewind para atualizar propriedades como scrollToEscalada,
        // verificamos o tipo e a estrutura de pai em vez da identidade exata da instância.
        expect(controller.currentNode, isA<SetorNode>());
        expect(controller.currentNode.parent, picoNode);

        // Simula o usuário abrindo a mesma Via novamente a partir do Mapa/Setor.
        final viaNodeRepetido = ViaNode(
          escaladaNome: escalada.viaEsportiva.nome,
          setorNome: setor.nome,
          cragId: cragId,
          parent: setorNode,
        );
        controller.navigateTo(viaNodeRepetido);

        // VERIFICAÇÃO 2: O nó atual deve representar a mesma Via original.
        expect(controller.currentNode, isA<ViaNode>());
        final currentVia = controller.currentNode as ViaNode;
        expect(currentVia.escaladaNome, 'Via Lactea');
        expect(currentVia.cragId, cragId);

        // VERIFICAÇÃO 3: O botão de "Voltar" (goBack) deve percorrer linearmente
        // a árvore real limpa, ignorando todo o empilhamento redundante paralelo.

        // Voltar da Via -> Setor
        expect(controller.goBack(), isTrue);
        expect(controller.currentNode, isA<SetorNode>());

        // Voltar do Setor -> Pico
        expect(controller.goBack(), isTrue);
        expect(controller.currentNode, picoNode);

        // Voltar do Pico -> Home
        expect(controller.goBack(), isTrue);
        expect(controller.currentNode, home);

        // Home (raiz) não volta mais
        expect(controller.goBack(), isFalse);
      },
    );

    test(
      'NÃO deve persistir escaladaNome em SetorNode ao retornar (goBack padrão) de ViaNode',
      () {
        final home = controller.currentNode;

        final picoNode = PicoNode(cragId: cragId, parent: home);
        controller.navigateTo(picoNode);

        final setorNode = SetorNode(
          setorNome: setor.nome,
          cragId: cragId,
          parent: picoNode,
        );
        controller.navigateTo(setorNode);

        final viaNode = ViaNode(
          escaladaNome: escalada.viaEsportiva.nome,
          setorNome: setor.nome,
          cragId: cragId,
          parent: setorNode,
        );
        controller.navigateTo(viaNode);

        // Node atual é a Via
        expect(controller.currentNode, isA<ViaNode>());
        expect(
          (controller.currentNode as ViaNode).escaladaNome,
          escalada.viaEsportiva.nome,
        );

        // Simula o clique no botão voltar do Android (ou AppNav.back)
        expect(controller.goBack(), isTrue);

        // Deve ter retornado para o SetorNode
        expect(controller.currentNode, isA<SetorNode>());

        // O SetorNode NÃO deve receber o escaladaNome (highlight automático desabilitado)
        final updatedSetorNode = controller.currentNode as SetorNode;
        expect(
          updatedSetorNode.scrollToEscaladaNome,
          isNull,
        );
      },
    );

    test('goHome deve resetar a árvore inteira para o HomeNode', () {
      final home = controller.currentNode;

      final picoNode = PicoNode(cragId: cragId, parent: home);
      controller.navigateTo(picoNode);

      final setorNode = SetorNode(
        setorNome: setor.nome,
        cragId: cragId,
        parent: picoNode,
      );
      controller.navigateTo(setorNode);

      // Executa goHome
      controller.goHome();
      expect(controller.currentNode, home);
    });
    test(
      'Deve preservar propriedades de estado (scrollToMapaGeral e returnToSetor) no rewind do PicoNode',
      () {
        final picoNode = PicoNode(
          cragId: cragId,
          parent: controller.currentNode,
        );
        controller.navigateTo(picoNode);

        final picoNodeRepetido = PicoNode(
          cragId: cragId,
          scrollToMapaGeral: true,
          returnToSetorNome: setor.nome,
          parent: controller.currentNode,
        );
        controller.navigateTo(picoNodeRepetido);

        expect(controller.currentNode, isA<PicoNode>());
        final currentPico = controller.currentNode as PicoNode;
        expect(currentPico.scrollToMapaGeral, isTrue);
        expect(currentPico.returnToSetorNome, isNotNull);
        expect(currentPico.returnToSetorNome, 'Setor Principal');
      },
    );
  });
}
