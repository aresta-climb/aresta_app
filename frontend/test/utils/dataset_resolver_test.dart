import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/utils/dataset_resolver.dart';

void main() {
  group('MapaReferenciaExtension Tests', () {
    test('nome returns escalada if not empty', () {
      final ref = Mapa_Referencia(
        escalada: 'Via 1',
        setor: 'Setor 1',
        grupo: 'Grupo 1',
      );
      expect(ref.nome, 'Via 1');
    });
    test('nome returns setor if escalada is empty', () {
      final ref = Mapa_Referencia(setor: 'Setor 1', grupo: 'Grupo 1');
      expect(ref.nome, 'Setor 1');
    });
    test('nome returns grupo if escalada and setor are empty', () {
      final ref = Mapa_Referencia(grupo: 'Grupo 1');
      expect(ref.nome, 'Grupo 1');
    });
    test('nome returns empty string if all are empty', () {
      final ref = Mapa_Referencia();
      expect(ref.nome, '');
    });
  });

  group('DatasetResolver', () {
    late Pico pico;

    setUp(() {
      pico = Pico(nome: 'Pedra Grande');

      final setor1 = Setor(nome: 'Setor A');
      setor1.escaladas.add(Escalada(viaEsportiva: ViaEsportiva(nome: 'Via 1')));
      setor1.escaladas.add(Escalada(viaMovel: ViaMovel(nome: 'Via 2')));
      setor1.escaladas.add(Escalada(boulder: Boulder(nome: 'Boulder 1')));

      final setor2 = Setor(nome: 'Setor B');
      setor2.escaladas.add(
        Escalada(viaMultiplasEnfiadas: ViaMultiplasEnfiadas(nome: 'Via 3')),
      );
      setor2.escaladas.add(Escalada(highline: Highline(nome: 'Highline 1')));

      pico.setoresOuGrupos.add(
        SetorOuGrupo(setor: ArquivoSetor(conteudo: setor1)),
      );
      pico.setoresOuGrupos.add(
        SetorOuGrupo(setor: ArquivoSetor(conteudo: setor2)),
      );

      final grupo1 = Grupo(nome: 'Grupo 1');
      final setorGrupo = Setor(nome: 'Setor Grupo');
      setorGrupo.escaladas.add(
        Escalada(viaEsportiva: ViaEsportiva(nome: 'Via 4')),
      );
      grupo1.setores.add(ArquivoSetor(conteudo: setorGrupo));

      pico.setoresOuGrupos.add(
        SetorOuGrupo(grupo: ArquivoGrupo(conteudo: grupo1)),
      );
    });

    test('resolves simple setor', () {
      final res = DatasetResolver.resolve(pico: pico, setorNome: 'Setor A');
      expect(res.setor?.nome, 'Setor A');
      expect(res.grupo, isNull);
      expect(res.escalada, isNull);
    });

    test('resolves setor with escalada', () {
      final res = DatasetResolver.resolve(
        pico: pico,
        setorNome: 'Setor A',
        escaladaNome: 'Via 1',
      );
      expect(res.setor?.nome, 'Setor A');
      expect(res.escalada?.viaEsportiva.nome, 'Via 1');
    });

    test('resolves different types of escalada', () {
      var res = DatasetResolver.resolve(
        pico: pico,
        setorNome: 'Setor A',
        escaladaNome: 'Via 2',
      );
      expect(res.escalada?.viaMovel.nome, 'Via 2');

      res = DatasetResolver.resolve(
        pico: pico,
        setorNome: 'Setor A',
        escaladaNome: 'Boulder 1',
      );
      expect(res.escalada?.boulder.nome, 'Boulder 1');

      res = DatasetResolver.resolve(
        pico: pico,
        setorNome: 'Setor B',
        escaladaNome: 'Via 3',
      );
      expect(res.escalada?.viaMultiplasEnfiadas.nome, 'Via 3');

      res = DatasetResolver.resolve(
        pico: pico,
        setorNome: 'Setor B',
        escaladaNome: 'Highline 1',
      );
      expect(res.escalada?.highline.nome, 'Highline 1');
    });

    test('throws when setor not found', () {
      expect(
        () =>
            DatasetResolver.resolve(pico: pico, setorNome: 'Setor Inexistente'),
        throwsException,
      );
    });

    test('throws when escalada not found in setor', () {
      expect(
        () => DatasetResolver.resolve(
          pico: pico,
          setorNome: 'Setor A',
          escaladaNome: 'Via Inexistente',
        ),
        throwsException,
      );
    });

    test('resolves grupo and its setor', () {
      final res = DatasetResolver.resolve(
        pico: pico,
        grupoNome: 'Grupo 1',
        setorNome: 'Setor Grupo',
      );
      expect(res.grupo?.nome, 'Grupo 1');
      expect(res.setor?.nome, 'Setor Grupo');
    });

    test('resolves grupo, setor and escalada', () {
      final res = DatasetResolver.resolve(
        pico: pico,
        grupoNome: 'Grupo 1',
        setorNome: 'Setor Grupo',
        escaladaNome: 'Via 4',
      );
      expect(res.grupo?.nome, 'Grupo 1');
      expect(res.setor?.nome, 'Setor Grupo');
      expect(res.escalada?.viaEsportiva.nome, 'Via 4');
    });

    test('throws when grupo not found', () {
      expect(
        () =>
            DatasetResolver.resolve(pico: pico, grupoNome: 'Grupo Inexistente'),
        throwsException,
      );
    });

    test(
      'resolves setor globally if not inside explicitly given root (fallback)',
      () {
        // Setor Grupo is inside Grupo 1.
        final res = DatasetResolver.resolve(
          pico: pico,
          setorNome: 'Setor Grupo',
        );
        expect(res.setor?.nome, 'Setor Grupo');
      },
    );

    group('resolveReferencia', () {
      test('resolves escalada using defaultSetorNome', () {
        final ref = Mapa_Referencia(escalada: 'Via 1');
        final res = DatasetResolver.resolveReferencia(
          pico: pico,
          referencia: ref,
          defaultSetorNome: 'Setor A',
        );
        expect(res.setor?.nome, 'Setor A');
        expect(res.escalada?.viaEsportiva.nome, 'Via 1');
      });

      test(
        'resolves escalada and uses defaultGrupoNome and defaultSetorNome',
        () {
          final ref = Mapa_Referencia(escalada: 'Via 4');
          final res = DatasetResolver.resolveReferencia(
            pico: pico,
            referencia: ref,
            defaultGrupoNome: 'Grupo 1',
            defaultSetorNome: 'Setor Grupo',
          );
          expect(res.grupo?.nome, 'Grupo 1');
          expect(res.setor?.nome, 'Setor Grupo');
          expect(res.escalada?.viaEsportiva.nome, 'Via 4');
        },
      );

      test(
        'resolves explicit group, explicit setor, explicit escalada from ref',
        () {
          final ref = Mapa_Referencia(
            grupo: 'Grupo 1',
            setor: 'Setor Grupo',
            escalada: 'Via 4',
          );
          final res = DatasetResolver.resolveReferencia(
            pico: pico,
            referencia: ref,
            defaultGrupoNome: 'Grupo Errado',
            defaultSetorNome: 'Setor Errado',
          );
          expect(res.grupo?.nome, 'Grupo 1');
          expect(res.setor?.nome, 'Setor Grupo');
          expect(res.escalada?.viaEsportiva.nome, 'Via 4');
        },
      );

      test('throws when reference is totally empty', () {
        final ref = Mapa_Referencia(); // all empty
        expect(
          () => DatasetResolver.resolveReferencia(pico: pico, referencia: ref),
          throwsException,
        );
      });

      test('throws when referenced entity does not exist', () {
        final ref = Mapa_Referencia(escalada: 'Via 1');
        expect(
          () => DatasetResolver.resolveReferencia(
            pico: pico,
            referencia: ref,
            defaultSetorNome: 'Setor Inexistente',
          ),
          throwsException,
        );
      });
    });
  });

  group('ResolvedDataset', () {
    test('should properly store and retrieve values', () {
      final pico = Pico()..nome = 'Pico Teste';
      final grupo = Grupo()..nome = 'Grupo Teste';
      final setor = Setor()..nome = 'Setor Teste';
      final escalada = Escalada()
        ..viaEsportiva = (ViaEsportiva()..nome = 'Via Teste');

      final resolved = ResolvedDataset(
        grupo: grupo,
        setor: setor,
        escalada: escalada,
      );

      expect(resolved.grupo?.nome, 'Grupo Teste');
      expect(resolved.setor?.nome, 'Setor Teste');
      expect(resolved.escalada?.viaEsportiva.nome, 'Via Teste');
    });

    test('should support equality', () {
      final grupo = Grupo()..nome = 'Grupo Teste';

      final resolved1 = ResolvedDataset(grupo: grupo);
      final resolved2 = ResolvedDataset(grupo: grupo);
      final resolved3 = ResolvedDataset(grupo: Grupo()..nome = 'Grupo Teste');

      expect(resolved1, resolved2);
      expect(resolved1, resolved3); // value equality works
    });
  });
}
