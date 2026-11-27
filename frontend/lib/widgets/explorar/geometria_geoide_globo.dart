// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;
import 'dart:ui';

/// Coordenada projetada no plano da tela com profundidade relativa e visibilidade.
class PontoProjetadoTela {
  final double x;
  final double y;
  final double profundidade;
  final bool visivel;

  const PontoProjetadoTela({
    required this.x,
    required this.y,
    required this.profundidade,
    required this.visivel,
  });

  static const PontoProjetadoTela oculto = PontoProjetadoTela(
    x: 0,
    y: 0,
    profundidade: 9999,
    visivel: false,
  );
}

/// Estado cinemático de um arco parabólico (`Fly-To`) sobre o globo ou plano Mercator.
class TrajetoriaVooParabolico {
  final double latInicial;
  final double lonInicial;
  final double lodInicial;
  final double latFinal;
  final double deltaLonCurto;
  final double lodFinal;
  final double recuoArco;
  double progresso = 0.0;

  TrajetoriaVooParabolico({
    required this.latInicial,
    required this.lonInicial,
    required this.lodInicial,
    required this.latFinal,
    required this.deltaLonCurto,
    required this.lodFinal,
    required this.recuoArco,
  });

  /// Avança a curva cúbica suave e retorna a pose interpolada `(lat, lon, lod, concluido)`.
  ({double lat, double lon, double lod, bool concluido}) avancarPasso({
    required double passoNormalizado,
    required double lodMinimo,
    required double lodMaximo,
  }) {
    progresso = (progresso + 0.036 * passoNormalizado).clamp(0.0, 1.0);
    if (progresso >= 1.0) {
      return (
        lat: latFinal,
        lon: GeometriaGeoideGlobo.normalizarLongitude(lonInicial + deltaLonCurto),
        lod: lodFinal,
        concluido: true,
      );
    }
    final t = progresso;
    final ease = t < 0.5
        ? 4.0 * t * t * t
        : 1.0 - math.pow(-2.0 * t + 2.0, 3) / 2.0;
    final lat = latInicial + (latFinal - latInicial) * ease;
    final lon = GeometriaGeoideGlobo.normalizarLongitude(
      lonInicial + deltaLonCurto * ease,
    );
    final recuoMeioVoo = math.sin(math.pi * ease) * recuoArco;
    final lod = (lodInicial + (lodFinal - lodInicial) * ease - recuoMeioVoo)
        .clamp(lodMinimo, lodMaximo);
    return (lat: lat, lon: lon, lod: lod, concluido: false);
  }
}

/// Agrupamento geográfico de picos por unidade federativa para renderização limpa no `LOD 0`.
class ClusterEstadoGlobo {
  final String uf;
  final double latitudeMedia;
  final double longitudeMedia;
  final int quantidade;
  final String primeiroPicoId;

  const ClusterEstadoGlobo({
    required this.uf,
    required this.latitudeMedia,
    required this.longitudeMedia,
    required this.quantidade,
    required this.primeiroPicoId,
  });
}

/// Motor matemático puro do Geoide Terrestre (`WGS84 + NASA EGM96 / GRACE`),
/// agrupamento por estado e prevenção de colisão espacial de rótulos na tela.
abstract final class GeometriaGeoideGlobo {
  static const double grausParaRad = math.pi / 180.0;

  /// Raio normalizado do Geoide Terrestre combinando o achatamento polar elipsoidal `WGS84`
  /// e os harmônicos gravitacionais reais `NASA GSFC EGM96 / GRACE` (Baixa do Oceano Índico `-106m`,
  /// Alta da Nova Guiné `+85m`, Alta do Atlântico Norte `+68m`, Alta Andina `+45m`, Baixa do Caribe `-52m`,
  /// Baixa do Atlântico Sul `-28m` e Baixa de Ross `-62m`), em escala científica visível na órbita 3D.
  static double raioNormalizadoGeoide({
    required double latitude,
    required double longitude,
  }) {
    final phi = latitude * grausParaRad;
    final lam = longitude * grausParaRad;
    final sinPhi = math.sin(phi);
    final cosPhi = math.cos(phi);

    final p3 = 0.5 * (5.0 * sinPhi * sinPhi * sinPhi - 3.0 * sinPhi);
    final triaxial = cosPhi * cosPhi * math.cos(2.0 * (lam + 0.26)) * 0.0085;
    final rElipsoide =
        1.024 - 0.056 * sinPhi * sinPhi + 0.0065 * p3 + triaxial;

    double gaussianaGeo(double latC, double lonC, double larguraGraus) {
      final dLat = latitude - latC;
      final dLon = ((longitude - lonC + 540.0) % 360.0) - 180.0;
      final d2 = dLat * dLat + (dLon * 0.78) * (dLon * 0.78);
      return math.exp(-d2 / (2.0 * larguraGraus * larguraGraus));
    }

    final ondulacaoEgm96 =
        -0.0320 * gaussianaGeo(4.0, 79.0, 24.0) +
        0.0270 * gaussianaGeo(-5.0, 146.0, 22.0) +
        0.0220 * gaussianaGeo(58.0, -30.0, 23.0) +
        0.0235 * gaussianaGeo(-18.0, -69.0, 19.0) -
        0.0195 * gaussianaGeo(22.0, -66.0, 19.0) -
        0.0145 * gaussianaGeo(-35.0, -38.0, 20.0) -
        0.0175 * gaussianaGeo(28.0, -135.0, 22.0) -
        0.0210 * gaussianaGeo(-74.0, -175.0, 24.0);

    return rElipsoide + ondulacaoEgm96;
  }

