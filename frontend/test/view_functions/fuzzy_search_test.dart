// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:frontend/view_functions/common_functions.dart';

class TestResult {
  final String title;
  final String subtitle;

  TestResult(this.title, this.subtitle);
}

void main() {
  group('Fuzzy Search Logic (Global Search config)', () {
    late Fuzzy<TestResult> fuse;

    setUp(() {
      final data = [
        TestResult('Pão de Açúcar', 'Via • Rio de Janeiro'),
        TestResult('Corcovado', 'Via Esportiva • Rio de Janeiro'),
        TestResult('Pedra Bonita', 'Setor • Rio de Janeiro'),
        TestResult('Morro da Urca', 'Boulder • Rio de Janeiro'),
      ];

      fuse = Fuzzy<TestResult>(
        data,
        options: FuzzyOptions(
          keys: [
            WeightedKey(
              name: 'title',
              getter: (TestResult i) => normalizeSearchString(i.title),
              weight: 1.0,
            ),
            WeightedKey(
              name: 'subtitle',
              getter: (TestResult i) => normalizeSearchString(i.subtitle),
              weight: 0.5,
            ),
          ],
          threshold: 0.4,
        ),
      );
    });

    test(
      'deve encontrar correspondência exata independentemente de acentos',
      () {
        // "Pao" sem til deve encontrar "Pão"
        final result = fuse.search(normalizeSearchString('Pao'));
        expect(result.isNotEmpty, isTrue);
        expect(result.first.item.title, 'Pão de Açúcar');
      },
    );

    test('deve encontrar correspondência com erro de digitação (fuzzy)', () {
      // "corcqvado" em vez de "corcovado"
      final result = fuse.search(normalizeSearchString('corcqvado'));
      expect(result.isNotEmpty, isTrue);
      expect(result.first.item.title, 'Corcovado');
    });

    test('deve pesquisar no subtítulo também (devido ao peso secundário)', () {
      // "boulder" só aparece no subtítulo de "Morro da Urca"
      final result = fuse.search(normalizeSearchString('boulder'));
      expect(result.isNotEmpty, isTrue);
      expect(result.first.item.title, 'Morro da Urca');
    });

    test('deve lidar corretamente com busca vazia e sem resultados', () {
      // Buscar algo muito diferente não deve retornar resultados com threshold 0.4
      final result = fuse.search(normalizeSearchString('zxywvuts'));
      expect(result.isEmpty, isTrue);
    });
  });
}
