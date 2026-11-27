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
      // Quantização fina (~85 m) para costurar intersecções reais do OSRM/OpenStreetMap
      final qLon = (pt.dx * 1250.0).round() + 500000;
      final qLat = (pt.dy * 1250.0).round() + 500000;
      final chave = qLon * 1000003 + qLat;
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

    // Ponte curta (<= 2,2 km) apenas entre pontas de segmentos rodoviários adjacentes (trevos/viadutos)
    for (final u in pontasPolilinhas) {
      final pu = nos[u];
      for (var v = 0; v < nos.length; v++) {
        if (u == v) continue;
        final pv = nos[v];
        if ((pu.dx - pv.dx).abs() > 0.022 || (pu.dy - pv.dy).abs() > 0.022) {
          continue;
        }
        final d = _distanciaKm(pu, pv);
        if (d <= 2.2) {
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

    // Destaca também as vias arteriais reais dentro da mancha central de BH (<= 11 km)
    for (var u = 0; u < totalNos; u++) {
      if (!distKm[u].isFinite || distKm[u] > 11.0) continue;
      final p = pai[u];
      if (p >= 0 && !arestaPaiVirtual[u]) {
        arestasAtivas[p * totalNos + u] = (u: p, v: u);
        nosCorredor
          ..add(p)
          ..add(u);
      }
    }

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

