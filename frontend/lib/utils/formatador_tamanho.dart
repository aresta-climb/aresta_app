// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

/// Utilitário puro responsável pela formatação e conversão de tamanhos em bytes
/// para representações textuais legíveis para humanos (B, KB, MB, GB).
class FormatadorTamanho {
  const FormatadorTamanho._();

  /// Converte uma quantidade de [bytes] em uma [String] amigável e legível.
  ///
  /// Exemplos de retorno:
  /// - `null` ou `<= 0` -> `'0 B'`
  /// - `512` -> `'512 B'`
  /// - `1536` -> `'1.5 KB'`
  /// - `19293798` -> `'18.4 MB'`
  /// - `1073741824` -> `'1.0 GB'`
  static String formatarBytes(int? bytes) {
    if (bytes == null || bytes <= 0) {
      return '0 B';
    }

    const int umKb = 1024;
    const int umMb = umKb * 1024;
    const int umGb = umMb * 1024;

    if (bytes < umKb) {
      return '$bytes B';
    } else if (bytes < umMb) {
      final valorKb = bytes / umKb;
      return '${valorKb.toStringAsFixed(1)} KB';
    } else if (bytes < umGb) {
      final valorMb = bytes / umMb;
      return '${valorMb.toStringAsFixed(1)} MB';
    } else {
      final valorGb = bytes / umGb;
      return '${valorGb.toStringAsFixed(1)} GB';
    }
  }
}
