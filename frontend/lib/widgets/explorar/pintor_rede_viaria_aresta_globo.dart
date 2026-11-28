// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../utils/geometria_clipping_mapa.dart';
import 'controlador_camera_globo.dart';
import 'malha_relevo_lod.dart';

/// Renderizador cartográfico puramente declarativo (Dumb UI) das rodovias principais (`BR-xxx`)
/// e do pulso luminoso laranja Aresta, projetado diretamente na superfície do geoide
/// (`elevacaoMetros = 0`) sem paralaxe e sem artefatos urbanos avulsos.
///
/// Os pontos indicadores e rótulos de cidades são renderizados com detecção de colisão em
/// `CamadaMarcadoresGloboExplorar`, evitando bolinhas órfãs sem texto sobre as rodovias.
abstract final class PintorRedeViariaArestaGlobo {
  static const Color corLaranjaAresta = Color(0xFFE27D60);
  static const Color corBrilhoViasAresta = Color(0xFFFF9248);
  static const Color corFilamentoQuente = Color(0xFFFFE3B8);

  /// Desenha a malha de rodovias principais, os corredores laranjas Aresta e os escudos `BR-xxx`.
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
    final alfaNivel2 =
        fatorModoViario * ControladorCameraGlobo.smoothstep(2.05, 2.65, lod);
    final alfaNivel3 =
        fatorModoViario * ControladorCameraGlobo.smoothstep(2.85, 3.40, lod);
    final opacidadeEscudos = (fatorModoViario *
            ControladorCameraGlobo.smoothstep(2.50, 3.10, lod))
        .clamp(0.0, 1.0);
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
    // Subdivisão leve (0,020°) apenas para curvatura esférica e recorte nas bordas
    const passoSubdivisaoGraus = 0.020;

