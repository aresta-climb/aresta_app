// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;
import '../../idioma/tradutor_app.dart';

/// Estado discreto e conservador de umidade superficial da rocha (janela de 4 dias
/// reiniciada a cada chuva regional próxima ao pico).
enum NivelUmidadePico {
  seco(peso: 0),
  possivelmenteUmido(peso: 1);

  /// Peso numérico crescente de severidade hídrica usado em comparações de dominância.
  final int peso;

  const NivelUmidadePico({required this.peso});

  /// Nome localizado apresentado nos avisos conservadores de picos com chuva próxima.
  String get rotulo => switch (this) {
        NivelUmidadePico.seco => tr(ChaveTexto.climaSeco),
        NivelUmidadePico.possivelmenteUmido =>
          tr(ChaveTexto.climaPossivelmenteUmido),
      };

  /// Verdadeiro quando houve chuva próxima na região dentro da janela conservadora de 4 dias.
  bool get estaUmido => this != NivelUmidadePico.seco;
}

/// Quatro níveis visuais de intensidade de precipitação ao vivo no radar do globo,
/// acionados pela análise hidrometeorológica (`mm/h` e células convectivas internas).
enum NivelIntensidadeChuva {
  fraca(peso: 1),
  moderada(peso: 2),
  forte(peso: 3),
  extrema(peso: 4);

  /// Peso ordinal (`1..4`) usado para escalar contraste cromático, gotas e trovoadas.
  final int peso;

  const NivelIntensidadeChuva({required this.peso});

  /// Rótulo localizado da faixa de intensidade da precipitação ao vivo.
  String get rotulo => switch (this) {
        NivelIntensidadeChuva.fraca => tr(ChaveTexto.climaChuvaFraca),
        NivelIntensidadeChuva.moderada => tr(ChaveTexto.climaChuvaModerada),
        NivelIntensidadeChuva.forte => tr(ChaveTexto.climaChuvaForte),
        NivelIntensidadeChuva.extrema => tr(ChaveTexto.climaTempestadeSevera),
      };
}

/// Vértice geográfico `(longitude, latitude)` pertencente à isoieta real de uma tempestade ou perímetro de incêndio.
class PontoContornoGeo {
  final double longitude;
  final double latitude;

  const PontoContornoGeo({
    required this.longitude,
    required this.latitude,
  });

  factory PontoContornoGeo.deLista(List<dynamic> par) {
    if (par.length < 2 || par[0] is! num || par[1] is! num) {
      throw const FormatException('PontoContornoGeo inválido.');
    }
    final lon = (par[0] as num).toDouble();
    final lat = (par[1] as num).toDouble();
    if (!lon.isFinite ||
        !lat.isFinite ||
        lat < -90.0 ||
        lat > 90.0 ||
        lon < -180.0 ||
        lon > 180.0) {
      throw const FormatException(
        'Coordenadas fora dos limites em PontoContornoGeo.',
      );
    }
    return PontoContornoGeo(longitude: lon, latitude: lat);
  }

  List<double> paraLista() => <double>[longitude, latitude];
}

/// Pegada geográfica histórica (`horasAtras` antes do instante atual) por onde a tempestade passou.
class RastroPassadoTempestade {
  final int horasAtras;
  final List<PontoContornoGeo> contorno;

  const RastroPassadoTempestade({
    required this.horasAtras,
    required this.contorno,
  });

  factory RastroPassadoTempestade.deMapa(Map<String, dynamic> mapa) {
    final horas = mapa['horas_atras'];
    final contornoBruto = mapa['contorno'];
    if (horas is! num ||
        horas <= 0 ||
        contornoBruto is! List ||
        contornoBruto.length < 3) {
      throw const FormatException('RastroPassadoTempestade inválido.');
    }
    return RastroPassadoTempestade(
      horasAtras: horas.round(),
      contorno: List<PontoContornoGeo>.unmodifiable(
        contornoBruto.map((p) => PontoContornoGeo.deLista(p as List<dynamic>)),
      ),
    );
  }

  Map<String, dynamic> paraMapa() => <String, dynamic>{
        'horas_atras': horasAtras,
        'contorno': contorno.map((p) => p.paraLista()).toList(growable: false),
      };
}

/// Sistema meteorológico de chuva ao vivo delimitado por contornos reais (isoietas) e vetor de vento.
class BolhaChuvaRegional {
  final String id;
  final double latitude;
  final double longitude;
  final double intensidadeMmHora;
  final double ventoRumoGraus;
  final double ventoVelocidadeKmh;
  final List<PontoContornoGeo> contornoExterno;
  final List<List<PontoContornoGeo>> nucleosIntensos;
  final List<RastroPassadoTempestade> rastrosPassados;

