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

      final severidade = f.nivelSeveridade;
      final rumoRad = f.ventoRumoGraus * _grausParaRad;
      final uLon = math.sin(rumoRad);
      final uLat = math.cos(rumoRad);
      final fatorVel = (f.ventoVelocidadeKmh / 20.0).clamp(0.45, 2.20);

      final projBruta = _projetarAnel(
        anel: f.contornoExterno,
        tamanhoTela: tamanhoTela,
        controlador: controlador,
        picosReferencia: picosReferencia,
        sobreRelevo: sobreRelevo,
        faseSegundos: faseSegundos,
        uLon: uLon,
        uLat: uLat,
        amplitudeCintilacaoGraus: 0.003 + 0.0015 * severidade.peso,
      );
      if (!projBruta.visivel) continue;

      final Path caminhoSeco = mascaraChuvasVisiveis != null
          ? Path.combine(
              PathOperation.difference,
              projBruta.caminho,
              mascaraChuvasVisiveis,
            )
          : projBruta.caminho;
      final limites = caminhoSeco.getBounds();
      if (limites.width < 2.0 || limites.height < 2.0) continue;
      desenhados++;

      final paleta = EfeitosParticulasIncendioGlobo.paletaPorSeveridade(
        severidade,
        atenuacaoLod,
      );
      final pxPorGrau = (controlador.modo3D
              ? controlador.raioAparentePx
              : controlador.calcularEscala2D(tamanhoTela)) *
          _grausParaRad;
      final cosLatCam = math.max(
        0.28,
        math.cos(controlador.latitudeCentral * _grausParaRad),
      );
      final spanLonGeo = math.max(0.03, f.maxLon - f.minLon);
      final spanLatGeo = math.max(0.03, f.maxLat - f.minLat);
      final menorLadoMundoPx =
          math.min(spanLonGeo * cosLatCam, spanLatGeo) * pxPorGrau;
      final maiorLadoMundoPx =
          math.max(spanLonGeo * cosLatCam, spanLatGeo) * pxPorGrau;

      final elevCentro = sobreRelevo
          ? math.max(
              0.0,
              GeradorRelevoLod.amostrarTerrenoRegionalContinuo(
                    latitude: f.latitude,
                    longitude: f.longitude,
                    picosReferencia: picosReferencia,
                  ) +
                  28.0,
            )
          : 0.0;
      final ptCentroFogo = controlador.projetarCoordenada(
        latitude: f.latitude,
        longitude: f.longitude,
        elevacaoMetros: elevCentro,
        tamanhoTela: tamanhoTela,
      );
      final centroMundoFogo = Offset(ptCentroFogo.x, ptCentroFogo.y);

      final dirVentoTela = _estimarVetorVentoTela(
        incendio: f,
        uLon: uLon,
        uLat: uLat,
        tamanhoTela: tamanhoTela,
        controlador: controlador,
      );

      // 1. Coluna volumétrica de fumaça e reverberação térmica externa ancoradas ao centro geográfico do foco
      if (ptCentroFogo.visivel) {
        EfeitosParticulasIncendioGlobo.desenharColunaFumacaExterna(
          canvas: canvas,
          origemFogo: centroMundoFogo,
          menorLadoPx: menorLadoMundoPx,
          dirVentoTela: dirVentoTela,
          fatorVel: fatorVel,
          faseSegundos: faseSegundos,
          severidade: severidade,
          paleta: paleta,
        );
        EfeitosParticulasIncendioGlobo.desenharOndaCalorRadiante(
          canvas: canvas,
          centro: centroMundoFogo,
          menorLadoPx: menorLadoMundoPx,
          faseSegundos: faseSegundos,
          severidade: severidade,
          paleta: paleta,
        );
      }

      // 2. Halo termal pulsante + cicatriz incandescente
      final pulsoCalor = 0.84 +
          0.16 *
              math.sin(
                faseSegundos * (3.2 + 0.5 * severidade.peso) + f.id.length,
              );
      final raioBlur =
          (menorLadoMundoPx * (0.16 + 0.03 * severidade.peso)).clamp(2.4, 12.0);
      canvas.drawPath(
        caminhoSeco,
        Paint()
          ..color = paleta.haloTermal.withValues(
            alpha: (paleta.haloTermal.a * pulsoCalor).clamp(0.0, 1.0),
          )
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, raioBlur),
      );
      canvas.drawPath(
        caminhoSeco,
        Paint()..color = paleta.preenchimento,
      );

      // 3. Iluminação termal radial + línguas de chama + núcleos em brasa + fagulhas fixas no mundo
      canvas.save();
      canvas.clipPath(caminhoSeco);

      if (ptCentroFogo.visivel &&
          severidade.peso >= 2 &&
          menorLadoMundoPx >= 16.0) {
        final raioLuz = math.max(12.0, maiorLadoMundoPx * 0.55);
        final alfaCentro = severidade == NivelSeveridadeIncendio.extremo
            ? 0.52
            : (severidade.peso == 3 ? 0.34 : 0.18);
        canvas.drawRect(
          limites.inflate(6.0),
          Paint()
            ..shader = ui.Gradient.radial(
              centroMundoFogo,
              raioLuz,
              <Color>[
                paleta.nucleoBrasa.withValues(
                  alpha: (alfaCentro * pulsoCalor).clamp(0.0, 1.0),
                ),
                Colors.transparent,
              ],
            ),
        );
      }

      EfeitosParticulasIncendioGlobo.desenharChamasEFagulhasAscendentes(
        canvas: canvas,
        incendio: f,
        pxPorGrau: pxPorGrau,
        menorLadoMundoPx: menorLadoMundoPx,
        dirVentoTela: dirVentoTela,
        faseSegundos: faseSegundos,
        fatorVel: fatorVel,
        tamanhoTela: tamanhoTela,
        controlador: controlador,
        picosReferencia: picosReferencia,
        sobreRelevo: sobreRelevo,
        severidade: severidade,
        paleta: paleta,
      );

      for (final nuc in f.nucleosIntensos) {
        final projNuc = _projetarAnel(
          anel: nuc,
          tamanhoTela: tamanhoTela,
          controlador: controlador,
          picosReferencia: picosReferencia,
          sobreRelevo: sobreRelevo,
          faseSegundos: faseSegundos * 1.35,
          uLon: uLon,
          uLat: uLat,
          amplitudeCintilacaoGraus: 0.005,
        );
        if (!projNuc.visivel) continue;
        canvas.drawPath(
          projNuc.caminho,
          Paint()
            ..color = paleta.nucleoBrasa.withValues(
              alpha: (paleta.nucleoBrasa.a * pulsoCalor).clamp(0.0, 1.0),
            )
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0),
        );
      }
      canvas.restore();