  /// Constrói o contorno fechado da silhueta do Geoide Terrestre (`WGS84 + NASA EGM96`) para o limbo orbital.
  static Path construirSilhuetaGeoide({
    required Size tamanhoTela,
    required double centroVerticalOpticoPx,
    required double raioAparentePx,
    required double latitudeCentral,
    required double longitudeCentral,
    required double lod,
    double escalaExtra = 1.0,
    int segmentos = 108,
  }) {
    final rPx = raioAparentePx * escalaExtra;
    final cx = tamanhoTela.width * 0.5;
    final phi0 = latitudeCentral * grausParaRad;
    final lam0 = longitudeCentral * grausParaRad;
    final cosPhi0 = math.cos(phi0);
    final sinPhi0 = math.sin(phi0);
    final cosLam0 = math.cos(lam0);
    final sinLam0 = math.sin(lam0);
    final atenuacaoLocal = 1.0 - smoothstep(0.95, 1.85, lod);

    final lesteX = -sinLam0;
    final lesteY = cosLam0;
    const lesteZ = 0.0;
    final norteX = -sinPhi0 * cosLam0;
    final norteY = -sinPhi0 * sinLam0;
    final norteZ = cosPhi0;

    final caminho = Path();
    for (var i = 0; i < segmentos; i++) {
      final theta = (i / segmentos) * 2.0 * math.pi;
      final ct = math.cos(theta);
      final st = math.sin(theta);

      final vx = ct * lesteX + st * norteX;
      final vy = ct * lesteY + st * norteY;
      final vz = ct * lesteZ + st * norteZ;

      final latLimbo = math.asin(vz.clamp(-1.0, 1.0)) / grausParaRad;
      final lonLimbo = math.atan2(vy, vx) / grausParaRad;
      final rGeo = 1.0 +
          (raioNormalizadoGeoide(latitude: latLimbo, longitude: lonLimbo) -
                  1.0) *
              atenuacaoLocal;

      final px = cx + ct * rPx * rGeo;
      final py = centroVerticalOpticoPx - st * rPx * rGeo;
      if (i == 0) {
        caminho.moveTo(px, py);
      } else {
        caminho.lineTo(px, py);
      }
    }
    caminho.close();
    return caminho;
  }

  /// Agrupa picos por sigla de estado (`UF`) para exibição sem poluição no `LOD 0`.
  static List<ClusterEstadoGlobo> agruparPorEstado(
    Iterable<({String id, String uf, double lat, double lon})> picos,
  ) {
    final acumulador = <String,
        ({double latSoma, double lonSoma, int qtd, String primeiroId})>{};
    for (final p in picos) {
      final chaveUf = p.uf.isEmpty ? 'BR' : p.uf;
      final atual = acumulador[chaveUf];
      if (atual == null) {
        acumulador[chaveUf] = (
          latSoma: p.lat,
          lonSoma: p.lon,
          qtd: 1,
          primeiroId: p.id,
        );
      } else {
        acumulador[chaveUf] = (
          latSoma: atual.latSoma + p.lat,
          lonSoma: atual.lonSoma + p.lon,
          qtd: atual.qtd + 1,
          primeiroId: atual.primeiroId,
        );
      }
    }

    return acumulador.entries
        .map(
          (e) => ClusterEstadoGlobo(
            uf: e.key,
            latitudeMedia: e.value.latSoma / e.value.qtd,
            longitudeMedia: e.value.lonSoma / e.value.qtd,
            quantidade: e.value.qtd,
            primeiroPicoId: e.value.primeiroId,
          ),
        )
        .toList();
  }

  /// Seleciona os identificadores cujos rótulos textuais não se sobrepõem, priorizando âncoras marcadas.
  static Set<String> selecionarIdsSemColisaoRotulos(
    List<({String id, String nome, Offset posicao, bool prioritario})>
    candidatos, {
    double alturaCaixa = 26.0,
  }) {
    final ordenados = List.of(candidatos)
      ..sort((a, b) => (b.prioritario ? 1 : 0) - (a.prioritario ? 1 : 0));

    final caixasAceitas = <({double x, double y, double largura})>[];
    final aprovados = <String>{};

    for (final item in ordenados) {
      final largura = item.nome.length * 6.4 + 30.0;
      final colide = caixasAceitas.any(
        (c) =>
            (c.x - item.posicao.dx).abs() < (c.largura + largura) * 0.52 &&
            (c.y - item.posicao.dy).abs() < alturaCaixa,
      );
      if (!colide) {
        aprovados.add(item.id);
        caixasAceitas.add((
          x: item.posicao.dx,
          y: item.posicao.dy,
          largura: largura,
        ));
      }
    }
    return aprovados;
  }

