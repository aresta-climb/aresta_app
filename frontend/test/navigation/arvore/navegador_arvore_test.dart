// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/navigation/arvore/modelo_arvore_navegacao.dart';
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
      'goBack pula PerfilNode intermediário quando o escalador não está autenticado e mantém quando autenticado',
      () {
        var autenticado = false;
        final controller = TreeNavigationController(
          estadoInicial: const ArvoreNavegacao(
            noAtual: SettingsNode(PerfilNode(HomeNode())),
          ),
          verificarUsuarioAutenticado: () => autenticado,
        );

        expect(controller.goBack(), isTrue);
        expect(controller.currentNode, isA<HomeNode>());

        autenticado = true;
        controller.navigateTo(PerfilNode(controller.currentNode));
        controller.navigateTo(SettingsNode(controller.currentNode));
        expect(controller.goBack(), isTrue);
        expect(controller.currentNode, isA<PerfilNode>());
      },
    );
  });
}
