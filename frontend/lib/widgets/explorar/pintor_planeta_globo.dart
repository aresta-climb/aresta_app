// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../data/modelos/modelos_relevo_topografico.dart';
import 'componentes_marcador_globo.dart';
import 'controlador_camera_globo.dart';
import 'malha_relevo_lod.dart';
import 'pintor_rede_viaria_aresta_globo.dart';
import 'pintor_terreno_vetores_globo.dart';

export 'pintor_atmosfera_clima_globo.dart';

/// Pintor acelerado por GPU (`CustomPainter`) da superfície planetária (`NASA Blue Marble` + `EGM96`)
/// que compõe oceanos, transição dinâmica satélite/P&B, terreno topográfico contínuo, divisas IBGE,
/// malha viária Aresta pré-computada e onda sonar de seleção (Dumb UI).
class PintorPlanetaGlobo extends CustomPainter {
  static final Float64List _matrizIdentidade = Float64List.fromList(const [
    1, 0, 0, 0,
    0, 1, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1,
  ]);
  static const double _grausParaRad = math.pi / 180.0;

  final ControladorCameraGlobo controlador;
  final MalhaGeograficaGlobo? malha;
  final RedeViariaArestaGlobo? redeViaria;
  final ConjuntoCurvasNivelMundo? curvasMundo;
  final double? Function(double latitude, double longitude)?
      amostradorElevacaoReal;
  final ui.Image? texturaNasa;
  final List<PicoRelevoReferencia> picosReferencia;
  final MarcadorPicoGlobo? sonarPico;
  final double progressoSonar;
  final double progressoLuzViaria;

