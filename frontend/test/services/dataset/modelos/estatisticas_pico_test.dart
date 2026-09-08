// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/dataset/modelos/estatisticas_pico.dart';

void main() {
  group('EstatisticasPico', () {
    test('cria instância com valores padrão', () {
      const stats = EstatisticasPico();
      expect(stats.totalVias, equals(0));
      expect(stats.totalSetores, equals(0));
      expect(stats.totalEsportivas, equals(0));
      expect(stats.totalMoveis, equals(0));
      expect(stats.totalBoulders, equals(0));
      expect(stats.totalMultiplasEnfiadas, equals(0));
      expect(stats.totalHighlines, equals(0));
      expect(stats.tamanhoDownloadBytes, isNull);
    });

    test('cria instância com valores customizados e exporta para mapa', () {
      const stats = EstatisticasPico(
        totalVias: 15,
        totalSetores: 3,
        totalEsportivas: 10,
        totalMoveis: 5,
        totalBoulders: 2,
        totalMultiplasEnfiadas: 1,
        totalHighlines: 0,
        tamanhoDownloadBytes: 2048,
      );

      final mapa = stats.paraMapa();
      expect(mapa['totalVias'], equals(15));
      expect(mapa['totalSetores'], equals(3));
      expect(mapa['totalEsportivas'], equals(10));
      expect(mapa['totalMoveis'], equals(5));
      expect(mapa['totalBoulders'], equals(2));
      expect(mapa['totalMultiplasEnfiadas'], equals(1));
      expect(mapa['totalHighlines'], equals(0));
      expect(mapa['tamanhoDownloadBytes'], equals(2048));
    });

    test('converte a partir de mapa legado', () {
      final mapa = {
        'totalVias': 20,
        'totalSetores': 4,
        'tamanhoDownloadBytes': 5000,
      };

      final stats = EstatisticasPico.deMapa(mapa);
      expect(stats.totalVias, equals(20));
      expect(stats.totalSetores, equals(4));
      expect(stats.totalEsportivas, equals(0));
      expect(stats.tamanhoDownloadBytes, equals(5000));
    });

    test('implementa igualdade por valor e hashCode corretamente', () {
      const statsA = EstatisticasPico(totalVias: 10, totalSetores: 2);
      const statsB = EstatisticasPico(totalVias: 10, totalSetores: 2);
      const statsC = EstatisticasPico(totalVias: 5, totalSetores: 1);

      expect(statsA, equals(statsB));
      expect(statsA.hashCode, equals(statsB.hashCode));
      expect(statsA, isNot(equals(statsC)));
      expect(statsA.toString(), contains('totalVias: 10'));
    });
  });
}
