// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../data/modelos/modelos_clima_pico.dart';
import '../../utils/geometria_clipping_mapa.dart';
import 'controlador_camera_globo.dart';
import 'efeitos_particulas_tempestade_globo.dart';
import 'malha_relevo_lod.dart';

/// Renderizador meteorológico de tempestades ao vivo com contornos reais (isoietas),
/// trajetória histórica (`rastrosPassados`), setas exclusivas de rumo de deslocamento
/// e efeito *pitter-patter* de gotas sobre a superfície.
abstract final class PintorTempestadeGlobo {
  static const double _grausParaRad = math.pi / 180.0;

  /// Verifica por ray-casting se `(longitude, latitude)` encontra-se no interior de [contorno].
  static bool contemCoordenadaNoContorno({
    required double longitude,
    required double latitude,
    required List<PontoContornoGeo> contorno,
  }) {
    var dentro = false;
    for (var i = 0, j = contorno.length - 1; i < contorno.length; j = i++) {
      final xi = contorno[i].longitude;
      final yi = contorno[i].latitude;
      final xj = contorno[j].longitude;
      final yj = contorno[j].latitude;
      final cruza = ((yi > latitude) != (yj > latitude)) &&
          (longitude < (xj - xi) * (latitude - yi) / (yj - yi) + xi);
      if (cruza) dentro = !dentro;
    }
    return dentro;
  }

  /// Desenha todas as frentes de tempestade visíveis em [bolhasAtivas] e retorna quantas foram pintadas.
  static int desenharTempestades({
    required Canvas canvas,
    required Size tamanhoTela,
    required ControladorCameraGlobo controlador,
    required List<BolhaAtivaRenderizavel> bolhasAtivas,
    required List<PicoRelevoReferencia> picosReferencia,
    required double faseSegundos,
    String? bolhaRealcadaId,
  }) {
    final lod = controlador.lod;
    final sobreRelevo = lod >= 1.45;
    final atenuacaoLod =
        1.0 - 0.66 * ControladorCameraGlobo.smoothstep(2.25, 3.65, lod);
    final pxPorGrau = (controlador.modo3D
            ? controlador.raioAparentePx
            : controlador.calcularEscala2D(tamanhoTela)) *
        _grausParaRad;
    final cyOptico = controlador.calcularCentroVerticalOptico(tamanhoTela);
    final cosLatCam =
        math.max(0.28, math.cos(controlador.latitudeCentral * _grausParaRad));
    var desenhadas = 0;

    for (final bolhaAtiva in bolhasAtivas) {
      final bolha = bolhaAtiva.bolha;
      final realcada = bolhaRealcadaId == bolha.id;
      final rumoRad = bolha.ventoRumoGraus * _grausParaRad;
      final uLon = math.sin(rumoRad);
      final uLat = math.cos(rumoRad);
      final fatorVel = (bolha.ventoVelocidadeKmh / 22.0).clamp(0.40, 2.35);

      final projecaoExterna = _projetarAnelContorno(
        anel: bolha.contornoExterno,
        tamanhoTela: tamanhoTela,
        controlador: controlador,
        picosReferencia: picosReferencia,
        sobreRelevo: sobreRelevo,
        faseSegundos: faseSegundos,
        uLon: uLon,
        uLat: uLat,
        fatorVel: fatorVel,
        amplitudeOndulacaoGraus: 0.016,
      );
      if (!projecaoExterna.visivel) continue;
      desenhadas++;

      final limites = projecaoExterna.limites;
      final spanLonGeo = math.max(0.05, bolha.maxLon - bolha.minLon);
      final spanLatGeo = math.max(0.05, bolha.maxLat - bolha.minLat);
      final alcanceGeoGraus = math.max(spanLonGeo, spanLatGeo);
      final menorLadoMundoPx =
          math.min(spanLonGeo * cosLatCam, spanLatGeo) * pxPorGrau;
      final maiorLadoMundoPx =
          math.max(spanLonGeo * cosLatCam, spanLatGeo) * pxPorGrau;

