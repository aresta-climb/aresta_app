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

  /// Desenha iluminação radial volumétrica interna ancorada ao centro geográfico real da tempestade.
  static void desenharIluminacaoVolumetricaTempestade({
    required Canvas canvas,
    required Rect limitesRecorteTela,
    required Offset centroMundoTela,
    required double maiorLadoMundoPx,
    required double menorLadoMundoPx,
    required NivelIntensidadeChuva nivel,
    required PaletaTempestadeGlobo paleta,
    required double faseSegundos,
  }) {
    if (nivel == NivelIntensidadeChuva.fraca || menorLadoMundoPx < 18.0) return;
    final raio = math.max(12.0, maiorLadoMundoPx * 0.56);
    final pulso = 0.86 + 0.14 * math.sin(faseSegundos * 2.4 + nivel.peso);
    final shader = ui.Gradient.radial(
      centroMundoTela,
      raio,
      <Color>[
        paleta.luzCentro.withValues(
          alpha: (paleta.luzCentro.a * pulso).clamp(0.0, 1.0),
        ),
        paleta.preenchimento.withValues(alpha: 0.04),
        paleta.sombraBorda,
      ],
      const <double>[0.0, 0.58, 1.0],
    );
    canvas.drawRect(limitesRecorteTela.inflate(8.0), Paint()..shader = shader);
  }

  /// Desenha bandas nebulosas suaves ancoradas ao ponto geográfico da tempestade (sem deslizar com a câmera).
  static void desenharBandasAdveccaoVento({
    required Canvas canvas,
    required Rect limitesRecorteTela,
    required Offset ancoraMundoTela,
    required double menorLadoMundoPx,
    required Offset dirTela,
    required double faseSegundos,
    required double fatorVel,
    required Color corCrista,
  }) {
    final comprimentoOndaPx = (menorLadoMundoPx * 0.95).clamp(18.0, 64.0);
    final atenuacaoPequena =
        ((menorLadoMundoPx - 16.0) / 36.0).clamp(0.28, 1.0);
    final deslocamento = (faseSegundos * 22.0 * fatorVel) % comprimentoOndaPx;
    final origem = ancoraMundoTela + dirTela * deslocamento;
    final destino = origem + dirTela * comprimentoOndaPx;

    final shader = ui.Gradient.linear(
      origem,
      destino,
      <Color>[
        Colors.transparent,
        corCrista.withValues(
          alpha: (corCrista.a * atenuacaoPequena).clamp(0.0, 1.0),
        ),
        Colors.transparent,
      ],
      const <double>[0.0, 0.5, 1.0],
      TileMode.repeated,
    );
    canvas.drawRect(
      limitesRecorteTela.inflate(comprimentoOndaPx),
      Paint()..shader = shader,
    );
  }

  /// Desenha células volumétricas de nuvem e relâmpagos posicionados em coordenadas geográficas reais `(lon, lat)`.
  static void desenharCelulasNuvemTempestade({
    required Canvas canvas,
    required BolhaChuvaRegional bolha,
    required double menorLadoMundoPx,
    required double uLon,
    required double uLat,
    required double faseSegundos,
    required double fatorVel,
    required Size tamanhoTela,
    required ControladorCameraGlobo controlador,
    required List<PicoRelevoReferencia> picosReferencia,
    required bool sobreRelevo,
    required NivelIntensidadeChuva nivel,
    required Color corNuvem,
  }) {
    if (nivel == NivelIntensidadeChuva.fraca) return;
    final spanLon = math.max(0.08, bolha.maxLon - bolha.minLon);
    final spanLat = math.max(0.08, bolha.maxLat - bolha.minLat);
    final qtdNuvens = nivel.peso * 2;
    final opacidadeCelula = 0.20 + 0.09 * nivel.peso;

    Offset? projetarPontoBolha(double lon, double lat) {
      final elev = sobreRelevo
          ? math.max(
                0.0,
                GeradorRelevoLod.amostrarElevacaoMetros(
                  latitude: lat,
                  longitude: lon,
                  picosReferencia: picosReferencia,
                ),
              ) +
              18.0
          : 0.0;
      final pt = controlador.projetarCoordenada(
        latitude: lat,
        longitude: lon,
        elevacaoMetros: elev,
        tamanhoTela: tamanhoTela,
      );
      if (!pt.visivel) return null;
      return Offset(pt.x, pt.y);
    }

    for (var i = 0; i < qtdNuvens; i++) {
      final sx = ((i * 47 + 13) % 83) / 83.0;
      final sy = ((i * 31 + 29) % 79) / 79.0;
      final avancoGraus = faseSegundos * 0.025 * fatorVel + i * 0.17;
      final uFrac = ((sx + uLon * avancoGraus) % 1.0 + 1.0) % 1.0;
      final vFrac = ((sy + uLat * avancoGraus) % 1.0 + 1.0) % 1.0;
      final lon = bolha.minLon + (0.08 + 0.84 * uFrac) * spanLon;
      final lat = bolha.minLat + (0.08 + 0.84 * vFrac) * spanLat;
      final pos = projetarPontoBolha(lon, lat);
      if (pos == null) continue;

      final raio =
          (menorLadoMundoPx * (0.20 + (i % 3) * 0.07)).clamp(5.5, 30.0);
      canvas.drawCircle(
        pos,
        raio,
        Paint()
          ..color = corNuvem.withValues(
            alpha: (corNuvem.a * opacidadeCelula).clamp(0.0, 1.0),
          )
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            (raio * 0.52).clamp(3.0, 11.0),
          ),
      );
    }

    if (nivel == NivelIntensidadeChuva.forte) {
      final centro = projetarPontoBolha(bolha.longitude, bolha.latitude);
      if (centro != null) {
        final pulsoCumulus = 0.55 + 0.45 * math.sin(faseSegundos * 2.5);
        canvas.drawCircle(
          centro,
          (menorLadoMundoPx * 0.30).clamp(8.0, 30.0),
          Paint()
            ..color = Color.fromRGBO(
              125,
              211,
              252,
              (0.24 * pulsoCumulus).clamp(0.0, 1.0),
            )
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0),
        );
      }
    } else if (nivel == NivelIntensidadeChuva.extrema) {
      // 3 células elétricas fixas em coordenadas geográficas da tempestade
      const deslocamentos = <Offset>[
        Offset(0.0, 0.0),
        Offset(-0.22, -0.16),
        Offset(0.24, 0.18),
      ];
      for (var k = 0; k < deslocamentos.length; k++) {
        final onda = math
            .pow(0.5 + 0.5 * math.sin(faseSegundos * 3.2 + k * 2.09), 4)
            .toDouble();
        if (onda <= 0.12) continue;
        final c = projetarPontoBolha(
          bolha.longitude + deslocamentos[k].dx * spanLon,
          (bolha.latitude + deslocamentos[k].dy * spanLat).clamp(-89.0, 89.0),
        );
        if (c == null) continue;
        final raioClarao = (menorLadoMundoPx * 0.30).clamp(8.0, 34.0);
        canvas.drawCircle(
          c,
          raioClarao,
          Paint()
            ..color = Color.fromRGBO(
              224,
              242,
              254,
              (0.42 * onda).clamp(0.0, 1.0),
            )
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9.0),
        );