  const BolhaChuvaRegional({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.intensidadeMmHora,
    required this.ventoRumoGraus,
    required this.ventoVelocidadeKmh,
    required this.contornoExterno,
    this.nucleosIntensos = const [],
    this.rastrosPassados = const [],
  });

  /// Classifica o sistema em 4 níveis visuais combinando taxa de precipitação (`mm/h`)
  /// e multiplicidade de núcleos convectivos internos extraídos do radar/modelo.
  NivelIntensidadeChuva get nivelIntensidade {
    if (intensidadeMmHora >= 5.8 ||
        (intensidadeMmHora >= 4.0 && nucleosIntensos.length >= 2)) {
      return NivelIntensidadeChuva.extrema;
    }
    if (intensidadeMmHora >= 2.8 ||
        (intensidadeMmHora >= 2.2 && nucleosIntensos.isNotEmpty)) {
      return NivelIntensidadeChuva.forte;
    }
    if (intensidadeMmHora >= 0.9) {
      return NivelIntensidadeChuva.moderada;
    }
    return NivelIntensidadeChuva.fraca;
  }

  /// Retorna as pegadas passadas da tempestade (ordenadas da mais antiga para a mais recente),
  /// utilizando os contornos horários do Open-Meteo quando presentes ou retroprojetando pela
  /// cinemática real de `(ventoRumoGraus, ventoVelocidadeKmh)` quando ainda ausentes no snapshot.
  List<RastroPassadoTempestade> obterPegadasTrajetoria() {
    if (rastrosPassados.isNotEmpty) {
      return rastrosPassados;
    }
    final velEfetivaKmh = math.max(8.0, ventoVelocidadeKmh);
    final rumoRad = ventoRumoGraus * (math.pi / 180.0);
    final uLon = math.sin(rumoRad);
    final uLat = math.cos(rumoRad);
    final cosLat = math.max(0.28, math.cos(latitude * (math.pi / 180.0)));

    RastroPassadoTempestade projetarHorasAtras(int horas, double escalaForma) {
      final distKm = velEfetivaKmh * horas;
      final dLat = -(uLat * distKm) / 111.32;
      final dLon = -(uLon * distKm) / (111.32 * cosLat);
      final cLat = (latitude + dLat).clamp(-89.0, 89.0);
      final cLon = longitude + dLon;
      final vertices = contornoExterno.map((p) {
        final relLon = (p.longitude - longitude) * escalaForma;
        final relLat = (p.latitude - latitude) * escalaForma;
        var lon = cLon + relLon;
        if (lon > 180.0) lon -= 360.0;
        if (lon < -180.0) lon += 360.0;
        return PontoContornoGeo(
          longitude: lon,
          latitude: (cLat + relLat).clamp(-89.5, 89.5),
        );
      }).toList(growable: false);
      return RastroPassadoTempestade(horasAtras: horas, contorno: vertices);
    }

    return <RastroPassadoTempestade>[
      projetarHorasAtras(6, 0.84),
      projetarHorasAtras(3, 0.92),
    ];
  }

  double get minLon {
    var m = contornoExterno.first.longitude;
    for (final p in contornoExterno) {
      if (p.longitude < m) m = p.longitude;
    }
    return m;
  }

  double get maxLon {
    var m = contornoExterno.first.longitude;
    for (final p in contornoExterno) {
      if (p.longitude > m) m = p.longitude;
    }
    return m;
  }

  double get minLat {
    var m = contornoExterno.first.latitude;
    for (final p in contornoExterno) {
      if (p.latitude < m) m = p.latitude;
    }
    return m;
  }

  double get maxLat {
    var m = contornoExterno.first.latitude;
    for (final p in contornoExterno) {
      if (p.latitude > m) m = p.latitude;
    }
    return m;
  }

