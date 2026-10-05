// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:frontend/view/function_library/sintaxe_tag_small.dart';

void main() {
  group('SintaxeTagSmall', () {
    late md.Document documento;

    setUp(() {
      documento = md.Document(
        extensionSet: md.ExtensionSet.gitHubFlavored,
        inlineSyntaxes: [SintaxeTagSmall()],
      );
    });

    test('deve identificar tag <small> minúscula e criar elemento small', () {
      final linhas = ['Este é um <small>texto menor</small> no parágrafo.'];
      final nos = documento.parseLines(linhas);

      expect(nos, isNotEmpty);
      final paragrafo = nos.first as md.Element;
      expect(paragrafo.tag, equals('p'));

      final elementoSmall = paragrafo.children!.firstWhere(
        (no) => no is md.Element && no.tag == 'small',
      ) as md.Element;

      expect(elementoSmall.textContent, equals('texto menor'));
    });

    test('deve ser insensível a maiúsculas e minúsculas (<SMALL> e <Small>)', () {
      final linhas = ['Texto com <SMALL>CAIXA ALTA</SMALL> e <Small>Mista</Small>.'];
      final nos = documento.parseLines(linhas);

      final paragrafo = nos.first as md.Element;
      final elementosSmall = paragrafo.children!
          .whereType<md.Element>()
          .where((el) => el.tag == 'small')
          .toList();

      expect(elementosSmall.length, equals(2));
      expect(elementosSmall[0].textContent, equals('CAIXA ALTA'));
      expect(elementosSmall[1].textContent, equals('Mista'));
    });

    test('deve suportar formatação Markdown aninhada como negrito e itálico', () {
      final linhas = ['Nota: <small>**Importante:** *leia com atenção*</small>.'];
      final nos = documento.parseLines(linhas);

      final paragrafo = nos.first as md.Element;
      final elementoSmall = paragrafo.children!.firstWhere(
        (no) => no is md.Element && no.tag == 'small',
      ) as md.Element;

      expect(elementoSmall.children, isNotNull);
      final tagsFilhas = elementoSmall.children!
          .whereType<md.Element>()
          .map((el) => el.tag)
          .toList();

      expect(tagsFilhas, containsAll(['strong', 'em']));
      expect(elementoSmall.textContent, equals('Importante: leia com atenção'));
    });

    test('não deve capturar tags não fechadas', () {
      final linhas = ['Texto com <small>aberto sem fechar.'];
      final nos = documento.parseLines(linhas);

      final paragrafo = nos.first as md.Element;
      final contemSmall = paragrafo.children!
          .whereType<md.Element>()
          .any((el) => el.tag == 'small');

      expect(contemSmall, isFalse);
    });
  });
}
