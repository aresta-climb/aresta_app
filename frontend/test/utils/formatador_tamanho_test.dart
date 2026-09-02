// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/utils/formatador_tamanho.dart';

void main() {
  group('FormatadorTamanho', () {
    test('formata 0 bytes ou valores nulos/negativos como 0 B', () {
      expect(FormatadorTamanho.formatarBytes(0), equals('0 B'));
      expect(FormatadorTamanho.formatarBytes(-10), equals('0 B'));
      expect(FormatadorTamanho.formatarBytes(null), equals('0 B'));
    });

    test('formata bytes menores que 1 KB corretamente', () {
      expect(FormatadorTamanho.formatarBytes(1), equals('1 B'));
      expect(FormatadorTamanho.formatarBytes(512), equals('512 B'));
      expect(FormatadorTamanho.formatarBytes(1023), equals('1023 B'));
    });

    test('formata kilobytes (KB) com 1 casa decimal quando aplicável', () {
      expect(FormatadorTamanho.formatarBytes(1024), equals('1.0 KB'));
      expect(FormatadorTamanho.formatarBytes(1536), equals('1.5 KB'));
      expect(FormatadorTamanho.formatarBytes(1024 * 500), equals('500.0 KB'));
    });

    test('formata megabytes (MB) com precisão', () {
      expect(FormatadorTamanho.formatarBytes(1024 * 1024), equals('1.0 MB'));
      expect(
        FormatadorTamanho.formatarBytes((1024 * 1024 * 18.4).round()),
        equals('18.4 MB'),
      );
      expect(
        FormatadorTamanho.formatarBytes(25 * 1024 * 1024),
        equals('25.0 MB'),
      );
    });

    test('formata gigabytes (GB) com precisão', () {
      expect(
        FormatadorTamanho.formatarBytes(1024 * 1024 * 1024),
        equals('1.0 GB'),
      );
      expect(
        FormatadorTamanho.formatarBytes((1024 * 1024 * 1024 * 2.5).round()),
        equals('2.5 GB'),
      );
    });
  });
}
