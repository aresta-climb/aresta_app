// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../data/modelos/modelos_relevo_topografico.dart';
import '../../utils/geometria_clipping_mapa.dart';
import 'controlador_camera_globo.dart';
import 'malha_relevo_lod.dart';
import 'pintor_curvas_nivel_globo.dart';

/// Renderizador de relevo topográfico contínuo (`NASA SRTM 30m`), retículas cartográficas,
/// fronteiras vetoriais do IBGE e eixos rodoviários principais sobre o globo/mapa.
abstract final class PintorTerrenoVetoresGlobo {
  static const double _grausParaRad = math.pi / 180.0;

  /// Renderiza a superfície topográfica detalhada ancorada em múltiplos fixos do mundo `(lat, lon)`,
  /// evitando oscilação de iluminação ou geometria ao mover a câmera.
  static void desenharTerrenoDetalhadoContinuo({
    required Canvas canvas,
    required Size size,
    required ControladorCameraGlobo controlador,
    required MalhaGeograficaGlobo? dadosMalha,
    required List<PicoRelevoReferencia> picosReferencia,
    required double opacidadeBase,
    double fatorMonocromatico = 0.0,
    ConjuntoCurvasNivelMundo? curvasMundo,
    double? Function(double latitude, double longitude)? amostradorElevacaoReal,
  }) {
    if (picosReferencia.isEmpty && amostradorElevacaoReal == null) return;

    final lod = controlador.lod;
    final lat0 = controlador.latitudeCentral;
    final cosLat0 = math.max(0.28, math.cos(lat0 * _grausParaRad));
    final janela = GeometriaClippingMapa.calcularJanelaVisivelCamera(
      modo3D: controlador.modo3D,
      latitudeCentral: lat0,
      longitudeCentral: controlador.longitudeCentral,
      lod: lod,
      raioAparentePx: controlador.raioAparentePx,
      escala2D: controlador.modo3D ? 1.0 : controlador.calcularEscala2D(size),
      tamanhoTela: size,
      fatorMargem: 1.06,
    );

    // Passo fixo no mundo por faixa discreta de LOD para eliminar cintilação ao arrastar o mapa
    final passoBase = lod >= 3.55
        ? 0.0040
        : (lod >= 2.72 ? 0.0125 : (lod >= 1.95 ? 0.0400 : 0.1200));
    final spanLatBruto = (janela.maxLat - janela.minLat).clamp(0.02, 18.0);
    final spanLonBruto = (janela.maxLon - janela.minLon).clamp(0.02, 22.0);
    final multPasso = math.max(
      1,
      (math.max(spanLatBruto, spanLonBruto) / (passoBase * 40.0)).ceil(),
    );
    final passoMundo = passoBase * multPasso;

    final jMin = (janela.minLat / passoMundo).floor();
    final jMax = (janela.maxLat / passoMundo).ceil();
    final iMin = (janela.minLon / passoMundo).floor();
    final iMax = (janela.maxLon / passoMundo).ceil();
    final rows = (jMax - jMin).clamp(2, 44);
    final cols = (iMax - iMin).clamp(2, 44);
    final latMax = (jMin + rows) * passoMundo;
    final latMin = jMin * passoMundo;
    final lonMin = iMin * passoMundo;
    final lonMax = (iMin + cols) * passoMundo;

    final totalVerts = (rows + 1) * (cols + 1);
    final posicoes = List<Offset>.filled(totalVerts, Offset.zero);
    final cores = List<Color>.filled(totalVerts, Colors.transparent);
    final visiveis = List<bool>.filled(totalVerts, false);
    final profundidades = List<double>.filled(totalVerts, 0.0);
    final elevs = List<double>.filled(totalVerts, 0.0);

    for (var j = 0; j <= rows; j++) {
      final lat = latMax - j * passoMundo;
      for (var i = 0; i <= cols; i++) {
        final idx = j * (cols + 1) + i;
        final lon = lonMin + i * passoMundo;
        final ehTerra =
            dadosMalha?.contemPontoTerrestre(latitude: lat, longitude: lon);
        final el = GeradorRelevoLod.amostrarTerrenoRegionalContinuo(
          latitude: lat,
          longitude: lon,
          picosReferencia: picosReferencia,
          ehTerraConfirmada: ehTerra,
          amostradorElevacaoReal: amostradorElevacaoReal,
        );
        elevs[idx] = el;

        final pt = controlador.projetarCoordenada(
          latitude: lat,
          longitude: lon,
          elevacaoMetros: math.max(0.0, el) * opacidadeBase,
          tamanhoTela: size,
          estenderBordaHorizonte: true,
        );
        if (pt.visivel) {
          visiveis[idx] = true;
          posicoes[idx] = Offset(pt.x, pt.y);
          profundidades[idx] = pt.profundidade;
        }
      }
    }

    final nevoaHorizonte = controlador.modo3D
        ? ControladorCameraGlobo.smoothstep(1.80, 2.75, lod) *
            (1.0 - 0.45 * ControladorCameraGlobo.smoothstep(3.10, 4.10, lod))
        : 0.0;
    // Mantém sombreamento direcional vigoroso mesmo no zoom máximo (LOD 4.65) para esculpir vales e cristas
    final ganhoRelevoLuz = 1.0 + 6.2 * fatorMonocromatico;

    final passoMetrosLat =
        math.max(4.0, ((latMax - latMin) / rows) * 111320.0);
    final passoMetrosLon =
        math.max(4.0, ((lonMax - lonMin) / cols) * 111320.0 * cosLat0);

    for (var j = 0; j <= rows; j++) {
      final jAnt = math.max(0, j - 1);
      final jProx = math.min(rows, j + 1);
      final distY = (jProx - jAnt) * passoMetrosLat;

      for (var i = 0; i <= cols; i++) {
        final idx = j * (cols + 1) + i;
        if (!visiveis[idx]) continue;

        final el = elevs[idx];
        final alfaCosta = ControladorCameraGlobo.smoothstep(1.0, 10.0, el);
        final alfaVert = opacidadeBase * alfaCosta;
        if (alfaVert <= 0.01) continue;

        final iAnt = math.max(0, i - 1);
        final iProx = math.min(cols, i + 1);
        final distX = (iProx - iAnt) * passoMetrosLon;

        final dzDx =
            (elevs[j * (cols + 1) + iProx] - elevs[j * (cols + 1) + iAnt]) /
                distX;
        final dzDySul =
            (elevs[jProx * (cols + 1) + i] - elevs[jAnt * (cols + 1) + i]) /
                distY;
        final declive = math.sqrt(dzDx * dzDx + dzDySul * dzDySul);

        final corHipsometrica =
            _corHipsometricaRocha(el, declive, fatorMonocromatico);
        final dzDxLuz = dzDx * ganhoRelevoLuz;
        final dzDyLuz = dzDySul * ganhoRelevoLuz;
        final invNorm =
            1.0 / math.sqrt(dzDxLuz * dzDxLuz + dzDyLuz * dzDyLuz + 1.0);
        final solDot = (-dzDxLuz * 0.64 + dzDyLuz * 0.48 + 0.56) * invNorm;
        final luzSolar =
            (0.42 + 1.08 * solDot.clamp(0.0, 1.0)).clamp(0.42, 1.48);

        var r = corHipsometrica.r * luzSolar;
        var g = corHipsometrica.g * luzSolar;
        var b = corHipsometrica.b * luzSolar;

        final prof = profundidades[idx];
        if (nevoaHorizonte > 0.02 && prof > 60.0) {
          final nevoa =
              ((prof - 60.0) / 480.0).clamp(0.0, 0.52) * nevoaHorizonte;
          final nr = 24.0 * (1.0 - fatorMonocromatico) +
              18.0 * fatorMonocromatico;
          final ng = 48.0 * (1.0 - fatorMonocromatico) +
              22.0 * fatorMonocromatico;
          final nb = 74.0 * (1.0 - fatorMonocromatico) +
              30.0 * fatorMonocromatico;
          r = r + (nr - r) * nevoa;
          g = g + (ng - g) * nevoa;
          b = b + (nb - b) * nevoa;
        }

        cores[idx] = Color.fromRGBO(
          r.round().clamp(0, 255),
          g.round().clamp(0, 255),
          b.round().clamp(0, 255),
          alfaVert.clamp(0.0, 1.0),
        );
      }
    }

    final quads = <({double prof, int i00, int i10, int i11, int i01})>[];
    for (var j = 0; j < rows; j++) {
      for (var i = 0; i < cols; i++) {
        final i00 = j * (cols + 1) + i;
        final i10 = i00 + 1;
        final i01 = i00 + (cols + 1);
        final i11 = i01 + 1;
        if (!visiveis[i00] ||
            !visiveis[i10] ||
            !visiveis[i01] ||
            !visiveis[i11]) {
          continue;
        }
        final alfaMax = math.max(
          math.max(cores[i00].a, cores[i10].a),
          math.max(cores[i01].a, cores[i11].a),
        );
        if (alfaMax < 0.02) continue;

        final profMedia = (profundidades[i00] +
                profundidades[i10] +
                profundidades[i11] +
                profundidades[i01]) *
            0.25;
        quads.add((prof: profMedia, i00: i00, i10: i10, i11: i11, i01: i01));
      }
    }

    if (quads.isNotEmpty) {
      quads.sort((a, b) => b.prof.compareTo(a.prof));
      final indices = <int>[];
      for (final q in quads) {
        indices
          ..add(q.i00)
          ..add(q.i10)
          ..add(q.i11)
          ..add(q.i00)
          ..add(q.i11)
          ..add(q.i01);
      }

      canvas.drawVertices(
        ui.Vertices(
          ui.VertexMode.triangles,
          posicoes,
          colors: cores,
          indices: indices,
        ),
        BlendMode.srcOver,
        Paint(),
      );
    }

    // Projeta isolinhas topográficas suaves ancoradas em coordenadas fixas do mundo
    PintorCurvasNivelGlobo.desenharCurvasETopografiaProxima(
      canvas: canvas,
      size: size,
      controlador: controlador,
      picosReferencia: picosReferencia,
      opacidadeTerreno: opacidadeBase,
      fatorMonocromatico: fatorMonocromatico,
      curvasMundo: curvasMundo,
      dadosMalha: dadosMalha,
      amostradorElevacaoReal: amostradorElevacaoReal,
    );
  }

