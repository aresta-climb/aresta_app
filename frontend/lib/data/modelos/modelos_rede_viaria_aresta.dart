// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:ui';

/// Polígono vetorial nomeado em coordenadas geográficas `(longitude, latitude)`.
class PoligonoGeografico {
  final String id;
  final List<Offset> verticesLonLat;

  const PoligonoGeografico({
    required this.id,
    required this.verticesLonLat,
  });
}

/// Município ou localidade real do IBGE hierarquizada em 3 níveis (`1` polo regional, `2` cidade-base, `3` local).
class LocalidadeRegionalMapa {
  final String nome;
  final bool ehCidade;
  final int nivel;
  final double longitude;
  final double latitude;

  const LocalidadeRegionalMapa({
    required this.nome,
    required this.ehCidade,
    this.nivel = 1,
    required this.longitude,
    required this.latitude,
  });
}

/// Trecho de rodovia federal ou estadual real exibido sobre o terreno contínuo detalhado.
class RodoviaRegionalMapa {
  final bool ehPrincipal;
  final String codigo;
  final List<Offset> verticesLonLat;

  const RodoviaRegionalMapa({
    required this.ehPrincipal,
    required this.codigo,
    required this.verticesLonLat,
  });
}

/// Referência geomorfológica e grade DEM de satélite (`NASA SRTM 30m`) de um pico para os `LODs 2–3`.
class PicoRelevoReferencia {
  final String id;
  final double latitude;
  final double longitude;
  final int altitudeBaseMetros;
  final int altitudePicoMetros;
  final int dimensaoGradeDem;
  final double raioGradeDemGraus;
  final List<int> gradeDemMetros;

