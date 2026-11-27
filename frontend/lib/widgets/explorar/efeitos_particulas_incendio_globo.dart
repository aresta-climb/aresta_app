// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../data/modelos/modelos_clima_pico.dart';
import '../../utils/geometria_clipping_mapa.dart';
import 'controlador_camera_globo.dart';
import 'malha_relevo_lod.dart';

/// Paleta termal graduada em 4 faixas de severidade orbital (`baixo`, `moderado`, `alto`, `extremo`).
typedef PaletaIncendioGlobo = ({
  Color haloTermal,
  Color preenchimento,
  Color nucleoBrasa,
  Color fumacaDensa,
  Color fumacaDifusa,
  Color fagulha,
  Color bordaViva,
});

/// Efeitos visuais de fumaça convectiva, ondas de calor radiante, chamas orgânicas, fagulhas
/// em espiral e emblema vetorial graduados nos 4 níveis de [NivelSeveridadeIncendio].
abstract final class EfeitosParticulasIncendioGlobo {
  /// Retorna a paleta termal calibrada para os 4 níveis de [severidade] escalonada por [multiplicadorOpacidade].
  static PaletaIncendioGlobo paletaPorSeveridade(
    NivelSeveridadeIncendio severidade,
    double multiplicadorOpacidade,
  ) {
    final mult = multiplicadorOpacidade.clamp(0.15, 1.40);
    Color c(int r, int g, int b, double a) =>
        Color.fromRGBO(r, g, b, (a * mult).clamp(0.0, 1.0));

    switch (severidade) {
      case NivelSeveridadeIncendio.baixo:
        return (
          haloTermal: c(217, 119, 6, 0.16),
          preenchimento: c(146, 64, 14, 0.15),
          nucleoBrasa: c(251, 191, 36, 0.36),
          fumacaDensa: c(100, 116, 139, 0.20),
          fumacaDifusa: c(148, 163, 184, 0.10),
          fagulha: c(254, 243, 199, 0.58),
          bordaViva: c(245, 158, 11, 0.56),
        );
      case NivelSeveridadeIncendio.moderado:
        return (
          haloTermal: c(249, 115, 22, 0.28),
          preenchimento: c(194, 65, 12, 0.25),
          nucleoBrasa: c(251, 191, 36, 0.52),
          fumacaDensa: c(71, 85, 105, 0.34),
          fumacaDifusa: c(148, 163, 184, 0.18),
          fagulha: c(253, 224, 71, 0.78),
          bordaViva: c(251, 146, 60, 0.78),
        );
      case NivelSeveridadeIncendio.alto:
        return (
          haloTermal: c(239, 68, 68, 0.42),
          preenchimento: c(185, 28, 28, 0.35),
          nucleoBrasa: c(251, 146, 60, 0.68),
          fumacaDensa: c(51, 65, 85, 0.46),
          fumacaDifusa: c(148, 163, 184, 0.25),
          fagulha: c(254, 240, 138, 0.88),
          bordaViva: c(248, 113, 113, 0.88),
        );
      case NivelSeveridadeIncendio.extremo:
        return (
          haloTermal: c(239, 68, 68, 0.58),
          preenchimento: c(153, 27, 27, 0.44),
          nucleoBrasa: c(253, 224, 71, 0.84),
          fumacaDensa: c(15, 23, 42, 0.62),
          fumacaDifusa: c(100, 116, 139, 0.34),
          fagulha: c(254, 249, 195, 0.98),
          bordaViva: c(254, 240, 138, 0.96),
        );
    }
  }

  /// Desenha a coluna volumétrica de fumaça escalonada do filete leve (`baixo`) até a coluna densa turbulenta (`extremo`).
  static void desenharColunaFumacaExterna({
    required Canvas canvas,
    required Offset origemFogo,
    required double menorLadoPx,
    required Offset dirVentoTela,
    required double fatorVel,
    required double faseSegundos,
    required NivelSeveridadeIncendio severidade,
    required PaletaIncendioGlobo paleta,
  }) {
    final empuxo = Offset(
      dirVentoTela.dx * 0.78,
      dirVentoTela.dy * 0.55 - (0.42 + 0.08 * severidade.peso),
    );
    final norm = math.max(1e-4, empuxo.distance);
    final dirPluma = empuxo / norm;
    final perp = Offset(-dirPluma.dy, dirPluma.dx);

