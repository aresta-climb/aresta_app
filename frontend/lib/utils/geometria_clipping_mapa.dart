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

  /// Recorta um anel fechado `(longitude, latitude)` contra [janela] via Sutherland-Hodgman,
  /// impedindo que grandes polígonos de chuva/incêndio gerem cordas falsas ao dar zoom profundo.
  static List<Offset> recortarPoligonoNoRetangulo({
    required List<Offset> anelLonLat,
    required JanelaGeograficaVisivel janela,
  }) {
    if (anelLonLat.length < 3) return const [];

    var atual = anelLonLat;
    atual = _recortarSemiplano(
      atual,
      dentro: (p) => p.dx >= janela.minLon,
      intersecao: (a, b) => Offset(
        janela.minLon,
        a.dy + (b.dy - a.dy) * ((janela.minLon - a.dx) / (b.dx - a.dx)),
      ),
    );
    if (atual.length < 3) return const [];

    atual = _recortarSemiplano(
      atual,
      dentro: (p) => p.dx <= janela.maxLon,
      intersecao: (a, b) => Offset(
        janela.maxLon,
        a.dy + (b.dy - a.dy) * ((janela.maxLon - a.dx) / (b.dx - a.dx)),
      ),
    );
    if (atual.length < 3) return const [];

    atual = _recortarSemiplano(
      atual,
      dentro: (p) => p.dy >= janela.minLat,
      intersecao: (a, b) => Offset(
        a.dx + (b.dx - a.dx) * ((janela.minLat - a.dy) / (b.dy - a.dy)),
        janela.minLat,
      ),
    );
    if (atual.length < 3) return const [];

    atual = _recortarSemiplano(
      atual,
      dentro: (p) => p.dy <= janela.maxLat,
      intersecao: (a, b) => Offset(
        a.dx + (b.dx - a.dx) * ((janela.maxLat - a.dy) / (b.dy - a.dy)),
        janela.maxLat,
      ),
    );
    return atual.length >= 3 ? atual : const [];
  }

  /// Subdivide segmentos longos de polilinhas rodoviárias e recorta-as suavemente à [janela],
  /// garantindo que nenhuma rodovia desapareça quando seus vértices originais saírem da tela no zoom máximo.
  static List<List<Offset>> subdividirERecortarPolilinha({
    required List<Offset> verticesLonLat,
    required JanelaGeograficaVisivel janela,
    required double passoMaxGraus,
  }) {
    if (verticesLonLat.length < 2) return const [];

    final passoSeguro = math.max(0.0004, passoMaxGraus);
    final cadeias = <List<Offset>>[];
    var atual = <Offset>[];

    void descarregar() {
      if (atual.length >= 2) {
        cadeias.add(atual);
      }
      atual = <Offset>[];
    }

    bool pontoNaJanela(Offset p) =>
        p.dx >= janela.minLon &&
        p.dx <= janela.maxLon &&
        p.dy >= janela.minLat &&
        p.dy <= janela.maxLat;

    for (var i = 0; i < verticesLonLat.length - 1; i++) {
      final a = verticesLonLat[i];
      final b = verticesLonLat[i + 1];

      // Salto real do antimeridiano (±180°) em espaço geográfico, nunca em pixels de tela
      if ((b.dx - a.dx).abs() > 150.0) {
        descarregar();
        continue;
      }

      final segMinLon = math.min(a.dx, b.dx);
      final segMaxLon = math.max(a.dx, b.dx);
      final segMinLat = math.min(a.dy, b.dy);
      final segMaxLat = math.max(a.dy, b.dy);
      if (segMaxLon < janela.minLon ||
          segMinLon > janela.maxLon ||
          segMaxLat < janela.minLat ||
          segMinLat > janela.maxLat) {
        descarregar();
        continue;
      }

      final deltaMax = math.max((b.dx - a.dx).abs(), (b.dy - a.dy).abs());
      final passos = math.min(96, math.max(1, (deltaMax / passoSeguro).ceil()));

      for (var s = 0; s <= passos; s++) {
        if (s == 0 && atual.isNotEmpty) continue;
        final t = s / passos;
        final p = Offset(
          a.dx + (b.dx - a.dx) * t,
          a.dy + (b.dy - a.dy) * t,
        );
        if (pontoNaJanela(p)) {
          atual.add(p);
        } else {
          descarregar();
        }
      }
    }

    descarregar();
    return cadeias;
  }

  /// Suaviza cantos rodoviários em coordenadas fixas do mundo (raio físico `0,0018°`),
  /// mantendo o traçado 100% invariante ao zoom e preservando cortes no antimeridiano.
  static List<Offset> suavizarCantosPolilinhaMundo(List<Offset> pts) {
    if (pts.length < 3) return pts;
    final out = <Offset>[pts.first];
    for (var i = 1; i < pts.length - 1; i++) {
      final a = pts[i - 1];
      final b = pts[i];
      final c = pts[i + 1];
      if ((b.dx - a.dx).abs() > 150.0 || (c.dx - b.dx).abs() > 150.0) {
        out.add(b);
        continue;
      }
      final ab = b - a;
      final bc = c - b;
      final dAb = ab.distance;
      final dBc = bc.distance;
      if (dAb <= 1e-6 || dBc <= 1e-6) continue;
      final cosAng = (ab.dx * bc.dx + ab.dy * bc.dy) / (dAb * dBc);
      if (cosAng > 0.95) {
        out.add(b);
        continue;
      }
      final recuoAb = math.min(0.22, 0.0018 / dAb);
      final recuoBc = math.min(0.22, 0.0018 / dBc);
      out
        ..add(Offset(b.dx - ab.dx * recuoAb, b.dy - ab.dy * recuoAb))
        ..add(Offset(b.dx + bc.dx * recuoBc, b.dy + bc.dy * recuoBc));
    }
    out.add(pts.last);
    return out;
  }

  /// Recorta o prefixo proporcional `[0..fracao]` de uma polilinha em coordenadas geográficas.
  static List<Offset> recortarFracaoPolilinhaGeo(
    List<Offset> vertices,
    double fracao,
  ) {
    if (vertices.length < 2 || fracao <= 0.0) return const [];
    if (fracao >= 1.0) return vertices;

    var compTotal = 0.0;
    for (var i = 0; i < vertices.length - 1; i++) {
      compTotal += (vertices[i + 1] - vertices[i]).distance;
    }
    if (compTotal <= 1e-7) return const [];

    final alvo = compTotal * fracao;
    final resultado = <Offset>[vertices.first];
    var acumulado = 0.0;
    for (var i = 0; i < vertices.length - 1; i++) {
      final a = vertices[i];
      final b = vertices[i + 1];
      final seg = (b - a).distance;
      if (acumulado + seg >= alvo) {
        final t =
            seg <= 1e-7 ? 1.0 : ((alvo - acumulado) / seg).clamp(0.0, 1.0);
        resultado.add(
          Offset(a.dx + (b.dx - a.dx) * t, a.dy + (b.dy - a.dy) * t),
        );
        break;
      }
      resultado.add(b);
      acumulado += seg;
    }
    return resultado;
  }

  static List<Offset> _recortarSemiplano(
    List<Offset> entrada, {
    required bool Function(Offset) dentro,
    required Offset Function(Offset, Offset) intersecao,
  }) {
    final saida = <Offset>[];
    var anterior = entrada.last;
    var antDentro = dentro(anterior);

    for (final p in entrada) {
      final pDentro = dentro(p);
      if (pDentro) {
        if (!antDentro) {
          saida.add(intersecao(anterior, p));
        }
        saida.add(p);
      } else if (antDentro) {
        saida.add(intersecao(anterior, p));
      }
      anterior = p;
      antDentro = pDentro;
    }
    return saida;
  }

  static double _smoothstep(double borda0, double borda1, double x) {
    final t = ((x - borda0) / (borda1 - borda0)).clamp(0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
  }
}
