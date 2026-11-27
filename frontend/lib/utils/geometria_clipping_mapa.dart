// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;
import 'dart:ui';

/// Janela geográfica retangular visível da câmera (`longitude` e `latitude` em graus).
class JanelaGeograficaVisivel {
  final double minLon;
  final double maxLon;
  final double minLat;
  final double maxLat;

  const JanelaGeograficaVisivel({
    required this.minLon,
    required this.maxLon,
    required this.minLat,
    required this.maxLat,
  });

  /// Indica se `(lon, lat)` encontra-se dentro dos limites desta janela.
  bool contemPonto(double lon, double lat) =>
      lon >= minLon && lon <= maxLon && lat >= minLat && lat <= maxLat;
}

/// Utilitário matemático puro e sem estado (stateless) para cálculo do frustum geográfico visível,
/// recorte Sutherland-Hodgman de polígonos atmosféricos e subdivisão contínua de polilinhas viárias
/// em zooms profundos (`LOD 2 .. 4.65`), evitando desaparecimento de estradas e cordas de horizonte.
abstract final class GeometriaClippingMapa {
  static const double _grausParaRad = math.pi / 180.0;

  /// Calcula a janela geográfica que cobre integralmente a tela (com margem de segurança)
  /// mantendo todos os vértices estritamente à frente do plano próximo da câmera perspectiva 3D.
  static JanelaGeograficaVisivel calcularJanelaVisivelCamera({
    required bool modo3D,
    required double latitudeCentral,
    required double longitudeCentral,
    required double lod,
    required double raioAparentePx,
    required double escala2D,
    required Size tamanhoTela,
    double fatorMargem = 1.0,
  }) {
    final cosLat0 = math.max(0.28, math.cos(latitudeCentral * _grausParaRad));

    if (!modo3D) {
      final spanLon =
          (((tamanhoTela.width * 0.62 * fatorMargem) / escala2D) / _grausParaRad)
              .clamp(0.0004, 179.0);
      final spanLat =
          (((tamanhoTela.height * 0.68 * fatorMargem) / escala2D) / _grausParaRad)
              .clamp(0.0004, 85.0);
      return JanelaGeograficaVisivel(
        minLon: longitudeCentral - spanLon,
        maxLon: longitudeCentral + spanLon,
        minLat: (latitudeCentral - spanLat).clamp(-85.0, 85.0),
        maxLat: (latitudeCentral + spanLat).clamp(-85.0, 85.0),
      );
    }

    final tInclinacao = _smoothstep(1.45, 2.75, lod);
    // No sul (próximo à lente inclinada), limita a 465px/rPx para que depthPx permaneça > -290px (> -442px)
    // projetando y > height + 90px sem jamais descartar linhas atrás da câmera!
    final alcanceSulPx =
        (tamanhoTela.height * 0.56 * (1.0 - 0.35 * tInclinacao)).clamp(
          260.0,
          465.0,
        ) *
        fatorMargem.clamp(0.85, 1.08);
    final alcanceNortePx =
        (tamanhoTela.height * (0.64 + 1.48 * tInclinacao)) * fatorMargem;
    final alcanceLesteOestePx =
        (tamanhoTela.width * (0.66 + 1.12 * tInclinacao)) * fatorMargem;

    final spanSulGraus =
        ((alcanceSulPx / raioAparentePx) / _grausParaRad).clamp(0.0003, 55.0);
    final spanNorteGraus =
        ((alcanceNortePx / raioAparentePx) / _grausParaRad).clamp(0.0005, 65.0);
    final spanLonGraus =
        (((alcanceLesteOestePx / raioAparentePx) / _grausParaRad) / cosLat0)
            .clamp(0.0005, 85.0);

    return JanelaGeograficaVisivel(
      minLon: longitudeCentral - spanLonGraus,
      maxLon: longitudeCentral + spanLonGraus,
      minLat: (latitudeCentral - spanSulGraus).clamp(-85.0, 85.0),
      maxLat: (latitudeCentral + spanNorteGraus).clamp(-85.0, 85.0),
    );
  }

