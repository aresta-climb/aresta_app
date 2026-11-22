// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/estatisticas_caderneta.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';

void main() {
  group('EstatisticasCaderneta (modelo de valor puro)', () {
    test('EstatisticasCaderneta.vazia inicializa métricas zeradas e coleções imutáveis', () {
      final vazia = EstatisticasCaderneta.vazia();

      expect(vazia.totalAscensoes, 0);
      expect(vazia.totalCadenas, 0);
      expect(vazia.totalTentativas, 0);
      expect(vazia.contagemPorEstilo, isEmpty);
      expect(vazia.piramideVias, isEmpty);
      expect(vazia.piramideBoulders, isEmpty);
      expect(vazia.maiorGrauVia, isNull);
      expect(vazia.maiorGrauBoulder, isNull);
      expect(vazia.taxaAVistaFlash, 0.0);
    });

    test('suporta copyWith, igualdade estrutural, hashCode e toString descritivo', () {
      final base = EstatisticasCaderneta(
        totalAscensoes: 3,
        totalCadenas: 2,
        totalTentativas: 1,
        contagemPorEstilo: const {TipoAscensao.flash: 2, TipoAscensao.tentativa: 1},
        piramideVias: const {'7a': 2},
        piramideBoulders: const {'V4': 1},
        maiorGrauVia: '7a',
        maiorGrauBoulder: 'V4',
        taxaAVistaFlash: 100.0,
      );

      final copiaIdentica = base.copyWith();
      expect(identical(base, base), isTrue);
      expect(base, equals(copiaIdentica));
      expect(base.hashCode, equals(copiaIdentica.hashCode));
      expect(base.toString(), contains('maiorVia: 7a'));
      expect(base == Object(), isFalse);

      expect(base == base.copyWith(totalAscensoes: 4), isFalse);
      expect(base == base.copyWith(totalCadenas: 3), isFalse);
      expect(base == base.copyWith(totalTentativas: 2), isFalse);
      expect(base == base.copyWith(contagemPorEstilo: const {}), isTrue);
      expect(base == base.copyWith(maiorGrauVia: '7b'), isFalse);
      expect(base == base.copyWith(maiorGrauBoulder: 'V5'), isFalse);
      expect(base == base.copyWith(taxaAVistaFlash: 50.0), isFalse);
      expect(base == base.copyWith(piramideVias: const {'7a': 1, '7b': 1}), isFalse);
      expect(base == base.copyWith(piramideVias: const {'7a': 9}), isFalse);
      expect(base == base.copyWith(piramideBoulders: const {}), isFalse);
      expect(base == base.copyWith(piramideBoulders: const {'V4': 9}), isFalse);
    });
  });
}
