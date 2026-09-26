// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/editor_croqui/modelos/metadados_previa.dart';

void main() {
  group('MetadadosPrevia', () {
    test('deJson deve parsear local_url com sucesso', () {
      const jsonStr = '{"local_url": "http://192.168.1.10:8080"}';
      final metadados = MetadadosPrevia.deJson(jsonStr);

      expect(metadados.localUrl, 'http://192.168.1.10:8080');
    });

    test('deJson deve retornar objeto vazio para json invalido ou corrompido', () {
      expect(MetadadosPrevia.deJson('invalido').localUrl, isNull);
      expect(MetadadosPrevia.deJson('[]').localUrl, isNull);
      expect(MetadadosPrevia.deJson('{"outro_campo": 123}').localUrl, isNull);
    });

    test('igualdade e hashCode funcionam corretamente', () {
      const m1 = MetadadosPrevia(localUrl: 'http://localhost');
      const m2 = MetadadosPrevia(localUrl: 'http://localhost');
      const m3 = MetadadosPrevia(localUrl: 'http://outro');

      expect(m1, equals(m2));
      expect(m1.hashCode, equals(m2.hashCode));
      expect(m1, isNot(equals(m3)));
      expect(m1.toString(), contains('http://localhost'));
    });
  });
}
