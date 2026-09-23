// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/editor_croqui/modelos/configuracao_editor.dart';

void main() {
  group('ConfiguracaoEditor', () {
    test('instancia padrão possui valores esperados', () {
      const config = ConfiguracaoEditor();
      expect(config.editorUrl, isNull);
      expect(config.isExperimental, isFalse);
      expect(config.isDevMode, isFalse);
      expect(config.expiryTime, isNull);
    });

    test('serializa e desserializa de mapa com fidelidade', () {
      final mapa = {
        'editorUrl': 'http://192.168.1.100:8080',
        'isExperimental': true,
        'isDevMode': true,
        'expiryTime': '2026-09-12T20:00:00Z',
      };

      final config = ConfiguracaoEditor.deMapa(mapa);
      expect(config.editorUrl, equals('http://192.168.1.100:8080'));
      expect(config.isExperimental, isTrue);
      expect(config.isDevMode, isTrue);
      expect(config.expiryTime, equals('2026-09-12T20:00:00Z'));

      final exportado = config.paraMapa();
      expect(exportado['editorUrl'], equals('http://192.168.1.100:8080'));
      expect(exportado['isExperimental'], isTrue);
      expect(exportado['isDevMode'], isTrue);
    });

    test('suporta copyWith e limpeza de editorUrl', () {
      const original = ConfiguracaoEditor(
        editorUrl: 'http://localhost:3000',
        isExperimental: true,
      );

      final alterado = original.copyWith(isDevMode: true);
      expect(alterado.editorUrl, equals('http://localhost:3000'));
      expect(alterado.isDevMode, isTrue);

      final limpo = original.copyWith(clearEditorUrl: true);
      expect(limpo.editorUrl, isNull);
    });

    test('implementa igualdade estrutural e hashCode', () {
      const a = ConfiguracaoEditor(editorUrl: 'http://a', isExperimental: true);
      const b = ConfiguracaoEditor(editorUrl: 'http://a', isExperimental: true);
      const c = ConfiguracaoEditor(editorUrl: 'http://b', isExperimental: true);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
      expect(a.toString(), contains('editorUrl: http://a'));
    });
  });
}
