// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';

import '../../data/modelos/modelos_relevo_topografico.dart';
import '../../utils/extrator_curvas_nivel_mundo.dart';
import '../../utils/geometria_clipping_mapa.dart';
import 'controlador_camera_globo.dart';
import 'malha_relevo_lod.dart';

/// Renderizador cartográfico declarativo (Dumb UI) de isolinhas aditivas (`400m -> +200m -> +100m -> +50m`)
/// travadas diretamente sobre a superfície do Geoide (Opção A — zero deformação ou paralaxe no zoom).
abstract final class PintorCurvasNivelGlobo {
  static const Color _corCobreEscarpasAresta = Color(0xFFE88D5A);

  /// Projeta e desenha sobre [canvas] a hierarquia aditiva de isolinhas [curvasMundo],
  /// revelando progressivamente subdivisões mais finas sem alterar as curvas já visíveis.
  static void desenharCurvasETopografiaProxima({
    required Canvas canvas,
    required Size size,
    required ControladorCameraGlobo controlador,
    required List<PicoRelevoReferencia> picosReferencia,
    required double opacidadeTerreno,
    required double fatorMonocromatico,
    ConjuntoCurvasNivelMundo? curvasMundo,
    MalhaGeograficaGlobo? dadosMalha,
    double? Function(double latitude, double longitude)? amostradorElevacaoReal,
  }) {
    final lod = controlador.lod;
    final alfaGeracao0 = ControladorCameraGlobo.smoothstep(1.92, 2.42, lod) *
        opacidadeTerreno.clamp(0.0, 1.0);
    if (alfaGeracao0 <= 0.02) return;

    final alfaGeracao1 = ControladorCameraGlobo.smoothstep(2.55, 3.05, lod) *
        opacidadeTerreno.clamp(0.0, 1.0);
    final alfaGeracao2 = ControladorCameraGlobo.smoothstep(3.25, 3.75, lod) *
        opacidadeTerreno.clamp(0.0, 1.0);
    final alfaGeracao3 = ControladorCameraGlobo.smoothstep(3.90, 4.35, lod) *
        opacidadeTerreno.clamp(0.0, 1.0);

    final janela = GeometriaClippingMapa.calcularJanelaVisivelCamera(
      modo3D: controlador.modo3D,
      latitudeCentral: controlador.latitudeCentral,
      longitudeCentral: controlador.longitudeCentral,
      lod: lod,
      raioAparentePx: controlador.raioAparentePx,
      escala2D: controlador.modo3D ? 1.0 : controlador.calcularEscala2D(size),
      tamanhoTela: size,
      fatorMargem: 1.08,
    );

    final conjunto = curvasMundo ??
        ExtratorCurvasNivelMundo.extrairCurvasBloco(
          janela: janela,
          nivelDetalhe: ExtratorCurvasNivelMundo.resolverNivelDetalhe(lod),
          versaoDadosElevacao: 0,
          picosReferencia: picosReferencia,
          amostrarElevacaoMetros: (lat, lon) {
            final ehTerra = dadosMalha?.contemPontoTerrestre(
              latitude: lat,
              longitude: lon,
            );
            return GeradorRelevoLod.amostrarTerrenoRegionalContinuo(
              latitude: lat,
              longitude: lon,
              picosReferencia: picosReferencia,
              ehTerraConfirmada: ehTerra,
              amostradorElevacaoReal: amostradorElevacaoReal,
            );
          },
        );

    final caminhosGeracao = <Path>[Path(), Path(), Path(), Path()];
    final temGeracao = <bool>[false, false, false, false];
    final caminhoEscarpasAresta = Path();
    var temEscarpa = false;

    final rotulosCotas = <({Offset pos, int metros, bool escarpa})>[];
    final exibirRotulos400 = lod >= 2.55;
    final exibirRotulos200 = lod >= 3.35;
    final margemTelaX = size.width * 0.35;
    final margemTelaY = size.height * 0.35;

    for (final curva in conjunto.curvas) {
      final g = curva.geracaoDetalhe.clamp(0, 3);
      if (g == 1 && alfaGeracao1 <= 0.02) continue;
      if (g == 2 && alfaGeracao2 <= 0.02) continue;
      if (g == 3 && alfaGeracao3 <= 0.02) continue;

      final destino =
          curva.ehEscarpaPico ? caminhoEscarpasAresta : caminhosGeracao[g];
      final subTraco = <Offset>[];
      var segmentosVisiveis = 0;

      void descarregarSubTraco() {
        if (subTraco.length >= 2) {
          _adicionarSplineSuaveAoPath(destino, subTraco);
          segmentosVisiveis += subTraco.length - 1;
        }
        subTraco.clear();
      }

      for (final v in curva.verticesLonLat) {
        if (!janela.contemPonto(v.dx, v.dy)) {
          descarregarSubTraco();
          continue;
        }
        final pt = controlador.projetarCoordenada(
          latitude: v.dy,
          longitude: v.dx,
          elevacaoMetros: 0.0,
          tamanhoTela: size,
        );
        if (!pt.visivel ||
            pt.x < -margemTelaX ||
            pt.x > size.width + margemTelaX ||
            pt.y < -margemTelaY ||
            pt.y > size.height + margemTelaY) {
          descarregarSubTraco();
          continue;
        }
        subTraco.add(Offset(pt.x, pt.y));
      }
      descarregarSubTraco();

      if (segmentosVisiveis > 0) {
        if (curva.ehEscarpaPico) {
          temEscarpa = true;
        } else {
          temGeracao[g] = true;
        }
      }

      final podeRotular =
          (g == 0 && exibirRotulos400) || (g == 1 && exibirRotulos200);
      final ancora = curva.ancoraRotuloLonLat;
      if (podeRotular &&
          ancora != null &&
          rotulosCotas.length < 4 &&
          janela.contemPonto(ancora.dx, ancora.dy)) {
        final ptRotulo = controlador.projetarCoordenada(
          latitude: ancora.dy,
          longitude: ancora.dx,
          elevacaoMetros: 0.0,
          tamanhoTela: size,
        );
        if (ptRotulo.visivel &&
            ptRotulo.x > 56.0 &&
            ptRotulo.x < size.width - 56.0 &&
            ptRotulo.y > 98.0 &&
            ptRotulo.y < size.height - controlador.alturaGavetaPx - 30.0) {
          final pos = Offset(ptRotulo.x, ptRotulo.y);
          final semColisao = rotulosCotas.every(
            (r) => (r.pos - pos).distanceSquared > 175.0 * 175.0,
          );
          if (semColisao) {
            rotulosCotas.add((
              pos: pos,
              metros: curva.cotaMetros,
              escarpa: curva.ehEscarpaPico,
            ));
          }
        }
      }
    }

    final ganhoMono = 0.65 + 0.35 * fatorMonocromatico;

    // Desenha da subdivisão mais fina (50m) para a mestra (400m) mantendo hierarquia sólida
    if (temGeracao[3] && alfaGeracao3 > 0.02) {
      canvas.drawPath(
        caminhosGeracao[3],
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 0.85
          ..color = Color.fromRGBO(
            148,
            165,
            186,
            (0.28 * alfaGeracao3 * ganhoMono).clamp(0.0, 1.0),
          ),
      );
    }
    if (temGeracao[2] && alfaGeracao2 > 0.02) {
      canvas.drawPath(
        caminhosGeracao[2],
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 1.05
          ..color = Color.fromRGBO(
            168,
            184,
            204,
            (0.40 * alfaGeracao2 * ganhoMono).clamp(0.0, 1.0),
          ),
      );
    }
    if (temGeracao[1] && alfaGeracao1 > 0.02) {
      canvas.drawPath(
        caminhosGeracao[1],
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 1.30
          ..color = Color.fromRGBO(
            202,
            214,
            230,
            (0.55 * alfaGeracao1 * ganhoMono).clamp(0.0, 1.0),
          ),
      );
    }
    if (temGeracao[0]) {
      canvas.drawPath(
        caminhosGeracao[0],
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 1.65
          ..color = Color.fromRGBO(
            228,
            236,
            246,
            (0.74 * alfaGeracao0 * ganhoMono).clamp(0.0, 1.0),
          ),
      );
    }
    if (temEscarpa) {
      canvas.drawPath(
        caminhoEscarpasAresta,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 1.75
          ..color = _corCobreEscarpasAresta.withValues(
            alpha: (0.82 * alfaGeracao0).clamp(0.0, 1.0),
          ),
      );
    }

    if (rotulosCotas.isNotEmpty) {
      _desenharEtiquetasCotaMestra(
        canvas: canvas,
        rotulos: rotulosCotas,
        opacidade:
            (alfaGeracao0 * ControladorCameraGlobo.smoothstep(2.55, 3.10, lod))
                .clamp(0.0, 1.0),
      );
    }
  }

