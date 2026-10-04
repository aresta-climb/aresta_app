// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/navigation/arvore/nos_globais.dart';
import 'package:frontend/navigation/arvore/nos_pico.dart';

void main() {
  group('SetoresNode', () {
    test('compara por cragId e tipo de nó', () {
      const parentNode = HomeNode();
      const node1 = SetoresNode(cragId: 'bau', parent: parentNode);
      const node2 = SetoresNode(cragId: 'bau', parent: null);
      const nodeOutro = SetoresNode(cragId: 'itaipava', parent: parentNode);
      const outroTipo = IndiceEscaladasNode(cragId: 'bau', parent: parentNode);

      expect(node1.isSameNode(node2), isTrue);
      expect(node1.isSameNode(nodeOutro), isFalse);
      expect(node1.isSameNode(outroTipo), isFalse);
    });

    test('retorna rótulo amigável e caminho curto corretos', () {
      const parentNode = HomeNode();
      const node = SetoresNode(cragId: 'bau', parent: parentNode);

      expect(node.rotuloAmigavel, 'Setores & Escaladas');
      expect(node.obterCaminhoCurto(), 'Início -> Pico (bau) -> Setores & Escaladas');
      expect(node.toString(), 'SetoresNode');
    });

    test('suporta modalidadeInicial e preserva em copyWithMergedAncestor', () {
      const parent1 = HomeNode();
      const parent2 = HomeNode();
      const node = SetoresNode(
        cragId: 'bau',
        modalidadeInicial: 'Esportivas',
        parent: parent1,
      );
      const matchingAncestor = SetoresNode(cragId: 'bau', parent: parent2);

      final merged = node.copyWithMergedAncestor(matchingAncestor);
      expect(merged, isA<SetoresNode>());
      final nodeMerged = merged as SetoresNode;
      expect(nodeMerged.cragId, 'bau');
      expect(nodeMerged.modalidadeInicial, 'Esportivas');
      expect(nodeMerged.parent, parent2);
    });
  });
}
