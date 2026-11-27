// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/idioma/dicionario_pt.dart';
import 'package:frontend/idioma/modelo_idioma_app.dart';

void main() {
  group('dicionarioPortugues', () {
    test('contém tradução não vazia em português para todas as chaves de ChaveTexto', () {
      expect(dicionarioPortugues.keys.toSet(), equals(ChaveTexto.values.toSet()));
      for (final chave in ChaveTexto.values) {
        expect(
          dicionarioPortugues[chave],
          isNotNull,
          reason: 'Chave ausente em PT: ${chave.name}',
        );
        expect(
          dicionarioPortugues[chave]!.trim(),
          isNotEmpty,
          reason: 'Tradução vazia em PT: ${chave.name}',
        );
      }
    });

    test('mantém chaves de navegação e ações principais fiéis ao português brasileiro', () {
      expect(dicionarioPortugues[ChaveTexto.navInicio], 'INÍCIO');
      expect(dicionarioPortugues[ChaveTexto.navExplorar], 'EXPLORAR');
      expect(dicionarioPortugues[ChaveTexto.navMeusCroquis], 'MEUS CROQUIS');
      expect(dicionarioPortugues[ChaveTexto.navComunidade], 'COMUNIDADE');
      expect(dicionarioPortugues[ChaveTexto.configTitulo], 'Configurações');
    });
  });
}
