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
        final esc = (menorLadoMundoPx * 0.15).clamp(5.0, 14.0);
        final relampago = Path()
          ..moveTo(c.dx + esc * 0.18, c.dy - esc * 0.90)
          ..lineTo(c.dx - esc * 0.30, c.dy - esc * 0.08)
          ..lineTo(c.dx + esc * 0.14, c.dy - esc * 0.08)
          ..lineTo(c.dx - esc * 0.24, c.dy + esc * 0.92);
        canvas.drawPath(
          relampago,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.65
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = Color.fromRGBO(
              254,
              249,
              195,
              (0.90 * onda).clamp(0.0, 1.0),
            ),
        );
      }
    }
  }

  /// Desenha o efeito rítmico *pitter-patter* ancorado em uma grade geográfica fixa no mundo `(0°, 0°)`
  /// com oitavas potência-de-2, garantindo que as gotas jamais deslizem junto com a câmera ao dar zoom ou pan.
  static void desenharPingoPatterChuva({
    required Canvas canvas,
    required BolhaChuvaRegional bolha,
    required NivelIntensidadeChuva nivel,
    required double pxPorGrau,
    required double menorLadoMundoPx,
    required Size tamanhoTela,
    required ControladorCameraGlobo controlador,
    required List<PicoRelevoReferencia> picosReferencia,
    required bool sobreRelevo,
    required double faseSegundos,
    required Color corGota,
  }) {
    final espacamentoAlvoPx = switch (nivel) {
      NivelIntensidadeChuva.fraca => 40.0,
      NivelIntensidadeChuva.moderada => 29.0,
      NivelIntensidadeChuva.forte => 22.5,
      NivelIntensidadeChuva.extrema => 18.0,
    };

    final passoIdealGraus = espacamentoAlvoPx / math.max(1.0, pxPorGrau);
    final octavaCont =
        (math.log(2.0 / passoIdealGraus) / math.ln2).clamp(0.0, 14.0);
    final octavaBase = octavaCont.floor();
    final alfaSub = ControladorCameraGlobo.smoothstep(
      0.18,
      0.94,
      octavaCont - octavaBase,
    );
    final passoFino = (2.0 / (1 << octavaBase)) * 0.5;

    final janela = GeometriaClippingMapa.calcularJanelaVisivelCamera(
      modo3D: controlador.modo3D,
      latitudeCentral: controlador.latitudeCentral,
      longitudeCentral: controlador.longitudeCentral,
      lod: controlador.lod,
      raioAparentePx: controlador.raioAparentePx,
      escala2D: controlador.modo3D
          ? 1.0
          : controlador.calcularEscala2D(tamanhoTela),
      tamanhoTela: tamanhoTela,
      fatorMargem: 1.08,
    );

    final lonIni = math.max(bolha.minLon, janela.minLon);
    final lonFim = math.min(bolha.maxLon, janela.maxLon);
    final latIni = math.max(bolha.minLat, janela.minLat);
    final latFim = math.min(bolha.maxLat, janela.maxLat);
    if (lonFim < lonIni || latFim < latIni) return;

    final ixIni = (lonIni / passoFino).floor();
    final iyIni = (latIni / passoFino).floor();
    final ixFim = math.min(ixIni + 15, (lonFim / passoFino).ceil());
    final iyFim = math.min(iyIni + 15, (latFim / passoFino).ceil());

    final raioMaxAnel =
        (menorLadoMundoPx * (0.07 + 0.022 * nivel.peso)).clamp(2.6, 10.4);
    final pincelAnel = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth =
          menorLadoMundoPx < 28.0 ? 0.75 : (0.70 + 0.16 * nivel.peso);
    final pincelPingo = Paint()..style = PaintingStyle.fill;
    final sementeBolha = bolha.id.codeUnits.fold<int>(19, (a, b) => a * 31 + b);

    var gotasDesenhadas = 0;

    void desenharGotaEmCoordenada({
      required double lon,
      required double lat,
      required int hash,
      required double pesoOctava,
    }) {
      final elev = sobreRelevo
          ? math.max(
                0.0,
                GeradorRelevoLod.amostrarElevacaoMetros(
                  latitude: lat,
                  longitude: lon,
                  picosReferencia: picosReferencia,
                ),
              ) +
              14.0
          : 0.0;

      final pt = controlador.projetarCoordenada(
        latitude: lat,
        longitude: lon,
        elevacaoMetros: elev,
        tamanhoTela: tamanhoTela,
      );
      if (!pt.visivel) return;
      gotasDesenhadas++;

      final cadencia = 0.75 + (hash % 4) * 0.20 + nivel.peso * 0.24;
      final desvioFase = ((hash >> 4) & 0xff) / 255.0;
      final fase = ((faseSegundos * cadencia + desvioFase) % 1.0 + 1.0) % 1.0;
      final centro = Offset(pt.x, pt.y);

      if (fase < 0.26 && menorLadoMundoPx >= 16.0) {
        final tPingo = 1.0 - (fase / 0.26);
        pincelPingo.color = corGota.withValues(
          alpha:
              (corGota.a * pesoOctava * (0.40 + 0.60 * tPingo)).clamp(0.0, 1.0),
        );
        canvas.drawCircle(
          centro,
          (0.65 + 0.18 * nivel.peso) + 0.90 * tPingo,
          pincelPingo,
        );
      }

      final escalaGota = (hash % 3 == 0) ? 1.16 : 0.82;
      final raio = (0.9 + fase * raioMaxAnel) * escalaGota;
      final alfaAnel = (1.0 - fase) * (0.44 + 0.11 * nivel.peso) * pesoOctava;
      pincelAnel.color = corGota.withValues(
        alpha: (corGota.a * alfaAnel).clamp(0.0, 1.0),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: centro,
          width: raio * 2.0,
          height: raio * 1.55,
        ),
        pincelAnel,
      );

      final exibeEco = nivel.peso >= 2 &&
          fase > 0.22 &&
          menorLadoMundoPx >= 22.0 &&
          (nivel.peso == 4 ||
              (nivel.peso == 3 && hash.isEven) ||
              (nivel.peso == 2 && hash % 3 == 0));
      if (exibeEco) {
        final faseEco = (fase - 0.22) / 0.78;
        final raioEco = (0.8 + faseEco * raioMaxAnel * 0.60) * escalaGota;
        pincelAnel.color = corGota.withValues(
          alpha:
              (corGota.a * (1.0 - faseEco) * 0.52 * pesoOctava).clamp(0.0, 1.0),
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: centro,
            width: raioEco * 2.0,
            height: raioEco * 1.55,
          ),
          pincelAnel,
        );
      }
    }

    for (var iy = iyIni; iy <= iyFim; iy++) {
      for (var ix = ixIni; ix <= ixFim; ix++) {
        final ehCelulaBase = ix.isEven && iy.isEven;
        final pesoOctava = ehCelulaBase ? 1.0 : alfaSub;
        if (pesoOctava <= 0.04) continue;

        final h = _hashCelulaMundo(ix, iy, sementeBolha);
        final uJitter = (h & 0x3ff) / 1023.0;
        final vJitter = ((h >> 10) & 0x3ff) / 1023.0;
        final lon = (ix + 0.14 + 0.72 * uJitter) * passoFino;
        final lat = (iy + 0.14 + 0.72 * vJitter) * passoFino;
        if (lon < bolha.minLon ||
            lon > bolha.maxLon ||
            lat < bolha.minLat ||
            lat > bolha.maxLat) {
          continue;
        }
        desenharGotaEmCoordenada(
          lon: lon,
          lat: lat,
          hash: h,
          pesoOctava: pesoOctava,
        );
      }
    }

    // Se um bolsão compacto ficar entre nós da malha mundial, ancora 1 gota fixa em seu centro geográfico
    if (gotasDesenhadas == 0) {
      desenharGotaEmCoordenada(
        lon: bolha.longitude,
        lat: bolha.latitude,
        hash: sementeBolha & 0x7fffffff,
        pesoOctava: 1.0,
      );
    }
  }

  static int _hashCelulaMundo(int ix, int iy, int semente) {
    var h = (ix * 73856093) ^ (iy * 19349663) ^ (semente * 83492791);
    h = ((h >> 16) ^ h) * 0x45d9f3b;
    h = ((h >> 16) ^ h) & 0x7fffffff;
    return h;
  }

  /// Desenha o emblema central da nuvem com assinatura luminosa distinta nos 4 níveis.
  static void desenharEmblemaNuvemChuva({
    required Canvas canvas,
    required Offset centro,
    required double escalaPx,
    required double faseSegundos,
    required NivelIntensidadeChuva nivel,
    required Color corBorda,
  }) {
    final oscY = math.sin(faseSegundos * 2.2) * 0.9;
    final c = centro.translate(0, oscY - escalaPx * 0.14);
    final r = escalaPx * (0.44 + 0.04 * nivel.peso);

    canvas.drawCircle(
      centro,
      escalaPx * (0.95 + 0.08 * nivel.peso),
      Paint()
        ..color = nivel.peso >= 3
            ? const Color(0x78090D16)
            : const Color(0x440F172A)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.8),
    );

    final nuvem = Path()
      ..addOval(
        Rect.fromCircle(
          center: c.translate(-r * 0.65, r * 0.18),
          radius: r * 0.68,
        ),
      )
      ..addOval(
        Rect.fromCircle(
          center: c.translate(r * 0.05, -r * 0.15),
          radius: r * 0.86,
        ),
      )
      ..addOval(
        Rect.fromCircle(
          center: c.translate(r * 0.75, r * 0.22),
          radius: r * 0.62,
        ),
      )
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            c.dx - r * 1.15,
            c.dy,
            c.dx + r * 1.18,
            c.dy + r * 0.78,
          ),
          Radius.circular(r * 0.4),
        ),
      );

