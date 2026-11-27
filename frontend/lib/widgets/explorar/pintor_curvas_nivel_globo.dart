// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';

import '../../data/modelos/modelos_relevo_topografico.dart';
import '../../utils/extrator_curvas_nivel_mundo.dart';
import '../../utils/geometria_clipping_mapa.dart';
import 'controlador_camera_globo.dart';
import 'malha_relevo_lod.dart';

/// Renderizador cartográfico puramente declarativo (Dumb UI) de isolinhas topográficas sólidas
/// e enxutas ancoradas em coordenadas fixas do mundo (`ConjuntoCurvasNivelMundo`).
///
/// Prioriza poucas linhas contínuas, nítidas e legíveis (sem micro-curvas ruidosas, sem desfoque
/// artificial e sem anéis decorativos sobrepostos aos picos).
abstract final class PintorCurvasNivelGlobo {
  static const Color _corCobreEscarpasAresta = Color(0xFFE88D5A);

  /// Projeta e desenha sobre [canvas] o conjunto de isolinhas do mundo [curvasMundo] (ou extrai
  /// sob demanda caso omitido em testes isolados), preservando rótulos de cota fixos no terreno.
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
    final pesoCurvas = ControladorCameraGlobo.smoothstep(1.92, 2.55, lod) *
        opacidadeTerreno.clamp(0.0, 1.0);
    if (pesoCurvas <= 0.02) return;

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

    final caminhoSecundarias = Path();
    final caminhoMestras = Path();
    final caminhoEscarpasAresta = Path();
    var temSecundaria = false;
    var temMestra = false;
    var temEscarpa = false;

    final rotulosCotas = <({Offset pos, int metros, bool escarpa})>[];
    final exibirRotulosCota = lod >= 2.72;
    final margemTelaX = size.width * 0.35;
    final margemTelaY = size.height * 0.35;

