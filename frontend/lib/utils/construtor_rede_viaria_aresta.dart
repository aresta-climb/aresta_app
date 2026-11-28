// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;
import 'dart:ui';

import '../data/modelos/modelos_rede_viaria_aresta.dart';
import 'geometria_clipping_mapa.dart';

typedef _ArestaGrafoViario = ({
  int vizinho,
  double custoPondKm,
  double distRealKm,
  bool virtual,
});

/// Construtor funcional puro e sem estado (stateless) da árvore de caminhos mínimos rodoviários reais
/// (`OpenStreetMap` `BR-xxx`) entre Belo Horizonte (ou a posição GPS do usuário) e os picos Aresta,
/// operando em `O(N log N)` via grade espacial `O(1)` sem cordas aéreas sobre serras.
abstract final class ConstrutorRedeViariaAresta {
  static const double _grausParaRad = math.pi / 180.0;
  static const double _passoCelulaEspacial = 0.016;

  /// Constrói deterministicamente [RedeViariaArestaGlobo] a partir de [rodovias], [localidades] e [picos],
  /// priorizando as rodovias federais principais (`BR-xxx`).
  static RedeViariaArestaGlobo construir({
    required List<RodoviaRegionalMapa> rodovias,
    required List<LocalidadeRegionalMapa> localidades,
    required List<PicoRelevoReferencia> picos,
  }) {
    final rodoviasNormalizadas = rodovias
        .map(
          (r) => RodoviaRegionalMapa.comLimites(
            ehPrincipal: r.ehPrincipal,
            nivelViario: r.nivelViario,
            codigo: _limparCodigoEscudoRodovia(r.codigo),
            verticesLonLat:
                GeometriaClippingMapa.suavizarCantosPolilinhaMundo(r.verticesLonLat),
          ),
        )
        .toList(growable: false);

    if (rodoviasNormalizadas.isEmpty || picos.isEmpty) {
      return _construirSemCorredores(
        rodovias: rodoviasNormalizadas,
        localidades: localidades,
      );
    }

    final grafo = _construirGrafoTopologico(rodoviasNormalizadas);
    if (grafo == null) {
      return _construirSemCorredores(
        rodovias: rodoviasNormalizadas,
        localidades: localidades,
      );
    }

    final nos = grafo.nos;
    const centroBh = Offset(
      RedeViariaArestaGlobo.longitudeCentroBeloHorizonte,
      RedeViariaArestaGlobo.latitudeCentroBeloHorizonte,
    );
    final origemBh = _encontrarNoMaisProximo(nos: nos, alvoLonLat: centroBh).indice;
    final caminhos = _executarDijkstra(
      totalNos: nos.length,
      adj: grafo.adj,
      noOrigem: origemBh,
    );

    final totalNos = nos.length;
    final distKm = caminhos.distKm;
    final pai = caminhos.pai;
    final arestaPaiVirtual = caminhos.arestaPaiVirtual;

    final arestasAtivas = <int, ({int u, int v})>{};
    final nosCorredor = <int>{origemBh};
    var maiorDistTotalKm = 18.0;

    for (final pico in picos) {
      final cosPico = math.cos(pico.latitude * _grausParaRad);
      var melhorNo = origemBh;
      var menorDist2 = double.infinity;
      for (var i = 0; i < totalNos; i++) {
        if (!distKm[i].isFinite) continue;
        final dx = (nos[i].dx - pico.longitude) * cosPico;
        final dy = nos[i].dy - pico.latitude;
        final d2 = dx * dx + dy * dy;
        if (d2 < menorDist2) {
          menorDist2 = d2;
          melhorNo = i;
        }
      }

      if (distKm[melhorNo] > maiorDistTotalKm) {
        maiorDistTotalKm = distKm[melhorNo];
      }

      var cursor = melhorNo;
      while (cursor >= 0) {
        nosCorredor.add(cursor);
        final p = pai[cursor];
        if (p < 0) break;
        if (!arestaPaiVirtual[cursor]) {
          arestasAtivas[p * totalNos + cursor] = (u: p, v: cursor);
        }
        cursor = p;
      }
    }

    double normalizarTempo(double dKm) {
      final frac = (dKm / maiorDistTotalKm).clamp(0.0, 1.0);
      return math.pow(frac, 0.58).toDouble();
    }

    final filhosNaArvore = <int, List<int>>{};
    final grauEntrada = <int, int>{};
    for (final ar in arestasAtivas.values) {
      (filhosNaArvore[ar.u] ??= <int>[]).add(ar.v);
      grauEntrada[ar.v] = (grauEntrada[ar.v] ?? 0) + 1;
    }

    final trechos = <TrechoPropagacaoViaria>[];
    for (final entrada in filhosNaArvore.entries) {
      final u = entrada.key;
      final ehRaizCadeia =
          (grauEntrada[u] ?? 0) != 1 || (filhosNaArvore[u]?.length ?? 0) != 1;
      if (!ehRaizCadeia) continue;

      for (final primeiroFilho in entrada.value) {
        final polilinha = <Offset>[nos[u], nos[primeiroFilho]];
        var atual = primeiroFilho;
        while ((filhosNaArvore[atual]?.length ?? 0) == 1 &&
            (grauEntrada[atual] ?? 0) == 1) {
          final prox = filhosNaArvore[atual]!.first;
          polilinha.add(nos[prox]);
          atual = prox;
        }
        final tIni = normalizarTempo(distKm[u]);
        final tFim = math.max(tIni + 0.025, normalizarTempo(distKm[atual]));
        trechos.add(
          TrechoPropagacaoViaria(
            verticesLonLat: polilinha,
            tempoInicio: tIni,
            tempoFim: tFim.clamp(0.0, 1.0),
          ),
        );
      }
    }
    trechos.sort((a, b) => a.tempoInicio.compareTo(b.tempoInicio));

    final cidades = _classificarCidades(
      localidades: localidades,
      nos: nos,
      distKm: distKm,
      nosCorredor: nosCorredor,
      picos: picos,
      normalizarTempo: normalizarTempo,
    );

    return RedeViariaArestaGlobo(
      rodoviasFundo: rodoviasNormalizadas,
      trechosCorredorAresta: List<TrechoPropagacaoViaria>.unmodifiable(trechos),
      cidadesClassificadas: List<CidadeClassificadaMapa>.unmodifiable(cidades),
    );
  }