  static ({double r, double g, double b}) _corHipsometricaRocha(
    double el,
    double declive,
    double fatorMonocromatico,
  ) {
    double tr, tg, tb;
    if (el < 650.0) {
      final t = (el / 650.0).clamp(0.0, 1.0);
      tr = 42.0 + 26.0 * t;
      tg = 74.0 + 28.0 * t;
      tb = 52.0 + 14.0 * t;
    } else if (el < 1050.0) {
      final t = ((el - 650.0) / 400.0).clamp(0.0, 1.0);
      tr = 68.0 + 48.0 * t;
      tg = 102.0 + 28.0 * t;
      tb = 66.0 + 20.0 * t;
    } else if (el < 1450.0) {
      final t = ((el - 1050.0) / 400.0).clamp(0.0, 1.0);
      tr = 116.0 + 48.0 * t;
      tg = 130.0 + 26.0 * t;
      tb = 86.0 + 36.0 * t;
    } else {
      tr = 176.0;
      tg = 166.0;
      tb = 148.0;
    }

    final exposicaoRocha =
        ControladorCameraGlobo.smoothstep(0.16, 0.48, declive);
    final rNat = tr + (174.0 - tr) * exposicaoRocha;
    final gNat = tg + (165.0 - tg) * exposicaoRocha;
    final bNat = tb + (154.0 - tb) * exposicaoRocha;

    if (fatorMonocromatico <= 0.001) {
      return (r: rNat, g: gNat, b: bNat);
    }

    // Versão monocromática basalto/prata esculpida com realce mineral em paredes íngremes
    final cotaNorm = (el / 1600.0).clamp(0.0, 1.0);
    final degrauNorm = ((el / 200.0).floorToDouble() / 8.0).clamp(0.0, 1.0);
    final cinzaBase =
        21.0 + 30.0 * cotaNorm + 16.0 * degrauNorm + 40.0 * exposicaoRocha;
    final m = fatorMonocromatico.clamp(0.0, 1.0);
    final rMono = cinzaBase + 8.0 * exposicaoRocha;
    final gMono = cinzaBase + 2.5 + 3.0 * exposicaoRocha;
    final bMono = cinzaBase + 6.5 - 2.0 * exposicaoRocha;
    return (
      r: rNat + (rMono - rNat) * m,
      g: gNat + (gMono - gNat) * m,
      b: bNat + (bMono - bNat) * m,
    );
  }

