// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/utils/formatador_escalada.dart';

void main() {
  group('formatador_escalada', () {
    test('obterNomeEscalada extrai o nome conforme a modalidade da Escalada', () {
      expect(
        obterNomeEscalada(
          Escalada()..viaEsportiva = (ViaEsportiva()..nome = 'Via Esportiva 1'),
        ),
        equals('Via Esportiva 1'),
      );
      expect(
        obterNomeEscalada(
          Escalada()..viaMovel = (ViaMovel()..nome = 'Fenda Clássica'),
        ),
        equals('Fenda Clássica'),
      );
      expect(
        obterNomeEscalada(
          Escalada()..boulder = (Boulder()..nome = 'Bloco Lunar'),
        ),
        equals('Bloco Lunar'),
      );
      expect(
        obterNomeEscalada(
          Escalada()
            ..viaMultiplasEnfiadas = (ViaMultiplasEnfiadas()
              ..nome = 'Paredão Sul'),
        ),
        equals('Paredão Sul'),
      );
      expect(
        obterNomeEscalada(
          Escalada()..highline = (Highline()..nome = 'Travessia Aérea'),
        ),
        equals('Travessia Aérea'),
      );
    });

    test(
      'obterNomeEscalada retorna Sem Nome ou fallback personalizado quando modalidade não está definida',
      () {
        expect(obterNomeEscalada(Escalada()), equals('Sem Nome'));
        expect(obterNomeEscalada(Escalada(), padrao: ''), isEmpty);
      },
    );

    test(
      'formatarTextoGrau formata graduações brasileiras e de boulder e ignora valores vazios ou indefinidos',
      () {
        expect(formatarTextoGrau(''), isEmpty);
        expect(formatarTextoGrau('GRAU_VIA_INDEFINIDO'), isEmpty);
        expect(formatarTextoGrau('BR_4'), equals('4º'));
        expect(formatarTextoGrau('BR_6_SUP'), equals('6ºsup'));
        expect(formatarTextoGrau('BR_7A'), equals('7a'));
        expect(formatarTextoGrau('BR_7A_BARRA_7B'), equals('7a/7b'));
        expect(formatarTextoGrau('V4'), equals('v4'));
      },
    );

    test(
      'obterTextoGrauEscalada retorna o grau formatado para vias e boulders e vazio para highline ou indefinido',
      () {
        expect(
          obterTextoGrauEscalada(
            Escalada()
              ..viaEsportiva = (ViaEsportiva()
                ..dificuldade = GrauVia_GrauVia.BR_7B),
          ),
          equals('7b'),
        );
        expect(
          obterTextoGrauEscalada(
            Escalada()
              ..viaMovel = (ViaMovel()
                ..dificuldade = GrauVia_GrauVia.BR_5SUP),
          ),
          equals('5ºsup'),
        );
        expect(
          obterTextoGrauEscalada(
            Escalada()
              ..boulder = (Boulder()
                ..dificuldade = GrauBoulder_GrauBoulder.V5),
          ),
          equals('v5'),
        );
        expect(
          obterTextoGrauEscalada(
            Escalada()
              ..viaMultiplasEnfiadas = (ViaMultiplasEnfiadas()
                ..dificuldadeMaxima = GrauVia_GrauVia.BR_6SUP),
          ),
          equals('6ºsup'),
        );
        expect(
          obterTextoGrauEscalada(
            Escalada()..highline = (Highline()..nome = 'Highline'),
          ),
          isEmpty,
        );
        expect(obterTextoGrauEscalada(Escalada()), isEmpty);
      },
    );

    test(
      'obterCodigoGrauOficial retorna código inteiro válido ou null para graus indefinidos e modalidades sem grau',
      () {
        expect(
          obterCodigoGrauOficial(
            Escalada()
              ..viaEsportiva = (ViaEsportiva()
                ..dificuldade = GrauVia_GrauVia.BR_7A),
          ),
          equals(GrauVia_GrauVia.BR_7A.value),
        );
        expect(
          obterCodigoGrauOficial(
            Escalada()
              ..viaEsportiva = (ViaEsportiva()
                ..dificuldade = GrauVia_GrauVia.INDEFINIDO),
          ),
          isNull,
        );
        expect(
          obterCodigoGrauOficial(
            Escalada()
              ..viaMovel = (ViaMovel()
                ..dificuldade = GrauVia_GrauVia.BR_6SUP),
          ),
          equals(GrauVia_GrauVia.BR_6SUP.value),
        );
        expect(
          obterCodigoGrauOficial(
            Escalada()..viaMovel = ViaMovel(),
          ),
          isNull,
        );
        expect(
          obterCodigoGrauOficial(
            Escalada()
              ..viaMultiplasEnfiadas = (ViaMultiplasEnfiadas()
                ..dificuldadeMaxima = GrauVia_GrauVia.BR_8A),
          ),
          equals(GrauVia_GrauVia.BR_8A.value),
        );
        expect(
          obterCodigoGrauOficial(
            Escalada()..viaMultiplasEnfiadas = ViaMultiplasEnfiadas(),
          ),
          isNull,
        );
        expect(
          obterCodigoGrauOficial(
            Escalada()
              ..boulder = (Boulder()
                ..dificuldade = GrauBoulder_GrauBoulder.V3),
          ),
          equals(GrauBoulder_GrauBoulder.V3.value),
        );
        expect(
          obterCodigoGrauOficial(
            Escalada()..boulder = Boulder(),
          ),
          isNull,
        );
        expect(
          obterCodigoGrauOficial(
            Escalada()..highline = Highline(),
          ),
          isNull,
        );
        expect(obterCodigoGrauOficial(Escalada()), isNull);
      },
    );

    test(
      'normalizarGrauEscalada normaliza graus brasileiros e boulders e descarta nulos, vazios ou highline',
      () {
        expect(normalizarGrauEscalada(null), isNull);
        expect(normalizarGrauEscalada('   '), isNull);
        expect(
          normalizarGrauEscalada('45m', tipoEscalada: 'highline'),
          isNull,
        );

        expect(normalizarGrauEscalada('5'), equals('5º'));
        expect(normalizarGrauEscalada('6sup'), equals('6ºsup'));
        expect(normalizarGrauEscalada('5sup / 6a'), equals('5ºsup/6a'));
        expect(normalizarGrauEscalada('7b'), equals('7b'));

        expect(normalizarGrauEscalada('v4'), equals('V4'));
        expect(normalizarGrauEscalada('vb'), equals('VB'));
        expect(
          normalizarGrauEscalada('v2', tipoEscalada: 'boulder'),
          equals('V2'),
        );
      },
    );

    test(
      'iterarEscaladasDoCroqui percorre todas as escaladas em setores diretos e grupos aninhados',
      () {
        final viaSetorDireto = Escalada()
          ..uid = 'via-direta'
          ..viaEsportiva = (ViaEsportiva()..nome = 'Via Direta');
        final viaEmGrupo = Escalada()
          ..uid = 'via-grupo'
          ..boulder = (Boulder()..nome = 'Bloco do Grupo');

        final croqui = Croqui(
          picos: [
            Pico(
              setoresOuGrupos: [
                SetorOuGrupo(
                  setor: ArquivoSetor(
                    conteudo: Setor(escaladas: [viaSetorDireto]),
                  ),
                ),
                SetorOuGrupo(
                  grupo: ArquivoGrupo(
                    conteudo: Grupo(
                      setores: [
                        ArquivoSetor(
                          conteudo: Setor(escaladas: [viaEmGrupo]),
                        ),
                      ],
                    ),
                  ),
                ),
                SetorOuGrupo(),
              ],
            ),
          ],
        );

        final uids = iterarEscaladasDoCroqui(croqui).map((e) => e.uid).toList();
        expect(uids, equals(['via-direta', 'via-grupo']));
      },
    );
  });
}
