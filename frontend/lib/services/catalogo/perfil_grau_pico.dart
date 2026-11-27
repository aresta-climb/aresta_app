// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

/// Perfil imutável de distribuição de graduações (Vias e Boulders) de um pico,
/// extraído offline a partir da tabela `catalogo_aresta` (`catalogo.db`).
///
/// Permite que a aba `Explorar` filtre picos nacionais por intervalo de grau
/// (`1º` a `12a` e `V0` a `V15`) em tempo constante sem precisar abrir os
/// arquivos `.binarypb` completos dos croquis ainda não baixados.
class PerfilGrauPico {
  /// Contagem de vias por peso numérico de graduação (compatível com `OpcoesGrau.grausVia`).
  final Map<int, int> contagemPorPesoVia;

  /// Contagem de boulders por peso numérico da escala V (`OpcoesGrau.grausBoulder`).
  final Map<int, int> contagemPorPesoBoulder;

  const PerfilGrauPico({
    this.contagemPorPesoVia = const <int, int>{},
    this.contagemPorPesoBoulder = const <int, int>{},
  });

  /// Verifica se o pico possui ao menos uma via dentro de `[minPeso..maxPeso]`.
  bool atendeIntervaloVia(int? minPeso, int? maxPeso) {
    if (contagemPorPesoVia.isEmpty) return false;
    for (final peso in contagemPorPesoVia.keys) {
      if (minPeso != null && peso < minPeso) continue;
      if (maxPeso != null && peso > maxPeso) continue;
      return true;
    }
    return false;
  }

  /// Verifica se o pico possui ao menos um boulder dentro de `[minPeso..maxPeso]`.
  bool atendeIntervaloBoulder(int? minPeso, int? maxPeso) {
    if (contagemPorPesoBoulder.isEmpty) return false;
    for (final peso in contagemPorPesoBoulder.keys) {
      if (minPeso != null && peso < minPeso) continue;
      if (maxPeso != null && peso > maxPeso) continue;
      return true;
    }
    return false;
  }

  /// Soma o total de escaladas do pico que caem dentro dos intervalos fornecidos.
  int contarEscaladasNoIntervalo({
    int? minVia,
    int? maxVia,
    int? minBoulder,
    int? maxBoulder,
  }) {
    var soma = 0;
    if (minVia != null || maxVia != null) {
      for (final e in contagemPorPesoVia.entries) {
        if ((minVia == null || e.key >= minVia) &&
            (maxVia == null || e.key <= maxVia)) {
          soma += e.value;
        }
      }
    }
    if (minBoulder != null || maxBoulder != null) {
      for (final e in contagemPorPesoBoulder.entries) {
        if ((minBoulder == null || e.key >= minBoulder) &&
            (maxBoulder == null || e.key <= maxBoulder)) {
          soma += e.value;
        }
      }
    }
    return soma;
  }

  static final RegExp _regexBoulder = RegExp(r'^v(b|\d{1,2})$');
  static final RegExp _regexViaArabico = RegExp(r'^(\d{1,2})(sup|[abc])?$');

  /// Converte um rótulo textual de via brasileira (`'5sup'`, `'6º'`, `'7b'`, `'IVsup'`, `'6sup/7a'`)
  /// para o peso numérico canônico de `OpcoesGrau.grausVia` (`200..1310`).
  static int? converterGrauViaParaPeso(String? grauBruto) {
    if (grauBruto == null) return null;
    var limpo = grauBruto
        .trim()
        .toLowerCase()
        .split('/')
        .first
        .replaceAll('º', '')
        .replaceAll('°', '')
        .replaceAll(' ', '');
    if (limpo.isEmpty) return null;

    limpo = _substituirRomanoInicial(limpo);
    final match = _regexViaArabico.firstMatch(limpo);
    if (match == null) return null;

