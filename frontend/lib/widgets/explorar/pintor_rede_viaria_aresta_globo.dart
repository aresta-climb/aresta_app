// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../utils/geometria_clipping_mapa.dart';
import 'controlador_camera_globo.dart';
import 'malha_relevo_lod.dart';

/// Renderizador cartográfico puramente declarativo (Dumb UI) da camada viária monocromática
/// e do pulso luminoso laranja Aresta pré-computado em [RedeViariaArestaGlobo].
abstract final class PintorRedeViariaArestaGlobo {
  static const Color corLaranjaAresta = Color(0xFFE27D60);
  static const Color corBrilhoViasAresta = Color(0xFFFF9248);
  static const Color corFilamentoQuente = Color(0xFFFFE3B8);

  /// Desenha a malha rodoviária P&B de fundo, as cidades de referência (pontos brancos),
  /// a propagação/retração laranja Aresta nas rodovias e o contorno viário das cidades Aresta.
  static void desenharRedeViariaECidades({
    required Canvas canvas,
    required Size size,
    required ControladorCameraGlobo controlador,
    required RedeViariaArestaGlobo? redeViaria,
    required List<PicoRelevoReferencia> picosReferencia,
    required double fatorModoViario,
    required double progressoLuzViaria,
    double? Function(double latitude, double longitude)? amostradorElevacaoReal,
  }) {
    final opacidadeLuzLaranja = math.max(
      fatorModoViario,
      ControladorCameraGlobo.smoothstep(0.0, 0.06, progressoLuzViaria),
    );
    if ((fatorModoViario <= 0.02 && opacidadeLuzLaranja <= 0.02) ||
        redeViaria == null) {
      return;
    }

    final rede = redeViaria;
    final lod = controlador.lod;
    final pesoTerreno = ControladorCameraGlobo.smoothstep(1.35, 2.05, lod);
    final mostrarSecundarias = lod >= 1.95;
    final janelaVisivel = GeometriaClippingMapa.calcularJanelaVisivelCamera(
      modo3D: controlador.modo3D,
      latitudeCentral: controlador.latitudeCentral,
      longitudeCentral: controlador.longitudeCentral,
      lod: lod,
      raioAparentePx: controlador.raioAparentePx,
      escala2D: controlador.modo3D ? 1.0 : controlador.calcularEscala2D(size),
      tamanhoTela: size,
      fatorMargem: 1.08,
    );
    final passoSubdivisaoGraus =
        lod >= 3.40 ? 0.0022 : (lod >= 2.40 ? 0.0070 : 0.024);

    // 1. Malha rodoviária monocromática com leito asfáltico progressivo no zoom próximo
    final escudosRodovia = <({Offset pos, String codigo})>[];
    if (fatorModoViario > 0.02) {
      final caminhoFundo = Path();
      var temFundo = false;
      for (final via in rede.rodoviasFundo) {
        if (!via.ehPrincipal && !mostrarSecundarias) continue;
        Offset? pontoMeioVia;
        if (_adicionarPolilinhaSuaveAoPath(
          destino: caminhoFundo,
          verticesLonLat: via.verticesLonLat,
          janelaVisivel: janelaVisivel,
          passoSubdivisaoGraus: passoSubdivisaoGraus,
          size: size,
          controlador: controlador,
          picosReferencia: picosReferencia,
          pesoTerreno: pesoTerreno,
          amostradorElevacaoReal: amostradorElevacaoReal,
          aoAmostrarPontoCentral: lod >= 2.35 && via.codigo.isNotEmpty
              ? (pt) => pontoMeioVia ??= pt
              : null,
        )) {
          temFundo = true;
          if (pontoMeioVia != null && escudosRodovia.length < 4) {
            final p = pontoMeioVia!;
            final dentroMargem = p.dx > 52.0 &&
                p.dx < size.width - 52.0 &&
                p.dy > 96.0 &&
                p.dy < size.height - controlador.alturaGavetaPx - 28.0;
            final semColisao = escudosRodovia.every(
              (e) =>
                  e.codigo != via.codigo &&
                  (e.pos - p).distanceSquared > 125.0 * 125.0,
            );
            if (dentroMargem && semColisao) {
              escudosRodovia.add((pos: p, codigo: via.codigo));
            }
          }
        }
      }

      if (temFundo) {
        final escalaViaZoom =
            1.0 + 1.35 * ControladorCameraGlobo.smoothstep(2.40, 4.20, lod);
        canvas.drawPath(
          caminhoFundo,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2 * escalaViaZoom
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = Color.fromRGBO(
              7,
              10,
              15,
              (0.62 * fatorModoViario).clamp(0.0, 1.0),
            ),
        );
        canvas.drawPath(
          caminhoFundo,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.95 * escalaViaZoom
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = Color.fromRGBO(
              214,
              224,
              236,
              (0.28 * fatorModoViario).clamp(0.0, 1.0),
            ),
        );
      }
    }

    // 2. Corredores laranja Aresta (ida: BH -> extremidades; volta ao dar zoom-out: extremidades -> centro de BH)
    if (progressoLuzViaria > 0.0 && rede.trechosCorredorAresta.isNotEmpty) {
      _desenharCorredoresIluminados(
        canvas: canvas,
        size: size,
        controlador: controlador,
        rede: rede,
        janelaVisivel: janelaVisivel,
        passoSubdivisaoGraus: passoSubdivisaoGraus,
        picosReferencia: picosReferencia,
        pesoTerreno: pesoTerreno,
        fatorModoViario: opacidadeLuzLaranja,
        progressoLuz: progressoLuzViaria,
        amostradorElevacaoReal: amostradorElevacaoReal,
      );
    }

    // 3. Dois tipos de cidade: referência (pontos brancos) vs Aresta-relevantes (contorno viário brilhante)
    _desenharCidadesClassificadas(
      canvas: canvas,
      size: size,
      controlador: controlador,
      rede: rede,
      janelaVisivel: janelaVisivel,
      passoSubdivisaoGraus: passoSubdivisaoGraus,
      picosReferencia: picosReferencia,
      pesoTerreno: pesoTerreno,
      fatorModoViario: fatorModoViario,
      opacidadeLuzLaranja: opacidadeLuzLaranja,
      progressoLuz: progressoLuzViaria,
      amostradorElevacaoReal: amostradorElevacaoReal,
    );

    if (escudosRodovia.isNotEmpty && fatorModoViario > 0.25) {
      _desenharEscudosCodigoRodovia(
        canvas: canvas,
        escudos: escudosRodovia,
        opacidade: (fatorModoViario *
                ControladorCameraGlobo.smoothstep(2.55, 3.15, lod))
            .clamp(0.0, 1.0),
      );
    }
  }

