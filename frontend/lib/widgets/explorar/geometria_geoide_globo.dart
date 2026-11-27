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

