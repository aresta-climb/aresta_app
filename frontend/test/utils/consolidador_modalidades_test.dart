// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/utils/consolidador_modalidades.dart';

void main() {
  group('ConsolidadorModalidades - Formatação de Rótulos', () {
    test('formata corretamente singular para 1 via de cada tipo', () {
      expect(
        ConsolidadorModalidades.formatarRotulo(
          ModalidadeEscaladaEnum.esportiva,
          1,
        ),
        '1 esportiva',
      );
      expect(
        ConsolidadorModalidades.formatarRotulo(ModalidadeEscaladaEnum.movel, 1),
        '1 móvel',
      );
      expect(
        ConsolidadorModalidades.formatarRotulo(
          ModalidadeEscaladaEnum.boulder,
          1,
        ),
        '1 boulder',
      );
      expect(
        ConsolidadorModalidades.formatarRotulo(
          ModalidadeEscaladaEnum.multienfiada,
          1,
        ),
        '1 multienfiada',
      );
      expect(
        ConsolidadorModalidades.formatarRotulo(
          ModalidadeEscaladaEnum.highline,
          1,
        ),
        '1 highline',
      );
    });

    test('formata corretamente plural para mais de 1 via de cada tipo', () {
      expect(
        ConsolidadorModalidades.formatarRotulo(
          ModalidadeEscaladaEnum.esportiva,
          12,
        ),
        '12 esportivas',
      );
      expect(
        ConsolidadorModalidades.formatarRotulo(ModalidadeEscaladaEnum.movel, 3),
        '3 móveis',
      );
      expect(
        ConsolidadorModalidades.formatarRotulo(
          ModalidadeEscaladaEnum.boulder,
          5,
        ),
        '5 boulders',
      );
      expect(
        ConsolidadorModalidades.formatarRotulo(
          ModalidadeEscaladaEnum.multienfiada,
          2,
        ),
        '2 multienfiadas',
      );
      expect(
        ConsolidadorModalidades.formatarRotulo(
          ModalidadeEscaladaEnum.highline,
          4,
        ),
        '4 highlines',
      );
    });

    test('formata resumo quantitativo de grupo com singular e plural', () {
      expect(
        ConsolidadorModalidades.formatarResumoGrupo(
          totalSetores: 1,
          totalEscaladas: 1,
        ),
        '1 setor • 1 escalada',
      );
      expect(
        ConsolidadorModalidades.formatarResumoGrupo(
          totalSetores: 5,
          totalEscaladas: 42,
        ),
        '5 setores • 42 escaladas',
      );
      expect(
        ConsolidadorModalidades.formatarResumoGrupo(
          totalSetores: 2,
          totalEscaladas: 1,
        ),
        '2 setores • 1 escalada',
      );
      expect(
        ConsolidadorModalidades.formatarResumoGrupo(
          totalSetores: 1,
          totalEscaladas: 10,
        ),
        '1 setor • 10 escaladas',
      );
    });
  });

  group('ConsolidadorModalidades - Consolidação de Setores', () {
    test('retorna lista vazia quando setor não possui escaladas', () {
      final setor = Setor()..nome = 'Setor Vazio';
      final resultado = ConsolidadorModalidades.consolidarSetor(setor);
      expect(resultado, isEmpty);
    });

    test('consolida escaladas de um setor respeitando ordem e contagem', () {
      final setor = Setor()
        ..nome = 'Falésia Principal'
        ..escaladas.addAll([
          Escalada()..viaEsportiva = (ViaEsportiva()..nome = 'Via 1'),
          Escalada()..viaEsportiva = (ViaEsportiva()..nome = 'Via 2'),
          Escalada()..viaMovel = (ViaMovel()..nome = 'Fenda 1'),
          Escalada()..boulder = (Boulder()..nome = 'Bloco 1'),
          Escalada()..boulder = (Boulder()..nome = 'Bloco 2'),
          Escalada()..boulder = (Boulder()..nome = 'Bloco 3'),
          Escalada()..highline = (Highline()..nome = 'Linha Alta'),
          Escalada()
            ..viaMultiplasEnfiadas = (ViaMultiplasEnfiadas()..nome = 'Paredão'),
        ]);

      final resultado = ConsolidadorModalidades.consolidarSetor(setor);

      expect(resultado.length, 5);

      final esportivas = resultado.firstWhere(
        (i) => i.modalidade == ModalidadeEscaladaEnum.esportiva,
      );
      expect(esportivas.quantidade, 2);
      expect(esportivas.rotuloFormatado, '2 esportivas');

      final moveis = resultado.firstWhere(
        (i) => i.modalidade == ModalidadeEscaladaEnum.movel,
      );
      expect(moveis.quantidade, 1);
      expect(moveis.rotuloFormatado, '1 móvel');

      final boulders = resultado.firstWhere(
        (i) => i.modalidade == ModalidadeEscaladaEnum.boulder,
      );
      expect(boulders.quantidade, 3);
      expect(boulders.rotuloFormatado, '3 boulders');

      final multienfiadas = resultado.firstWhere(
        (i) => i.modalidade == ModalidadeEscaladaEnum.multienfiada,
      );
      expect(multienfiadas.quantidade, 1);
      expect(multienfiadas.rotuloFormatado, '1 multienfiada');

      final highlines = resultado.firstWhere(
        (i) => i.modalidade == ModalidadeEscaladaEnum.highline,
      );
      expect(highlines.quantidade, 1);
      expect(highlines.rotuloFormatado, '1 highline');
    });

    test('utiliza precomputados do setor como fallback se escaladas estiver vazia', () {
      final setor = Setor()
        ..nome = 'Setor Com Precomputados'
        ..precomputados = (PrecomputadosSetor()
          ..totalEsportivas = 5
          ..totalMoveis = 1
          ..totalBoulders = 0);

      final resultado = ConsolidadorModalidades.consolidarSetor(setor);

      expect(resultado.length, 2);
      expect(resultado[0].rotuloFormatado, '5 esportivas');
      expect(resultado[1].rotuloFormatado, '1 móvel');
    });

    test('utiliza precomputados com boulders, multienfiadas e highlines', () {
      final setor = Setor()
        ..nome = 'Setor Completo Precomputado'
        ..precomputados = (PrecomputadosSetor()
          ..totalBoulders = 8
          ..totalMultiplasEnfiadas = 3
          ..totalHighlines = 2);

      final resultado = ConsolidadorModalidades.consolidarSetor(setor);

      expect(resultado.length, 3);
      expect(resultado[0].rotuloFormatado, '8 boulders');
      expect(resultado[1].rotuloFormatado, '3 multienfiadas');
      expect(resultado[2].rotuloFormatado, '2 highlines');
    });
  });

  group('ConsolidadorModalidades - Consolidação de Grupos', () {
    test('retorna lista vazia quando grupo não tem setores nem precomputados', () {
      final grupo = Grupo()..nome = 'Grupo Vazio';
      final resultado = ConsolidadorModalidades.consolidarGrupo(grupo);
      expect(resultado, isEmpty);
    });

    test('agrega escaladas de todos os setores contidos no grupo', () {
      final setor1 = Setor()
        ..nome = 'Bloco A'
        ..escaladas.addAll([
          Escalada()..boulder = (Boulder()..nome = 'B1'),
          Escalada()..boulder = (Boulder()..nome = 'B2'),
        ]);

      final setor2 = Setor()
        ..nome = 'Parede B'
        ..escaladas.addAll([
          Escalada()..boulder = (Boulder()..nome = 'B3'),
          Escalada()..viaEsportiva = (ViaEsportiva()..nome = 'Via E1'),
        ]);

      final grupo = Grupo()
        ..nome = 'Vale dos Blocos'
        ..setores.addAll([
          ArquivoSetor()..conteudo = setor1,
          ArquivoSetor()..conteudo = setor2,
        ]);

      final resultado = ConsolidadorModalidades.consolidarGrupo(grupo);

      expect(resultado.length, 2);

      final boulders = resultado.firstWhere(
        (i) => i.modalidade == ModalidadeEscaladaEnum.boulder,
      );
      expect(boulders.quantidade, 3);
      expect(boulders.rotuloFormatado, '3 boulders');

      final esportivas = resultado.firstWhere(
        (i) => i.modalidade == ModalidadeEscaladaEnum.esportiva,
      );
      expect(esportivas.quantidade, 1);
      expect(esportivas.rotuloFormatado, '1 esportiva');
    });

    test('utiliza precomputados do grupo como fallback se setores não tiverem escaladas', () {
      final grupo = Grupo()
        ..nome = 'Grupo Precomputado'
        ..precomputados = (PrecomputadosGrupo()
          ..totalEsportivas = 10
          ..totalMoveis = 2
          ..totalBoulders = 4
          ..totalMultiplasEnfiadas = 1
          ..totalHighlines = 1);

      final resultado = ConsolidadorModalidades.consolidarGrupo(grupo);

      expect(resultado.length, 5);
      expect(resultado[0].rotuloFormatado, '10 esportivas');
      expect(resultado[1].rotuloFormatado, '2 móveis');
      expect(resultado[2].rotuloFormatado, '4 boulders');
      expect(resultado[3].rotuloFormatado, '1 multienfiada');
      expect(resultado[4].rotuloFormatado, '1 highline');
    });
  });
}