  factory BolhaChuvaRegional.deMapa(Map<String, dynamic> mapa) {
    final id = mapa['id'];
    final lat = mapa['lat'];
    final lon = mapa['lon'];
    final mmHora = mapa['intensidade_mm_h'];
    final rumo = mapa['vento_rumo_graus'];
    final velKmh = mapa['vento_kmh'];
    final contornoBruto = mapa['contorno_externo'];
    final nucleosBrutos = mapa['nucleos_intensos'];
    final rastrosBrutos = mapa['rastros_passados'];

    if (id is! String ||
        id.isEmpty ||
        lat is! num ||
        lon is! num ||
        mmHora is! num ||
        mmHora < 0 ||
        rumo is! num ||
        velKmh is! num ||
        velKmh < 0 ||
        contornoBruto is! List ||
        contornoBruto.length < 3) {
      throw const FormatException('BolhaChuvaRegional inválida.');
    }

    final contorno = contornoBruto
        .map((p) => PontoContornoGeo.deLista(p as List<dynamic>))
        .toList(growable: false);

    final nucleos = <List<PontoContornoGeo>>[];
    if (nucleosBrutos != null) {
      if (nucleosBrutos is! List) {
        throw const FormatException('nucleos_intensos inválido.');
      }
      for (final anelBruto in nucleosBrutos) {
        if (anelBruto is! List || anelBruto.length < 3) {
          throw const FormatException(
            'Anel interno em nucleos_intensos com menos de 3 vértices.',
          );
        }
        nucleos.add(
          anelBruto
              .map((p) => PontoContornoGeo.deLista(p as List<dynamic>))
              .toList(growable: false),
        );
      }
    }

    final rastros = <RastroPassadoTempestade>[];
    if (rastrosBrutos != null) {
      if (rastrosBrutos is! List) {
        throw const FormatException('rastros_passados inválido.');
      }
      for (final item in rastrosBrutos) {
        if (item is! Map) {
          throw const FormatException('Elemento inválido em rastros_passados.');
        }
        rastros.add(
          RastroPassadoTempestade.deMapa(Map<String, dynamic>.from(item)),
        );
      }
      rastros.sort((a, b) => b.horasAtras.compareTo(a.horasAtras));
    }

    return BolhaChuvaRegional(
      id: id,
      latitude: lat.toDouble(),
      longitude: lon.toDouble(),
      intensidadeMmHora: mmHora.toDouble(),
      ventoRumoGraus: (rumo.toDouble() % 360.0 + 360.0) % 360.0,
      ventoVelocidadeKmh: velKmh.toDouble(),
      contornoExterno: contorno,
      nucleosIntensos: List<List<PontoContornoGeo>>.unmodifiable(nucleos),
      rastrosPassados: List<RastroPassadoTempestade>.unmodifiable(rastros),
    );
  }

  Map<String, dynamic> paraMapa() => <String, dynamic>{
        'id': id,
        'lat': latitude,
        'lon': longitude,
        'intensidade_mm_h': intensidadeMmHora,
        'vento_rumo_graus': ventoRumoGraus,
        'vento_kmh': ventoVelocidadeKmh,
        'contorno_externo':
            contornoExterno.map((p) => p.paraLista()).toList(growable: false),
        if (nucleosIntensos.isNotEmpty)
          'nucleos_intensos': nucleosIntensos
              .map(
                (anel) => anel.map((p) => p.paraLista()).toList(growable: false),
              )
              .toList(growable: false),
        if (rastrosPassados.isNotEmpty)
          'rastros_passados':
              rastrosPassados.map((r) => r.paraMapa()).toList(growable: false),
      };
}

/// Tempestade ao vivo validada para pintura animada de isoietas e vento sobre o globo/relevo.
class BolhaAtivaRenderizavel {
  final BolhaChuvaRegional bolha;
  final NivelIntensidadeChuva nivelIntensidade;

  const BolhaAtivaRenderizavel({
    required this.bolha,
    required this.nivelIntensidade,
  });
}

/// Quatro níveis visuais de severidade termal de incêndio florestal derivados da análise
/// orbital (`FRP` em megawatts, densidade de focos de calor e núcleos em brasa).
enum NivelSeveridadeIncendio {
  baixo(peso: 1),
  moderado(peso: 2),
  alto(peso: 3),
  extremo(peso: 4);

  /// Peso ordinal (`1..4`) para escalar coluna de fumaça, ondas de calor, fagulhas e emblema.
  final int peso;

  const NivelSeveridadeIncendio({required this.peso});

  /// Rótulo localizado da severidade do incêndio florestal.
  String get rotulo => switch (this) {
        NivelSeveridadeIncendio.baixo => tr(ChaveTexto.climaFocoIsolado),
        NivelSeveridadeIncendio.moderado => tr(ChaveTexto.climaFocoQueimada),
        NivelSeveridadeIncendio.alto => tr(ChaveTexto.climaIncendioAtivo),
        NivelSeveridadeIncendio.extremo => tr(ChaveTexto.climaIncendioSevero),
      };
}

/// Zona regional de incêndio florestal ativo delimitada por contornos reais (NASA FIRMS / INPE VIIRS-MODIS) e vento.
class BolhaIncendioRegional {
  final String id;
  final double latitude;
  final double longitude;
  final double potenciaFrpMw;
  final int totalFocos;
  final double ventoRumoGraus;
  final double ventoVelocidadeKmh;
  final String fonteSatelite;
  final List<PontoContornoGeo> contornoExterno;
  final List<List<PontoContornoGeo>> nucleosIntensos;

