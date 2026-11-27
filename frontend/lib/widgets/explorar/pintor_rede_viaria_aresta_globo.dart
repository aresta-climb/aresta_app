// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../utils/geometria_clipping_mapa.dart';
import 'controlador_camera_globo.dart';
import 'malha_relevo_lod.dart';

/// Renderizador cartográfico puramente declarativo (Dumb UI) da camada viária monocromática
/// e do pulso luminoso laranja Aresta pré-computado em [RedeViariaArestaGlobo].
abstract final class PintorRedeViariaArestaGlobo {
  static const Color corLaranjaAresta = Color(0xFFE27D60);
  static const Color corBrilhoViasAresta = Color(0xFFFF9248);
  static const Color corFilamentoQuente = Color(0xFFFFE3B8);

  /// Desenha a malha rodoviária P&B de fundo, as cidades de referência (pontos brancos),
  /// a propagação/retração laranja Aresta nas rodovias e o contorno viário das cidades Aresta.
  static void desenharRedeViariaECidades({
    required Canvas canvas,
    required Size size,
    required ControladorCameraGlobo controlador,
    required RedeViariaArestaGlobo? redeViaria,
    required List<PicoRelevoReferencia> picosReferencia,
    required double fatorModoViario,
    required double progressoLuzViaria,
    double? Function(double latitude, double longitude)? amostradorElevacaoReal,
  }) {
    final opacidadeLuzLaranja = math.max(
      fatorModoViario,
      ControladorCameraGlobo.smoothstep(0.0, 0.06, progressoLuzViaria),
    );
    if ((fatorModoViario <= 0.02 && opacidadeLuzLaranja <= 0.02) ||
        redeViaria == null) {
      return;
    }

    final rede = redeViaria;
    final lod = controlador.lod;
    final pesoTerreno = ControladorCameraGlobo.smoothstep(1.35, 2.05, lod);
    final mostrarSecundarias = lod >= 1.95;
    final janelaVisivel = GeometriaClippingMapa.calcularJanelaVisivelCamera(
      modo3D: controlador.modo3D,
      latitudeCentral: controlador.latitudeCentral,
      longitudeCentral: controlador.longitudeCentral,
      lod: lod,
      raioAparentePx: controlador.raioAparentePx,
      escala2D: controlador.modo3D ? 1.0 : controlador.calcularEscala2D(size),
      tamanhoTela: size,
      fatorMargem: 1.08,
    );
    final passoSubdivisaoGraus =
        lod >= 3.40 ? 0.0022 : (lod >= 2.40 ? 0.0070 : 0.024);

    // 1. Malha rodoviária monocromática com leito asfáltico progressivo no zoom próximo
    final escudosRodovia = <({Offset pos, String codigo})>[];
    if (fatorModoViario > 0.02) {
      final caminhoFundo = Path();
      var temFundo = false;
      for (final via in rede.rodoviasFundo) {
        if (!via.ehPrincipal && !mostrarSecundarias) continue;
        Offset? pontoMeioVia;
        if (_adicionarPolilinhaSuaveAoPath(
          destino: caminhoFundo,
          verticesLonLat: via.verticesLonLat,
          janelaVisivel: janelaVisivel,
          passoSubdivisaoGraus: passoSubdivisaoGraus,
          size: size,
          controlador: controlador,
          picosReferencia: picosReferencia,
          pesoTerreno: pesoTerreno,
          amostradorElevacaoReal: amostradorElevacaoReal,
          aoAmostrarPontoCentral: lod >= 2.35 && via.codigo.isNotEmpty
              ? (pt) => pontoMeioVia ??= pt
              : null,
        )) {
          temFundo = true;
          if (pontoMeioVia != null && escudosRodovia.length < 4) {
            final p = pontoMeioVia!;
            final dentroMargem = p.dx > 52.0 &&
                p.dx < size.width - 52.0 &&
                p.dy > 96.0 &&
                p.dy < size.height - controlador.alturaGavetaPx - 28.0;
            final semColisao = escudosRodovia.every(
              (e) =>
                  e.codigo != via.codigo &&
                  (e.pos - p).distanceSquared > 125.0 * 125.0,
            );
            if (dentroMargem && semColisao) {
              escudosRodovia.add((pos: p, codigo: via.codigo));
            }
          }
        }
      }

