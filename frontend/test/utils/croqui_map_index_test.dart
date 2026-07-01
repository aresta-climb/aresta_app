import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/utils/croqui_map_index.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/utils/dataset_resolver.dart';

void main() {
  group('ReferenceKey', () {
    test('should equal another instance with same properties', () {
      final key1 = ReferenceKey(grupoNome: 'G1', setorNome: 'S1', escaladaNome: 'E1');
      final key2 = ReferenceKey(grupoNome: 'G1', setorNome: 'S1', escaladaNome: 'E1');

      expect(key1, equals(key2));
      expect(key1.hashCode, equals(key2.hashCode));
    });

    test('should not equal instance with different properties', () {
      final key1 = ReferenceKey(grupoNome: 'G1', setorNome: 'S1', escaladaNome: 'E1');
      final key2 = ReferenceKey(grupoNome: 'G2', setorNome: 'S1', escaladaNome: 'E1');
      final key3 = ReferenceKey(grupoNome: 'G1', setorNome: 'S2', escaladaNome: 'E1');
      final key4 = ReferenceKey(grupoNome: 'G1', setorNome: 'S1', escaladaNome: 'E2');
      final key5 = ReferenceKey(setorNome: 'S1', escaladaNome: 'E1'); // null grupo

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
      final indexedMap = IndexedMap(
        mapa: null,
        referencedId: 'id-1',
      );
      expect(indexedMap.referencedId, equals('id-1'));
      expect(indexedMap.mapa, isNull);
      expect(indexedMap.setorContext, isNull);
      expect(indexedMap.grupoContext, isNull);
    });
  });

  group('CroquiMapIndex', () {
    test('should index maps from Pico, Grupo and Setor correctly', () {
      final pico = Pico(nome: 'Pico Teste');
      pico.mapasGerais = ArquivoMapas(conteudo: ColecaoDeMapas());
      
      final mapaPico = Mapa();
      mapaPico.referencias.add(Mapa_Referencia(escalada: 'E1', setor: 'S1', grupo: 'G1'));
      mapaPico.referencias.add(Mapa_Referencia(escalada: 'E2', setor: 'S2'));
      pico.mapasGerais.conteudo.mapas.add(mapaPico);

      final grupo = Grupo(nome: 'G1');
      final mapaGrupo = Mapa();
      mapaGrupo.referencias.add(Mapa_Referencia(escalada: 'E3', setor: 'S1', grupo: 'G1'));
      grupo.mapas.add(mapaGrupo);

      final setorNoGrupo = Setor(nome: 'S1');
      final mapaSetorNoGrupo = Mapa();
      mapaSetorNoGrupo.referencias.add(Mapa_Referencia(escalada: 'E1', setor: 'S1', grupo: 'G1'));
      setorNoGrupo.mapas.add(mapaSetorNoGrupo);
      setorNoGrupo.escaladas.add(Escalada(viaEsportiva: ViaEsportiva(nome: 'E1')));
      setorNoGrupo.escaladas.add(Escalada(viaEsportiva: ViaEsportiva(nome: 'E3')));
      grupo.setores.add(ArquivoSetor(conteudo: setorNoGrupo));
      
      pico.setoresOuGrupos.add(SetorOuGrupo(grupo: ArquivoGrupo(conteudo: grupo)));

      final setorFora = Setor(nome: 'S2');
      final mapaSetorFora = Mapa();
      mapaSetorFora.referencias.add(Mapa_Referencia(escalada: 'E4', setor: 'S2'));
      setorFora.mapas.add(mapaSetorFora);
      setorFora.escaladas.add(Escalada(viaEsportiva: ViaEsportiva(nome: 'E2')));
      setorFora.escaladas.add(Escalada(viaEsportiva: ViaEsportiva(nome: 'E4')));

      pico.setoresOuGrupos.add(SetorOuGrupo(setor: ArquivoSetor(conteudo: setorFora)));

      final index = CroquiMapIndex(pico);

      // E1 in S1
      final reqE1 = ResolvedDataset(
        grupo: grupo,
        setor: setorNoGrupo,
        escalada: Escalada(viaEsportiva: ViaEsportiva(nome: 'E1'))
      );
      final mapsE1 = index.getMapasForReference(reqE1);
      
      // We expect the global map (which resolves to E1 inside S1 since it's the first one it finds if default is empty? Wait, if E1 is found in S1, DatasetResolver will find it there). 
      // Actually, if we search E1, it just finds the first E1. It's in S1.
      expect(mapsE1.length, equals(2)); // Should be in global map and in S1 map.

      final reqE3 = ResolvedDataset(
        grupo: grupo,
        setor: setorNoGrupo,
        escalada: Escalada(viaEsportiva: ViaEsportiva(nome: 'E3'))
      );
      final mapsE3 = index.getMapasForReference(reqE3);
      expect(mapsE3.length, equals(1)); // G1 map
      expect(mapsE3.first.grupoContext?.nome, equals('G1'));
      expect(mapsE3.first.setorContext, isNull); 

      final reqE4 = ResolvedDataset(
        setor: setorFora,
        escalada: Escalada(viaEsportiva: ViaEsportiva(nome: 'E4'))
      );
      final mapsE4 = index.getMapasForReference(reqE4);
      expect(mapsE4.length, equals(1));
      expect(mapsE4.first.setorContext?.nome, equals('S2'));
      expect(mapsE4.first.grupoContext, isNull);
    });
  });
}
