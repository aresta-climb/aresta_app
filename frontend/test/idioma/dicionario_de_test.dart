// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/idioma/dicionario_de.dart';
import 'package:frontend/idioma/dicionario_pt.dart';
import 'package:frontend/idioma/modelo_idioma_app.dart';

void main() {
  final padraoMarcador = RegExp(r'\{([a-zA-Z0-9_]+)\}');

  group('dicionarioAlemao', () {
    test(
      'contém tradução não vazia em alemão para todas as chaves de ChaveTexto com paridade exata de marcadores',
      () {
        expect(dicionarioAlemao.keys.toSet(), equals(ChaveTexto.values.toSet()));
        for (final chave in ChaveTexto.values) {
          final textoDe = dicionarioAlemao[chave]!;
          final textoPt = dicionarioPortugues[chave]!;
          expect(textoDe.trim(), isNotEmpty, reason: 'Vazio em DE: ${chave.name}');

          final marcadoresPt = padraoMarcador
              .allMatches(textoPt)
              .map((m) => m.group(1)!)
              .toSet();
          final marcadoresDe = padraoMarcador
              .allMatches(textoDe)
              .map((m) => m.group(1)!)
              .toSet();
          expect(
            marcadoresDe,
            equals(marcadoresPt),
            reason: 'Marcadores divergentes em DE na chave ${chave.name}',
          );
        }
      },
    );

    test('traduz termos essenciais de escalada e navegação para o alemão', () {
      expect(dicionarioAlemao[ChaveTexto.navInicio], 'START');
      expect(dicionarioAlemao[ChaveTexto.navExplorar], 'ENTDECKEN');
      expect(dicionarioAlemao[ChaveTexto.navMeusCroquis], 'MEINE TOPOS');
      expect(dicionarioAlemao[ChaveTexto.navComunidade], 'COMMUNITY');
      expect(dicionarioAlemao[ChaveTexto.configTitulo], 'Einstellungen');
    });
  });
}
