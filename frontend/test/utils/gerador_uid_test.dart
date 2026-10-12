// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/utils/gerador_uid.dart';

void main() {
  group('GeradorUid', () {
    test('gerarUid gera NanoID com 14 caracteres Base62', () {
      final uid = gerarUid();
      expect(uid.length, 14);
      expect(validarUid(uid), isTrue);
    });

    test('gerarUid gera valores distintos e criptograficamente aleatórios', () {
      final uids = List.generate(100, (_) => gerarUid()).toSet();
      expect(uids.length, 100);
    });

    test('validarUid aceita apenas strings com 14 caracteres Base62 válidos', () {
      expect(validarUid('x8siJek3FiG3aB'), isTrue);
      expect(validarUid('0123456789aBcD'), isTrue);

      // Comprimento incorreto
      expect(validarUid('curto'), isFalse);
      expect(validarUid('muitolongoparaoumidentificadorvalido'), isFalse);
      expect(validarUid(''), isFalse);
      expect(validarUid(null), isFalse);

      // Caracteres fora do alfabeto Base62
      expect(validarUid('x8siJek-FiG3aB'), isFalse); // hífen
      expect(validarUid('x8siJek_FiG3aB'), isFalse); // underline
      expect(validarUid('x8siJek@FiG3aB'), isFalse); // símbolo
      expect(validarUid('x8siJek FiG3aB'), isFalse); // espaço
    });
  });
}
