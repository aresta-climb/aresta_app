// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../idioma/modelo_idioma_app.dart';

/// Emblema vetorial nítido da bandeira correspondente a cada [IdiomaApp].
///
/// Desenhado via [CustomPaint] puro (sem `Image`, sem assets externos e sem emojis
/// de indicadores regionais que degradam para letras `BR`/`US` no Windows),
/// garantindo nitidez idêntica em todas as plataformas e preservando os invariantes
/// de contagem de imagens da `HomePage` e da `PicoDetailsPage`.
class BandeiraIdiomaApp extends StatelessWidget {
  /// Idioma cuja bandeira representativa será renderizada.
  final IdiomaApp idioma;

  /// Largura lógica da bandeira em pixels independentes de densidade.
  final double largura;

  /// Altura lógica da bandeira em pixels independentes de densidade.
  final double altura;

  /// Raio de arredondamento dos cantos da bandeira.
  final double raioBorda;

  const BandeiraIdiomaApp({
    super.key,
    required this.idioma,
    this.largura = 22.0,
    this.altura = 15.5,
    this.raioBorda = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: largura,
      height: altura,
      child: CustomPaint(
        painter: PintorBandeiraIdioma(
          idioma: idioma,
          raioBorda: raioBorda,
        ),
      ),
    );
  }
}

/// Pintor vetorial das cinco bandeiras suportadas (`BR`, `US`, `ES`, `DE`, `NL`).
class PintorBandeiraIdioma extends CustomPainter {
  final IdiomaApp idioma;
  final double raioBorda;

  const PintorBandeiraIdioma({
    required this.idioma,
    this.raioBorda = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final retangulo = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(retangulo, Radius.circular(raioBorda));

    canvas.save();
    canvas.clipRRect(rrect);

    switch (idioma) {
      case IdiomaApp.portugues:
        _pintarBrasil(canvas, size);
      case IdiomaApp.ingles:
        _pintarEstadosUnidos(canvas, size);
      case IdiomaApp.espanhol:
        _pintarEspanha(canvas, size);
      case IdiomaApp.alemao:
        _pintarAlemanha(canvas, size);
      case IdiomaApp.holandes:
        _pintarPaisesBaixos(canvas, size);
    }

    canvas.restore();

    final borda = Paint()
      ..color = const Color(0x42FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85;
    canvas.drawRRect(rrect, borda);
  }

