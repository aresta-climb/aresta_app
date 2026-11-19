// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../aresta_api/proto/generated/croqui.pbenum.dart';
import 'formatador_escalada.dart';

/// Escada ordenada de graus inteiros brasileiros de vias (excluindo `INDEFINIDO`, `PROJETO` e graus com `_BARRA_`).
final List<GrauVia_GrauVia> _escadaGrausViaInteiros = GrauVia_GrauVia.values
    .where(
      (g) =>
          g != GrauVia_GrauVia.INDEFINIDO &&
          g != GrauVia_GrauVia.PROJETO &&
          !g.name.contains('_BARRA_'),
    )
    .toList(growable: false);

/// Escada ordenada de graus inteiros V de boulders (excluindo `INDEFINIDO`, `PROJETO` e graus com `_BARRA_`).
final List<GrauBoulder_GrauBoulder> _escadaGrausBoulderInteiros =
    GrauBoulder_GrauBoulder.values
        .where(
          (g) =>
              g != GrauBoulder_GrauBoulder.INDEFINIDO &&
              g != GrauBoulder_GrauBoulder.PROJETO &&
              !g.name.contains('_BARRA_'),
        )
        .toList(growable: false);

/// Calcula o código numérico Protobuf resultante ao aplicar um [delta] (`-2` a `+2`)
/// sobre [codigoOficial], tratando tanto graus inteiros (`7a` + `1` -> `7b`) quanto
/// graus divididos com barra (`6ºsup/7a` - `1` -> `6ºsup`, `+1` -> `7a`).
int? deslocarCodigoGrau(
  int? codigoOficial,
  int delta, {
  required bool ehBoulder,
}) {
  if (codigoOficial == null) return null;

  if (ehBoulder) {
    final atual = GrauBoulder_GrauBoulder.valueOf(codigoOficial);
    if (atual == null ||
        atual == GrauBoulder_GrauBoulder.INDEFINIDO ||
        atual == GrauBoulder_GrauBoulder.PROJETO) {
      return null;
    }
    if (delta == 0) return atual.value;

    if (atual.name.contains('_BARRA_')) {
      final partes = atual.name.split('_BARRA_');
      final idxBase = _escadaGrausBoulderInteiros.indexWhere(
        (g) => g.name == partes.first,
      );
      final indiceAlvo = delta < 0 ? idxBase + delta + 1 : idxBase + delta;
      return _escadaGrausBoulderInteiros[_limitarIndice(
        indiceAlvo,
        _escadaGrausBoulderInteiros.length,
      )].value;
    }

    final idx = _escadaGrausBoulderInteiros.indexOf(atual);
    return _escadaGrausBoulderInteiros[_limitarIndice(
      idx + delta,
      _escadaGrausBoulderInteiros.length,
    )].value;
  }

  final atual = GrauVia_GrauVia.valueOf(codigoOficial);
  if (atual == null ||
      atual == GrauVia_GrauVia.INDEFINIDO ||
      atual == GrauVia_GrauVia.PROJETO) {
    return null;
  }
  if (delta == 0) return atual.value;

  if (atual.name.contains('_BARRA_')) {
    final partes = atual.name.split('_BARRA_');
    final nomeInferior = 'BR_${partes.first.replaceFirst('BR_', '')}';
    final idxBase = _escadaGrausViaInteiros.indexWhere(
      (g) => g.name == nomeInferior,
    );
    final indiceAlvo = delta < 0 ? idxBase + delta + 1 : idxBase + delta;
    return _escadaGrausViaInteiros[_limitarIndice(
      indiceAlvo,
      _escadaGrausViaInteiros.length,
    )].value;
  }

  final idx = _escadaGrausViaInteiros.indexOf(atual);
  return _escadaGrausViaInteiros[_limitarIndice(
    idx + delta,
    _escadaGrausViaInteiros.length,
  )].value;
}

int _limitarIndice(int indice, int tamanho) {
  if (indice < 0) return 0;
  if (indice >= tamanho) return tamanho - 1;
  return indice;
}

