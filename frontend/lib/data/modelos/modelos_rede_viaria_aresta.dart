// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;
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

/// Trecho de rodovia pavimentada real (`OpenStreetMap`) hierarquizada em 3 níveis:
/// `1` (`motorway/trunk`), `2` (`primary`) e `3` (`secondary/tertiary` de acesso aos picos).
class RodoviaRegionalMapa {
  final bool ehPrincipal;
  final int nivelViario;
  final String codigo;
  final List<Offset> verticesLonLat;
  final double minLon;
  final double maxLon;
  final double minLat;
  final double maxLat;

  const RodoviaRegionalMapa({
    required this.ehPrincipal,
    int? nivelViario,
    required this.codigo,
    required this.verticesLonLat,
    this.minLon = -180.0,
    this.maxLon = 180.0,
    this.minLat = -90.0,
    this.maxLat = 90.0,
  }) : nivelViario = nivelViario ?? (ehPrincipal ? 1 : 2);

  /// Constrói uma rodovia pré-computando sua caixa envolvente geográfica para descarte em `O(1)`.
  factory RodoviaRegionalMapa.comLimites({
    required bool ehPrincipal,
    int? nivelViario,
    required String codigo,
    required List<Offset> verticesLonLat,
  }) {
    final nivelResolvido = (nivelViario ?? (ehPrincipal ? 1 : 2)).clamp(1, 3);
    if (verticesLonLat.isEmpty) {
      return RodoviaRegionalMapa(
        ehPrincipal: ehPrincipal,
        nivelViario: nivelResolvido,
        codigo: codigo,
        verticesLonLat: verticesLonLat,
        minLon: 0.0,
        maxLon: 0.0,
        minLat: 0.0,
        maxLat: 0.0,
      );
    }
    var xMin = verticesLonLat.first.dx;
    var xMax = xMin;
    var yMin = verticesLonLat.first.dy;
    var yMax = yMin;
    for (var i = 1; i < verticesLonLat.length; i++) {
      final p = verticesLonLat[i];
      if (p.dx < xMin) xMin = p.dx;
      if (p.dx > xMax) xMax = p.dx;
      if (p.dy < yMin) yMin = p.dy;
      if (p.dy > yMax) yMax = p.dy;
    }
    return RodoviaRegionalMapa(
      ehPrincipal: ehPrincipal,
      nivelViario: nivelResolvido,
      codigo: codigo,
      verticesLonLat: verticesLonLat,
      minLon: xMin,
      maxLon: xMax,
      minLat: yMin,
      maxLat: yMax,
    );
  }

  /// Desserializa um registro viário JSON (`malha_globo_brasil.json` ou `snapshots_malha_viaria_picos`).
  factory RodoviaRegionalMapa.deMapa(Map<String, dynamic> mapa) {
    final classe = (mapa['classe'] as String?) ?? '';
    final ehPrinc = classe == 'principal' || (mapa['nivel'] as num?)?.toInt() == 1;
    final nivelBruto = (mapa['nivel'] as num?)?.toInt() ?? (ehPrinc ? 1 : 2);
    final poligonoBruto = (mapa['poligono'] as List<dynamic>?) ?? const [];
    final vertices = poligonoBruto
        .map((par) {
          final p = par as List<dynamic>;
          return Offset((p[0] as num).toDouble(), (p[1] as num).toDouble());
        })
        .toList(growable: false);
    return RodoviaRegionalMapa.comLimites(
      ehPrincipal: nivelBruto == 1,
      nivelViario: nivelBruto.clamp(1, 3),
      codigo: (mapa['codigo'] as String?) ?? '',
      verticesLonLat: vertices,
    );
  }

  /// Serializa a rodovia para persistência local de 2 slots em disco.
  Map<String, dynamic> paraMapa() => <String, dynamic>{
        'classe': nivelViario == 1 ? 'principal' : 'secundaria',
        'nivel': nivelViario,
        'codigo': codigo,
        'poligono': verticesLonLat
            .map((v) => <double>[v.dx, v.dy])
            .toList(growable: false),
      };

  /// Verifica em `O(1)` se a caixa envolvente da rodovia intercepta a janela visível da câmera.
  bool interceptaJanela({
    required double janelaMinLon,
    required double janelaMaxLon,
    required double janelaMinLat,
    required double janelaMaxLat,
  }) =>
      maxLon >= janelaMinLon &&
      minLon <= janelaMaxLon &&
      maxLat >= janelaMinLat &&
      minLat <= janelaMaxLat;
}

/// Snapshot offline-first da malha viária hierárquica sincronizado via Supabase (`atual` / `copia_seguranca`).
class SnapshotMalhaViariaOffline {
  final DateTime geradoEm;
  final String versaoHash;
  final List<RodoviaRegionalMapa> rodovias;

  const SnapshotMalhaViariaOffline({
    required this.geradoEm,
    required this.versaoHash,
    required this.rodovias,
  });

  /// Constrói [SnapshotMalhaViariaOffline] validando o payload JSON persistido ou remoto.
  factory SnapshotMalhaViariaOffline.deMapa(Map<String, dynamic> mapa) {
    final versao = (mapa['versao_hash'] as String?)?.trim() ?? '';
    final listaBruta = mapa['rodovias'];
    if (versao.isEmpty || listaBruta is! List) {
      throw const FormatException('Snapshot de malha viária inválido.');
    }
    final geradoTexto = mapa['gerado_em'] as String?;
    final gerado = (geradoTexto != null ? DateTime.tryParse(geradoTexto) : null)
            ?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final rodoviasLidas = listaBruta
        .whereType<Map>()
        .map((item) => RodoviaRegionalMapa.deMapa(Map<String, dynamic>.from(item)))
        .where((r) => r.verticesLonLat.length >= 2)
        .toList(growable: false);
    if (rodoviasLidas.isEmpty) {
      throw const FormatException('Snapshot de malha viária sem rodovias válidas.');
    }
    return SnapshotMalhaViariaOffline(
      geradoEm: gerado,
      versaoHash: versao,
      rodovias: rodoviasLidas,
    );
  }

  /// Converte o snapshot para JSON persistível nos slots `atual` e `seguranca`.
  Map<String, dynamic> paraMapa() => <String, dynamic>{
        'gerado_em': geradoEm.toUtc().toIso8601String(),
        'versao_hash': versaoHash,
        'rodovias': rodovias
            .take(math.max(1, rodovias.length))
            .map((r) => r.paraMapa())
            .toList(growable: false),
      };
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
