// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../data/modelos/modelos_relevo_topografico.dart';
import '../../utils/extrator_curvas_nivel_mundo.dart';
import '../../utils/geometria_clipping_mapa.dart';
import 'controlador_camera_globo.dart';
import 'malha_relevo_lod.dart';

/// Renderizador cartográfico puramente declarativo (Dumb UI) de isolinhas topográficas suaves
/// ancoradas em coordenadas fixas do mundo (`ConjuntoCurvasNivelMundo`), eliminando qualquer
/// deformação ou movimento aparente das curvas quando a câmera faz pan, rotação ou zoom.
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

    final rotulosCotas = <({Offset pos, int metros})>[];
    final exibirRotulosCota = lod >= 2.75;
    final margemTelaX = size.width * 0.35;
    final margemTelaY = size.height * 0.35;

    for (final curva in conjunto.curvas) {
      final elevProj = curva.cotaMetros.toDouble() * opacidadeTerreno;
      final destino = curva.ehEscarpaPico
          ? caminhoEscarpasAresta
          : (curva.ehMestra ? caminhoMestras : caminhoSecundarias);

      var iniciado = false;
      var segmentosVisiveis = 0;
      for (final v in curva.verticesLonLat) {
        if (!janela.contemPonto(v.dx, v.dy)) {
          iniciado = false;
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
          iniciado = false;
          continue;
        }
        if (!iniciado) {
          destino.moveTo(pt.x, pt.y);
          iniciado = true;
        } else {
          destino.lineTo(pt.x, pt.y);
          segmentosVisiveis++;
        }
      }

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
          rotulosCotas.length < 5 &&
          janela.contemPonto(ancora.dx, ancora.dy)) {
        final ptRotulo = controlador.projetarCoordenada(
          latitude: ancora.dy,
          longitude: ancora.dx,
          elevacaoMetros: elevProj + 3.0,
          tamanhoTela: size,
        );
        if (ptRotulo.visivel &&
            ptRotulo.x > 54.0 &&
            ptRotulo.x < size.width - 54.0 &&
            ptRotulo.y > 96.0 &&
            ptRotulo.y < size.height - controlador.alturaGavetaPx - 28.0) {
          final pos = Offset(ptRotulo.x, ptRotulo.y);
          final semColisao = rotulosCotas.every(
            (r) => (r.pos - pos).distanceSquared > 145.0 * 145.0,
          );
          if (semColisao) {
            rotulosCotas.add((pos: pos, metros: curva.cotaMetros));
          }
        }
      }
    }

    final ganhoMono = 0.58 + 0.42 * fatorMonocromatico;
    if (temSecundaria) {
      canvas.drawPath(
        caminhoSecundarias,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = lod >= 3.4 ? 0.72 : 0.56
          ..color = Color.fromRGBO(
            186,
            198,
            214,
            (0.22 * pesoCurvas * ganhoMono).clamp(0.0, 1.0),
          ),
      );
    }