    // 1. Malha rodoviária de fundo (rodovias federais BR-xxx e eventuais níveis secundários)
    final escudosRodovia = <({Offset pos, String codigo})>[];
    if (fatorModoViario > 0.02) {
      final caminhoNivel1 = Path();
      final caminhoNivel2 = Path();
      final caminhoNivel3 = Path();
      var temN1 = false;
      var temN2 = false;
      var temN3 = false;

      for (final via in rede.rodoviasFundo) {
        final nivel = via.nivelViario;
        if (nivel == 2 && alfaNivel2 <= 0.02) continue;
        if (nivel >= 3 && alfaNivel3 <= 0.02) continue;
        if (!via.interceptaJanela(
          janelaMinLon: janelaVisivel.minLon,
          janelaMaxLon: janelaVisivel.maxLon,
          janelaMinLat: janelaVisivel.minLat,
          janelaMaxLat: janelaVisivel.maxLat,
        )) {
          continue;
        }

        final destinoNivel = nivel == 1
            ? caminhoNivel1
            : (nivel == 2 ? caminhoNivel2 : caminhoNivel3);
        Offset? pontoMeioVia;
        if (_adicionarPolilinhaSuaveAoPath(
          destino: destinoNivel,
          verticesLonLat: via.verticesLonLat,
          janelaVisivel: janelaVisivel,
          passoSubdivisaoGraus: passoSubdivisaoGraus,
          size: size,
          controlador: controlador,
          aoAmostrarPontoCentral:
              opacidadeEscudos > 0.04 && nivel <= 2 && via.codigo.isNotEmpty
                  ? (pt) => pontoMeioVia ??= pt
                  : null,
        )) {
          if (nivel == 1) {
            temN1 = true;
          } else if (nivel == 2) {
            temN2 = true;
          } else {
            temN3 = true;
          }
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

      final escalaViaZoom =
          1.0 + 1.25 * ControladorCameraGlobo.smoothstep(2.40, 4.20, lod);
      if (temN3) {
        _desenharCamadaAsfalticaFundo(
          canvas: canvas,
          caminho: caminhoNivel3,
          larguraBorda: 1.45 * escalaViaZoom,
          larguraMiolo: 0.66 * escalaViaZoom,
          alfaBorda: 0.48 * alfaNivel3,
          alfaMiolo: 0.21 * alfaNivel3,
          corMiolo: const Color(0xFFBAC6D6),
        );
      }
      if (temN2) {
        _desenharCamadaAsfalticaFundo(
          canvas: canvas,
          caminho: caminhoNivel2,
          larguraBorda: 1.85 * escalaViaZoom,
          larguraMiolo: 0.82 * escalaViaZoom,
          alfaBorda: 0.56 * alfaNivel2,
          alfaMiolo: 0.26 * alfaNivel2,
          corMiolo: const Color(0xFFCBD5E1),
        );
      }
      if (temN1) {
        _desenharCamadaAsfalticaFundo(
          canvas: canvas,
          caminho: caminhoNivel1,
          larguraBorda: 2.30 * escalaViaZoom,
          larguraMiolo: 1.04 * escalaViaZoom,
          alfaBorda: 0.64 * fatorModoViario,
          alfaMiolo: 0.34 * fatorModoViario,
          corMiolo: const Color(0xFFDEE7F2),
        );
      }
    }

    // 2. Corredores laranjas Aresta (ida: BH -> picos; retração no zoom-out: picos -> BH)
    if (progressoLuzViaria > 0.0 && rede.trechosCorredorAresta.isNotEmpty) {
      _desenharCorredoresIluminados(
        canvas: canvas,
        size: size,
        controlador: controlador,
        rede: rede,
        janelaVisivel: janelaVisivel,
        passoSubdivisaoGraus: passoSubdivisaoGraus,
        fatorModoViario: opacidadeLuzLaranja,
        progressoLuz: progressoLuzViaria,
      );
    }

    // 3. Escudos identificadores das rodovias principais (ex.: BR-040, BR-381, BR-262)
    if (escudosRodovia.isNotEmpty) {
      _desenharEscudosCodigoRodovia(
        canvas: canvas,
        escudos: escudosRodovia,
        opacidade: opacidadeEscudos,
      );
    }
  }

  static void _desenharCamadaAsfalticaFundo({
    required Canvas canvas,
    required Path caminho,
    required double larguraBorda,
    required double larguraMiolo,
    required double alfaBorda,
    required double alfaMiolo,
    required Color corMiolo,
  }) {
    canvas.drawPath(
      caminho,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = larguraBorda
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Color.fromRGBO(7, 10, 15, alfaBorda.clamp(0.0, 1.0)),
    );
    canvas.drawPath(
      caminho,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = larguraMiolo
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = corMiolo.withValues(alpha: alfaMiolo.clamp(0.0, 1.0)),
    );
  }

  static void _desenharCorredoresIluminados({
    required Canvas canvas,
    required Size size,
    required ControladorCameraGlobo controlador,
    required RedeViariaArestaGlobo rede,
    required JanelaGeograficaVisivel janelaVisivel,
    required double passoSubdivisaoGraus,
    required double fatorModoViario,
    required double progressoLuz,
  }) {
    final caminhoAceso = Path();
    final pontasOnda = <Offset>[];
    var temAceso = false;

    for (final trecho in rede.trechosCorredorAresta) {
      if (progressoLuz <= trecho.tempoInicio) continue;

      final vertsAtivos = progressoLuz >= trecho.tempoFim
          ? trecho.verticesLonLat
          : GeometriaClippingMapa.recortarFracaoPolilinhaGeo(
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
      );
      if (!visivel) continue;

      caminhoAceso.addPath(caminhoTrecho, Offset.zero);
      temAceso = true;

      if (progressoLuz < trecho.tempoFim) {
        final pontaGeo = vertsAtivos.last;
        final ptPonta = controlador.projetarCoordenada(
          latitude: pontaGeo.dy,
          longitude: pontaGeo.dx,
          elevacaoMetros: 0.0,
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
        1.05 + 0.85 * ControladorCameraGlobo.smoothstep(2.20, 4.15, lod);
    if (lod >= 2.35) {
      canvas.drawPath(
        caminhoAceso,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = espessuraNuc * 2.10
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = Color.fromRGBO(
            8,
            11,
            17,
            (0.68 * fatorModoViario).clamp(0.0, 1.0),
          ),
      );
    }
    canvas.drawPath(
      caminhoAceso,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = espessuraNuc * 2.15
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = corLaranjaAresta.withValues(
          alpha: (0.16 * fatorModoViario).clamp(0.0, 1.0),
        ),
    );
    canvas.drawPath(
      caminhoAceso,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = espessuraNuc
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = corLaranjaAresta.withValues(
          alpha: (0.72 * fatorModoViario).clamp(0.0, 1.0),
        ),
    );
    canvas.drawPath(
      caminhoAceso,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = espessuraNuc * 0.38
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = corFilamentoQuente.withValues(
          alpha: (0.54 * fatorModoViario).clamp(0.0, 1.0),
        ),
    );

    if (progressoLuz < 1.0 && pontasOnda.isNotEmpty) {
      final pincelHaloPonta = Paint()
        ..color = corBrilhoViasAresta.withValues(
          alpha: (0.28 * fatorModoViario).clamp(0.0, 1.0),
        );
      final pincelCentroPonta = Paint()
        ..color = corFilamentoQuente.withValues(
          alpha: (0.86 * fatorModoViario).clamp(0.0, 1.0),
        );
      for (final p in pontasOnda) {
        canvas.drawCircle(p, 4.2, pincelHaloPonta);
        canvas.drawCircle(p, 1.8, pincelCentroPonta);
      }
    }
  }

  static void _desenharCidadesClassificadas({
    required Canvas canvas,
    required Size size,
    required ControladorCameraGlobo controlador,
    required RedeViariaArestaGlobo rede,
    required JanelaGeograficaVisivel janelaVisivel,
    required double passoSubdivisaoGraus,
    required double fatorModoViario,
    required double opacidadeLuzLaranja,
    required double progressoLuz,
  }) {
    final lod = controlador.lod;
    final nivelMaxVisivel = lod >= 2.85 ? 3 : (lod >= 2.05 ? 2 : 1);
    final caminhoContornosCidades = Path();
    var temContornoCidade = false;

    final pincelBordaPontoRef = Paint()
      ..color = Color.fromRGBO(
        9,
        13,
        20,
        (0.85 * fatorModoViario).clamp(0.0, 1.0),
      );
    final pincelPontoBrancoRef = Paint()
      ..color = Color.fromRGBO(
        248,
        250,
        252,
        (0.88 * fatorModoViario).clamp(0.0, 1.0),
      );

    for (final cidade in rede.cidadesClassificadas) {
      final loc = cidade.localidade;
      final jaIluminada = cidade.ehRelevanteAresta &&
          progressoLuz > 0.0 &&
          progressoLuz >= cidade.tempoAtivacao;
      if (!jaIluminada && fatorModoViario <= 0.02) continue;
      if (!cidade.ehRelevanteAresta && loc.nivel > nivelMaxVisivel) continue;
      if (cidade.ehRelevanteAresta && loc.nivel == 3 && lod < 2.15) {
        continue;
      }

      final pt = controlador.projetarCoordenada(
        latitude: loc.latitude,
        longitude: loc.longitude,
        elevacaoMetros: 0.0,
        tamanhoTela: size,
      );
      if (!pt.visivel ||
          pt.x < -30 ||
          pt.x > size.width + 30 ||
          pt.y < -30 ||
          pt.y > size.height + 30) {
        continue;
      }

      final pos = Offset(pt.x, pt.y);

      if (!jaIluminada) {
        final raioRef = loc.nivel == 1 ? 2.8 : 2.1;
        canvas.drawCircle(pos, raioRef + 1.1, pincelBordaPontoRef);
        canvas.drawCircle(pos, raioRef, pincelPontoBrancoRef);
        continue;
      }

      for (final viaUrbana in cidade.viasUrbanasLonLat) {
        if (_adicionarPolilinhaSuaveAoPath(
          destino: caminhoContornosCidades,
          verticesLonLat: viaUrbana,
          janelaVisivel: janelaVisivel,
          passoSubdivisaoGraus: passoSubdivisaoGraus,
          size: size,
          controlador: controlador,
        )) {
          temContornoCidade = true;
        }
      }

      final deltaTempo = (progressoLuz - cidade.tempoAtivacao).clamp(0.0, 1.0);
      final pulsoChegada =
          progressoLuz < 1.0 ? math.max(0.0, 1.0 - deltaTempo * 4.2) : 0.0;
      final raioNoUrbano = (loc.nivel == 1 ? 3.4 : 2.5) + pulsoChegada * 3.6;

      if (pulsoChegada > 0.04) {
        canvas.drawCircle(
          pos,
          raioNoUrbano * 2.1,
          Paint()
            ..color = corBrilhoViasAresta.withValues(
              alpha:
                  (0.24 * pulsoChegada * opacidadeLuzLaranja).clamp(0.0, 1.0),
            ),
        );
      }
      canvas.drawCircle(
        pos,
        raioNoUrbano,
        Paint()
          ..color = corFilamentoQuente.withValues(
            alpha: (0.86 * opacidadeLuzLaranja).clamp(0.0, 1.0),
          ),
      );
    }

    if (temContornoCidade) {
      canvas.drawPath(
        caminhoContornosCidades,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.35
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = corLaranjaAresta.withValues(
            alpha: (0.18 * opacidadeLuzLaranja).clamp(0.0, 1.0),
          ),
      );
      canvas.drawPath(
        caminhoContornosCidades,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.05
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = corLaranjaAresta.withValues(
            alpha: (0.64 * opacidadeLuzLaranja).clamp(0.0, 1.0),
          ),
      );
    }
  }

  static void _desenharEscudosCodigoRodovia({
    required Canvas canvas,
    required List<({Offset pos, String codigo})> escudos,
    required double opacidade,
  }) {
    if (opacidade <= 0.04) return;
    final pincelFundo = Paint()
      ..color = Color.fromRGBO(12, 16, 23, (0.86 * opacidade).clamp(0.0, 1.0));
    final pincelBorda = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85
      ..color = corLaranjaAresta.withValues(
        alpha: (0.62 * opacidade).clamp(0.0, 1.0),
      );

    for (final item in escudos) {
      final tp = TextPainter(
        text: TextSpan(
          text: item.codigo,
          style: TextStyle(
            color: Color.fromRGBO(
              248,
              250,
              252,
              (0.92 * opacidade).clamp(0.0, 1.0),
            ),
            fontSize: 8.6,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.35,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: item.pos,
          width: tp.width + 9.0,
          height: tp.height + 3.6,
        ),
        const Radius.circular(5.0),
      );
      canvas.drawRRect(rrect, pincelFundo);
      canvas.drawRRect(rrect, pincelBorda);
      tp.paint(
        canvas,
        Offset(item.pos.dx - tp.width * 0.5, item.pos.dy - tp.height * 0.5),
      );
      tp.dispose();
    }
  }

  static bool _adicionarPolilinhaSuaveAoPath({
    required Path destino,
    required List<Offset> verticesLonLat,
    required JanelaGeograficaVisivel janelaVisivel,
    required double passoSubdivisaoGraus,
    required Size size,
    required ControladorCameraGlobo controlador,
    ValueChanged<Offset>? aoAmostrarPontoCentral,
  }) {
    final cadeiasVisiveis = GeometriaClippingMapa.subdividirERecortarPolilinha(
      verticesLonLat: verticesLonLat,
      janela: janelaVisivel,
      passoMaxGraus: passoSubdivisaoGraus,
    );
    if (cadeiasVisiveis.isEmpty) return false;

    final margemX = size.width * 0.65;
    final margemY = size.height * 0.65;
    var adicionou = false;

    for (final cadeia in cadeiasVisiveis) {
      final sub = <Offset>[];
      void descarregar() {
        if (sub.length < 2) {
          sub.clear();
          return;
        }
        adicionou = true;
        if (aoAmostrarPontoCentral != null) {
          aoAmostrarPontoCentral(sub[sub.length ~/ 2]);
        }
        destino.moveTo(sub.first.dx, sub.first.dy);
        for (var i = 1; i < sub.length; i++) {
          destino.lineTo(sub[i].dx, sub[i].dy);
        }
        sub.clear();
      }

      for (final v in cadeia) {
        final pt = controlador.projetarCoordenada(
          latitude: v.dy,
          longitude: v.dx,
          elevacaoMetros: 0.0,
          tamanhoTela: size,
        );
        if (!pt.visivel ||
            pt.x < -margemX ||
            pt.x > size.width + margemX ||
            pt.y < -margemY ||
            pt.y > size.height + margemY) {
          descarregar();
          continue;
        }
        sub.add(Offset(pt.x, pt.y));
      }
      descarregar();
    }
    return adicionou;
  }
}