  /// Interpolação Hermite cúbica suave `smoothstep(e0, e1, x)`.
  static double smoothstep(double borda0, double borda1, double x) {
    final t = ((x - borda0) / (borda1 - borda0)).clamp(0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
  }

  /// Normaliza qualquer ângulo longitudinal para o intervalo canônico `[-180, +180)`.
  static double normalizarLongitude(double lon) {
    var normalizada = (lon + 180.0) % 360.0;
    if (normalizada < 0) normalizada += 360.0;
    return normalizada - 180.0;
  }

  /// Projeta uma coordenada esférica `(latitude, longitude, elevacaoMetros)` sobre o Geoide 3D com inclinação perspectiva.
  static PontoProjetadoTela projetarCoordenada3D({
    required double latitude,
    required double longitude,
    required double elevacaoMetros,
    required double latitudeCentral,
    required double longitudeCentral,
    required double lod,
    required double raioAparentePx,
    required double centroVerticalOpticoPx,
    required double elevacaoReferenciaCameraMetros,
    required Size tamanhoTela,
    bool estenderBordaHorizonte = false,
  }) {
    final cosPhi0 = math.cos(latitudeCentral * grausParaRad);
    final sinPhi0 = math.sin(latitudeCentral * grausParaRad);
    final phi = latitude * grausParaRad;
    final dLam = (longitude - longitudeCentral) * grausParaRad;
    final cosPhi = math.cos(phi);
    final sinPhi = math.sin(phi);
    final cosDLam = math.cos(dLam);
    final sinDLam = math.sin(dLam);

    final x0 = cosPhi * sinDLam;
    final y0 = cosPhi0 * sinPhi - sinPhi0 * cosPhi * cosDLam;
    final z0 = sinPhi0 * sinPhi + cosPhi0 * cosPhi * cosDLam;
    final limiteZ = estenderBordaHorizonte
        ? (lod >= 1.65 ? 0.88 : -0.18)
        : (lod >= 1.65 ? 0.94 : 0.015);
    if (z0 < limiteZ) return PontoProjetadoTela.oculto;

    var xEsfera = x0;
    var yEsfera = y0;
    var zEsfera = z0;
    if (zEsfera < 0.0) {
      final norma = math.max(1e-6, math.sqrt(x0 * x0 + y0 * y0));
      xEsfera = (x0 / norma) * 1.004;
      yEsfera = (y0 / norma) * 1.004;
      zEsfera = 0.0;
    }

    final pesoGeoide = 1.0 - smoothstep(0.95, 1.85, lod);
    final rBaseGeoide = 1.0 +
        (raioNormalizadoGeoide(latitude: latitude, longitude: longitude) -
                1.0) *
            pesoGeoide;

    final exageroVertical = 6.0 - 4.55 * smoothstep(2.15, 3.85, lod);
    final pesoRef = smoothstep(2.35, 3.35, lod);
    final elevRelativa = math.max(0.0, elevacaoMetros) -
        (elevacaoReferenciaCameraMetros * pesoRef);
    final hNormBruto = (elevRelativa / 6371000.0) * exageroVertical;
    final hNorm =
        (hNormBruto * raioAparentePx).clamp(-150.0, 255.0) / raioAparentePx;
    final rad = rBaseGeoide + hNorm;
    final dx = xEsfera * rad;
    final dy = yEsfera * rad;
    final dz = zEsfera * rad - rBaseGeoide;

    final tilt = smoothstep(1.50, 2.75, lod) * 0.66;
    final cosTilt = math.cos(tilt);
    final sinTilt = math.sin(tilt);

    final camX = dx;
    final camY = dy * cosTilt + dz * sinTilt;
    final camDepth = dy * sinTilt - dz * cosTilt;

    final depthPx = camDepth * raioAparentePx;
    final perspForca = smoothstep(1.40, 2.55, lod);
    const perspDist = 650.0;
    if (depthPx * perspForca < -perspDist * 0.68) {
      return PontoProjetadoTela.oculto;
    }
    final persp = perspDist / math.max(190.0, perspDist + depthPx * perspForca);

    return PontoProjetadoTela(
      x: tamanhoTela.width * 0.5 + (camX * raioAparentePx) * persp,
      y: centroVerticalOpticoPx - (camY * raioAparentePx) * persp,
      profundidade: depthPx,
      visivel: true,
    );
  }
}
