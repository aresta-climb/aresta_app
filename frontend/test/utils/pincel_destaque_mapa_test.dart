// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/utils/pincel_destaque_mapa.dart';

void main() {
  group('PincelDestaqueMapa - Estilos de Pincel e Cores de Destaque', () {
    const corTeste = Color(0xFFFFD600); // Amarelo padrão

    test('obterPincelBordaDestaque configura pincel com opacidade 70%, blur sólido e espessura 2.0', () {
      final paint = PincelDestaqueMapa.obterPincelBordaDestaque(corTeste);

      expect(paint.style, PaintingStyle.stroke);
      expect(paint.strokeWidth, 2.0);
      expect(paint.strokeJoin, StrokeJoin.round);
      expect(paint.color.a, closeTo(0.7, 0.01));
      expect(paint.color.r, closeTo(corTeste.r, 0.01));
      expect(paint.color.g, closeTo(corTeste.g, 0.01));
      expect(paint.color.b, closeTo(corTeste.b, 0.01));
      expect(paint.maskFilter, const MaskFilter.blur(BlurStyle.solid, 1.5));
    });

    test('obterPincelBordaDestaque respeita espessura customizada', () {
      final paint = PincelDestaqueMapa.obterPincelBordaDestaque(corTeste, espessura: 3.5);

      expect(paint.strokeWidth, 3.5);
      expect(paint.style, PaintingStyle.stroke);
      expect(paint.maskFilter, const MaskFilter.blur(BlurStyle.solid, 1.5));
    });

    test('obterPincelPreenchimentoDestaque configura pincel com preenchimento, opacidade 50% e blur normal 3.0', () {
      final paint = PincelDestaqueMapa.obterPincelPreenchimentoDestaque(corTeste);

      expect(paint.style, PaintingStyle.fill);
      expect(paint.color.a, closeTo(0.5, 0.01));
      expect(paint.color.r, closeTo(corTeste.r, 0.01));
      expect(paint.color.g, closeTo(corTeste.g, 0.01));
      expect(paint.color.b, closeTo(corTeste.b, 0.01));
      expect(paint.maskFilter, const MaskFilter.blur(BlurStyle.normal, 3.0));
    });

    test('obterPincelPreenchimentoPulso calcula opacidade base e interpolada', () {
      // Intensidade 0.0 -> alpha base 0.25
      final paintZero = PincelDestaqueMapa.obterPincelPreenchimentoPulso(0.0);
      expect(paintZero.style, PaintingStyle.fill);
      expect(paintZero.color.a, closeTo(0.25, 0.01));
      expect(paintZero.maskFilter, const MaskFilter.blur(BlurStyle.normal, 3.0));

      // Intensidade 1.0 -> alpha máximo 0.50
      final paintUm = PincelDestaqueMapa.obterPincelPreenchimentoPulso(1.0);
      expect(paintUm.color.a, closeTo(0.50, 0.01));
    });

    test('obterPincelBordaPulso configura borda proporcional à intensidade', () {
      final paint = PincelDestaqueMapa.obterPincelBordaPulso(0.5);

      expect(paint.style, PaintingStyle.stroke);
      expect(paint.strokeWidth, closeTo(0.75, 0.01)); // 1.5 * 0.5
      expect(paint.color.a, closeTo(0.4, 0.01)); // 0.8 * 0.5
      expect(paint.maskFilter, const MaskFilter.blur(BlurStyle.solid, 1.0));
    });

    test('obterPincelBordaPulso aceita espessuraBase customizada', () {
      final paint = PincelDestaqueMapa.obterPincelBordaPulso(0.5, espessuraBase: 4.0);

      expect(paint.strokeWidth, closeTo(2.0, 0.01)); // 4.0 * 0.5
    });

    test('obterCorDestaque alterna de amarelo para laranja e de outras cores para amarelo', () {
      // Amarelo vira laranja vibrante
      expect(
        PincelDestaqueMapa.obterCorDestaque(const Color(0xFFFFD600)),
        const Color(0xFFFF6D00),
      );

      // Laranja vira amarelo vibrante
      expect(
        PincelDestaqueMapa.obterCorDestaque(const Color(0xFFFF6D00)),
        const Color(0xFFFFD600),
      );

      // Azul ciano vira amarelo vibrante
      expect(
        PincelDestaqueMapa.obterCorDestaque(const Color(0xFF00E5FF)),
        const Color(0xFFFFD600),
      );
    });
  });
}
