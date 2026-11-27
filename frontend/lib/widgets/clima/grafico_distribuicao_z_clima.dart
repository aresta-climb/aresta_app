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

