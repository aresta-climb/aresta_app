// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math';

/// Alfabeto Base62 padrão para geração de NanoIDs no ecossistema Aresta Climb.
const String alfabetoBase62 =
    '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';

/// Comprimento padrão de identificadores NanoID 14c.
const int comprimentoPadraoUid = 14;

/// Gera um NanoID de 14 caracteres Base62 criptograficamente seguro.
///
/// Utiliza [Random.secure] para garantir entropia resistente a colisões
/// ($62^{14} \approx 1{,}24 \times 10^{25}$ combinações).
String gerarUid([int comprimento = comprimentoPadraoUid]) {
  final random = Random.secure();
  return List.generate(
    comprimento,
    (_) => alfabetoBase62[random.nextInt(62)],
  ).join();
}

/// Valida se uma string é um NanoID válido de [comprimento] caracteres Base62.
bool validarUid(String? uid, [int comprimento = comprimentoPadraoUid]) {
  if (uid == null || uid.length != comprimento) {
    return false;
  }
  for (var i = 0; i < uid.length; i++) {
    final char = uid[i];
    final codigo = char.codeUnitAt(0);
    final isDigito = codigo >= 48 && codigo <= 57; // 0-9
    final isMaiuscula = codigo >= 65 && codigo <= 90; // A-Z
    final isMinuscula = codigo >= 97 && codigo <= 122; // a-z
    if (!isDigito && !isMaiuscula && !isMinuscula) {
      return false;
    }
  }
  return true;
}
