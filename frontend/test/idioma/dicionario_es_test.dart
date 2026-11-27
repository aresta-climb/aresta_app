// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/idioma/dicionario_es.dart';
import 'package:frontend/idioma/dicionario_pt.dart';
import 'package:frontend/idioma/modelo_idioma_app.dart';

void main() {
  final padraoMarcador = RegExp(r'\{([a-zA-Z0-9_]+)\}');

  group('dicionarioEspanhol', () {
    test(
      'contém tradução não vazia em espanhol para todas as chaves de ChaveTexto com paridade exata de marcadores',
      () {
        expect(
          dicionarioEspanhol.keys.toSet(),
          equals(ChaveTexto.values.toSet()),
        );
        for (final chave in ChaveTexto.values) {
          final textoEs = dicionarioEspanhol[chave]!;
          final textoPt = dicionarioPortugues[chave]!;
          expect(textoEs.trim(), isNotEmpty, reason: 'Vazio em ES: ${chave.name}');

          final marcadoresPt = padraoMarcador
              .allMatches(textoPt)
              .map((m) => m.group(1)!)
              .toSet();
          final marcadoresEs = padraoMarcador
              .allMatches(textoEs)
              .map((m) => m.group(1)!)
              .toSet();
          expect(
            marcadoresEs,
            equals(marcadoresPt),
            reason: 'Marcadores divergentes em ES na chave ${chave.name}',
          );
        }
      },
    );

    test('traduz termos essenciais de escalada e navegação para o espanhol', () {
      expect(dicionarioEspanhol[ChaveTexto.navInicio], 'INICIO');
      expect(dicionarioEspanhol[ChaveTexto.navExplorar], 'EXPLORAR');
      expect(dicionarioEspanhol[ChaveTexto.navMeusCroquis], 'MIS CROQUIS');
      expect(dicionarioEspanhol[ChaveTexto.navComunidade], 'COMUNIDAD');
      expect(dicionarioEspanhol[ChaveTexto.configTitulo], 'Ajustes');
    });
  });
}
