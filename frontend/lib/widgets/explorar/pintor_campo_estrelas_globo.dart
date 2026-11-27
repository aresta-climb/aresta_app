// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'controlador_camera_globo.dart';

/// Dados imutáveis de uma estrela visível ao redor do planeta em determinado instante.
class EstrelaProjetadaCampo {
  final int indice;
  final Offset posicao;
  final double raioPx;
  final Color cor;
  final bool possuiHaloSuave;

  const EstrelaProjetadaCampo({
    required this.indice,
    required this.posicao,
    required this.raioPx,
    required this.cor,
    required this.possuiHaloSuave,
  });
}

/// Pintor dedicado ao fundo espacial profundo, halo atmosférico externo e campo de estrelas com deriva lenta.
///
/// Isolado em seu próprio `RepaintBoundary` atrás do globo para animar suavemente as estrelas em velocidade
/// subpixel (`~0,30–0,52 px/s`) sem reprocessar a malha 4K da Terra nem travar `pumpAndSettle`.
class PintorCampoEstrelasGlobo extends CustomPainter {
  final ControladorCameraGlobo controlador;
  final ValueListenable<double> tempoSegundosListenable;

  PintorCampoEstrelasGlobo({
    required this.controlador,
    required this.tempoSegundosListenable,
  }) : super(repaint: Listenable.merge([controlador, tempoSegundosListenable]));

  /// Calcula as estrelas visíveis fora do disco planetário com deriva orbital leve, paralaxe sutil e cintilação lenta.
  static List<EstrelaProjetadaCampo> calcularEstrelasVisiveis({
    required Size tamanho,
    required Offset centroGlobo,
    required double raioGloboPx,
    required double tempoSegundos,
    double longitudeCameraGraus = 0.0,
    double latitudeCameraGraus = 0.0,
  }) {
    final alfaBase =
        (1.0 - ControladorCameraGlobo.smoothstep(280.0, 740.0, raioGloboPx)) *
            0.78;
    if (alfaBase <= 0.02) return const [];

    const margem = 8.0;
    final larguraEnv = tamanho.width + margem * 2.0;
    final alturaEnv = tamanho.height * 0.86 + margem * 2.0;
    final rMin2 = (raioGloboPx * 1.04) * (raioGloboPx * 1.04);
    final resultado = <EstrelaProjetadaCampo>[];

    for (var i = 0; i < 48; i++) {
      final camada = (i % 5 == 0) ? 1.0 : 0.58;
      final fx = ((i * 73 + 19) % 97) / 97.0;
      final fy = ((i * 41 + 53) % 89) / 89.0;

      final velX = 0.52 * camada;
      final velY = -0.19 * camada;
      final oscilacaoX =
          math.sin(tempoSegundos * 0.28 + i * 1.37) * (1.20 * camada);
      final oscilacaoY =
          math.cos(tempoSegundos * 0.23 + i * 0.91) * (0.90 * camada);
      final paralaxeX = -longitudeCameraGraus * 0.28 * camada;
      final paralaxeY = latitudeCameraGraus * 0.20 * camada;

      final brutoX =
          fx * larguraEnv + tempoSegundos * velX + oscilacaoX + paralaxeX;
      final brutoY =
          fy * alturaEnv + tempoSegundos * velY + oscilacaoY + paralaxeY;
      final sx = ((brutoX % larguraEnv) + larguraEnv) % larguraEnv - margem;
      final sy = ((brutoY % alturaEnv) + alturaEnv) % alturaEnv - margem;

      final dx = sx - centroGlobo.dx;
      final dy = sy - centroGlobo.dy;
      if (dx * dx + dy * dy < rMin2) continue;

      final cintilacao =
          0.88 + 0.12 * math.sin(tempoSegundos * 0.55 + i * 2.13);
      final brilho =
          ((0.36 + ((i * 29) % 10) * 0.064) * cintilacao * alfaBase)
              .clamp(0.0, 1.0);
      final matiz = i % 7;
      final cor = matiz == 0
          ? Color.fromRGBO(254, 243, 199, brilho)
          : (matiz == 3
              ? Color.fromRGBO(248, 250, 252, brilho)
              : Color.fromRGBO(226, 238, 255, brilho));

