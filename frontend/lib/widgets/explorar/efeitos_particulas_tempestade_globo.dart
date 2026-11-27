// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../data/modelos/modelos_clima_pico.dart';
import '../../utils/geometria_clipping_mapa.dart';
import 'controlador_camera_globo.dart';
import 'malha_relevo_lod.dart';

/// Paleta cromática e de iluminação atmosférica graduada em 4 níveis de tempestade ao vivo.
typedef PaletaTempestadeGlobo = ({
  Color halo,
  Color preenchimento,
  Color luzCentro,
  Color sombraBorda,
  Color bandaVento,
  Color nucleo,
  Color tracoChuva,
  Color borda,
});

/// Efeitos visuais de iluminação radial interna, nuvens convectivas, relâmpagos ramificados,
/// pingo-patter escalonado nos 4 níveis (`fraca`, `moderada`, `forte`, `extrema`) e emblema animado.
abstract final class EfeitosParticulasTempestadeGlobo {
  /// Calcula a paleta de alto contraste luminoso para os 4 níveis de [nivel] escalonada por [multiplicadorOpacidade].
  static PaletaTempestadeGlobo paletaPorIntensidade(
    NivelIntensidadeChuva nivel,
    double multiplicadorOpacidade,
  ) {
    final m = multiplicadorOpacidade.clamp(0.15, 1.45);
    Color c(int r, int g, int b, double a) =>
        Color.fromRGBO(r, g, b, (a * m).clamp(0.0, 1.0));

    switch (nivel) {
      case NivelIntensidadeChuva.fraca:
        return (
          halo: c(125, 211, 252, 0.07),
          preenchimento: c(125, 211, 252, 0.11),
          luzCentro: c(186, 230, 253, 0.06),
          sombraBorda: c(14, 116, 144, 0.05),
          bandaVento: c(186, 230, 253, 0.09),
          nucleo: c(56, 189, 248, 0.18),
          tracoChuva: c(186, 230, 253, 0.46),
          borda: c(186, 230, 253, 0.34),
        );
      case NivelIntensidadeChuva.moderada:
        return (
          halo: c(14, 165, 233, 0.18),
          preenchimento: c(14, 165, 233, 0.24),
          luzCentro: c(125, 211, 252, 0.18),
          sombraBorda: c(3, 105, 161, 0.16),
          bandaVento: c(125, 211, 252, 0.20),
          nucleo: c(2, 132, 199, 0.36),
          tracoChuva: c(186, 230, 253, 0.68),
          borda: c(125, 211, 252, 0.62),
        );
      case NivelIntensidadeChuva.forte:
        return (
          halo: c(37, 99, 235, 0.21),
          preenchimento: c(29, 78, 216, 0.28),
          luzCentro: c(56, 189, 248, 0.34),
          sombraBorda: c(15, 23, 66, 0.28),
          bandaVento: c(147, 197, 253, 0.28),
          nucleo: c(30, 64, 175, 0.48),
          tracoChuva: c(224, 242, 254, 0.84),
          borda: c(147, 197, 253, 0.80),
        );
      case NivelIntensidadeChuva.extrema:
        return (
          halo: c(124, 58, 237, 0.30),
          preenchimento: c(88, 48, 226, 0.33),
          luzCentro: c(186, 230, 253, 0.44),
          sombraBorda: c(30, 27, 94, 0.34),
          bandaVento: c(196, 181, 253, 0.34),
          nucleo: c(109, 40, 217, 0.58),
          tracoChuva: c(240, 249, 255, 0.95),
          borda: c(221, 214, 254, 0.92),
        );
    }
  }

