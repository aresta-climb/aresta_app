// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/utils/calculadora_delta_grau.dart';
import 'package:frontend/utils/formatador_escalada.dart';

void main() {
  group('deslocarCodigoGrau e formatarGrauPorCodigo', () {
    test('desloca graus inteiros e com barra em vias brasileiras (-2 a +2) respeitando limites', () {
      final cod7a = GrauVia_GrauVia.BR_7A.value;
      expect(
        deslocarCodigoGrau(cod7a, 0, ehBoulder: false),
        equals(GrauVia_GrauVia.BR_7A.value),
      );
      expect(
        deslocarCodigoGrau(cod7a, 1, ehBoulder: false),
        equals(GrauVia_GrauVia.BR_7B.value),
      );
      expect(
        deslocarCodigoGrau(cod7a, 2, ehBoulder: false),
        equals(GrauVia_GrauVia.BR_7C.value),
      );
      expect(
        deslocarCodigoGrau(cod7a, -1, ehBoulder: false),
        equals(GrauVia_GrauVia.BR_6SUP.value),
      );
      expect(
        deslocarCodigoGrau(cod7a, -2, ehBoulder: false),
        equals(GrauVia_GrauVia.BR_6.value),
      );

      // Grau com barra (6ºsup/7a): 0 mantém, -1 -> 6ºsup, +1 -> 7a, +2 -> 7b, -2 -> 6º
      final codBarra = GrauVia_GrauVia.BR_6SUP_BARRA_7A.value;
      expect(
        deslocarCodigoGrau(codBarra, 0, ehBoulder: false),
        equals(codBarra),
      );
      expect(
        deslocarCodigoGrau(codBarra, -1, ehBoulder: false),
        equals(GrauVia_GrauVia.BR_6SUP.value),
      );
      expect(
        deslocarCodigoGrau(codBarra, -2, ehBoulder: false),
        equals(GrauVia_GrauVia.BR_6.value),
      );
      expect(
        deslocarCodigoGrau(codBarra, 1, ehBoulder: false),
        equals(GrauVia_GrauVia.BR_7A.value),
      );
      expect(
        deslocarCodigoGrau(codBarra, 2, ehBoulder: false),
        equals(GrauVia_GrauVia.BR_7B.value),
      );

      // Limites inferior (BR_1) e superior (BR_13A)
      expect(
        deslocarCodigoGrau(GrauVia_GrauVia.BR_1.value, -2, ehBoulder: false),
        equals(GrauVia_GrauVia.BR_1.value),
      );
      expect(
        deslocarCodigoGrau(GrauVia_GrauVia.BR_13A.value, 2, ehBoulder: false),
        equals(GrauVia_GrauVia.BR_13A.value),
      );

      expect(formatarGrauPorCodigo(GrauVia_GrauVia.BR_6SUP.value, ehBoulder: false), '6ºsup');
      expect(formatarGrauPorCodigo(null, ehBoulder: false), isNull);
      expect(formatarGrauPorCodigo(GrauVia_GrauVia.INDEFINIDO.value, ehBoulder: false), isNull);
      expect(deslocarCodigoGrau(null, 1, ehBoulder: false), isNull);
      expect(deslocarCodigoGrau(999, 1, ehBoulder: false), isNull);
    });

    test('desloca graus inteiros e com barra em boulders e ignora PROJETO', () {
      final codV4 = GrauBoulder_GrauBoulder.V4.value;
      expect(
        deslocarCodigoGrau(codV4, 1, ehBoulder: true),
        equals(GrauBoulder_GrauBoulder.V5.value),
      );
      expect(
        deslocarCodigoGrau(codV4, -1, ehBoulder: true),
        equals(GrauBoulder_GrauBoulder.V3.value),
      );

      final codBarra = GrauBoulder_GrauBoulder.V3_BARRA_V4.value;
      expect(deslocarCodigoGrau(codBarra, 0, ehBoulder: true), equals(codBarra));
      expect(
        deslocarCodigoGrau(codBarra, -1, ehBoulder: true),
        equals(GrauBoulder_GrauBoulder.V3.value),
      );
      expect(
        deslocarCodigoGrau(codBarra, 1, ehBoulder: true),
        equals(GrauBoulder_GrauBoulder.V4.value),
      );

      expect(formatarGrauPorCodigo(GrauBoulder_GrauBoulder.V5.value, ehBoulder: true), 'v5');
      expect(formatarGrauPorCodigo(GrauBoulder_GrauBoulder.PROJETO.value, ehBoulder: true), isNull);
      expect(deslocarCodigoGrau(GrauBoulder_GrauBoulder.PROJETO.value, 1, ehBoulder: true), isNull);

      // Verifica correção em obterCodigoGrauOficial para Boulder PROJETO
      expect(
        obterCodigoGrauOficial(
          Escalada(boulder: Boulder(dificuldade: GrauBoulder_GrauBoulder.PROJETO)),
        ),
        isNull,
      );
    });
  });

  group('rotuloOpcaoDeltaGrau e consolidarConsensoDeVotos', () {
    test('gera rótulos de opção e consolida moda/mediana dos votos em ConsensoGrauVia', () {
      final cod7a = GrauVia_GrauVia.BR_7A.value;
      expect(rotuloOpcaoDeltaGrau(0, codigoOficial: cod7a, ehBoulder: false), 'Justo (7a)');
      expect(rotuloOpcaoDeltaGrau(1, codigoOficial: cod7a, ehBoulder: false), '+1 (7b)');
      expect(rotuloOpcaoDeltaGrau(-1, codigoOficial: cod7a, ehBoulder: false), '-1 (6ºsup)');
      expect(rotuloOpcaoDeltaGrau(0, codigoOficial: null, ehBoulder: false), 'Grau Justo (0)');
      expect(rotuloOpcaoDeltaGrau(2, codigoOficial: null, ehBoulder: false), '+2');
      expect(rotuloOpcaoDeltaGrau(-2, codigoOficial: null, ehBoulder: false), '-2');

      final vazio = consolidarConsensoDeVotos(
        votos: const [],
        codigoGrauOficial: cod7a,
        ehBoulder: false,
      );
      expect(vazio.possuiVotos, isFalse);

      final consenso = consolidarConsensoDeVotos(
        votos: [
          (deltaGrau: 1, grauSugerido: GrauVia_GrauVia.BR_7B.value),
          (deltaGrau: 1, grauSugerido: GrauVia_GrauVia.BR_7B.value),
          (deltaGrau: 1, grauSugerido: GrauVia_GrauVia.BR_7B.value),
          (deltaGrau: 0, grauSugerido: GrauVia_GrauVia.BR_7A.value),
        ],
        codigoGrauOficial: cod7a,
        ehBoulder: false,
      );
      expect(consenso.totalVotos, 4);
      expect(consenso.grauSugerido, '7b');
      expect(consenso.resumoTendencia, '75% sugerem +1');

      // Via projeto (sem grau oficial): consolida diretamente a moda de grauSugerido
      final consensoProjeto = consolidarConsensoDeVotos(
        votos: [
          (deltaGrau: 0, grauSugerido: GrauVia_GrauVia.BR_8A.value),
          (deltaGrau: 0, grauSugerido: GrauVia_GrauVia.BR_8A.value),
        ],
        codigoGrauOficial: null,
        ehBoulder: false,
      );
      expect(consensoProjeto.totalVotos, 2);
      expect(consensoProjeto.grauSugerido, '8a');

      // Voto apenas com deltaGrau sem grauSugerido explícito deriva o código pelo oficial
      final apenasDelta = consolidarConsensoDeVotos(
        votos: [(deltaGrau: 1, grauSugerido: null)],
        codigoGrauOficial: cod7a,
        ehBoulder: false,
      );
      expect(apenasDelta.grauSugerido, '7b');

      // Votos sem código resolvível nem grau oficial retornam consenso vazio
      final semResolucao = consolidarConsensoDeVotos(
        votos: [(deltaGrau: 0, grauSugerido: null)],
        codigoGrauOficial: null,
        ehBoulder: false,
      );
      expect(semResolucao.possuiVotos, isFalse);
    });
  });
}
