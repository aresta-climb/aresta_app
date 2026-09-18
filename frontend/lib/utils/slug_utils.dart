// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

/// Mapa de substituição de caracteres com acentos e diacríticos para caracteres ASCII simples.
const Map<String, String> _mapaDiacriticos = {
  'á': 'a', 'à': 'a', 'ã': 'a', 'â': 'a', 'ä': 'a',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
  'ó': 'o', 'ò': 'o', 'õ': 'o', 'ô': 'o', 'ö': 'o',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
  'ç': 'c', 'ñ': 'n',
  'Á': 'a', 'À': 'a', 'Ã': 'a', 'Â': 'a', 'Ä': 'a',
  'É': 'e', 'È': 'e', 'Ê': 'e', 'Ë': 'e',
  'Í': 'i', 'Ì': 'i', 'Î': 'i', 'Ï': 'i',
  'Ó': 'o', 'Ò': 'o', 'Õ': 'o', 'Ô': 'o', 'Ö': 'o',
  'Ú': 'u', 'Ù': 'u', 'Û': 'u', 'Ü': 'u',
  'Ç': 'c', 'Ñ': 'n',
};

/// Converte um texto qualquer em um slug seguro e padronizado para URLs e comparação de rotas.
///
/// Remove acentos, pontuações e caracteres especiais, convertendo espaços e hífens
/// em underlines (`_`), colapsando múltiplos separadores e removendo-os das extremidades.
///
/// Exemplo:
/// ```dart
/// slugify("Grupo Estacionamento") // "grupo_estacionamento"
/// slugify("Falésia da Esperança") // "falesia_da_esperanca"
/// ```
String slugify(String texto) {
  if (texto.trim().isEmpty) return '';

  var resultado = texto.trim().toLowerCase();

  // Substitui caracteres acentuados pelos equivalentes ASCII
  final buffer = StringBuffer();
  for (var i = 0; i < resultado.length; i++) {
    final char = resultado[i];
    buffer.write(_mapaDiacriticos[char] ?? char);
  }
  resultado = buffer.toString();

  // Substitui espaços, hífens e separadores comuns por underline
  resultado = resultado.replaceAll(RegExp(r'[\s\-]+'), '_');

  // Remove qualquer caractere que não seja letra minúscula ASCII, dígito ou underline
  resultado = resultado.replaceAll(RegExp(r'[^a-z0-9_]'), '');

  // Colapsa múltiplos underlines consecutivos
  resultado = resultado.replaceAll(RegExp(r'_+'), '_');

  // Remove underlines no início e no final
  resultado = resultado.replaceAll(RegExp(r'^_+|_+$'), '');

  return resultado;
}

/// Verifica se dois textos ou nomes produzem o mesmo slug normalizado.
///
/// Útil para comparar nomes vindos do Protobuf com caminhos de URL ou QR Codes,
/// permitindo correspondência exata ou flexível (ex: "bloco_fugitivos_i" e "fugitivos_i").
bool slugsCoincidem(String textoA, String textoB) {
  final slugA = slugify(textoA);
  final slugB = slugify(textoB);
  if (slugA.isEmpty || slugB.isEmpty) return false;
  if (slugA == slugB) return true;

  final semPrefixoA = slugA.replaceFirst(RegExp(r'^(setor|bloco|grupo)_'), '');
  final semPrefixoB = slugB.replaceFirst(RegExp(r'^(setor|bloco|grupo)_'), '');
  return semPrefixoA.isNotEmpty && semPrefixoA == semPrefixoB;
}

