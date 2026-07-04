import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/navigation/map_hierarchy_resolver.dart';

void main() {
  group('MapHierarchyResolver', () {
    late Pico picoVazio;
    late Pico picoComMapaGeral;
    late Setor setorComum;
    late Grupo grupoSemMapa;
    late Grupo grupoComMapa;

    setUp(() {
      picoVazio = Pico(nome: 'Pico Vazio');
      
      final mapaGeral = Mapa(caminhoImagemMapa: 'geral.jpg');
      final colecao = ColecaoDeMapas(mapas: [mapaGeral]);
      final arquivoMapas = ArquivoMapas(conteudo: colecao);
      picoComMapaGeral = Pico(nome: 'Pico Geral', mapasGerais: arquivoMapas);

      setorComum = Setor(nome: 'Setor A');
      
      grupoSemMapa = Grupo(nome: 'Grupo Vazio');
      
      final mapaGrupo = Mapa(caminhoImagemMapa: 'grupo.jpg');
      grupoComMapa = Grupo(nome: 'Grupo Cheio', mapas: [mapaGrupo]);
    });

    test('1.2: Retorna Mapa de Grupo caso setorContext pertença a um grupoContext que possua mapas', () {
      final dest = MapHierarchyResolver.resolveUpDestination(
        pico: picoVazio,
        setorContext: setorComum,
        grupoContext: grupoComMapa,
      );

      expect(dest, isNotNull);
      expect(dest!.label, 'Grupo Cheio');
      expect(dest.mapa.caminhoImagemMapa, 'grupo.jpg');
      expect(dest.grupoContext, grupoComMapa);
      expect(dest.setorContext, isNull);
    });

    test('1.3: Retorna Mapa Geral caso não haja Mapa de Grupo, mas o Pico tenha mapasGerais', () {
      // Cenário A: Setor pertence a grupo, mas grupo não tem mapa
      final destA = MapHierarchyResolver.resolveUpDestination(
        pico: picoComMapaGeral,
        setorContext: setorComum,
        grupoContext: grupoSemMapa,
      );

      expect(destA, isNotNull);
      expect(destA!.label, 'Mapa Geral');
      expect(destA.mapa.caminhoImagemMapa, 'geral.jpg');
      expect(destA.grupoContext, isNull);
      expect(destA.setorContext, isNull);

      // Cenário B: Visualizando Mapa de Grupo (sem setor)
      final destB = MapHierarchyResolver.resolveUpDestination(
        pico: picoComMapaGeral,
        grupoContext: grupoComMapa,
      );

      expect(destB, isNotNull);
      expect(destB!.label, 'Mapa Geral');
      expect(destB.mapa.caminhoImagemMapa, 'geral.jpg');
      expect(destB.grupoContext, isNull);
      expect(destB.setorContext, isNull);
      
      // Cenário C: Setor sem grupo (direto no pico)
      final destC = MapHierarchyResolver.resolveUpDestination(
        pico: picoComMapaGeral,
        setorContext: setorComum,
      );

      expect(destC, isNotNull);
      expect(destC!.label, 'Mapa Geral');
      expect(destC.mapa.caminhoImagemMapa, 'geral.jpg');
      expect(destC.grupoContext, isNull);
      expect(destC.setorContext, isNull);
    });

    test('1.4: Retorna null caso não existam mapas de nível superior', () {
      // Cenário A: No topo, no Mapa Geral, deve retornar null mesmo se houver mapa geral
      final destA1 = MapHierarchyResolver.resolveUpDestination(
        pico: picoComMapaGeral,
      );
      expect(destA1, isNull);

      final destA2 = MapHierarchyResolver.resolveUpDestination(
        pico: picoVazio,
      );
      expect(destA2, isNull);

      // Cenário B: Setor em pico vazio, sem grupo
      final destB = MapHierarchyResolver.resolveUpDestination(
        pico: picoVazio,
        setorContext: setorComum,
      );
      expect(destB, isNull);

      // Cenário C: Grupo sem mapa em pico sem mapa geral
      final destC = MapHierarchyResolver.resolveUpDestination(
        pico: picoVazio,
        grupoContext: grupoSemMapa,
      );
      expect(destC, isNull);
    });
  });
}