  /// Calcula uma assinatura inteira leve para memoização de instância em ViewModels.
  static int calcularAssinaturaPicos(List<PicoRelevoReferencia> picos) {
    var h = picos.length;
    for (final p in picos) {
      h = (h * 37 + p.id.hashCode) & 0x3fffffff;
    }
    return h;
  }

  static String _limparCodigoEscudoRodovia(String bruto) {
    final limpo = bruto.trim().toUpperCase();
    // Ignora siglas genéricas sem número (ex.: 'MG', 'BR') vindas de bases antigas
    if (!limpo.contains('-') || limpo.length < 4) return '';
    return limpo;
  }

  static RedeViariaArestaGlobo _construirSemCorredores({
    required List<RodoviaRegionalMapa> rodovias,
    required List<LocalidadeRegionalMapa> localidades,
  }) {
    final referenciaApenas = localidades
        .map(
          (loc) => CidadeClassificadaMapa(
            localidade: loc,
            ehRelevanteAresta: false,
            tempoAtivacao: double.infinity,
            viasUrbanasLonLat: const [],
          ),
        )
        .toList(growable: false);
    return RedeViariaArestaGlobo(
      rodoviasFundo: rodovias,
      trechosCorredorAresta: const [],
      cidadesClassificadas: referenciaApenas,
    );
  }

  static List<CidadeClassificadaMapa> _classificarCidades({
    required List<LocalidadeRegionalMapa> localidades,
    required List<RodoviaRegionalMapa> rodovias,
    required List<Offset> nos,
    required List<double> distKm,
    required Set<int> nosCorredor,
    required List<PicoRelevoReferencia> picos,
    required double Function(double) normalizarTempo,
  }) {
    const centroBh = Offset(
      RedeViariaArestaGlobo.longitudeCentroBeloHorizonte,
      RedeViariaArestaGlobo.latitudeCentroBeloHorizonte,
    );
    final resultado = <CidadeClassificadaMapa>[];

    for (final loc in localidades) {
      final ptCidade = Offset(loc.longitude, loc.latitude);
      final distBh = _distanciaKm(ptCidade, centroBh);

      var menorDistCorredor = double.infinity;
      var distViariaChegada = 0.0;
      for (final idxNo in nosCorredor) {
        final d = _distanciaKm(ptCidade, nos[idxNo]);
        if (d < menorDistCorredor) {
          menorDistCorredor = d;
          distViariaChegada = distKm[idxNo];
        }
      }

      var menorDistPico = double.infinity;
      for (final p in picos) {
        final d = _distanciaKm(ptCidade, Offset(p.longitude, p.latitude));
        if (d < menorDistPico) menorDistPico = d;
      }

      final ehBh = distBh <= 7.5;
      final relevante =
          ehBh || menorDistCorredor <= 9.5 || menorDistPico <= 12.0;

      if (!relevante) {
        resultado.add(
          CidadeClassificadaMapa(
            localidade: loc,
            ehRelevanteAresta: false,
            tempoAtivacao: double.infinity,
            viasUrbanasLonLat: const [],
          ),
        );
        continue;
      }

      final tAtivacao = ehBh
          ? 0.0
          : normalizarTempo(distViariaChegada).clamp(0.02, 0.96);
      resultado.add(
        CidadeClassificadaMapa(
          localidade: loc,
          ehRelevanteAresta: true,
          tempoAtivacao: tAtivacao,
          viasUrbanasLonLat: _extrairViasUrbanasReaisDaCidade(
            loc: loc,
            ehBh: ehBh,
            rodovias: rodovias,
          ),
        ),
      );
    }

    return resultado;
  }

