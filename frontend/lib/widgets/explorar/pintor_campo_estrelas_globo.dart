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

      resultado.add(
        EstrelaProjetadaCampo(
          indice: i,
          posicao: Offset(sx, sy),
          raioPx: (i % 5 == 0) ? 1.35 : 0.88,
          cor: cor,
          possuiHaloSuave: i % 10 == 0,
        ),
      );
    }

    return resultado;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final lod = controlador.lod;
    final rPx = controlador.raioAparentePx;
    final cy = controlador.calcularCentroVerticalOptico(size);
    final skyMix = controlador.modo3D
        ? ControladorCameraGlobo.smoothstep(1.55, 2.75, lod)
        : 0.0;
    final retTela = Offset.zero & size;

    final pinturaFundo = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: skyMix > 0.5
            ? const [Color(0xFF102238), Color(0xFF1E3A58), Color(0xFF090F18)]
            : const [Color(0xFF040811), Color(0xFF0A1424), Color(0xFF050A13)],
      ).createShader(retTela);
    canvas.drawRect(retTela, pinturaFundo);

    if (controlador.modo3D && rPx < 760.0) {
      final centroGlobo = Offset(size.width * 0.5, cy);
      final estrelas = calcularEstrelasVisiveis(
        tamanho: size,
        centroGlobo: centroGlobo,
        raioGloboPx: rPx,
        tempoSegundos: tempoSegundosListenable.value,
        longitudeCameraGraus: controlador.longitudeCentral,
        latitudeCameraGraus: controlador.latitudeCentral,
      );

      final paintEstrela = Paint()..style = PaintingStyle.fill;
      for (final e in estrelas) {
        if (e.possuiHaloSuave) {
          paintEstrela.color = e.cor.withValues(alpha: e.cor.a * 0.24);
          canvas.drawCircle(e.posicao, e.raioPx * 2.35, paintEstrela);
        }
        paintEstrela.color = e.cor;
        canvas.drawCircle(e.posicao, e.raioPx, paintEstrela);
      }

      final caminhoHaloGeoide =
          controlador.construirCaminhoSilhuetaGeoide(size, escalaExtra: 1.20);
      final haloAtmosfera = Paint()
        ..shader = RadialGradient(
          colors: const [
            Color(0x5260A5FA),
            Color(0x2838BDF8),
            Color(0x0A0284C7),
            Color(0x000284C7),
          ],
          stops: const [0.78, 0.87, 0.95, 1.0],
        ).createShader(
          Rect.fromCircle(center: centroGlobo, radius: rPx * 1.22),
        );
      canvas.drawPath(caminhoHaloGeoide, haloAtmosfera);
    }
  }

  @override
  bool shouldRepaint(covariant PintorCampoEstrelasGlobo oldDelegate) =>
      oldDelegate.controlador != controlador ||
      oldDelegate.tempoSegundosListenable != tempoSegundosListenable;
}
