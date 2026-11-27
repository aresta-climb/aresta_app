// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;
import 'dart:ui';

import '../data/modelos/modelos_rede_viaria_aresta.dart';

/// Construtor funcional puro e sem estado (stateless) da árvore de caminhos mínimos rodoviários reais
/// entre o centro de Belo Horizonte e cada nó de pico Aresta, classificando cidades relevantes vs referência.
abstract final class ConstrutorRedeViariaAresta {
  static const double _grausParaRad = math.pi / 180.0;

  /// Constrói deterministicamente [RedeViariaArestaGlobo] a partir de [rodovias], [localidades] e [picos],
  /// utilizando exclusivamente geometrias viárias reais (sem anéis poligonais sintéticos ou retas irreais).
  static RedeViariaArestaGlobo construir({
    required List<RodoviaRegionalMapa> rodovias,
    required List<LocalidadeRegionalMapa> localidades,
    required List<PicoRelevoReferencia> picos,
  }) {
    final rodoviasNormalizadas = rodovias
        .map(
          (r) => RodoviaRegionalMapa(
            ehPrincipal: r.ehPrincipal,
            codigo: _limparCodigoEscudoRodovia(r.codigo),
            verticesLonLat: r.verticesLonLat,
          ),
        )
        .toList(growable: false);

    if (rodoviasNormalizadas.isEmpty || picos.isEmpty) {
      return _construirSemCorredores(
        rodovias: rodoviasNormalizadas,
        localidades: localidades,
      );
    }

    final nos = <Offset>[];
    final indicePorChave = <int, int>{};
    final pontasPolilinhas = <int>{};

    int obterOuCriarNo(Offset pt) {
      // Quantização fina (~34 m) preservando geometria real das curvas rodoviárias OSRM
      final qLon = (pt.dx * 3200.0).round() + 1000000;
      final qLat = (pt.dy * 3200.0).round() + 1000000;
      final chave = qLon * 2000003 + qLat;
      final existente = indicePorChave[chave];
      if (existente != null) return existente;
      final novo = nos.length;
      nos.add(pt);
      indicePorChave[chave] = novo;
      return novo;
    }

    final adj = <List<({int vizinho, double pesoKm, bool virtual})>>[];
    void garantirAdj(int n) {
      while (adj.length <= n) {
        adj.add(<({int vizinho, double pesoKm, bool virtual})>[]);
      }
    }

    for (final via in rodoviasNormalizadas) {
      final verts = via.verticesLonLat;
      if (verts.length < 2) continue;
      final ids = verts.map(obterOuCriarNo).toList(growable: false);
      garantirAdj(nos.length - 1);
      pontasPolilinhas
        ..add(ids.first)
        ..add(ids.last);
      for (var i = 0; i < ids.length - 1; i++) {
        final u = ids[i];
        final v = ids[i + 1];
        if (u == v) continue;
        final w = math.max(0.02, _distanciaKm(nos[u], nos[v]));
        adj[u].add((vizinho: v, pesoKm: w, virtual: false));
        adj[v].add((vizinho: u, pesoKm: w, virtual: false));
      }
    }

    if (nos.length < 2) {
      return _construirSemCorredores(
        rodovias: rodoviasNormalizadas,
        localidades: localidades,
      );
    }

    // Ponte virtual estritamente curta (<= 0,45 km) para conectar alças de trevos sem nunca desenhar retas aéreas
    for (final u in pontasPolilinhas) {
      final pu = nos[u];
      for (var v = 0; v < nos.length; v++) {
        if (u == v) continue;
        final pv = nos[v];
        if ((pu.dx - pv.dx).abs() > 0.0045 || (pu.dy - pv.dy).abs() > 0.0045) {
          continue;
        }
        final d = _distanciaKm(pu, pv);
        if (d <= 0.45) {
          adj[u].add((vizinho: v, pesoKm: d * 1.15, virtual: true));
          adj[v].add((vizinho: u, pesoKm: d * 1.15, virtual: true));
        }
      }
    }

    const centroBh = Offset(
      RedeViariaArestaGlobo.longitudeCentroBeloHorizonte,
      RedeViariaArestaGlobo.latitudeCentroBeloHorizonte,
    );
    var origemBh = 0;
    var menorDistBh = double.infinity;
    for (var i = 0; i < nos.length; i++) {
      final d = _distanciaKm(nos[i], centroBh);
      if (d < menorDistBh) {
        menorDistBh = d;
        origemBh = i;
      }
    }

    final totalNos = nos.length;
    final distKm = List<double>.filled(totalNos, double.infinity);
    final pai = List<int>.filled(totalNos, -1);
    final arestaPaiVirtual = List<bool>.filled(totalNos, false);
    distKm[origemBh] = 0.0;

    final fila = _FilaPrioridadeMinima()..inserir(origemBh, 0.0);
    while (!fila.estaVazia) {
      final atual = fila.removerMinimo();
      if (atual.custo > distKm[atual.no] + 1e-6) continue;
      for (final ar in adj[atual.no]) {
        final novoCusto = atual.custo + ar.pesoKm;
        if (novoCusto + 1e-6 < distKm[ar.vizinho]) {
          distKm[ar.vizinho] = novoCusto;
          pai[ar.vizinho] = atual.no;
          arestaPaiVirtual[ar.vizinho] = ar.virtual;
          fila.inserir(ar.vizinho, novoCusto);
        }
      }
    }

    final arestasAtivas = <int, ({int u, int v})>{};
    final nosCorredor = <int>{origemBh};
    final ramaisCurtoAcesso =
        <({Offset de, Offset para, double dIni, double dFim})>[];
    var maiorDistTotalKm = 18.0;

    for (final pico in picos) {
      final alvo = Offset(pico.longitude, pico.latitude);
      var melhorNo = origemBh;
      var menorGapKm = _distanciaKm(nos[origemBh], alvo);
      for (var i = 0; i < totalNos; i++) {
        if (!distKm[i].isFinite) continue;
        final d = _distanciaKm(nos[i], alvo);
        if (d < menorGapKm) {
          menorGapKm = d;
          melhorNo = i;
        }
      }

      final distChegadaPico = distKm[melhorNo] + menorGapKm;
      if (distChegadaPico > maiorDistTotalKm) {
        maiorDistTotalKm = distChegadaPico;
      }
      // Apenas trilha curtíssima de estacionamento -> base da pedra (<= 1,4 km)
      if (menorGapKm > 0.12 && menorGapKm <= 1.4) {
        ramaisCurtoAcesso.add((
          de: nos[melhorNo],
          para: alvo,
          dIni: distKm[melhorNo],
          dFim: distChegadaPico,
        ));
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

    for (final ramal in ramaisCurtoAcesso) {
      final tIni = normalizarTempo(ramal.dIni);
      final tFim = math.max(tIni + 0.020, normalizarTempo(ramal.dFim));
      trechos.add(
        TrechoPropagacaoViaria(
          verticesLonLat: <Offset>[ramal.de, ramal.para],
          tempoInicio: tIni,
          tempoFim: tFim.clamp(0.0, 1.0),
        ),
      );
    }
    trechos.sort((a, b) => a.tempoInicio.compareTo(b.tempoInicio));

    final cidades = _classificarCidades(
      localidades: localidades,
      rodovias: rodoviasNormalizadas,
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

  /// Extrai exclusivamente os trechos de rodovias e avenidas arteriais REAIS que cruzam o perímetro
  /// urbano de [loc], sem jamais fabricar polígonos artificiais ao redor da cidade.
  static List<List<Offset>> _extrairViasUrbanasReaisDaCidade({
    required LocalidadeRegionalMapa loc,
    required bool ehBh,
    required List<RodoviaRegionalMapa> rodovias,
  }) {
    final raioGraus = ehBh
        ? 0.115
        : (loc.nivel == 1 ? 0.048 : (loc.nivel == 2 ? 0.032 : 0.022));
    final cosLat = math.max(0.35, math.cos(loc.latitude * _grausParaRad));
    final r2 = raioGraus * raioGraus;
    final vias = <List<Offset>>[];

    for (final via in rodovias) {
      var sub = <Offset>[];
      for (final v in via.verticesLonLat) {
        final dx = (v.dx - loc.longitude) * cosLat;
        final dy = v.dy - loc.latitude;
        if (dx * dx + dy * dy <= r2) {
          sub.add(v);
        } else {
          if (sub.length >= 2) vias.add(sub);
          sub = <Offset>[];
        }
      }
      if (sub.length >= 2) vias.add(sub);
    }

    return List<List<Offset>>.unmodifiable(vias);
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
