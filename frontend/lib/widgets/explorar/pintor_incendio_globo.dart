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

      // 4. Borda viva graduada por severidade (com contorno duplo incandescente no nível extremo)
      final espessuraBorda = (0.85 + 0.25 * severidade.peso) *
          (menorLadoMundoPx < 20.0 ? 0.80 : 1.0);
      if (severidade == NivelSeveridadeIncendio.extremo &&
          menorLadoMundoPx >= 18.0) {
        canvas.drawPath(
          caminhoSeco,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = espessuraBorda + 1.5
            ..color = paleta.haloTermal
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2),
        );
      }
      canvas.drawPath(
        caminhoSeco,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = espessuraBorda
          ..color = paleta.bordaViva,
      );

      // 5. Emblema vetorial animado ancorado estritamente à coordenada geográfica real do incêndio
      if (ptCentroFogo.visivel && menorLadoMundoPx >= 13.0) {
        EfeitosParticulasIncendioGlobo.desenharEmblemaChamaViva(
          canvas: canvas,
          centro: centroMundoFogo,
          escalaPx: (menorLadoMundoPx * (0.19 + 0.02 * severidade.peso))
              .clamp(6.0, 14.5),
          faseSegundos: faseSegundos,
          inclinacaoVentoX: (dirVentoTela.dx * 0.28).clamp(-0.32, 0.32),
          severidade: severidade,
          opacidade: atenuacaoLod,
        );
      }
    }

    if (mascaraLivreDeChuva != null) {
      canvas.restore();
    }

    return desenhados;
  }

  static ({Path caminho, Rect limites, bool visivel}) _projetarAnel({
    required List<PontoContornoGeo> anel,
    required Size tamanhoTela,
    required ControladorCameraGlobo controlador,
    required List<PicoRelevoReferencia> picosReferencia,
    required bool sobreRelevo,
    required double faseSegundos,
    required double uLon,
    required double uLat,
    required double amplitudeCintilacaoGraus,
  }) {
    final pts = <Offset>[];
    var minX = double.infinity, maxX = -double.infinity;
    var minY = double.infinity, maxY = -double.infinity;

    var vertices = <Offset>[];
    for (var i = 0; i < anel.length; i++) {
      final v = anel[i];
      final cintilacao = amplitudeCintilacaoGraus > 0.0
          ? math.sin(faseSegundos * 2.6 + i * 1.15) * amplitudeCintilacaoGraus
          : 0.0;
      vertices.add(
        Offset(
          v.longitude + uLon * cintilacao,
          (v.latitude + uLat * cintilacao).clamp(-89.5, 89.5),
        ),
      );
    }

    if (controlador.modo3D && controlador.lod >= 1.65) {
      final janela = GeometriaClippingMapa.calcularJanelaVisivelCamera(
        modo3D: true,
        latitudeCentral: controlador.latitudeCentral,
        longitudeCentral: controlador.longitudeCentral,
        lod: controlador.lod,
        raioAparentePx: controlador.raioAparentePx,
        escala2D: 1.0,
        tamanhoTela: tamanhoTela,
        fatorMargem: 1.06,
      );
      vertices = GeometriaClippingMapa.recortarPoligonoNoRetangulo(
        anelLonLat: vertices,
        janela: janela,
      );
      if (vertices.length < 3) {
        return (caminho: Path(), limites: Rect.zero, visivel: false);
      }
    }

    var lonAnt = 0.0;
    for (final vert in vertices) {
      final lon = vert.dx;
      final lat = vert.dy;
      final elev = sobreRelevo
          ? math.max(
              0.0,
              GeradorRelevoLod.amostrarTerrenoRegionalContinuo(
                    latitude: lat,
                    longitude: lon,
                    picosReferencia: picosReferencia,
                  ) +
                  28.0,
            )
          : 0.0;
      final pt = controlador.projetarCoordenada(
        latitude: lat,
        longitude: lon,
        elevacaoMetros: elev,
        tamanhoTela: tamanhoTela,
      );
      if (!pt.visivel) continue;
      if (pts.isNotEmpty && (lon - lonAnt).abs() > 150.0) {
        continue;
      }
      lonAnt = lon;
      pts.add(Offset(pt.x, pt.y));
      if (pt.x < minX) minX = pt.x;
      if (pt.x > maxX) maxX = pt.x;
      if (pt.y < minY) minY = pt.y;
      if (pt.y > maxY) maxY = pt.y;
    }

    if (pts.length < 3 ||
        maxX < -40 ||
        minX > tamanhoTela.width + 40 ||
        maxY < -40 ||
        minY > tamanhoTela.height + 40) {
      return (caminho: Path(), limites: Rect.zero, visivel: false);
    }

    final caminho = Path()
      ..moveTo(
        (pts.last.dx + pts.first.dx) * 0.5,
        (pts.last.dy + pts.first.dy) * 0.5,
      );
    for (var i = 0; i < pts.length; i++) {
      final atual = pts[i];
      final prox = pts[(i + 1) % pts.length];
      caminho.quadraticBezierTo(
        atual.dx,
        atual.dy,
        (atual.dx + prox.dx) * 0.5,
        (atual.dy + prox.dy) * 0.5,
      );
    }
    caminho.close();
    return (
      caminho: caminho,
      limites: Rect.fromLTRB(minX, minY, maxX, maxY),
      visivel: true,
    );
  }

  static Offset _estimarVetorVentoTela({
    required BolhaIncendioRegional incendio,
    required double uLon,
    required double uLat,
    required Size tamanhoTela,
    required ControladorCameraGlobo controlador,
  }) {
    final p0 = controlador.projetarCoordenada(
      latitude: incendio.latitude,
      longitude: incendio.longitude,
      elevacaoMetros: 0,
      tamanhoTela: tamanhoTela,
    );
    final p1 = controlador.projetarCoordenada(
      latitude: (incendio.latitude + uLat * 0.25).clamp(-89.0, 89.0),
      longitude: incendio.longitude + uLon * 0.25,
      elevacaoMetros: 0,
      tamanhoTela: tamanhoTela,
    );
    final dx = p1.x - p0.x;
    final dy = p1.y - p0.y;
    final n = math.max(1e-3, math.sqrt(dx * dx + dy * dy));
    return Offset(dx / n, dy / n);
  }
}