  const BolhaIncendioRegional({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.potenciaFrpMw,
    required this.totalFocos,
    required this.ventoRumoGraus,
    required this.ventoVelocidadeKmh,
    this.fonteSatelite = 'INPE_BDQUEIMADAS_NASA_VIIRS_MODIS',
    required this.contornoExterno,
    this.nucleosIntensos = const [],
  });

  /// Determina o nível visual (`1..4`) combinando potência radiativa (`FRP`), contagem de focos e núcleos internos.
  NivelSeveridadeIncendio get nivelSeveridade {
    if (potenciaFrpMw >= 75.0 ||
        totalFocos >= 14 ||
        (potenciaFrpMw >= 55.0 && nucleosIntensos.isNotEmpty)) {
      return NivelSeveridadeIncendio.extremo;
    }
    if (potenciaFrpMw >= 35.0 || totalFocos >= 8) {
      return NivelSeveridadeIncendio.alto;
    }
    if (potenciaFrpMw >= 15.0 || totalFocos >= 4) {
      return NivelSeveridadeIncendio.moderado;
    }
    return NivelSeveridadeIncendio.baixo;
  }

  double get minLon => contornoExterno.map((p) => p.longitude).reduce(math.min);
  double get maxLon => contornoExterno.map((p) => p.longitude).reduce(math.max);
  double get minLat => contornoExterno.map((p) => p.latitude).reduce(math.min);
  double get maxLat => contornoExterno.map((p) => p.latitude).reduce(math.max);

  factory BolhaIncendioRegional.deMapa(Map<String, dynamic> mapa) {
    final id = mapa['id'];
    final lat = mapa['lat'];
    final lon = mapa['lon'];
    final frp = mapa['potencia_frp_mw'];
    final focos = mapa['total_focos'];
    final rumo = mapa['vento_rumo_graus'];
    final velKmh = mapa['vento_kmh'];
    final fonte = mapa['fonte_satelite'];
    final contornoBruto = mapa['contorno_externo'];
    final nucleosBrutos = mapa['nucleos_intensos'];

    if (id is! String ||
        id.isEmpty ||
        lat is! num ||
        lon is! num ||
        frp is! num ||
        frp <= 0 ||
        focos is! num ||
        focos < 1 ||
        rumo is! num ||
        velKmh is! num ||
        velKmh < 0 ||
        contornoBruto is! List ||
        contornoBruto.length < 3) {
      throw const FormatException('BolhaIncendioRegional inválida.');
    }

    final nucleos = <List<PontoContornoGeo>>[];
    if (nucleosBrutos is List) {
      for (final anelBruto in nucleosBrutos) {
        if (anelBruto is List && anelBruto.length >= 3) {
          nucleos.add(
            anelBruto
                .map((p) => PontoContornoGeo.deLista(p as List<dynamic>))
                .toList(growable: false),
          );
        }
      }
    }

    return BolhaIncendioRegional(
      id: id,
      latitude: lat.toDouble(),
      longitude: lon.toDouble(),
      potenciaFrpMw: frp.toDouble(),
      totalFocos: focos.round(),
      ventoRumoGraus: (rumo.toDouble() % 360.0 + 360.0) % 360.0,
      ventoVelocidadeKmh: velKmh.toDouble(),
      fonteSatelite: fonte is String && fonte.isNotEmpty
          ? fonte
          : 'INPE_BDQUEIMADAS_NASA_VIIRS_MODIS',
      contornoExterno: contornoBruto
          .map((p) => PontoContornoGeo.deLista(p as List<dynamic>))
          .toList(growable: false),
      nucleosIntensos: List<List<PontoContornoGeo>>.unmodifiable(nucleos),
    );
  }

  Map<String, dynamic> paraMapa() => <String, dynamic>{
        'id': id,
        'lat': latitude,
        'lon': longitude,
        'potencia_frp_mw': potenciaFrpMw,
        'total_focos': totalFocos,
        'vento_rumo_graus': ventoRumoGraus,
        'vento_kmh': ventoVelocidadeKmh,
        'fonte_satelite': fonteSatelite,
        'contorno_externo':
            contornoExterno.map((p) => p.paraLista()).toList(growable: false),
        if (nucleosIntensos.isNotEmpty)
          'nucleos_intensos': nucleosIntensos
              .map(
                (anel) => anel.map((p) => p.paraLista()).toList(growable: false),
              )
              .toList(growable: false),
      };
}

/// Incêndio florestal ativo validado para pintura termal e pluma de fumaça sobre o geoide/mapa.
class BolhaIncendioAtivaRenderizavel {
  final BolhaIncendioRegional incendio;

  const BolhaIncendioAtivaRenderizavel({required this.incendio});
}
