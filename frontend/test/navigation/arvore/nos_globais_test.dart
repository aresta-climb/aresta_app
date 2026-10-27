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

    test('SettingsNode possui caminho, rótulo e cópia de ancestral corretos', () {
      const home = HomeNode();
      final settings = SettingsNode(home);

      expect(settings.parent, same(home));
      expect(settings.rotuloAmigavel, 'Configurações');
      expect(settings.obterCaminhoCurto(), 'Início -> Configurações');
      expect(settings.toString(), 'SettingsNode');

      const outroPai = HomeNode();
      final copiado = settings.copyWithMergedAncestor(const SettingsNode(outroPai));
      expect(copiado, isA<SettingsNode>());
      expect(copiado.parent, same(outroPai));
    });

    test('ComunidadeNode possui metadados e comportamento de cópia de ancestral', () {
      const home = HomeNode();
      final comunidade = ComunidadeNode(home);

      expect(comunidade.parent, same(home));
      expect(comunidade.rotuloAmigavel, 'Comunidade');
      expect(comunidade.obterCaminhoCurto(), 'Início -> Comunidade');
      expect(comunidade.toString(), 'ComunidadeNode');

      const outroPai = HomeNode();
      final copiado = comunidade.copyWithMergedAncestor(const ComunidadeNode(outroPai));
      expect(copiado, isA<ComunidadeNode>());
      expect(copiado.parent, same(outroPai));
    });

    test('SobreTimeNode possui metadados e comportamento de cópia de ancestral', () {
      const home = HomeNode();
      final sobreTime = SobreTimeNode(home);

      expect(sobreTime.parent, same(home));
      expect(sobreTime.rotuloAmigavel, 'Sobre o Time');
      expect(sobreTime.obterCaminhoCurto(), 'Início -> Sobre o Time');
      expect(sobreTime.toString(), 'SobreTimeNode');

      const outroPai = HomeNode();
      final copiado = sobreTime.copyWithMergedAncestor(const SobreTimeNode(outroPai));
      expect(copiado, isA<SobreTimeNode>());
      expect(copiado.parent, same(outroPai));
    });

    test('MeusCroquisNode possui metadados e comportamento de cópia de ancestral', () {
      const home = HomeNode();
      final meusCroquis = MeusCroquisNode(home);

      expect(meusCroquis.parent, same(home));
      expect(meusCroquis.rotuloAmigavel, 'Meus Croquis');
      expect(meusCroquis.obterCaminhoCurto(), 'Início -> Meus Croquis');
      expect(meusCroquis.toString(), 'MeusCroquisNode');

      const outroPai = HomeNode();
      final copiado = meusCroquis.copyWithMergedAncestor(const MeusCroquisNode(outroPai));
      expect(copiado, isA<MeusCroquisNode>());
      expect(copiado.parent, same(outroPai));
    });

  });
}
