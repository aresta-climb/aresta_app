// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/navigation/arvore.dart';

void main() {
  group('Fachada da Árvore de Navegação (arvore.dart)', () {
    test('exporta e inicializa nós e componentes fundamentais da navegação', () {
      const home = HomeNode();
      final perfil = PerfilNode(home);
      final caderneta = CadernetaNode(perfil);
      final arvore = ArvoreNavegacao(noAtual: caderneta);
      final controlador = TreeNavigationController(estadoInicial: arvore);

      expect(controlador.currentNode, isA<CadernetaNode>());
      expect(controlador.currentNode.parent, isA<PerfilNode>());
      expect(controlador.goBack(), isTrue);
      expect(controlador.currentNode, isA<PerfilNode>());
      expect(controlador.goBack(), isTrue);
      expect(controlador.currentNode, isA<HomeNode>());
      expect(controlador.goBack(), isFalse);
    });
  });
}
