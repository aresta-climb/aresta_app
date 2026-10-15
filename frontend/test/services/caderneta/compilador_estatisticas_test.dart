// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/cadena.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';
import 'package:frontend/data/modelos/tipo_escalada.dart';
import 'package:frontend/services/caderneta/compilador_estatisticas.dart';

void main() {
  group('CompiladorEstatisticasCaderneta', () {
    test('retorna estatísticas vazias para lista vazia de cadenas', () {
      final stats = CompiladorEstatisticasCaderneta.compilar(const []);
      expect(stats.totalAscensoes, 0);
      expect(stats.totalCadenas, 0);
      expect(stats.totalTentativas, 0);
      expect(stats.piramideVias, isEmpty);
      expect(stats.piramideBoulders, isEmpty);
      expect(stats.maiorGrauVia, isNull);
      expect(stats.maiorGrauBoulder, isNull);
    });

    test(
      'compila corretamente contagens, maior grau e pirâmide via obterGrauDaVia',
      () {
        final cadenas = [
          Cadena.criar(
            escaladaUid: 'via-1',
            dataAscensao: DateTime(2026, 8, 1),
            tipoAscensao: TipoAscensao.aVista,
            tipoEscalada: TipoEscalada.guiado,
          ),
          Cadena.criar(
            escaladaUid: 'via-2',
            dataAscensao: DateTime(2026, 8, 2),
            tipoAscensao: TipoAscensao.flash,
            tipoEscalada: TipoEscalada.guiado,
          ),
          Cadena.criar(
            escaladaUid: 'boulder-1',
            dataAscensao: DateTime(2026, 8, 3),
            tipoAscensao: TipoAscensao.trabalhado,
            tipoEscalada: TipoEscalada.boulder,
          ),
        ];

        final stats = CompiladorEstatisticasCaderneta.compilar(
          cadenas,
          obterGrauDaVia: (uid) {
            if (uid == 'via-1') return '6sup';
            if (uid == 'via-2') return '7a';
            if (uid == 'boulder-1') return 'V4';
            return null;
          },
        );

        expect(stats.totalAscensoes, 3);
        expect(stats.totalCadenas, 3);
        expect(stats.totalTentativas, 0);
        expect(stats.taxaAVistaFlash, closeTo(66.66, 0.1));
        expect(stats.maiorGrauVia, '7a');
        expect(stats.maiorGrauBoulder, 'V4');
        expect(stats.piramideVias.containsKey('6sup'), isTrue);
        expect(stats.piramideVias.containsKey('7a'), isTrue);
        expect(stats.piramideBoulders.containsKey('V4'), isTrue);
      },
    );
  });
}