    for (final curva in conjunto.curvas) {
      final elevProj = curva.cotaMetros.toDouble() * opacidadeTerreno;
      final destino = curva.ehEscarpaPico
          ? caminhoEscarpasAresta
          : (curva.ehMestra ? caminhoMestras : caminhoSecundarias);

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
          elevacaoMetros: elevProj + 2.0,
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
        } else if (curva.ehMestra) {
          temMestra = true;
        } else {
          temSecundaria = true;
        }
      }

      final ancora = curva.ancoraRotuloLonLat;
      if (exibirRotulosCota &&
          ancora != null &&
          rotulosCotas.length < 4 &&
          janela.contemPonto(ancora.dx, ancora.dy)) {
        final ptRotulo = controlador.projetarCoordenada(
          latitude: ancora.dy,
          longitude: ancora.dx,
          elevacaoMetros: elevProj + 3.0,
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
    if (temSecundaria) {
      canvas.drawPath(
        caminhoSecundarias,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = lod >= 3.4 ? 1.15 : 0.95
          ..color = Color.fromRGBO(
            168,
            184,
            204,
            (0.42 * pesoCurvas * ganhoMono).clamp(0.0, 1.0),
          ),
      );
    }
    if (temMestra) {
      canvas.drawPath(
        caminhoMestras,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = lod >= 3.4 ? 1.65 : 1.35
          ..color = Color.fromRGBO(
            226,
            234,
            246,
            (0.72 * pesoCurvas * ganhoMono).clamp(0.0, 1.0),
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
          ..strokeWidth = lod >= 3.4 ? 1.80 : 1.50
          ..color = _corCobreEscarpasAresta.withValues(
            alpha: (0.82 * pesoCurvas).clamp(0.0, 1.0),
          ),
      );
    }

    if (rotulosCotas.isNotEmpty) {
      _desenharEtiquetasCotaMestra(
        canvas: canvas,
        rotulos: rotulosCotas,
        opacidade:
            (pesoCurvas * ControladorCameraGlobo.smoothstep(2.72, 3.25, lod))
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
    final pincelCardeal = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.05
      ..color = const Color(0xFFE2E8F0).withValues(
        alpha: (0.40 * alfaAnel).clamp(0.0, 1.0),
      );

    for (final p in picosReferencia) {
      if ((p.latitude - controlador.latitudeCentral).abs() > 0.35 ||
          (p.longitude - controlador.longitudeCentral).abs() > 0.42) {
        continue;
      }
      final cosLat = math.max(0.35, math.cos(p.latitude * (math.pi / 180.0)));
      final caminhoArcos = Path();

      for (var q = 0; q < 4; q++) {
        final angIni = q * (math.pi * 0.5) + 0.18;
        final angFim = (q + 1) * (math.pi * 0.5) - 0.18;
        var iniciado = false;
        for (var s = 0; s <= 8; s++) {
          final a = angIni + (angFim - angIni) * (s / 8.0);
          final lat = p.latitude + math.sin(a) * raioGraus;
          final lon = p.longitude + (math.cos(a) * raioGraus) / cosLat;
          final elev = math.max(
                0.0,
                GeradorRelevoLod.amostrarTerrenoRegionalContinuo(
                  latitude: lat,
                  longitude: lon,
                  picosReferencia: picosReferencia,
                  ehTerraConfirmada: true,
                  amostradorElevacaoReal: amostradorElevacaoReal,
                ),
              ) *
              opacidadeTerreno;
          final pt = controlador.projetarCoordenada(
            latitude: lat,
            longitude: lon,
            elevacaoMetros: elev + 4.0,
            tamanhoTela: size,
          );
          if (!pt.visivel) {
            iniciado = false;
            continue;
          }
          if (!iniciado) {
            caminhoArcos.moveTo(pt.x, pt.y);
            iniciado = true;
          } else {
            caminhoArcos.lineTo(pt.x, pt.y);
          }
        }
      }
      canvas.drawPath(caminhoArcos, pincelAnel);

      for (var c = 0; c < 4; c++) {
        final a = c * (math.pi * 0.5);
        final rInt = raioGraus * 0.86;
        final rExt = raioGraus * 1.14;
        final elevBase = p.altitudeBaseMetros.toDouble() * opacidadeTerreno;
        final pInt = controlador.projetarCoordenada(
          latitude: p.latitude + math.sin(a) * rInt,
          longitude: p.longitude + (math.cos(a) * rInt) / cosLat,
          elevacaoMetros: elevBase + 4.0,
          tamanhoTela: size,
        );
        final pExt = controlador.projetarCoordenada(
          latitude: p.latitude + math.sin(a) * rExt,
          longitude: p.longitude + (math.cos(a) * rExt) / cosLat,
          elevacaoMetros: elevBase + 4.0,
          tamanhoTela: size,
        );
        if (pInt.visivel && pExt.visivel) {
          canvas.drawLine(
            Offset(pInt.x, pInt.y),
            Offset(pExt.x, pExt.y),
            pincelCardeal,
          );
        }
      }
    }
  }

  static void _desenharEtiquetasCotaMestra({
    required Canvas canvas,
    required List<({Offset pos, int metros})> rotulos,
    required double opacidade,
  }) {
    if (opacidade <= 0.04) return;
    final pincelFundo = Paint()
      ..color = Color.fromRGBO(11, 15, 22, (0.82 * opacidade).clamp(0.0, 1.0));
    final pincelBorda = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75
      ..color =
          Color.fromRGBO(148, 163, 184, (0.36 * opacidade).clamp(0.0, 1.0));

    for (final item in rotulos) {
      final tp = TextPainter(
        text: TextSpan(
          text: '${item.metros} m',
          style: TextStyle(
            color: Color.fromRGBO(
              226,
              232,
              240,
              (0.88 * opacidade).clamp(0.0, 1.0),
            ),
            fontSize: 8.6,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: item.pos,
          width: tp.width + 8.0,
          height: tp.height + 3.0,
        ),
        const Radius.circular(4.0),
      );
      canvas.drawRRect(rect, pincelFundo);
      canvas.drawRRect(rect, pincelBorda);
      tp.paint(
        canvas,
        Offset(item.pos.dx - tp.width * 0.5, item.pos.dy - tp.height * 0.5),
      );
      tp.dispose();
    }
  }
}
