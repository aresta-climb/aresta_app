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

    final tintaEstrela = Paint()..color = Colors.white;
    final raioPonto = (h * 0.042).clamp(0.55, 1.3);
    for (var linha = 0; linha < 3; linha++) {
      final py = cantaoAltura * (0.24 + linha * 0.26);
      for (var col = 0; col < 3; col++) {
        final px = cantaoLargura * (0.22 + col * 0.28);
        canvas.drawCircle(Offset(px, py), raioPonto, tintaEstrela);
      }
    }
  }

  void _pintarEspanha(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final tintaVermelha = Paint()..color = const Color(0xFFAA151B);

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.25), tintaVermelha);
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.25, w, h * 0.50),
      Paint()..color = const Color(0xFFF1BF00),
    );
    canvas.drawRect(Rect.fromLTWH(0, h * 0.75, w, h * 0.25), tintaVermelha);

    final brasao = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.33, h * 0.50),
        width: w * 0.13,
        height: h * 0.26,
      ),
      Radius.circular(h * 0.05),
    );
    canvas.drawRRect(brasao, tintaVermelha);
  }

  void _pintarAlemanha(Canvas canvas, Size size) {
    final w = size.width;
    final terco = size.height / 3.0;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, terco),
      Paint()..color = const Color(0xFF18181B),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, terco, w, terco),
      Paint()..color = const Color(0xFFDD0000),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, terco * 2.0, w, terco),
      Paint()..color = const Color(0xFFFFCE00),
    );
  }

  void _pintarPaisesBaixos(Canvas canvas, Size size) {
    final w = size.width;
    final terco = size.height / 3.0;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, terco),
      Paint()..color = const Color(0xFFAE1C28),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, terco, w, terco),
      Paint()..color = Colors.white,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, terco * 2.0, w, terco),
      Paint()..color = const Color(0xFF21468B),
    );
  }

  @override
  bool shouldRepaint(covariant PintorBandeiraIdioma oldDelegate) {
    return oldDelegate.idioma != idioma || oldDelegate.raioBorda != raioBorda;
  }
}
