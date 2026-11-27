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

      final elevCentro = sobreRelevo
          ? math.max(
                0.0,
                GeradorRelevoLod.amostrarElevacaoMetros(
                  latitude: bolha.latitude,
                  longitude: bolha.longitude,
                  picosReferencia: picosReferencia,
                ),
              ) +
              18.0
          : 0.0;
      final ptCentroMundo = controlador.projetarCoordenada(
        latitude: bolha.latitude,
        longitude: bolha.longitude,
        elevacaoMetros: elevCentro,
        tamanhoTela: tamanhoTela,
      );
      final dLonCentro =
          ((bolha.longitude - controlador.longitudeCentral + 540.0) % 360.0) -
              180.0;
      final centroMundoAncora = ptCentroMundo.visivel
          ? Offset(ptCentroMundo.x, ptCentroMundo.y)
          : Offset(
              tamanhoTela.width * 0.5 + dLonCentro * cosLatCam * pxPorGrau,
              cyOptico -
                  (bolha.latitude - controlador.latitudeCentral) * pxPorGrau,
            );

      final ehSistemaSinotico = alcanceGeoGraus >= 0.85 ||
          bolha.rastrosPassados.isNotEmpty ||
          realcada;
      final realceBolsoCompacto =
          (!ehSistemaSinotico && bolhaAtiva.nivelIntensidade.peso <= 2)
              ? 1.26
              : 1.0;
      final paleta = EfeitosParticulasTempestadeGlobo.paletaPorIntensidade(
        bolhaAtiva.nivelIntensidade,
        atenuacaoLod * realceBolsoCompacto * (realcada ? 1.30 : 1.0),
      );
      final dirTela = _estimarVetorVentoTela(
        bolha: bolha,
        uLon: uLon,
        uLat: uLat,
        tamanhoTela: tamanhoTela,
        controlador: controlador,
      );

      // 0. Pegadas pretéritas + setas de deslocamento ancoradas ao centro geográfico real da frente
      if (ehSistemaSinotico) {
        _desenharRastroPassadoTempestade(
          canvas: canvas,
          bolha: bolha,
          centroAtualTela: centroMundoAncora,
          centroAtualVisivel: ptCentroMundo.visivel,
          menorLadoMundoPx: menorLadoMundoPx,
          dirTela: dirTela,
          faseSegundos: faseSegundos,
          tamanhoTela: tamanhoTela,
          controlador: controlador,
          picosReferencia: picosReferencia,
          sobreRelevo: sobreRelevo,
          paleta: paleta,
        );
      }

      final raioBlur = (menorLadoMundoPx *
              (0.12 + 0.045 * bolhaAtiva.nivelIntensidade.peso))
          .clamp(2.0, 11.0);
      canvas.drawPath(
        projecaoExterna.caminho,
        Paint()
          ..color = paleta.halo
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, raioBlur),
      );
      canvas.drawPath(
        projecaoExterna.caminho,
        Paint()..color = paleta.preenchimento,
      );

      canvas.save();
      canvas.clipPath(projecaoExterna.caminho);

      EfeitosParticulasTempestadeGlobo.desenharIluminacaoVolumetricaTempestade(
        canvas: canvas,
        limitesRecorteTela: limites,
        centroMundoTela: centroMundoAncora,
        maiorLadoMundoPx: maiorLadoMundoPx,
        menorLadoMundoPx: menorLadoMundoPx,
        nivel: bolhaAtiva.nivelIntensidade,
        paleta: paleta,
        faseSegundos: faseSegundos,
      );

      if (menorLadoMundoPx >= 18.0) {
        EfeitosParticulasTempestadeGlobo.desenharBandasAdveccaoVento(
          canvas: canvas,
          limitesRecorteTela: limites,
          ancoraMundoTela: centroMundoAncora,
          menorLadoMundoPx: menorLadoMundoPx,
          dirTela: dirTela,
          faseSegundos: faseSegundos,
          fatorVel: fatorVel,
          corCrista: paleta.bandaVento,
        );
        EfeitosParticulasTempestadeGlobo.desenharCelulasNuvemTempestade(
          canvas: canvas,
          bolha: bolha,
          menorLadoMundoPx: menorLadoMundoPx,
          uLon: uLon,
          uLat: uLat,
          faseSegundos: faseSegundos,
          fatorVel: fatorVel,
          tamanhoTela: tamanhoTela,
          controlador: controlador,
          picosReferencia: picosReferencia,
          sobreRelevo: sobreRelevo,
          nivel: bolhaAtiva.nivelIntensidade,
          corNuvem: paleta.nucleo,
        );
      }

      final pulsoNucleo =
          0.88 + 0.12 * math.sin(faseSegundos * 2.1 + bolha.id.length);
      for (final anelNucleo in bolha.nucleosIntensos) {
        final projNucleo = _projetarAnelContorno(
          anel: anelNucleo,
          tamanhoTela: tamanhoTela,
          controlador: controlador,
          picosReferencia: picosReferencia,
          sobreRelevo: sobreRelevo,
          faseSegundos: faseSegundos,
          uLon: uLon,
          uLat: uLat,
          fatorVel: fatorVel,
          amplitudeOndulacaoGraus: 0.010,
        );
        if (projNucleo.visivel) {
          canvas.drawPath(
            projNucleo.caminho,
            Paint()
              ..color = paleta.nucleo.withValues(
                alpha: (paleta.nucleo.a * pulsoNucleo).clamp(0.0, 1.0),
              )
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0),
          );
        }
      }

      if (menorLadoMundoPx >= 10.0) {
        EfeitosParticulasTempestadeGlobo.desenharPingoPatterChuva(
          canvas: canvas,
          bolha: bolha,
          nivel: bolhaAtiva.nivelIntensidade,
          pxPorGrau: pxPorGrau,
          menorLadoMundoPx: menorLadoMundoPx,
          tamanhoTela: tamanhoTela,
          controlador: controlador,
          picosReferencia: picosReferencia,
          sobreRelevo: sobreRelevo,
          faseSegundos: faseSegundos,
          corGota: paleta.tracoChuva,
        );
      }

      canvas.restore();

      final espessuraBase = 0.72 + 0.18 * bolhaAtiva.nivelIntensidade.peso;
      if (bolhaAtiva.nivelIntensidade == NivelIntensidadeChuva.extrema &&
          menorLadoMundoPx >= 18.0) {
        canvas.drawPath(
          projecaoExterna.caminho,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = espessuraBase + 1.4
            ..color = paleta.halo
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
        );
      }
