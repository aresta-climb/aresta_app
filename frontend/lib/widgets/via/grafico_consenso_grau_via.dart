// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/modelos/interacao_via.dart';
import '../../theme/cores_app.dart';

/// Anel vetorial compacto (estilo *donut*) que resume a proporção de votos mais suaves (`< 0`),
/// justos (`0`) e mais duros (`> 0`) ao lado do grau sugerido pela comunidade na `ViaPage`.
class AnelConsensoGrauVia extends StatelessWidget {
  /// Agregado de consenso comunitário da escalada.
  final ConsensoGrauVia consenso;

  /// Dimensão lateral do anel em pixels lógicos.
  final double tamanho;

  /// Cria uma instância de [AnelConsensoGrauVia].
  const AnelConsensoGrauVia({
    super.key,
    required this.consenso,
    this.tamanho = 30,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    return SizedBox.square(
      key: const Key('anel_consenso_grau_via'),
      dimension: tamanho,
      child: CustomPaint(
        painter: _PintorAnelConsenso(
          distribuicaoDeltas: consenso.distribuicaoDeltas,
          corMaisSuave: cores.fernGreen,
          corJusto: cores.beastHide,
          corMaisDuro: cores.rustIron,
          corTrilhaVazia: cores.graniteEdge,
        ),
      ),
    );
  }
}

class _PintorAnelConsenso extends CustomPainter {
  final Map<int, int> distribuicaoDeltas;
  final Color corMaisSuave;
  final Color corJusto;
  final Color corMaisDuro;
  final Color corTrilhaVazia;

  const _PintorAnelConsenso({
    required this.distribuicaoDeltas,
    required this.corMaisSuave,
    required this.corJusto,
    required this.corMaisDuro,
    required this.corTrilhaVazia,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const espessura = 4.5;
    final centro = size.center(Offset.zero);
    final raio = (math.min(size.width, size.height) - espessura) / 2;
    final retanguloArco = Rect.fromCircle(center: centro, radius: raio);

    final pincelBase = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = espessura
      ..color = corTrilhaVazia;
    canvas.drawCircle(centro, raio, pincelBase);

    var votosSuaves = 0;
    var votosJustos = 0;
    var votosDuros = 0;
    distribuicaoDeltas.forEach((delta, contagem) {
      if (delta < 0) {
        votosSuaves += contagem;
      } else if (delta == 0) {
        votosJustos += contagem;
      } else {
        votosDuros += contagem;
      }
    });

    final total = votosSuaves + votosJustos + votosDuros;
    if (total == 0) return;

    final segmentos = <(int, Color)>[
      (votosSuaves, corMaisSuave),
      (votosJustos, corJusto),
      (votosDuros, corMaisDuro),
    ];

    var anguloInicial = -math.pi / 2;
    for (final (contagem, cor) in segmentos) {
      if (contagem <= 0) continue;
      final varredura = (contagem / total) * 2 * math.pi;
      final pincelSegmento = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = espessura
        ..strokeCap = StrokeCap.butt
        ..color = cor;
      canvas.drawArc(retanguloArco, anguloInicial, varredura, false, pincelSegmento);
      anguloInicial += varredura;
    }
  }

  @override
  bool shouldRepaint(covariant _PintorAnelConsenso oldDelegate) {
    return !mapEquals(oldDelegate.distribuicaoDeltas, distribuicaoDeltas);
  }
}
