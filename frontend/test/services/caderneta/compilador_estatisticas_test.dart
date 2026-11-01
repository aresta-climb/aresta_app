// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pbenum.dart';
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

    test(
      'utiliza grauSugerido numérico da Cadena como fallback na pirâmide quando o catálogo não resolve o UID',
      () {
        final cadenas = [
          Cadena.criar(
            escaladaUid: 'via-offline-sem-catalogo',
            dataAscensao: DateTime(2026, 9, 1),
            tipoAscensao: TipoAscensao.aVista,
            tipoEscalada: TipoEscalada.guiado,
            grauSugerido: GrauVia_GrauVia.BR_6SUP.value,
          ),
          Cadena.criar(
            escaladaUid: 'boulder-offline-sem-catalogo',
            dataAscensao: DateTime(2026, 9, 2),
            tipoAscensao: TipoAscensao.flash,
            tipoEscalada: TipoEscalada.boulder,
            grauSugerido: GrauBoulder_GrauBoulder.V5.value,
          ),
          Cadena.criar(
            escaladaUid: 'via-com-codigo-invalido',
            dataAscensao: DateTime(2026, 9, 3),
            tipoAscensao: TipoAscensao.trabalhado,
            tipoEscalada: TipoEscalada.guiado,
            grauSugerido: GrauVia_GrauVia.PROJETO.value,
          ),
          Cadena.criar(
            escaladaUid: 'boulder-indefinido',
            dataAscensao: DateTime(2026, 9, 4),
            tipoAscensao: TipoAscensao.trabalhado,
            tipoEscalada: TipoEscalada.boulder,
            grauSugerido: GrauBoulder_GrauBoulder.INDEFINIDO.value,
          ),
          Cadena.criar(
            escaladaUid: 'via-sem-grau-sugerido',
            dataAscensao: DateTime(2026, 9, 5),
            tipoAscensao: TipoAscensao.trabalhado,
            tipoEscalada: TipoEscalada.guiado,
          ),
        ];

        final stats = CompiladorEstatisticasCaderneta.compilar(cadenas);

        expect(stats.piramideVias, equals({'6ºsup': 1}));
        expect(stats.piramideBoulders, equals({'V5': 1}));
        expect(stats.maiorGrauVia, equals('6ºsup'));
        expect(stats.maiorGrauBoulder, equals('V5'));
      },
    );
  });
}
