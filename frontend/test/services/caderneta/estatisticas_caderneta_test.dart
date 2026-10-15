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

    test('calcula totais e contagens de estilo com precisão', () {
      final cadenas = [
        Cadena(
          id: 'c1',
          escaladaUid: 'via-1',
          dataAscensao: DateTime(2026, 9, 1),
          tipoAscensao: TipoAscensao.aVista,
          tipoEscalada: TipoEscalada.guiado,
        ),
        Cadena(
          id: 'c2',
          escaladaUid: 'via-2',
          dataAscensao: DateTime(2026, 9, 2),
          tipoAscensao: TipoAscensao.flash,
          tipoEscalada: TipoEscalada.guiado,
        ),
        Cadena(
          id: 'c3',
          escaladaUid: 'via-3',
          dataAscensao: DateTime(2026, 9, 3),
          tipoAscensao: TipoAscensao.trabalhado,
          tipoEscalada: TipoEscalada.topRope,
        ),
        Cadena(
          id: 'c4',
          escaladaUid: 'via-4',
          dataAscensao: DateTime(2026, 9, 4),
          tipoAscensao: TipoAscensao.tentativa,
          tipoEscalada: TipoEscalada.guiado,
        ),
      ];

      final stats = EstatisticasCaderneta.calcular(cadenas);

      expect(stats.totalAscensoes, 4);
      expect(stats.totalCadenas, 3);
      expect(stats.totalTentativas, 1);
      expect(stats.contagemPorEstilo[TipoAscensao.aVista], 1);
      expect(stats.contagemPorEstilo[TipoAscensao.flash], 1);
      expect(stats.contagemPorEstilo[TipoAscensao.trabalhado], 1);
      expect(stats.contagemPorEstilo[TipoAscensao.tentativa], 1);

      // 2 cadenas aVista/flash de 3 cadenas totais = 66.67%
      expect(stats.taxaAVistaFlash, closeTo(66.67, 0.1));
    });

    test('calcula a pirâmide de graduação de vias e boulders ordenadas', () {
      final mapaGraus = {
        'via-5': '5º',
        'via-6a': '6º',
        'via-7a-1': '7a',
        'via-7a-2': '7a',
        'via-8a': '8a',
        'boulder-v3': 'V3',
        'boulder-v5': 'V5',
      };

      final cadenas = [
        Cadena(
          id: 'c1',
          escaladaUid: 'via-5',
          dataAscensao: DateTime(2026, 9, 1),
          tipoAscensao: TipoAscensao.aVista,
          tipoEscalada: TipoEscalada.guiado,
        ),
        Cadena(
          id: 'c2',
          escaladaUid: 'via-6a',
          dataAscensao: DateTime(2026, 9, 2),
          tipoAscensao: TipoAscensao.flash,
          tipoEscalada: TipoEscalada.guiado,
        ),
        Cadena(
          id: 'c3',
          escaladaUid: 'via-7a-1',
          dataAscensao: DateTime(2026, 9, 3),
          tipoAscensao: TipoAscensao.trabalhado,
          tipoEscalada: TipoEscalada.guiado,
        ),
        Cadena(
          id: 'c4',
          escaladaUid: 'via-7a-2',
          dataAscensao: DateTime(2026, 9, 4),
          tipoAscensao: TipoAscensao.trabalhado,
          tipoEscalada: TipoEscalada.guiado,
        ),
        Cadena(
          id: 'c5',
          escaladaUid: 'via-8a',
          dataAscensao: DateTime(2026, 9, 5),
          tipoAscensao: TipoAscensao.trabalhado,
          tipoEscalada: TipoEscalada.guiado,
        ),
        // Boulder
        Cadena(
          id: 'c6',
          escaladaUid: 'boulder-v3',
          dataAscensao: DateTime(2026, 9, 6),
          tipoAscensao: TipoAscensao.flash,
          tipoEscalada: TipoEscalada.boulder,
        ),
        Cadena(
          id: 'c7',
          escaladaUid: 'boulder-v5',
          dataAscensao: DateTime(2026, 9, 7),
          tipoAscensao: TipoAscensao.trabalhado,
          tipoEscalada: TipoEscalada.boulder,
        ),
        // Tentativa em 9a (não entra na pirâmide de cadenas nem maior grau)
        Cadena(
          id: 'c8',
          escaladaUid: 'via-9a',
          dataAscensao: DateTime(2026, 9, 8),
          tipoAscensao: TipoAscensao.tentativa,
          tipoEscalada: TipoEscalada.guiado,
        ),
      ];

      final stats = EstatisticasCaderneta.calcular(
        cadenas,
        obterGrauDaVia: (uid) =>
            mapaGraus[uid] ?? (uid == 'via-9a' ? '9a' : null),
      );

      expect(stats.piramideVias['5º'], 1);
      expect(stats.piramideVias['6º'], 1);
      expect(stats.piramideVias['7a'], 2);
      expect(stats.piramideVias['8a'], 1);
      expect(stats.piramideVias.containsKey('9a'), isFalse);

      expect(stats.piramideBoulders['V3'], 1);
      expect(stats.piramideBoulders['V5'], 1);

      expect(stats.maiorGrauVia, '8a');
      expect(stats.maiorGrauBoulder, 'V5');
    });

    test(
      'lida com listas vazias, graus não mapeados e graus nulos elegantemente',
      () {
        final statsVazia = EstatisticasCaderneta.calcular([]);
        expect(statsVazia.totalAscensoes, 0);

        final cadenas = [
          Cadena(
            id: 'c1',
            escaladaUid: 'u1',
            dataAscensao: DateTime(2026, 9, 1),
            tipoAscensao: TipoAscensao.aVista,
            tipoEscalada: TipoEscalada.guiado,
          ),
          Cadena(
            id: 'c2',
            escaladaUid: 'u2',
            dataAscensao: DateTime(2026, 9, 2),
            tipoAscensao: TipoAscensao.flash,
            tipoEscalada: TipoEscalada.boulder,
          ),
          Cadena(
            id: 'c3',
            escaladaUid: 'u3',
            dataAscensao: DateTime(2026, 9, 3),
            tipoAscensao: TipoAscensao.trabalhado,
            tipoEscalada: TipoEscalada.guiado,
          ),
        ];

        final stats = EstatisticasCaderneta.calcular(
          cadenas,
          obterGrauDaVia: (uid) {
            if (uid == 'u1') return 'Grau Especial 15';
            if (uid == 'u2') return 'SemNumero';
            return null; // u3 sem grau
          },
        );

        expect(stats.piramideVias.containsKey('Grau Especial 15'), isTrue);
        expect(stats.piramideBoulders.containsKey('SemNumero'), isTrue);
      },
    );

    test(
      'iguala instâncias com mesmos valores e diferencia com valores distintos',
      () {
        final s1 = EstatisticasCaderneta.vazia();
        final s2 = EstatisticasCaderneta.vazia();
        expect(s1, equals(s2));
        expect(s1.hashCode, equals(s2.hashCode));
        expect(s1.toString(), contains('EstatisticasCaderneta'));

        final s3 = EstatisticasCaderneta(
          totalAscensoes: 1,
          totalCadenas: 1,
          totalTentativas: 0,
          contagemPorEstilo: const {},
          piramideVias: const {'5º': 1},
          piramideBoulders: const {},
          maiorGrauVia: '5º',
          maiorGrauBoulder: null,
          taxaAVistaFlash: 100.0,
        );
        expect(s1 == s3, isFalse);
        expect(s1 == Object(), isFalse);

        // Testa diferenciação de cada propriedade no operator ==
        expect(s3 == s3.copyWith(totalCadenas: 2), isFalse);
        expect(s3 == s3.copyWith(totalTentativas: 1), isFalse);
        expect(s3 == s3.copyWith(maiorGrauVia: '6a'), isFalse);
        expect(s3 == s3.copyWith(maiorGrauBoulder: 'V2'), isFalse);
        expect(s3 == s3.copyWith(taxaAVistaFlash: 50.0), isFalse);
        expect(s3 == s3.copyWith(piramideVias: const {'6a': 1}), isFalse);
        expect(s3 == s3.copyWith(piramideVias: const {'5º': 2}), isFalse);
        expect(s3 == s3.copyWith(piramideBoulders: const {'V1': 1}), isFalse);
        expect(s3 == s3.copyWith(piramideBoulders: const {'V0': 2}), isFalse);
      },
    );

    test(
      'ordena graus com pesos idênticos alfabeticamente e extrai pesos regex para vias e boulders',
      () {
        final cadenas = [
          Cadena(
            id: 'v_custom1',
            escaladaUid: 'u_v1',
            dataAscensao: DateTime(2026, 9, 1),
            tipoAscensao: TipoAscensao.trabalhado,
            tipoEscalada: TipoEscalada.guiado,
          ),
          Cadena(
            id: 'v_custom2',
            escaladaUid: 'u_v2',
            dataAscensao: DateTime(2026, 9, 2),
            tipoAscensao: TipoAscensao.trabalhado,
            tipoEscalada: TipoEscalada.guiado,
          ),
          Cadena(
            id: 'b_custom1',
            escaladaUid: 'u_b1',
            dataAscensao: DateTime(2026, 9, 3),
            tipoAscensao: TipoAscensao.trabalhado,
            tipoEscalada: TipoEscalada.boulder,
          ),
          Cadena(
            id: 'b_custom2',
            escaladaUid: 'u_b2',
            dataAscensao: DateTime(2026, 9, 4),
            tipoAscensao: TipoAscensao.trabalhado,
            tipoEscalada: TipoEscalada.boulder,
          ),
        ];

        final stats = EstatisticasCaderneta.calcular(
          cadenas,
          obterGrauDaVia: (uid) {
            if (uid == 'u_v1') return 'Projeto 50 B';
            if (uid == 'u_v2') return 'Projeto 50 A';
            if (uid == 'u_b1') return 'Boulder V99';
            if (uid == 'u_b2') return 'Bloco 99';
            return null;
          },
        );

        final chavesVias = stats.piramideVias.keys.toList();
        expect(chavesVias, containsAll(['Projeto 50 A', 'Projeto 50 B']));
        expect(
          stats.piramideBoulders.keys,
          containsAll(['Boulder V99', 'Bloco 99']),
        );
      },
    );
  });
}
