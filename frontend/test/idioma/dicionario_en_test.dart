// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/idioma/dicionario_en.dart';
import 'package:frontend/idioma/dicionario_pt.dart';
import 'package:frontend/idioma/modelo_idioma_app.dart';

void main() {
  final padraoMarcador = RegExp(r'\{([a-zA-Z0-9_]+)\}');

  group('dicionarioIngles', () {
    test(
      'contém tradução não vazia em inglês para todas as chaves de ChaveTexto com paridade exata de marcadores',
      () {
        expect(dicionarioIngles.keys.toSet(), equals(ChaveTexto.values.toSet()));
        for (final chave in ChaveTexto.values) {
          final textoEn = dicionarioIngles[chave]!;
          final textoPt = dicionarioPortugues[chave]!;
          expect(textoEn.trim(), isNotEmpty, reason: 'Vazio em EN: ${chave.name}');

          final marcadoresPt = padraoMarcador
              .allMatches(textoPt)
              .map((m) => m.group(1)!)
              .toSet();
          final marcadoresEn = padraoMarcador
              .allMatches(textoEn)
              .map((m) => m.group(1)!)
              .toSet();
          expect(
            marcadoresEn,
            equals(marcadoresPt),
            reason: 'Marcadores divergentes em EN na chave ${chave.name}',
          );
        }
      },
    );

    test('traduz termos essenciais de escalada e navegação para o inglês', () {
      expect(dicionarioIngles[ChaveTexto.navInicio], 'HOME');
      expect(dicionarioIngles[ChaveTexto.navExplorar], 'EXPLORE');
      expect(dicionarioIngles[ChaveTexto.navMeusCroquis], 'MY TOPOS');
      expect(dicionarioIngles[ChaveTexto.navComunidade], 'COMMUNITY');
      expect(dicionarioIngles[ChaveTexto.configTitulo], 'Settings');
    });
  });
}
