// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../data/modelos/modelos_clima_pico.dart';
import '../../utils/geometria_clipping_mapa.dart';
import 'controlador_camera_globo.dart';
import 'efeitos_particulas_incendio_globo.dart';
import 'malha_relevo_lod.dart';
import 'pintor_tempestade_globo.dart';

/// Renderizador de zonas de incêndio florestal ativo detectadas por satélite (`NASA FIRMS` / `INPE VIIRS-MODIS`),
/// com exclusão geométrica contra frentes de chuva e distinção visual em 4 níveis de severidade termal.
abstract final class PintorIncendioGlobo {
  static const double _grausParaRad = math.pi / 180.0;

  /// Desenha todas as zonas de incêndio florestal visíveis em [incendiosAtivos] e retorna quantas foram pintadas.
  static int desenharIncendios({
    required Canvas canvas,
    required Size tamanhoTela,
    required ControladorCameraGlobo controlador,
    required List<BolhaIncendioAtivaRenderizavel> incendiosAtivos,
    List<BolhaAtivaRenderizavel> bolhasChuvaAtivas = const [],
    required List<PicoRelevoReferencia> picosReferencia,
    required double faseSegundos,
  }) {
    final lod = controlador.lod;
    final sobreRelevo = lod >= 1.45;
    final atenuacaoLod =
        1.0 - 0.34 * ControladorCameraGlobo.smoothstep(2.5, 3.6, lod);
    var desenhados = 0;

    Path? mascaraChuvasVisiveis;
    Path? mascaraLivreDeChuva;
    if (bolhasChuvaAtivas.isNotEmpty) {
      final acumulada = Path();
      var temChuvaNaTela = false;
      for (final b in bolhasChuvaAtivas) {
        final projChuva = _projetarAnel(
          anel: b.bolha.contornoExterno,
          tamanhoTela: tamanhoTela,
          controlador: controlador,
          picosReferencia: picosReferencia,
          sobreRelevo: sobreRelevo,
          faseSegundos: 0.0,
          uLon: 0.0,
          uLat: 0.0,
          amplitudeCintilacaoGraus: 0.0,
        );
        if (projChuva.visivel) {
          acumulada.addPath(projChuva.caminho, Offset.zero);
          temChuvaNaTela = true;
        }
      }
      if (temChuvaNaTela) {
        mascaraChuvasVisiveis = acumulada;
        final telaExpandida = Path()
          ..addRect(
            Rect.fromLTWH(
              -80.0,
              -80.0,
              tamanhoTela.width + 160.0,
              tamanhoTela.height + 160.0,
            ),
          );
        mascaraLivreDeChuva = Path.combine(
          PathOperation.difference,
          telaExpandida,
          acumulada,
        );
      }
    }

    if (mascaraLivreDeChuva != null) {
      canvas.save();
      canvas.clipPath(mascaraLivreDeChuva);
    }

    for (final item in incendiosAtivos) {
      final f = item.incendio;
      final centroSobChuva = bolhasChuvaAtivas.any(
        (b) => PintorTempestadeGlobo.contemCoordenadaNoContorno(
          longitude: f.longitude,
          latitude: f.latitude,
          contorno: b.bolha.contornoExterno,
        ),
      );
      if (centroSobChuva) continue;