  const PintorPlanetaGlobo({
    required this.controlador,
    required this.malha,
    this.redeViaria,
    this.curvasMundo,
    this.amostradorElevacaoReal,
    required this.texturaNasa,
    required this.picosReferencia,
    required this.sonarPico,
    required this.progressoSonar,
    this.progressoLuzViaria = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final lod = controlador.lod;
    final rPx = controlador.raioAparentePx;
    final cy = controlador.calcularCentroVerticalOptico(size);
    final recortarGeoide = controlador.modo3D && rPx < 900.0;
    final centroGlobo = Offset(size.width * 0.5, cy);
    final Path? silhuetaGeoide = recortarGeoide
        ? controlador.construirCaminhoSilhuetaGeoide(size)
        : null;

    canvas.save();
    if (silhuetaGeoide != null) {
      canvas.clipPath(silhuetaGeoide);
    }

    _desenharOceanoBase(canvas, size, centroGlobo, rPx, cy, recortarGeoide);
    _desenharSuperficiePlanetaria(canvas, size, lod);
    _desenharGradesERodovias(canvas, size, lod);
    _desenharFronteirasIbge(canvas, size, lod);
    _desenharOndaSonarSelecao(canvas, size, lod);

    if (silhuetaGeoide != null) {
      _desenharLimbAtmosfericoGeoide(canvas, silhuetaGeoide, centroGlobo, rPx);
    }
    canvas.restore();
  }

  void _desenharOceanoBase(
    Canvas canvas,
    Size size,
    Offset centroGlobo,
    double rPx,
    double cy,
    bool recortarGeoide,
  ) {
    final mViario = controlador.fatorModoViario;
    if (controlador.modo3D) {
      final oceanoRect = recortarGeoide
          ? Rect.fromCircle(center: centroGlobo, radius: rPx * 1.04)
          : Rect.fromLTWH(
              0,
              math.max(0.0, cy - rPx * 0.42),
              size.width,
              size.height,
            );
      final oceanoPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.32, -0.34),
          radius: 1.08,
          colors: [
            Color.lerp(
              const Color(0xFF1A436E),
              const Color(0xFF122C4C),
              mViario,
            )!,
            Color.lerp(
              const Color(0xFF0E2948),
              const Color(0xFF0B1E36),
              mViario,
            )!,
            Color.lerp(
              const Color(0xFF071528),
              const Color(0xFF061120),
              mViario,
            )!,
          ],
        ).createShader(oceanoRect);
      canvas.drawRect(oceanoRect, oceanoPaint);
    } else {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = Color.lerp(
            const Color(0xFF0E2640),
            const Color(0xFF0A1C32),
            mViario,
          )!,
      );
    }
  }

  void _desenharSuperficiePlanetaria(Canvas canvas, Size size, double lod) {
    final dadosMalha = malha;
    final imgNasa = texturaNasa;
    final mViario = controlador.fatorModoViario;
    final alfaTerrenoDetalhado =
        ControladorCameraGlobo.smoothstep(1.30, 1.95, lod);
    final opacidadeNasa =
        (1.0 - math.max(alfaTerrenoDetalhado * 0.92, mViario * 0.86))
            .clamp(0.08, 1.0);

    if (imgNasa != null) {
      _desenharEsferaTexturizadaNasa(
        canvas,
        size,
        imgNasa,
        opacidadeNasa,
        mViario,
      );
    }

    // Ao transicionar para o modo viário P&B no nível regional, preenche continentes e Brasil;
    // em zoom aproximado (alfaTerrenoDetalhado -> 1.0) o terreno contínuo assume 100%, evitando cordas costeiras
    final alfaPoligonoContinental = imgNasa == null
        ? 1.0
        : (mViario * 0.94 * (1.0 - alfaTerrenoDetalhado * 0.96));
    if (dadosMalha != null && alfaPoligonoContinental > 0.02) {
      final corContinente = Color.lerp(
        const Color(0xFF2B4235),
        const Color(0xFF12151B),
        mViario,
      )!.withValues(alpha: alfaPoligonoContinental.clamp(0.0, 1.0));
      final corBrasil = Color.lerp(
        const Color(0xFF375540),
        const Color(0xFF171B22),
        mViario,
      )!.withValues(alpha: alfaPoligonoContinental.clamp(0.0, 1.0));

      for (final cont in dadosMalha.continentes) {
        PintorTerrenoVetoresGlobo.desenharPoligonoGeo(
          canvas: canvas,
          size: size,
          controlador: controlador,
          verticesLonLat: cont.verticesLonLat,
          preenchimento: corContinente,
          borda: imgNasa == null ? const Color(0x4093C5FD) : null,
        );
      }
      PintorTerrenoVetoresGlobo.desenharPoligonoGeo(
        canvas: canvas,
        size: size,
        controlador: controlador,
        verticesLonLat: dadosMalha.brasil,
        preenchimento: corBrasil,
        borda: imgNasa == null
            ? const Color(0x66BAE6FD)
            : Color.fromRGBO(
                148,
                163,
                184,
                (0.24 * alfaPoligonoContinental).clamp(0.0, 1.0),
              ),
      );
    }

    if (alfaTerrenoDetalhado > 0.02) {
      PintorTerrenoVetoresGlobo.desenharTerrenoDetalhadoContinuo(
        canvas: canvas,
        size: size,
        controlador: controlador,
        dadosMalha: dadosMalha,
        picosReferencia: picosReferencia,
        opacidadeBase: alfaTerrenoDetalhado,
        fatorMonocromatico: mViario,
        curvasMundo: curvasMundo,
        amostradorElevacaoReal: amostradorElevacaoReal,
      );
    }
  }

  void _desenharGradesERodovias(Canvas canvas, Size size, double lod) {
    final alfaGrade = 1.0 - ControladorCameraGlobo.smoothstep(0.45, 1.05, lod);
    if (alfaGrade > 0.02) {
      PintorTerrenoVetoresGlobo.desenharGradeEsferica(
        canvas: canvas,
        size: size,
        controlador: controlador,
        alfaGrade: alfaGrade,
      );
    }
    final dadosMalha = malha;
    final mViario = controlador.fatorModoViario;
    final alfaMicroGrade = ControladorCameraGlobo.smoothstep(1.65, 2.35, lod);
    if (alfaMicroGrade > 0.02 && dadosMalha != null) {
      PintorTerrenoVetoresGlobo.desenharMicroGradeTopograficaTerrestre(
        canvas: canvas,
        size: size,
        controlador: controlador,
        dadosMalha: dadosMalha,
        alfaBase: alfaMicroGrade * (1.0 - 0.35 * mViario),
      );
    }
    if ((mViario > 0.02 || progressoLuzViaria > 0.005) && redeViaria != null) {
      PintorRedeViariaArestaGlobo.desenharRedeViariaECidades(
        canvas: canvas,
        size: size,
        controlador: controlador,
        redeViaria: redeViaria,
        picosReferencia: picosReferencia,
        fatorModoViario: mViario,
        progressoLuzViaria: progressoLuzViaria,
        amostradorElevacaoReal: amostradorElevacaoReal,
      );
    }
  }

  void _desenharFronteirasIbge(Canvas canvas, Size size, double lod) {
    final dadosMalha = malha;
    if (dadosMalha == null) return;

    final alfaBrasil = 1.0 - ControladorCameraGlobo.smoothstep(0.80, 1.35, lod);
    if (alfaBrasil > 0.02) {
      PintorTerrenoVetoresGlobo.desenharPoligonoGeo(
        canvas: canvas,
        size: size,
        controlador: controlador,
        verticesLonLat: dadosMalha.brasil,
        borda: Color.fromRGBO(224, 242, 254, 0.38 * alfaBrasil),
        espessuraBorda: 1.15,
      );
    }

    final alfaUf = ControladorCameraGlobo.smoothstep(0.32, 0.82, lod) *
        (1.0 - ControladorCameraGlobo.smoothstep(2.45, 3.25, lod));
    if (alfaUf > 0.02) {
      final corUf = Color.fromRGBO(241, 245, 249, 0.32 * alfaUf);
      for (final uf in dadosMalha.estados) {
        PintorTerrenoVetoresGlobo.desenharPoligonoGeo(
          canvas: canvas,
          size: size,
          controlador: controlador,
          verticesLonLat: uf.verticesLonLat,
          borda: corUf,
          espessuraBorda: 0.9,
        );
      }
    }
  }

  void _desenharOndaSonarSelecao(Canvas canvas, Size size, double lod) {
    final alvoSonar = sonarPico;
    if (alvoSonar == null || progressoSonar >= 1.0) return;
    final elev = lod > 1.35
        ? math.max(
            0.0,
            GeradorRelevoLod.amostrarTerrenoRegionalContinuo(
              latitude: alvoSonar.latitude,
              longitude: alvoSonar.longitude,
              picosReferencia: picosReferencia,
              amostradorElevacaoReal: amostradorElevacaoReal,
            ),
          )
        : 0.0;
    final pt = controlador.projetarCoordenada(
      latitude: alvoSonar.latitude,
      longitude: alvoSonar.longitude,
      elevacaoMetros: elev,
      tamanhoTela: size,
    );
    if (!pt.visivel) return;
    final raio = 8.0 + progressoSonar * 34.0;
    final opacidade = ((1.0 - progressoSonar) * 0.85).clamp(0.0, 1.0);
    canvas.drawCircle(
      Offset(pt.x, pt.y),
      raio,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = Color.fromRGBO(226, 125, 96, opacidade),
    );
  }

  void _desenharLimbAtmosfericoGeoide(
    Canvas canvas,
    Path silhuetaGeoide,
    Offset centroGlobo,
    double rPx,
  ) {
    final rectEsfera = Rect.fromCircle(center: centroGlobo, radius: rPx * 1.03);
    canvas.drawPath(
      silhuetaGeoide,
      Paint()
        ..shader = const RadialGradient(
          colors: [
            Color(0x0038BDF8),
            Color(0x1638BDF8),
            Color(0x547DD3FC),
          ],
          stops: [0.76, 0.91, 1.0],
        ).createShader(rectEsfera),
    );
    canvas.drawPath(
      silhuetaGeoide,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.25
        ..color = const Color(0x68BAE6FD),
    );
  }

  void _desenharEsferaTexturizadaNasa(
    Canvas canvas,
    Size size,
    ui.Image imagem,
    double opacidade,
    double fatorMonocromatico,
  ) {
    const cols = 54;
    const rows = 32;
    final rPx = controlador.raioAparentePx;
    final lat0 = controlador.latitudeCentral;
    final lon0 = controlador.longitudeCentral;

