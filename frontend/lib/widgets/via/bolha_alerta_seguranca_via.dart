// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../data/modelos/interacao_via.dart';

/// Cor vermelha de alta visibilidade usada nas bolhas de alerta estilo Waze sobre rocha e cartões escuros.
const Color _corVermelhoAlerta = Color(0xFFD93829);

/// Balão vermelho estilo chat/Waze contendo o emoji da categoria de risco e contador de confirmações.
class BolhaEmojiAlertaVia extends StatelessWidget {
  /// Alerta de segurança associado a esta bolha.
  final AlertaSegurancaVia alerta;

  /// Callback executado ao tocar na bolha.
  final VoidCallback aoTocar;

  /// Cria uma instância de [BolhaEmojiAlertaVia].
  const BolhaEmojiAlertaVia({
    super.key,
    required this.alerta,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Alerta: ${alerta.categoria.rotulo}',
      child: GestureDetector(
        onTap: aoTocar,
        child: CustomPaint(
          painter: _PintorBolhaChatVermelha(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(11, 7, 11, 13),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  alerta.categoria.emoji,
                  style: const TextStyle(fontSize: 18, height: 1.1),
                ),
                if (alerta.confirmacoesAtivas > 1) ...[
                  const SizedBox(width: 4),
                  Text(
                    '${alerta.confirmacoesAtivas}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PintorBolhaChatVermelha extends CustomPainter {
  const _PintorBolhaChatVermelha();

  @override
  void paint(Canvas canvas, Size size) {
    const alturaCauda = 6.0;
    final alturaCorpo = size.height - alturaCauda;
    final raio = alturaCorpo / 2;

    final caminho = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, alturaCorpo),
          Radius.circular(raio),
        ),
      )
      ..moveTo(size.width * 0.34, alturaCorpo - 1)
      ..lineTo(size.width * 0.24, size.height)
      ..lineTo(size.width * 0.52, alturaCorpo - 1)
      ..close();

    canvas.drawShadow(caminho, Colors.black.withValues(alpha: 0.65), 6, true);

    final preenchimento = Paint()
      ..color = _corVermelhoAlerta
      ..style = PaintingStyle.fill;
    canvas.drawPath(caminho, preenchimento);

    final borda = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(caminho, borda);
  }

  @override
  bool shouldRepaint(covariant _PintorBolhaChatVermelha oldDelegate) => false;
}
