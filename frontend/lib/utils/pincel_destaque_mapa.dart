// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:ui';
import 'package:flutter/material.dart';

/// Biblioteca utilitária para padronização dos pincéis (Paint) de destaque e seleção em mapas.
///
/// Centraliza a criação de estilos visuais (bordas luminosas, halos e preenchimentos translúcidos)
/// compartilhados entre áreas fechadas (círculos avulsos, polígonos, retângulos) e marcadores
/// de traçados vetoriais, garantindo coerência e evitando discrepâncias visuais no croqui.
class PincelDestaqueMapa {
  /// Retorna o pincel padrão para a borda luminosa de seleção e destaque.
  ///
  /// Utiliza opacidade de 70% e MaskFilter.blur(BlurStyle.solid, 1.5), mantendo o miolo
  /// nítido com dispersão suave nas bordas.
  static Paint obterPincelBordaDestaque(Color cor, {double espessura = 2.0}) {
    return Paint()
      ..color = cor.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = espessura
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1.5);
  }

  /// Retorna o pincel para o preenchimento difuso de áreas de destaque selecionadas.
  static Paint obterPincelPreenchimentoDestaque(Color cor) {
    return Paint()
      ..color = cor.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
  }

  /// Retorna o pincel para o brilho suave de fundo em repouso ou animação de pulso.
  static Paint obterPincelPreenchimentoPulso(double intensidade) {
    const double baseAlpha = 0.25;
    const double highlightAlpha = 0.5;
    final double effectiveAlpha = baseAlpha + ((highlightAlpha - baseAlpha) * intensidade);

    return Paint()
      ..color = Colors.white.withValues(alpha: effectiveAlpha)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
  }

  /// Retorna o pincel para a borda de pulso luminoso (ao tocar fora ou animar marcadores).
  static Paint obterPincelBordaPulso(double intensidade, {double espessuraBase = 1.5}) {
    return Paint()
      ..color = Colors.white.withValues(alpha: 0.8 * intensidade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = espessuraBase * intensidade
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1.0);
  }

  /// Determina a cor de destaque de alto contraste para seleção sobre o mapa.
  ///
  /// Se a cor base for o amarelo padrão (#FFD600), alterna para laranja vibrante (#FF6D00).
  /// Caso contrário, utiliza amarelo (#FFD600) para destaque sobre fundos escuros ou de outras cores.
  static Color obterCorDestaque(Color corBase) {
    return (corBase.toARGB32() == 0xFFFFD600)
        ? const Color(0xFFFF6D00)
        : const Color(0xFFFFD600);
  }
}
