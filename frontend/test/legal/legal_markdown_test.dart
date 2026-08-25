// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Legal Markdown Verification', () {
    test('termos-de-uso.md contains link to privacy policy', () {
      final file = File('legal/repo/public/docs/termos-de-uso.md');
      expect(
        file.existsSync(),
        isTrue,
        reason: 'Arquivo de termos não encontrado em legal/repo/public/docs/termos-de-uso.md',
      );

      final content = file.readAsStringSync();

      expect(
        content.contains('[Política de Privacidade]'),
        isTrue,
        reason:
            'O texto do link da Política de Privacidade foi removido. O modal no app depende deste texto para interceptar o clique.',
      );

      expect(
        content.contains('/politica-de-privacidade'),
        isTrue,
        reason:
            'A URL do link da Política de Privacidade foi removida ou alterada. Ela precisa estar presente para manter a estrutura do Markdown correta.',
      );
    });
  });
}
