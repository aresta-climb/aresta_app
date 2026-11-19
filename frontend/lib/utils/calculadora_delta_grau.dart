// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../aresta_api/proto/generated/croqui.pbenum.dart';
import '../data/modelos/interacao_via.dart';
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

/// Formata o rótulo legível de um [codigo] Protobuf de grau (`'6ºsup'`, `'7b'`, `'v5'`),
/// retornando `null` quando indefinido ou `PROJETO`.
String? formatarGrauPorCodigo(int? codigo, {required bool ehBoulder}) {
  if (codigo == null) return null;
  if (ehBoulder) {
    final enumBoulder = GrauBoulder_GrauBoulder.valueOf(codigo);
    if (enumBoulder == null ||
        enumBoulder == GrauBoulder_GrauBoulder.INDEFINIDO ||
        enumBoulder == GrauBoulder_GrauBoulder.PROJETO) {
      return null;
    }
    return formatarTextoGrau(enumBoulder.name);
  }

  final enumVia = GrauVia_GrauVia.valueOf(codigo);
  if (enumVia == null ||
      enumVia == GrauVia_GrauVia.INDEFINIDO ||
      enumVia == GrauVia_GrauVia.PROJETO) {
    return null;
  }
  return formatarTextoGrau(enumVia.name);
}

/// Constrói o rótulo compacto exibido nos botões de avaliação de grau (`-2` a `+2`).
String rotuloOpcaoDeltaGrau(
  int delta, {
  int? codigoOficial,
  required bool ehBoulder,
}) {
  final codigoAlvo = deslocarCodigoGrau(
    codigoOficial,
    delta,
    ehBoulder: ehBoulder,
  );
  final textoGrau = formatarGrauPorCodigo(codigoAlvo, ehBoulder: ehBoulder);

  if (delta == 0) {
    return textoGrau != null ? 'Justo ($textoGrau)' : 'Grau Justo (0)';
  }
  final prefixo = delta > 0 ? '+$delta' : '$delta';
  return textoGrau != null ? '$prefixo ($textoGrau)' : prefixo;
}

/// Consolida uma coleção de votos (`deltaGrau` e/ou `grauSugerido`) em [ConsensoGrauVia].
ConsensoGrauVia consolidarConsensoDeVotos({
  required List<({int? deltaGrau, int? grauSugerido})> votos,
  int? codigoGrauOficial,
  required bool ehBoulder,
}) {
  if (votos.isEmpty) {
    return const ConsensoGrauVia.vazio();
  }

  final contagemDeltas = <int, int>{};
  final contagemCodigos = <int, int>{};

  for (final v in votos) {
    if (v.deltaGrau != null) {
      contagemDeltas[v.deltaGrau!] = (contagemDeltas[v.deltaGrau!] ?? 0) + 1;
    }
    final codEfetivo =
        v.grauSugerido ??
        (v.deltaGrau != null
            ? deslocarCodigoGrau(
                codigoGrauOficial,
                v.deltaGrau!,
                ehBoulder: ehBoulder,
              )
            : null);
    if (codEfetivo != null) {
      contagemCodigos[codEfetivo] = (contagemCodigos[codEfetivo] ?? 0) + 1;
    }
  }

  String? grauConsensoTexto;
  if (codigoGrauOficial != null && contagemDeltas.isNotEmpty) {
    var deltaModa = 0;
    var maiorFreq = -1;
    for (final entrada in contagemDeltas.entries) {
      if (entrada.value > maiorFreq) {
        maiorFreq = entrada.value;
        deltaModa = entrada.key;
      }
    }
    final codigoModa = deslocarCodigoGrau(
      codigoGrauOficial,
      deltaModa,
      ehBoulder: ehBoulder,
    );
    grauConsensoTexto = formatarGrauPorCodigo(codigoModa, ehBoulder: ehBoulder);
  } else if (contagemCodigos.isNotEmpty) {
    var codigoModa = contagemCodigos.keys.first;
    var maiorFreq = -1;
    for (final entrada in contagemCodigos.entries) {
      if (entrada.value > maiorFreq) {
        maiorFreq = entrada.value;
        codigoModa = entrada.key;
      }
    }
    grauConsensoTexto = formatarGrauPorCodigo(codigoModa, ehBoulder: ehBoulder);
  }

  if (grauConsensoTexto == null) {
    return const ConsensoGrauVia.vazio();
  }

  return ConsensoGrauVia(
    grauSugerido: grauConsensoTexto,
    totalVotos: votos.length,
    distribuicaoDeltas: Map.unmodifiable(contagemDeltas),
  );
}
