// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/navigation/arvore/navegador_arvore.dart';
import 'package:frontend/navigation/arvore/nos_globais.dart';
import 'package:frontend/navigation/arvore/nos_pico.dart';

void main() {
  group('TreeNavigationController', () {
    test('notifica ouvintes ao navegar e atualizar estado', () {
      final controller = TreeNavigationController();
      int notificacoes = 0;
      controller.addListener(() {
        notificacoes++;
      });

      expect(controller.currentNode, isA<HomeNode>());

      controller.navigateTo(BrowseNode(controller.currentNode));
      expect(controller.currentNode, isA<BrowseNode>());
      expect(notificacoes, 1);

      controller.goBack();
      expect(controller.currentNode, isA<HomeNode>());
      expect(notificacoes, 2);
    });

    test('goBack respeita onBackInterceptor quando interceptado', () {
      final controller = TreeNavigationController();
      controller.navigateTo(BrowseNode(controller.currentNode));

      bool interceptorChamado = false;
      controller.onBackInterceptor = () {
        interceptorChamado = true;
        return true; // Interceptou e consumiu
      };

      final tratou = controller.goBack();
      expect(tratou, isTrue);
      expect(interceptorChamado, isTrue);
      expect(controller.currentNode, isA<BrowseNode>()); // Não desceu na árvore
    });

    test('goHome retorna para a raiz da árvore e emite notificação', () {
      final controller = TreeNavigationController();
      controller.navigateTo(BrowseNode(controller.currentNode));
      controller.navigateTo(PicoNode(cragId: '123', parent: controller.currentNode));

      expect(controller.currentNode, isA<PicoNode>());

      int notificacoes = 0;
      controller.addListener(() {
        notificacoes++;
      });

      controller.goHome();
      expect(controller.currentNode, isA<HomeNode>());
      expect(controller.noAtual, isA<HomeNode>());
      expect(notificacoes, 1);

      controller.navigateTo(BrowseNode(controller.noAtual));
      expect(controller.voltar(), isTrue);
      expect(controller.noAtual, isA<HomeNode>());

      controller.navigateTo(BrowseNode(controller.noAtual));
      controller.irParaHome();
      expect(controller.noAtual, isA<HomeNode>());
    });

    test(
      'podarNosPerfilECaderneta poda ancestrais de perfil e notifica apenas quando a árvore muda',
      () {
        final controller = TreeNavigationController();
        var notificacoes = 0;
        controller.addListener(() => notificacoes++);

        // Sem nós de perfil: não deve notificar
        controller.podarNosPerfilECaderneta();
        expect(notificacoes, equals(0));

        // Home -> Perfil -> Settings: ao podar, Settings passa a ter Home como pai
        controller.navigateTo(PerfilNode(controller.currentNode));
        controller.navigateTo(SettingsNode(controller.currentNode));
        notificacoes = 0;

        controller.podarNosPerfilECaderneta();
        expect(notificacoes, equals(1));
        expect(controller.currentNode, isA<SettingsNode>());
        expect(controller.currentNode.parent, isA<HomeNode>());
      },
    );
  });
}
