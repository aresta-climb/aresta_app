// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/tipo_escalada.dart';

void main() {
  group('TipoEscalada', () {
    test('possui as 4 modalidades com os códigos corretos', () {
      expect(TipoEscalada.guiado.codigo, 1);
      expect(TipoEscalada.topRope.codigo, 2);
      expect(TipoEscalada.boulder.codigo, 3);
      expect(TipoEscalada.solo.codigo, 4);
    });

    test('retorna os rótulos amigáveis em português brasileiro', () {
      expect(TipoEscalada.guiado.rotulo, 'Guiado');
      expect(TipoEscalada.topRope.rotulo, 'Top Rope');
      expect(TipoEscalada.boulder.rotulo, 'Boulder');
      expect(TipoEscalada.solo.rotulo, 'Solo');
    });

    test('diferencia modalidades de via e boulder', () {
      expect(TipoEscalada.guiado.isBoulder, isFalse);
      expect(TipoEscalada.topRope.isBoulder, isFalse);
      expect(TipoEscalada.solo.isBoulder, isFalse);
      expect(TipoEscalada.boulder.isBoulder, isTrue);

      expect(TipoEscalada.guiado.isVia, isTrue);
      expect(TipoEscalada.topRope.isVia, isTrue);
      expect(TipoEscalada.solo.isVia, isTrue);
      expect(TipoEscalada.boulder.isVia, isFalse);
    });

    test('fromCodigo mapeia códigos com segurança e valor padrão', () {
      expect(TipoEscalada.fromCodigo(1), TipoEscalada.guiado);
      expect(TipoEscalada.fromCodigo(2), TipoEscalada.topRope);
      expect(TipoEscalada.fromCodigo(3), TipoEscalada.boulder);
      expect(TipoEscalada.fromCodigo(4), TipoEscalada.solo);
      expect(TipoEscalada.fromCodigo(null), TipoEscalada.guiado);
      expect(TipoEscalada.fromCodigo(42), TipoEscalada.guiado);
    });

    test('fromString mapeia nomes textuais com segurança', () {
      expect(TipoEscalada.fromString('guiado'), TipoEscalada.guiado);
      expect(TipoEscalada.fromString('topRope'), TipoEscalada.topRope);
      expect(TipoEscalada.fromString('boulder'), TipoEscalada.boulder);
      expect(TipoEscalada.fromString('solo'), TipoEscalada.solo);
      expect(TipoEscalada.fromString(null), TipoEscalada.guiado);
      expect(TipoEscalada.fromString('invalido'), TipoEscalada.guiado);
    });
  });
}
