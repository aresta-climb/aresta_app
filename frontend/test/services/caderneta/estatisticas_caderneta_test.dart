// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/cadena.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';
import 'package:frontend/data/modelos/tipo_escalada.dart';
import 'package:frontend/services/caderneta/estatisticas_caderneta.dart';

void main() {
  group('EstatisticasCaderneta', () {
    test(
      'EstatisticasCaderneta.vazia retorna valores zerados e coleções vazias',
      () {
        final stats = EstatisticasCaderneta.vazia();

        expect(stats.totalAscensoes, 0);
        expect(stats.totalCadenas, 0);
        expect(stats.totalTentativas, 0);
        expect(stats.contagemPorEstilo, isEmpty);
        expect(stats.piramideVias, isEmpty);
        expect(stats.piramideBoulders, isEmpty);
        expect(stats.maiorGrauVia, isNull);
        expect(stats.maiorGrauBoulder, isNull);
        expect(stats.taxaAVistaFlash, 0.0);
      },
    );
  });
}
