// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/navigation/arvore/global_nodes.dart';
import 'package:frontend/navigation/arvore/pico_nodes.dart';

void main() {
  group('IndiceEscaladasNode', () {
    test('compara por cragId e tipo de nó', () {
      const parentNode = HomeNode();
      const node1 = IndiceEscaladasNode(cragId: 'bau', parent: parentNode);
      const node2 = IndiceEscaladasNode(cragId: 'bau', parent: null);
      const nodeOutro = IndiceEscaladasNode(cragId: 'itaipava', parent: parentNode);
      const outroTipo = SetoresNode(cragId: 'bau', parent: parentNode);

      expect(node1.isSameNode(node2), isTrue);
      expect(node1.isSameNode(nodeOutro), isFalse);
      expect(node1.isSameNode(outroTipo), isFalse);
    });

    test('retorna rótulo amigável e caminho curto corretos', () {
      const parentNode = HomeNode();
      const node = IndiceEscaladasNode(cragId: 'bau', parent: parentNode);

      expect(node.rotuloAmigavel, 'Índice de Escaladas');
      expect(node.obterCaminhoCurto(), 'Início -> Pico (bau) -> Índice de Escaladas');
      expect(node.toString(), 'IndiceEscaladasNode');
    });

    test('copyWithMergedAncestor preserva ancestral correto', () {
      const parent1 = HomeNode();
      const parent2 = HomeNode();
      const node = IndiceEscaladasNode(cragId: 'bau', parent: parent1);
      const matchingAncestor = IndiceEscaladasNode(cragId: 'bau', parent: parent2);

      final merged = node.copyWithMergedAncestor(matchingAncestor);
      expect(merged, isA<IndiceEscaladasNode>());
      expect((merged as IndiceEscaladasNode).cragId, 'bau');
      expect(merged.parent, parent2);
    });
  });
}
