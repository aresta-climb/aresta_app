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

    test('MapaGlobalNode gerencia picoIds, crags legados e mesclagem de ancestrais', () {
      const home = HomeNode();
      const mapaVazio = MapaGlobalNode(parent: home);

      expect(mapaVazio.picoIds, isEmpty);
      expect(mapaVazio.crags, isEmpty);
      expect(mapaVazio.rotuloAmigavel, 'Mapa Global');
      expect(mapaVazio.obterCaminhoCurto(), 'Início -> Mapa Global');
      expect(mapaVazio.toString(), 'MapaGlobalNode(0 picos)');

      const mapaComPicos = MapaGlobalNode(
        picoIds: ['bau', 'cipo'],
        parent: home,
      );
      expect(mapaComPicos.toString(), 'MapaGlobalNode(2 picos)');

      // Mescla com ancestral que contém IDs
      final mesclado = mapaVazio.copyWithMergedAncestor(mapaComPicos);
      expect(mesclado, isA<MapaGlobalNode>());
      final mapaMesclado = mesclado as MapaGlobalNode;
      expect(mapaMesclado.picoIds, equals(['bau', 'cipo']));

      // Mescla com lista de crags legada
      const mapaComCrags = MapaGlobalNode(
        crags: ['crag1', 'crag2', 'crag3'],
        parent: home,
      );
      final mescladoCrags = mapaVazio.copyWithMergedAncestor(mapaComCrags);
      expect((mescladoCrags as MapaGlobalNode).crags.length, 3);
      expect(mescladoCrags.toString(), 'MapaGlobalNode(3 picos)');
    });

  });
}