  static void _desenharCorredoresIluminados({
    required Canvas canvas,
    required Size size,
    required ControladorCameraGlobo controlador,
    required RedeViariaArestaGlobo rede,
    required JanelaGeograficaVisivel janelaVisivel,
    required double passoSubdivisaoGraus,
    required List<PicoRelevoReferencia> picosReferencia,
    required double pesoTerreno,
    required double fatorModoViario,
    required double progressoLuz,
    required double? Function(double latitude, double longitude)?
        amostradorElevacaoReal,
  }) {
    final caminhoAceso = Path();
    final pontasOnda = <Offset>[];
    var temAceso = false;

    for (final trecho in rede.trechosCorredorAresta) {
      if (progressoLuz <= trecho.tempoInicio) continue;

      final vertsAtivos = progressoLuz >= trecho.tempoFim
          ? trecho.verticesLonLat
          : _recortarFracaoPolilinhaGeo(
              trecho.verticesLonLat,
              ((progressoLuz - trecho.tempoInicio) /
                      math.max(1e-4, trecho.tempoFim - trecho.tempoInicio))
                  .clamp(0.0, 1.0),
            );
      if (vertsAtivos.length < 2) continue;

      final caminhoTrecho = Path();
      final visivel = _adicionarPolilinhaSuaveAoPath(
        destino: caminhoTrecho,
        verticesLonLat: vertsAtivos,
        janelaVisivel: janelaVisivel,
        passoSubdivisaoGraus: passoSubdivisaoGraus,
        size: size,
        controlador: controlador,
        picosReferencia: picosReferencia,
        pesoTerreno: pesoTerreno,
        amostradorElevacaoReal: amostradorElevacaoReal,
      );
      if (!visivel) continue;

      caminhoAceso.addPath(caminhoTrecho, Offset.zero);
      temAceso = true;

      if (progressoLuz < trecho.tempoFim) {
        final pontaGeo = vertsAtivos.last;
        final ptPonta = controlador.projetarCoordenada(
          latitude: pontaGeo.dy,
          longitude: pontaGeo.dx,
          elevacaoMetros: 6.0,
          tamanhoTela: size,
        );
        if (ptPonta.visivel) {
          pontasOnda.add(Offset(ptPonta.x, ptPonta.y));
        }
      }
    }

    if (!temAceso) return;

    final lod = controlador.lod;
    final espessuraNuc =
        1.25 + 1.10 * ControladorCameraGlobo.smoothstep(2.20, 4.15, lod);
    if (lod >= 2.35) {
      // Leito asfáltico escuro preciso sob o corredor Aresta
      canvas.drawPath(
        caminhoAceso,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = espessuraNuc * 2.15
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = Color.fromRGBO(
            8,
            11,
            17,
            (0.76 * fatorModoViario).clamp(0.0, 1.0),
          ),
      );
    }
    canvas.drawPath(
      caminhoAceso,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = espessuraNuc * 2.45
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = corLaranjaAresta.withValues(
          alpha: (0.34 * fatorModoViario).clamp(0.0, 1.0),
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0),
    );
    canvas.drawPath(
      caminhoAceso,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = espessuraNuc
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = corBrilhoViasAresta.withValues(
          alpha: (0.92 * fatorModoViario).clamp(0.0, 1.0),
        ),
    );
    canvas.drawPath(
      caminhoAceso,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = espessuraNuc * 0.42
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = corFilamentoQuente.withValues(
          alpha: (0.86 * fatorModoViario).clamp(0.0, 1.0),
        ),
    );

