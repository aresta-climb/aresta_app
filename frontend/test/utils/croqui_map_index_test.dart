// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/utils/croqui_map_index.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/utils/dataset_resolver.dart';

void main() {
  group('ReferenceKey', () {
    test('should equal another instance with same properties', () {
      final key1 = ReferenceKey(
        grupoNome: 'G1',
        setorNome: 'S1',
        escaladaNome: 'E1',
      );
      final key2 = ReferenceKey(
        grupoNome: 'G1',
        setorNome: 'S1',
        escaladaNome: 'E1',
      );

      expect(key1, equals(key2));
      expect(key1.hashCode, equals(key2.hashCode));
    });

    test('should not equal instance with different properties', () {
      final key1 = ReferenceKey(
        grupoNome: 'G1',
        setorNome: 'S1',
        escaladaNome: 'E1',
      );
      final key2 = ReferenceKey(
        grupoNome: 'G2',
        setorNome: 'S1',
        escaladaNome: 'E1',
      );
      final key3 = ReferenceKey(
        grupoNome: 'G1',
        setorNome: 'S2',
        escaladaNome: 'E1',
      );
      final key4 = ReferenceKey(
        grupoNome: 'G1',
        setorNome: 'S1',
        escaladaNome: 'E2',
      );
      final key5 = ReferenceKey(
        setorNome: 'S1',
        escaladaNome: 'E1',
      ); // null grupo

      expect(key1, isNot(equals(key2)));
      expect(key1, isNot(equals(key3)));
      expect(key1, isNot(equals(key4)));
      expect(key1, isNot(equals(key5)));

      expect(key1.hashCode, isNot(equals(key2.hashCode)));
    });

    test('handles null fields correctly', () {
      final key1 = ReferenceKey(escaladaNome: 'E1');
      final key2 = ReferenceKey(escaladaNome: 'E1');
      final key3 = ReferenceKey(escaladaNome: 'E2');

      expect(key1, equals(key2));
      expect(key1.hashCode, equals(key2.hashCode));
      expect(key1, isNot(equals(key3)));
    });
  });

  group('IndexedMap', () {
    test('creates successfully', () {
      final indexedMap = IndexedMap(mapa: null, referencedId: 'id-1');
      expect(indexedMap.referencedId, equals('id-1'));
      expect(indexedMap.mapa, isNull);
      expect(indexedMap.setorContext, isNull);
      expect(indexedMap.grupoContext, isNull);
      expect(indexedMap.ehMapaProprio, isFalse);
    });

    test('permite configurar ehMapaProprio como true', () {
      final indexedMap = IndexedMap(
        mapa: Mapa(caminhoImagemMapa: 'escalada_foto.webp'),
        referencedId: '',
        ehMapaProprio: true,
      );
      expect(indexedMap.ehMapaProprio, isTrue);
      expect(indexedMap.mapa?.caminhoImagemMapa, equals('escalada_foto.webp'));
    });
  });

  group('CroquiMapIndex', () {
    test('should index maps from Pico, Grupo and Setor correctly', () {
      final pico = Pico(nome: 'Pico Teste');
      pico.mapasGerais = ArquivoMapas(conteudo: ColecaoDeMapas());

      final mapaPico = Mapa();
      mapaPico.referencias.add(
        Mapa_Referencia(escalada: 'E1', setor: 'S1', grupo: 'G1'),
      );
      mapaPico.referencias.add(Mapa_Referencia(escalada: 'E2', setor: 'S2'));
      pico.mapasGerais.conteudo.mapas.add(mapaPico);

      final grupo = Grupo(nome: 'G1');
      final mapaGrupo = Mapa();
      mapaGrupo.referencias.add(
        Mapa_Referencia(escalada: 'E3', setor: 'S1', grupo: 'G1'),
      );
      grupo.mapas.add(mapaGrupo);

      final setorNoGrupo = Setor(nome: 'S1');
      final mapaSetorNoGrupo = Mapa();
      mapaSetorNoGrupo.referencias.add(
        Mapa_Referencia(escalada: 'E1', setor: 'S1', grupo: 'G1'),
      );
      setorNoGrupo.mapas.add(mapaSetorNoGrupo);
      setorNoGrupo.escaladas.add(
        Escalada(viaEsportiva: ViaEsportiva(nome: 'E1')),
      );
      setorNoGrupo.escaladas.add(
        Escalada(viaEsportiva: ViaEsportiva(nome: 'E3')),
      );
      grupo.setores.add(ArquivoSetor(conteudo: setorNoGrupo));

      pico.setoresOuGrupos.add(
        SetorOuGrupo(grupo: ArquivoGrupo(conteudo: grupo)),
      );

      final setorFora = Setor(nome: 'S2');
      final mapaSetorFora = Mapa();
      mapaSetorFora.referencias.add(
        Mapa_Referencia(escalada: 'E4', setor: 'S2'),
      );
      setorFora.mapas.add(mapaSetorFora);
      setorFora.escaladas.add(Escalada(viaEsportiva: ViaEsportiva(nome: 'E2')));
      setorFora.escaladas.add(Escalada(viaEsportiva: ViaEsportiva(nome: 'E4')));

      pico.setoresOuGrupos.add(
        SetorOuGrupo(setor: ArquivoSetor(conteudo: setorFora)),
      );

      final index = CroquiMapIndex(pico);

      // E1 in S1
      final reqE1 = ResolvedDataset(
        grupo: grupo,
        setor: setorNoGrupo,
        escalada: Escalada(viaEsportiva: ViaEsportiva(nome: 'E1')),
      );
      final mapsE1 = index.getMapasForReference(reqE1);

      expect(mapsE1.length, equals(2));

      final reqE3 = ResolvedDataset(
        grupo: grupo,
        setor: setorNoGrupo,
        escalada: Escalada(viaEsportiva: ViaEsportiva(nome: 'E3')),
      );
      final mapsE3 = index.getMapasForReference(reqE3);
      expect(mapsE3.length, equals(1));
      expect(mapsE3.first.grupoContext?.nome, equals('G1'));
      expect(mapsE3.first.setorContext, isNull);

      final reqE4 = ResolvedDataset(
        setor: setorFora,
        escalada: Escalada(viaEsportiva: ViaEsportiva(nome: 'E4')),
      );
      final mapsE4 = index.getMapasForReference(reqE4);
      expect(mapsE4.length, equals(1));
      expect(mapsE4.first.setorContext?.nome, equals('S2'));
      expect(mapsE4.first.grupoContext, isNull);
    });

    test('deve catalogar mapas próprios de escalada em setor direto e dentro de grupo', () {
      final pico = Pico(nome: 'Pico Boulder');

      // 1. Escalada em setor direto com mapa próprio
      final mapaBoulderProprio = Mapa(caminhoImagemMapa: 'boulder_saida.webp');
      final escaladaBoulder = Escalada(
        boulder: Boulder(nome: 'Sit Start do Fogo'),
      )..mapas.add(mapaBoulderProprio);

      final setorDireto = Setor(nome: 'Bloco Principal')
        ..escaladas.add(escaladaBoulder);

      pico.setoresOuGrupos.add(
        SetorOuGrupo(setor: ArquivoSetor(conteudo: setorDireto)),
      );

      // 2. Escalada em setor dentro de grupo com múltiplos mapas próprios
      final mapaVia1 = Mapa(caminhoImagemMapa: 'via_detalhe1.webp');
      final mapaVia2 = Mapa(caminhoImagemMapa: 'via_detalhe2.webp');
      final escaladaVia = Escalada(
        viaEsportiva: ViaEsportiva(nome: 'Sombra e Água Fresca'),
      )
        ..mapas.add(mapaVia1)
        ..mapas.add(mapaVia2);

      final setorNoGrupo = Setor(nome: 'Falésia Leste')
        ..escaladas.add(escaladaVia);

      final grupo = Grupo(nome: 'Complexo Central')
        ..setores.add(ArquivoSetor(conteudo: setorNoGrupo));

      pico.setoresOuGrupos.add(
        SetorOuGrupo(grupo: ArquivoGrupo(conteudo: grupo)),
      );

      final index = CroquiMapIndex(pico);

      // Verificação do Boulder
      final resolvedBoulder = ResolvedDataset(
        setor: setorDireto,
        escalada: escaladaBoulder,
      );
      expect(index.temMapasProprios(resolvedBoulder), isTrue);
      final mapasPropriosBoulder = index.getMapasProprios(resolvedBoulder);
      expect(mapasPropriosBoulder.length, equals(1));
      expect(mapasPropriosBoulder.first.ehMapaProprio, isTrue);
      expect(mapasPropriosBoulder.first.mapa?.caminhoImagemMapa, equals('boulder_saida.webp'));
      expect(mapasPropriosBoulder.first.setorContext?.nome, equals('Bloco Principal'));
      expect(mapasPropriosBoulder.first.grupoContext, isNull);
      expect(index.getMapasForReference(resolvedBoulder), isEmpty);

      // Verificação da Via Esportiva
      final resolvedVia = ResolvedDataset(
        grupo: grupo,
        setor: setorNoGrupo,
        escalada: escaladaVia,
      );
      expect(index.temMapasProprios(resolvedVia), isTrue);
      final mapasPropriosVia = index.getMapasProprios(resolvedVia);
      expect(mapasPropriosVia.length, equals(2));
      expect(mapasPropriosVia[0].ehMapaProprio, isTrue);
      expect(mapasPropriosVia[0].mapa?.caminhoImagemMapa, equals('via_detalhe1.webp'));
      expect(mapasPropriosVia[1].ehMapaProprio, isTrue);
      expect(mapasPropriosVia[1].mapa?.caminhoImagemMapa, equals('via_detalhe2.webp'));
      expect(mapasPropriosVia[0].grupoContext?.nome, equals('Complexo Central'));
      expect(mapasPropriosVia[0].setorContext?.nome, equals('Falésia Leste'));
    });

    test('deve resolver carrossel unificado sequenciando mapas locais primeiro e referências depois', () {
      final pico = Pico(nome: 'Pico Misto');

      final mapaSetor = Mapa(caminhoImagemMapa: 'panoramica_setor.webp')
        ..referencias.add(Mapa_Referencia(escalada: 'Fenda da Ilusão', ids: ['linha_fenda']));

      final mapaLocal1 = Mapa(caminhoImagemMapa: 'fenda_crux.webp');
      final mapaLocal2 = Mapa(caminhoImagemMapa: 'fenda_saida.webp');

      final escalada = Escalada(
        viaMovel: ViaMovel(nome: 'Fenda da Ilusão'),
      )
        ..mapas.add(mapaLocal1)
        ..mapas.add(mapaLocal2);

      final setor = Setor(nome: 'Paredão')
        ..mapas.add(mapaSetor)
        ..escaladas.add(escalada);

      pico.setoresOuGrupos.add(
        SetorOuGrupo(setor: ArquivoSetor(conteudo: setor)),
      );

      final index = CroquiMapIndex(pico);
      final resolved = ResolvedDataset(setor: setor, escalada: escalada);

      // Diferenciação em O(1)
      expect(index.getMapasProprios(resolved).length, equals(2));
      expect(index.getMapasForReference(resolved).length, equals(1));

      // Todos os mapas unificados (IndexedMap)
      final todosMapas = index.getTodosMapas(resolved);
      expect(todosMapas.length, equals(3));
      expect(todosMapas[0].ehMapaProprio, isTrue);
      expect(todosMapas[0].mapa?.caminhoImagemMapa, equals('fenda_crux.webp'));
      expect(todosMapas[1].ehMapaProprio, isTrue);
      expect(todosMapas[1].mapa?.caminhoImagemMapa, equals('fenda_saida.webp'));
      expect(todosMapas[2].ehMapaProprio, isFalse);
      expect(todosMapas[2].mapa?.caminhoImagemMapa, equals('panoramica_setor.webp'));
      expect(todosMapas[2].referencedId, equals('linha_fenda'));

      // Resolução para CarrosselItemData
      final carrosselItens = index.resolverCarrosselUnificado(resolved);
      expect(carrosselItens.length, equals(3));
      expect(carrosselItens[0].mapaCaminhoImagem, equals('fenda_crux.webp'));
      expect(carrosselItens[0].escaladaContextNome, equals('Fenda da Ilusão'));
      expect(carrosselItens[0].initialSelectedId, isNull);

      expect(carrosselItens[1].mapaCaminhoImagem, equals('fenda_saida.webp'));
      expect(carrosselItens[1].escaladaContextNome, equals('Fenda da Ilusão'));
      expect(carrosselItens[1].initialSelectedId, isNull);

      expect(carrosselItens[2].mapaCaminhoImagem, equals('panoramica_setor.webp'));
      expect(carrosselItens[2].escaladaContextNome, equals('Fenda da Ilusão'));
      expect(carrosselItens[2].initialSelectedId, equals('linha_fenda'));
    });

    test('resolverCarrosselUnificado e getTodosMapas retornam vazio quando escalada é nula', () {
      final pico = Pico(nome: 'Pico Vazio');
      final index = CroquiMapIndex(pico);
      final resolvedSemEscalada = ResolvedDataset();

      expect(index.getMapasProprios(resolvedSemEscalada), isEmpty);
      expect(index.getTodosMapas(resolvedSemEscalada), isEmpty);
      expect(index.resolverCarrosselUnificado(resolvedSemEscalada), isEmpty);
      expect(index.temMapasProprios(resolvedSemEscalada), isFalse);
    });
  });
}
