// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';

import '../../data/modelos/modelos_clima_pico.dart';
import 'controlador_camera_globo.dart';
import 'malha_relevo_lod.dart';
import 'pintor_incendio_globo.dart';
import 'pintor_tempestade_globo.dart';

/// Camada atmosférica superior (`IgnorePointer`) posicionada acima dos ícones de picos Aresta
/// na árvore de widgets, garantindo que tempestades e incêndios filtrem cromaticamente qualquer
/// marcador sob sua projeção sem bloquear toques.
class PintorFenomenosAtmosfericosGlobo extends CustomPainter {
  final ControladorCameraGlobo controlador;
  final List<PicoRelevoReferencia> picosReferencia;
  final List<BolhaAtivaRenderizavel> bolhasAtivas;
  final List<BolhaIncendioAtivaRenderizavel> incendiosAtivos;
  final String? sonarBolhaId;
  final double faseTempestadeSegundos;

  const PintorFenomenosAtmosfericosGlobo({
    required this.controlador,
    required this.picosReferencia,
    required this.bolhasAtivas,
    required this.incendiosAtivos,
    required this.sonarBolhaId,
    required this.faseTempestadeSegundos,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (bolhasAtivas.isEmpty && incendiosAtivos.isEmpty) return;

    final recortarGeoide =
        controlador.modo3D && controlador.raioAparentePx < 900.0;
    if (recortarGeoide) {
      canvas.save();
      canvas.clipPath(controlador.construirCaminhoSilhuetaGeoide(size));
    }

    if (bolhasAtivas.isNotEmpty) {
      PintorTempestadeGlobo.desenharTempestades(
        canvas: canvas,
        tamanhoTela: size,
        controlador: controlador,
        bolhasAtivas: bolhasAtivas,
        picosReferencia: picosReferencia,
        faseSegundos: faseTempestadeSegundos,
        bolhaRealcadaId: sonarBolhaId,
      );
    }
    if (incendiosAtivos.isNotEmpty) {
      PintorIncendioGlobo.desenharIncendios(
        canvas: canvas,
        tamanhoTela: size,
        controlador: controlador,
        incendiosAtivos: incendiosAtivos,
        bolhasChuvaAtivas: bolhasAtivas,
        picosReferencia: picosReferencia,
        faseSegundos: faseTempestadeSegundos,
      );
    }

    if (recortarGeoide) {
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant PintorFenomenosAtmosfericosGlobo oldDelegate) =>
      true;
}

