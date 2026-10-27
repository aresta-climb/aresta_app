// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/navigation/arvore/nos_globais.dart';

void main() {
  group('Nós Globais de Navegação (nos_globais.dart)', () {
    test('HomeNode possui propriedades canônicas e raiz sem pai', () {
      const home = HomeNode();

      expect(home.parent, isNull);
      expect(home.rotuloAmigavel, 'Início');
      expect(home.obterCaminhoCurto(), 'Início');
      expect(home.toString(), 'HomeNode');

      final copiado = home.copyWithMergedAncestor(const HomeNode());
      expect(copiado, isA<HomeNode>());
      expect(copiado.parent, isNull);
    });

    test('BrowseNode preserva hierarquia e metadados', () {
      const home = HomeNode();
      final browse = BrowseNode(home);

      expect(browse.parent, same(home));
      expect(browse.rotuloAmigavel, 'Buscar');
      expect(browse.obterCaminhoCurto(), 'Início -> Buscar');
      expect(browse.toString(), 'BrowseNode');

      const outroPai = HomeNode();
      final copiado = browse.copyWithMergedAncestor(const BrowseNode(outroPai));
      expect(copiado, isA<BrowseNode>());
      expect(copiado.parent, same(outroPai));
    });

  });
}
