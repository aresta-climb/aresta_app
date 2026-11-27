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
    final alfaMicroGrade = ControladorCameraGlobo.smoothstep(1.55, 2.05, lod) *
        (1.0 - ControladorCameraGlobo.smoothstep(2.15, 2.65, lod));
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
    final pt = controlador.projetarCoordenada(
      latitude: alvoSonar.latitude,
      longitude: alvoSonar.longitude,
      elevacaoMetros: 0.0,
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

    final double latMin;
    final double latMax;
    final double lonMin;
    final double lonMax;

    if (controlador.modo3D) {
      final multiplicadorHorizonte = 1.18 +
          3.60 * ControladorCameraGlobo.smoothstep(1.30, 2.75, controlador.lod);
      final diagRad =
          (math.max(size.width, size.height) * multiplicadorHorizonte / rPx)
              .clamp(0.002, 1.62);
      final spanLat = (diagRad / _grausParaRad).clamp(0.12, 92.0);
      latMin = (lat0 - spanLat).clamp(-89.92, 89.92);
      latMax = (lat0 + spanLat).clamp(-89.92, 89.92);
      final cobrePoloOuGlobo =
          latMax > 72.0 || latMin < -72.0 || rPx < 520.0;
      final spanLon = cobrePoloOuGlobo
          ? 180.0
          : (spanLat / math.max(0.28, math.cos(lat0 * _grausParaRad)))
              .clamp(0.07, 180.0);
      lonMin = lon0 - spanLon;
      lonMax = lon0 + spanLon;
    } else {
      final escala2D = controlador.calcularEscala2D(size);
      final spanLon2D =
          ((size.width * 0.56 / escala2D) / _grausParaRad).clamp(0.06, 220.0);
      final spanLat2D =
          ((size.height * 0.62 / escala2D) / _grausParaRad).clamp(0.06, 92.0);
      latMin =
          spanLat2D >= 80.0 ? -89.92 : (lat0 - spanLat2D).clamp(-89.92, 89.92);
      latMax =
          spanLat2D >= 80.0 ? 89.92 : (lat0 + spanLat2D).clamp(-89.92, 89.92);
      lonMin = lon0 - spanLon2D;
      lonMax = lon0 + spanLon2D;
    }

    final imgW = imagem.width.toDouble();
    final imgH = imagem.height.toDouble();
    final cosPhi0 = math.cos(lat0 * _grausParaRad);
    final sinPhi0 = math.sin(lat0 * _grausParaRad);
    final fatorSombraEsfera = controlador.modo3D
        ? (1.0 - ControladorCameraGlobo.smoothstep(1.05, 1.85, controlador.lod))
        : 0.0;

    const totalVertices = (rows + 1) * (cols + 1);
    final posicoes = List<Offset>.filled(totalVertices, Offset.zero);
    final uvs = List<Offset>.filled(totalVertices, Offset.zero);
    final cores = List<Color>.filled(totalVertices, Colors.white);
    final visiveis = List<bool>.filled(totalVertices, false);

    for (var j = 0; j <= rows; j++) {
      final lat = latMin + (latMax - latMin) * (j / rows);
      final phi = lat * _grausParaRad;
      final cosPhi = math.cos(phi);
      final sinPhi = math.sin(phi);
      final vPx = (((90.0 - lat) / 180.0) * imgH).clamp(0.5, imgH - 0.5);

      for (var i = 0; i <= cols; i++) {
        final idx = j * (cols + 1) + i;
        final lonCont = lonMin + (lonMax - lonMin) * (i / cols);
        final pt = controlador.projetarCoordenada(
          latitude: lat,
          longitude: lonCont,
          elevacaoMetros: 0.0,
          tamanhoTela: size,
          estenderBordaHorizonte: true,
        );
        if (!pt.visivel) continue;

        visiveis[idx] = true;
        posicoes[idx] = Offset(pt.x, pt.y);
        uvs[idx] = Offset(((lonCont + 180.0) / 360.0) * imgW, vPx);

        double rLuz = 1.0, gLuz = 1.0, bLuz = 1.0;
        if (fatorSombraEsfera > 0.01) {
          final dLam = (lonCont - lon0) * _grausParaRad;
          final x0 = cosPhi * math.sin(dLam);
          final y0 = cosPhi0 * sinPhi - sinPhi0 * cosPhi * math.cos(dLam);
          final z0 = sinPhi0 * sinPhi + cosPhi0 * cosPhi * math.cos(dLam);

          final rLeste = ControladorCameraGlobo.raioNormalizadoGeoide(
            latitude: lat,
            longitude: lonCont + 2.5,
          );
          final rOeste = ControladorCameraGlobo.raioNormalizadoGeoide(
            latitude: lat,
            longitude: lonCont - 2.5,
          );
          final rNorte = ControladorCameraGlobo.raioNormalizadoGeoide(
            latitude: (lat + 2.5).clamp(-89.5, 89.5),
            longitude: lonCont,
          );
          final rSul = ControladorCameraGlobo.raioNormalizadoGeoide(
            latitude: (lat - 2.5).clamp(-89.5, 89.5),
            longitude: lonCont,
          );
          final nx = x0 - (rLeste - rOeste) * 4.2;
          final ny = y0 - (rNorte - rSul) * 4.2;
          final invN =
              1.0 / math.max(1e-4, math.sqrt(nx * nx + ny * ny + z0 * z0));

          final ndotl =
              ((-0.36 * nx + 0.38 * ny + 0.85 * z0) * invN).clamp(0.0, 1.0);
          final difusa = 0.30 + 0.76 * math.pow(ndotl, 0.76).toDouble();
          rLuz = (1.0 - fatorSombraEsfera * (1.0 - difusa * 0.98))
              .clamp(0.20, 1.0);
          gLuz = (1.0 - fatorSombraEsfera * (1.0 - difusa * 1.00))
              .clamp(0.23, 1.0);
          bLuz = (1.0 - fatorSombraEsfera * (1.0 - difusa * 1.06))
              .clamp(0.30, 1.0);
        }

        cores[idx] = Color.fromRGBO(
          (rLuz * 255).round().clamp(0, 255),
          (gLuz * 255).round().clamp(0, 255),
          (bLuz * 255).round().clamp(0, 255),
          opacidade.clamp(0.0, 1.0),
        );
      }
    }

    final indices = <int>[];
    for (var j = 0; j < rows; j++) {
      for (var i = 0; i < cols; i++) {
        final i00 = j * (cols + 1) + i;
        final i10 = i00 + 1;
        final i01 = i00 + (cols + 1);
        final i11 = i01 + 1;
        if (visiveis[i00] && visiveis[i10] && visiveis[i01] && visiveis[i11]) {
          indices
            ..add(i00)
            ..add(i10)
            ..add(i11)
            ..add(i00)
            ..add(i11)
            ..add(i01);
        }
      }
    }

    if (indices.isEmpty) return;

    final shader = ImageShader(
      imagem,
      TileMode.repeated,
      TileMode.clamp,
      _matrizIdentidade,
    );
    final pincelTextura = Paint()
      ..shader = shader
      ..filterQuality = FilterQuality.high;
    if (fatorMonocromatico > 0.01) {
      final s = (1.0 - fatorMonocromatico).clamp(0.0, 1.0);
      final k = fatorMonocromatico.clamp(0.0, 1.0);
      pincelTextura.colorFilter = ColorFilter.matrix(<double>[
        0.2126 * k + s, 0.7152 * k, 0.0722 * k, 0, 0,
        0.2126 * k, 0.7152 * k + s, 0.0722 * k, 0, 0,
        0.1800 * k, 0.6200 * k, 0.2400 * k + s, 0, 6.0 * k,
        0, 0, 0, 1, 0,
      ]);
    }
    canvas.drawVertices(
      ui.Vertices(
        ui.VertexMode.triangles,
        posicoes,
        textureCoordinates: uvs,
        colors: cores,
        indices: indices,
      ),
      BlendMode.modulate,
      pincelTextura,
    );
  }

  @override
  bool shouldRepaint(covariant PintorPlanetaGlobo oldDelegate) => true;
}
