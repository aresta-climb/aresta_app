// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../theme/cores_app.dart';

/// Gráfico vetorial declarativo (Dumb UI) da Distribuição Normal Padrão (`H₀`) destacando
/// a região crítica na cauda direita (`Z ≥ 1,96`, `Z = +2,57`) e a projeção extrema `+27,7σ`,
/// com posicionamento escalonado de rótulos livre de colisões ou cortes em telas estreitas.
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
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: cores.deepBasalt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cores.graniteEdge),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _ItemLegendaCurva(
                cor: cores.chalkWhite,
                texto: rotuloH0,
                corTexto: cores.ashGrey,
              ),
              _ItemLegendaCurva(
                cor: cores.rustIron,
                texto: rotuloCaudaDireita,
                corTexto: cores.rustIron,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 128,
            width: double.infinity,
            child: CustomPaint(
              painter: _PintorCurvaNormalPadrao(
                corCurva: cores.chalkWhite,
                corCauda: cores.rustIron,
                corGrade: cores.graniteEdge,
                corEixoTexto: cores.ashGrey,
                corFundoEtiqueta: cores.caveShadow,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemLegendaCurva extends StatelessWidget {
  final Color cor;
  final String texto;
  final Color corTexto;

  const _ItemLegendaCurva({
    required this.cor,
    required this.texto,
    required this.corTexto,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            texto,
            style: TextStyle(
              color: corTexto,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _PintorCurvaNormalPadrao extends CustomPainter {
  final Color corCurva;
  final Color corCauda;
  final Color corGrade;
  final Color corEixoTexto;
  final Color corFundoEtiqueta;

  const _PintorCurvaNormalPadrao({
    required this.corCurva,
    required this.corCauda,
    required this.corGrade,
    required this.corEixoTexto,
    required this.corFundoEtiqueta,
  });

  static double _pdf(double z) =>
      math.exp(-0.5 * z * z) / math.sqrt(2.0 * math.pi);

  @override
  void paint(Canvas canvas, Size size) {
    const zMin = -3.0;
    const zMax = 4.1;
    final baseY = size.height - 22.0;
    final topoCurvaY = 22.0;
    final alturaUtil = math.max(32.0, baseY - topoCurvaY);
    final pdfPico = _pdf(0.0);

    double xDeZ(double z) =>
        ((z - zMin) / (zMax - zMin)) * (size.width - 20.0) + 10.0;
    double yDeZ(double z) => baseY - (_pdf(z) / pdfPico) * alturaUtil;

    // 1. Área sombreada da cauda direita crítica (Z >= 1.96)
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
      Paint()..color = corCauda.withValues(alpha: 0.32),
    );

    // 2. Curva Gaussiana N(0, 1) sob H0
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
        ..strokeWidth = 2.0
        ..color = corCurva.withValues(alpha: 0.88),
    );

    // 3. Eixo horizontal de base
    canvas.drawLine(
      Offset(6.0, baseY),
      Offset(size.width - 6.0, baseY),
      Paint()
        ..strokeWidth = 1.0
        ..color = corGrade,
    );

    // 4. Rótulos escalonados (acima da curva para +1.96σ, abaixo da base para 0σ e +2.57σ)
    // eliminando 100% qualquer colisão horizontal em telas compactas.
    _desenharMarcadorBase(canvas, size, x: xDeZ(-2.0), yTopo: yDeZ(-2.0), baseY: baseY, texto: '-2σ', cor: corEixoTexto);
    _desenharMarcadorBase(canvas, size, x: xDeZ(0.0), yTopo: yDeZ(0.0), baseY: baseY, texto: '0σ', cor: corEixoTexto);
    _desenharMarcadorTopoPilula(canvas, size, x: xDeZ(1.96), yCurva: yDeZ(1.96), baseY: baseY, texto: '+1.96σ', cor: corCauda);
    _desenharMarcadorBase(canvas, size, x: xDeZ(2.57), yTopo: yDeZ(2.57), baseY: baseY, texto: '+2.57σ', cor: corCauda);
    _desenharSetaExtremaDireita(canvas, size, baseY: baseY);
  }

  void _desenharMarcadorBase(
    Canvas canvas,
    Size size, {
    required double x,
    required double yTopo,
    required double baseY,
    required String texto,
    required Color cor,
  }) {
    canvas.drawLine(
      Offset(x, yTopo),
      Offset(x, baseY),
      Paint()
        ..strokeWidth = 1.1
        ..color = cor.withValues(alpha: 0.65),
    );
    final tp = TextPainter(
      text: TextSpan(
        text: texto,
        style: TextStyle(color: cor, fontSize: 10, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = (x - tp.width * 0.5)
        .clamp(4.0, math.max(4.0, size.width - tp.width - 4.0))
        .toDouble();
    tp.paint(canvas, Offset(dx, baseY + 5.0));
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
