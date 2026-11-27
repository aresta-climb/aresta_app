// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/idioma/dicionario_nl.dart';
import 'package:frontend/idioma/dicionario_pt.dart';
import 'package:frontend/idioma/modelo_idioma_app.dart';

void main() {
  final padraoMarcador = RegExp(r'\{([a-zA-Z0-9_]+)\}');

  group('dicionarioHolandes', () {
    test(
      'contém tradução não vazia em neerlandês para todas as chaves de ChaveTexto com paridade exata de marcadores',
      () {
        expect(
          dicionarioHolandes.keys.toSet(),
          equals(ChaveTexto.values.toSet()),
        );
        for (final chave in ChaveTexto.values) {
          final textoNl = dicionarioHolandes[chave]!;
          final textoPt = dicionarioPortugues[chave]!;
          expect(textoNl.trim(), isNotEmpty, reason: 'Vazio em NL: ${chave.name}');

          final marcadoresPt = padraoMarcador
              .allMatches(textoPt)
              .map((m) => m.group(1)!)
              .toSet();
          final marcadoresNl = padraoMarcador
              .allMatches(textoNl)
              .map((m) => m.group(1)!)
              .toSet();
          expect(
            marcadoresNl,
            equals(marcadoresPt),
            reason: 'Marcadores divergentes em NL na chave ${chave.name}',
          );
        }
      },
    );

    test(
      'traduz termos essenciais de escalada e navegação para o neerlandês dos Países Baixos',
      () {
        expect(dicionarioHolandes[ChaveTexto.navInicio], 'HOME');
        expect(dicionarioHolandes[ChaveTexto.navExplorar], 'ONTDEKKEN');
        expect(dicionarioHolandes[ChaveTexto.navMeusCroquis], 'MIJN TOPO\'S');
        expect(dicionarioHolandes[ChaveTexto.navComunidade], 'COMMUNITY');
        expect(dicionarioHolandes[ChaveTexto.configTitulo], 'Instellingen');
      },
    );
  });
}
