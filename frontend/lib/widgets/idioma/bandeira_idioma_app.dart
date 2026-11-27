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

  void _pintarBrasil(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF009B3A),
    );

    final losango = Path()
      ..moveTo(w * 0.50, h * 0.13)
      ..lineTo(w * 0.88, h * 0.50)
      ..lineTo(w * 0.50, h * 0.87)
      ..lineTo(w * 0.12, h * 0.50)
      ..close();
    canvas.drawPath(losango, Paint()..color = const Color(0xFFFEDF00));

    final centro = Offset(w * 0.50, h * 0.50);
    final raioGlobo = h * 0.235;
    canvas.drawCircle(
      centro,
      raioGlobo,
      Paint()..color = const Color(0xFF002776),
    );

    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: centro, radius: raioGlobo)),
    );
    final faixa = Path()
      ..moveTo(centro.dx - raioGlobo * 1.2, centro.dy - raioGlobo * 0.18)
      ..quadraticBezierTo(
        centro.dx,
        centro.dy - raioGlobo * 0.48,
        centro.dx + raioGlobo * 1.2,
        centro.dy + raioGlobo * 0.22,
      );
    canvas.drawPath(
      faixa,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = (h * 0.065).clamp(0.9, 2.2),
    );
    canvas.restore();
  }

  void _pintarEstadosUnidos(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);

    final tintaVermelha = Paint()..color = const Color(0xFFB22234);
    const totalListras = 7;
    final alturaListra = h / totalListras;
    for (var i = 0; i < totalListras; i += 2) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * alturaListra, w, alturaListra),
        tintaVermelha,
      );
    }

    final cantaoLargura = w * 0.46;
    final cantaoAltura = alturaListra * 4;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, cantaoLargura, cantaoAltura),
      Paint()..color = const Color(0xFF3C3B6E),
    );