  /// Desenha retícula topográfica fina sobre terra firme em zooms regionais e locais.
  static void desenharMicroGradeTopograficaTerrestre({
    required Canvas canvas,
    required Size size,
    required ControladorCameraGlobo controlador,
    required MalhaGeograficaGlobo dadosMalha,
    required double alfaBase,
  }) {
    final lod = controlador.lod;
    final passoGraus = lod >= 3.55 ? 0.02 : (lod >= 2.65 ? 0.10 : 0.50);
    final lat0 = controlador.latitudeCentral;
    final lon0 = controlador.longitudeCentral;
    final span = (passoGraus * 9.0).clamp(0.18, 4.5);

    final latIni = ((lat0 - span) / passoGraus).floor() * passoGraus;
    final latFim = ((lat0 + span) / passoGraus).ceil() * passoGraus;
    final lonIni = ((lon0 - span) / passoGraus).floor() * passoGraus;
    final lonFim = ((lon0 + span) / passoGraus).ceil() * passoGraus;

    final pincelLinhaPrincipal = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85
      ..color =
          Color.fromRGBO(203, 213, 225, (0.12 * alfaBase).clamp(0.0, 1.0));
    final pincelLinhaSecundaria = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.55
      ..color =
          Color.fromRGBO(148, 163, 184, (0.07 * alfaBase).clamp(0.0, 1.0));

    var idxLat = 0;
    for (var lat = latIni; lat <= latFim; lat += passoGraus, idxLat++) {
      final path = Path();
      var ativo = false;
      for (var k = 0; k <= 16; k++) {
        final lon = lonIni + (lonFim - lonIni) * (k / 16.0);
        if (!dadosMalha.contemPontoTerrestre(latitude: lat, longitude: lon)) {
          ativo = false;
          continue;
        }
        final pt = controlador.projetarCoordenada(
          latitude: lat,
          longitude: lon,
          elevacaoMetros: 0.0,
          tamanhoTela: size,
        );
        if (!pt.visivel) {
          ativo = false;
          continue;
        }
        if (!ativo) {
          path.moveTo(pt.x, pt.y);
          ativo = true;
        } else {
          path.lineTo(pt.x, pt.y);
        }
      }
      canvas.drawPath(
        path,
        idxLat % 5 == 0 ? pincelLinhaPrincipal : pincelLinhaSecundaria,
      );
    }

