// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../data/modelos/modelos_relevo_topografico.dart';
import 'componentes_marcador_globo.dart';
import 'controlador_camera_globo.dart';
import 'malha_relevo_lod.dart';
import 'pintor_rede_viaria_aresta_globo.dart';
import 'pintor_terreno_vetores_globo.dart';

export 'pintor_atmosfera_clima_globo.dart';

/// Pintor acelerado por GPU (`CustomPainter`) da superfície planetária (`NASA Blue Marble` + `EGM96`)
/// que compõe oceanos, transição dinâmica satélite/P&B, terreno topográfico contínuo, divisas IBGE,
/// malha viária Aresta pré-computada e onda sonar de seleção (Dumb UI).
class PintorPlanetaGlobo extends CustomPainter {
  static final Float64List _matrizIdentidade = Float64List.fromList(const [
    1, 0, 0, 0,
    0, 1, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1,
  ]);
  static const double _grausParaRad = math.pi / 180.0;

  final ControladorCameraGlobo controlador;
  final MalhaGeograficaGlobo? malha;
  final RedeViariaArestaGlobo? redeViaria;
  final ConjuntoCurvasNivelMundo? curvasMundo;
  final double? Function(double latitude, double longitude)?
      amostradorElevacaoReal;
  final ui.Image? texturaNasa;
  final List<PicoRelevoReferencia> picosReferencia;
  final MarcadorPicoGlobo? sonarPico;
  final double progressoSonar;
  final double progressoLuzViaria;

  const PintorPlanetaGlobo({
    required this.controlador,
    required this.malha,
    this.redeViaria,
    this.curvasMundo,
    this.amostradorElevacaoReal,
    required this.texturaNasa,
    required this.picosReferencia,
    required this.sonarPico,
    required this.progressoSonar,
    this.progressoLuzViaria = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final lod = controlador.lod;
    final rPx = controlador.raioAparentePx;
    final cy = controlador.calcularCentroVerticalOptico(size);
    final recortarGeoide = controlador.modo3D && rPx < 900.0;
    final centroGlobo = Offset(size.width * 0.5, cy);
    final Path? silhuetaGeoide = recortarGeoide
        ? controlador.construirCaminhoSilhuetaGeoide(size)
        : null;

    canvas.save();
    if (silhuetaGeoide != null) {
      canvas.clipPath(silhuetaGeoide);
    }

    _desenharOceanoBase(canvas, size, centroGlobo, rPx, cy, recortarGeoide);
    _desenharSuperficiePlanetaria(canvas, size, lod);
    _desenharGradesERodovias(canvas, size, lod);
    _desenharFronteirasIbge(canvas, size, lod);
    _desenharOndaSonarSelecao(canvas, size, lod);

    if (silhuetaGeoide != null) {
      _desenharLimbAtmosfericoGeoide(canvas, silhuetaGeoide, centroGlobo, rPx);
    }
    canvas.restore();
  }