  /// Extrai exclusivamente as **artérias principais** que cruzam o perímetro urbano de [loc]
  /// (`motorway/trunk` em metrópoles; ou rodovia numerada em cidades-base menores), evitando
  /// iluminar malhas densas de avenidas secundárias e bairros residenciais.
  static List<List<Offset>> _extrairViasUrbanasReaisDaCidade({
    required LocalidadeRegionalMapa loc,
    required bool ehBh,
    required List<RodoviaRegionalMapa> rodovias,
  }) {
    final raioGraus = ehBh
        ? 0.078
        : (loc.nivel == 1 ? 0.038 : (loc.nivel == 2 ? 0.026 : 0.025));
    final cosLat = math.max(0.35, math.cos(loc.latitude * _grausParaRad));
    final raioLon = raioGraus / cosLat;
    final r2 = raioGraus * raioGraus;

    List<List<Offset>> coletar({required int maxNivel, required bool exigirCodigoNoNivel2}) {
      final encontradas = <List<Offset>>[];
      for (final via in rodovias) {
        if (via.nivelViario > maxNivel) continue;
        if (via.nivelViario == 2 && exigirCodigoNoNivel2 && via.codigo.isEmpty) {
          continue;
        }
        if (!via.interceptaJanela(
          janelaMinLon: loc.longitude - raioLon,
          janelaMaxLon: loc.longitude + raioLon,
          janelaMinLat: loc.latitude - raioGraus,
          janelaMaxLat: loc.latitude + raioGraus,
        )) {
          continue;
        }
        var sub = <Offset>[];
        for (final v in via.verticesLonLat) {
          final dx = (v.dx - loc.longitude) * cosLat;
          final dy = v.dy - loc.latitude;
          if (dx * dx + dy * dy <= r2) {
            sub.add(v);
          } else {
            if (sub.length >= 2) encontradas.add(sub);
            sub = <Offset>[];
          }
        }
        if (sub.length >= 2) encontradas.add(sub);
      }
      return encontradas;
    }

    // Em BH e polos regionais (nível 1), ilumina estritamente artérias principais (nível 1);
    // em pequenas cidades-base sem BR/trunk, permite a rodovia estadual principal que corta a cidade.
    final arteriasN1 = coletar(maxNivel: 1, exigirCodigoNoNivel2: true);
    if (ehBh || arteriasN1.isNotEmpty) {
      return List<List<Offset>>.unmodifiable(arteriasN1);
    }
    final arteriasN2 = coletar(maxNivel: 2, exigirCodigoNoNivel2: loc.nivel <= 2);
    if (arteriasN2.isNotEmpty || loc.nivel <= 2) {
      return List<List<Offset>>.unmodifiable(arteriasN2);
    }
    return List<List<Offset>>.unmodifiable(
      coletar(maxNivel: 3, exigirCodigoNoNivel2: false),
    );
  }

  static double _distanciaKm(Offset a, Offset b) {
    final cosLat = math.cos(((a.dy + b.dy) * 0.5) * _grausParaRad);
    final dxKm = (a.dx - b.dx) * cosLat * 111.32;
    final dyKm = (a.dy - b.dy) * 111.32;
    return math.sqrt(dxKm * dxKm + dyKm * dyKm);
  }
}

class _FilaPrioridadeMinima {
  final List<({int no, double custo})> _heap = <({int no, double custo})>[];

  bool get estaVazia => _heap.isEmpty;

  void inserir(int no, double custo) {
    _heap.add((no: no, custo: custo));
    var idx = _heap.length - 1;
    while (idx > 0) {
      final pai = (idx - 1) >> 1;
      if (_heap[pai].custo <= _heap[idx].custo) break;
      final tmp = _heap[pai];
      _heap[pai] = _heap[idx];
      _heap[idx] = tmp;
      idx = pai;
    }
  }

  ({int no, double custo}) removerMinimo() {
    final topo = _heap.first;
    final ultimo = _heap.removeLast();
    if (_heap.isNotEmpty) {
      _heap[0] = ultimo;
      var idx = 0;
      final n = _heap.length;
      while (true) {
        final esq = (idx << 1) + 1;
        final dir = esq + 1;
        var menor = idx;
        if (esq < n && _heap[esq].custo < _heap[menor].custo) menor = esq;
        if (dir < n && _heap[dir].custo < _heap[menor].custo) menor = dir;
        if (menor == idx) break;
        final tmp = _heap[idx];
        _heap[idx] = _heap[menor];
        _heap[menor] = tmp;
        idx = menor;
      }
    }
    return topo;
  }
}