  static void _adicionarSplineSuaveAoPath(Path path, List<Offset> pts) {
    path.moveTo(pts.first.dx, pts.first.dy);
    if (pts.length == 2) {
      path.lineTo(pts.last.dx, pts.last.dy);
      return;
    }
    for (var i = 1; i < pts.length - 1; i++) {
      final atual = pts[i];
      final prox = pts[i + 1];
      path.quadraticBezierTo(
        atual.dx,
        atual.dy,
        (atual.dx + prox.dx) * 0.5,
        (atual.dy + prox.dy) * 0.5,
      );
    }
    path.lineTo(pts.last.dx, pts.last.dy);
  }

  static void _desenharEtiquetasCotaMestra({
    required Canvas canvas,
    required List<({Offset pos, int metros, bool escarpa})> rotulos,
    required double opacidade,
  }) {
    if (opacidade <= 0.04) return;
    final pincelFundo = Paint()
      ..color = Color.fromRGBO(12, 16, 23, (0.90 * opacidade).clamp(0.0, 1.0));

    for (final item in rotulos) {
      final corBorda = item.escarpa
          ? _corCobreEscarpasAresta.withValues(
              alpha: (0.62 * opacidade).clamp(0.0, 1.0),
            )
          : Color.fromRGBO(168, 184, 204, (0.52 * opacidade).clamp(0.0, 1.0));
      final tp = TextPainter(
        text: TextSpan(
          text: '${item.metros} m',
          style: TextStyle(
            color: Color.fromRGBO(
              236,
              242,
              249,
              (0.94 * opacidade).clamp(0.0, 1.0),
            ),
            fontSize: 9.2,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.25,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: item.pos,
          width: tp.width + 10.0,
          height: tp.height + 4.0,
        ),
        const Radius.circular(5.0),
      );
      canvas.drawRRect(rect, pincelFundo);
      canvas.drawRRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.95
          ..color = corBorda,
      );
      tp.paint(
        canvas,
        Offset(item.pos.dx - tp.width * 0.5, item.pos.dy - tp.height * 0.5),
      );
      tp.dispose();
    }
  }
}
