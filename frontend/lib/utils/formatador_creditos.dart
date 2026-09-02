// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

/// Utilitário para validação e formatação de créditos/autores de croquis.
class FormatadorCreditos {
  /// Lista de termos genéricos que atuam como placeholders e não devem ser exibidos como autores.
  static const Set<String> _placeholders = {
    'autores do croqui original',
    'autores do croqui',
    'autor do croqui',
    'autores',
    'autor',
    'créditos',
    'creditos',
    'créditos do croqui',
    'desconhecido',
    'sem autor',
  };

  /// Verifica se uma string de crédito é um placeholder genérico ou vazia.
  static bool isPlaceholder(String credito) {
    final clean = credito.trim().toLowerCase();
    return clean.isEmpty || _placeholders.contains(clean);
  }

  /// Retorna apenas os créditos válidos que não sejam placeholders.
  static List<String> extrairCreditosValidos(List<String> creditos) {
    return creditos.where((c) => !isPlaceholder(c)).map((c) => c.trim()).toList();
  }

  /// Formata uma lista de créditos em uma frase amigável para exibição (ex: "Croqui por João Silva").
  /// Retorna `null` se não houver créditos válidos.
  static String? formatarLinhaCreditos(List<String> creditos) {
    final validos = extrairCreditosValidos(creditos);
    if (validos.isEmpty) return null;

    final joined = validos.join(', ');
    final lower = joined.toLowerCase();
    if (lower.startsWith('croqui') ||
        lower.startsWith('autor') ||
        lower.startsWith('crédito') ||
        lower.startsWith('credito')) {
      return joined;
    }

    return 'Croqui por $joined';
  }
}
