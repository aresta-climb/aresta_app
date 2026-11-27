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

