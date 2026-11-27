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

  const PicoRelevoReferencia({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.altitudeBaseMetros,
    required this.altitudePicoMetros,
    this.dimensaoGradeDem = 0,
    this.raioGradeDemGraus = 0.024,
    this.gradeDemMetros = const [],
  });

  /// Verdadeiro quando o pico dispõe de matriz altimétrica real de satélite válida.
  bool get temGradeDemReal =>
      dimensaoGradeDem >= 2 &&
      gradeDemMetros.length == dimensaoGradeDem * dimensaoGradeDem &&
      raioGradeDemGraus > 0;
}

/// Trecho direcionado de rodovia percorrido pela onda de luz laranja Aresta a partir de Belo Horizonte.
class TrechoPropagacaoViaria {
  final List<Offset> verticesLonLat;
  final double tempoInicio;
  final double tempoFim;

  const TrechoPropagacaoViaria({
    required this.verticesLonLat,
    required this.tempoInicio,
    required this.tempoFim,
  });
}

/// Cidade classificada no mapa viário entre relevante para escalada Aresta (contorno viário iluminado)
/// ou cidade puramente de referência geográfica (ponto branco limpo).
class CidadeClassificadaMapa {
  final LocalidadeRegionalMapa localidade;
  final bool ehRelevanteAresta;
  final double tempoAtivacao;
  final List<List<Offset>> viasUrbanasLonLat;

  const CidadeClassificadaMapa({
    required this.localidade,
    required this.ehRelevanteAresta,
    required this.tempoAtivacao,
    required this.viasUrbanasLonLat,
  });
}

/// Modelo imutável da rede viária Aresta originada no centro de Belo Horizonte,
/// totalmente desacoplado de estado mutável estático, serviços ou widgets de UI.
class RedeViariaArestaGlobo {
  /// Coordenada central de Belo Horizonte (Praça Sete / Av. do Contorno) onde nasce o pulso luminoso.
  static const double latitudeCentroBeloHorizonte = -19.9191;
  static const double longitudeCentroBeloHorizonte = -43.9386;

  final List<RodoviaRegionalMapa> rodoviasFundo;
  final List<TrechoPropagacaoViaria> trechosCorredorAresta;
  final List<CidadeClassificadaMapa> cidadesClassificadas;

  const RedeViariaArestaGlobo({
    required this.rodoviasFundo,
    required this.trechosCorredorAresta,
    required this.cidadesClassificadas,
  });
}

