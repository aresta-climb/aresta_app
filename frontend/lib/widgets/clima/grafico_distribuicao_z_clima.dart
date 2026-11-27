// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../theme/cores_app.dart';

/// Gráfico vetorial declarativo (Dumb UI) da Distribuição Normal Padrão (`H₀`) destacando
/// a região crítica na cauda direita (`Z ≥ 1,96`, `Z = +2,57`) e a projeção extrema `+27,7σ`.
class GraficoDistribuicaoZClima extends StatelessWidget {
  final String rotuloH0;
  final String rotuloCaudaDireita;

  const GraficoDistribuicaoZClima({
    super.key,
    required this.rotuloH0,
    required this.rotuloCaudaDireita,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: cores.caveShadow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cores.graniteEdge),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  rotuloH0,
                  style: TextStyle(
                    color: cores.ashGrey,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  rotuloCaudaDireita,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: cores.rustIron,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 108,
            child: CustomPaint(
              painter: _PintorCurvaNormalPadrao(
                corCurva: cores.chalkWhite,
                corCauda: cores.rustIron,
                corGrade: cores.graniteEdge,
                corEixoTexto: cores.ashGrey,
              ),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }
}

class _PintorCurvaNormalPadrao extends CustomPainter {
  final Color corCurva;
  final Color corCauda;
  final Color corGrade;
  final Color corEixoTexto;

  const _PintorCurvaNormalPadrao({
    required this.corCurva,
    required this.corCauda,
    required this.corGrade,
    required this.corEixoTexto,
  });

  static double _pdf(double z) =>
      math.exp(-0.5 * z * z) / math.sqrt(2.0 * math.pi);

  @override
  void paint(Canvas canvas, Size size) {
    const zMin = -3.4;
    const zMax = 3.9;
    final baseY = size.height - 20.0;
    final alturaUtil = math.max(24.0, baseY - 8.0);
    final pdfPico = _pdf(0.0);

    double xDeZ(double z) =>
        ((z - zMin) / (zMax - zMin)) * (size.width - 16.0) + 8.0;
    double yDeZ(double z) => baseY - (_pdf(z) / pdfPico) * alturaUtil;

    // 1. Área sombreada da cauda direita (Z >= 1.96)
    final pathCauda = Path()..moveTo(xDeZ(1.96), baseY);
    for (var s = 0; s <= 36; s++) {
      final z = 1.96 + (zMax - 1.96) * (s / 36.0);
      pathCauda.lineTo(xDeZ(z), yDeZ(z));
    }
    pathCauda
      ..lineTo(xDeZ(zMax), baseY)
      ..close();
    canvas.drawPath(
      pathCauda,
      Paint()..color = corCauda.withValues(alpha: 0.34),
    );

    // 2. Curva em sino completa sob H0
    final pathSino = Path();
    for (var s = 0; s <= 90; s++) {
      final z = zMin + (zMax - zMin) * (s / 90.0);
      final pt = Offset(xDeZ(z), yDeZ(z));
      if (s == 0) {
        pathSino.moveTo(pt.dx, pt.dy);
      } else {
        pathSino.lineTo(pt.dx, pt.dy);
      }
    }
    canvas.drawPath(
      pathSino,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = corCurva.withValues(alpha: 0.86),
    );

    // 3. Linha de base e marcadores verticais canônicos (0, +1.96, +2.57)
    canvas.drawLine(
      Offset(6.0, baseY),
      Offset(size.width - 6.0, baseY),
      Paint()
        ..strokeWidth = 1.0
        ..color = corGrade,
    );

    final marcadores = <({double z, String texto, Color cor})>[
      (z: 0.0, texto: '0σ', cor: corEixoTexto),
      (z: 1.96, texto: '+1.96σ', cor: corCauda),
      (z: 2.57, texto: '+2.57σ', cor: corCauda),
    ];

    for (final m in marcadores) {
      final x = xDeZ(m.z);
      canvas.drawLine(
        Offset(x, yDeZ(m.z)),
        Offset(x, baseY),
        Paint()
          ..strokeWidth = 1.1
          ..color = m.cor.withValues(alpha: 0.65),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: m.texto,
          style: TextStyle(
            color: m.cor,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width * 0.5, baseY + 4.0));
      tp.dispose();
    }

    // Indicador de projeção fora de escala na extrema direita (+27.7σ)
    final setaX = size.width - 10.0;
    final setaY = baseY - 12.0;
    final pincelSeta = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..color = corCauda;
    canvas.drawLine(Offset(setaX - 24.0, setaY), Offset(setaX, setaY), pincelSeta);
    canvas.drawLine(Offset(setaX - 5.0, setaY - 4.0), Offset(setaX, setaY), pincelSeta);
    canvas.drawLine(Offset(setaX - 5.0, setaY + 4.0), Offset(setaX, setaY), pincelSeta);
  }

  @override
  bool shouldRepaint(covariant _PintorCurvaNormalPadrao oldDelegate) =>
      oldDelegate.corCurva != corCurva ||
      oldDelegate.corCauda != corCauda ||
      oldDelegate.corGrade != corGrade ||
      oldDelegate.corEixoTexto != corEixoTexto;
}
