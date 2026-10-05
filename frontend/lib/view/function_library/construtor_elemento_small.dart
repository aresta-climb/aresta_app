// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

/// Construtor de elemento Markdown para renderização de texto reduzido (<small>).
///
/// Aplica uma escala proporcional de aproximadamente 80% sobre o tamanho de fonte base
/// do elemento pai, mantendo o alinhamento da linha de base intacto e gerando [TextSpan]
/// para integração perfeita com o fluxo de texto do parágrafo.
class ConstrutorElementoSmall extends MarkdownElementBuilder {
  /// Fator de redução de escala aplicado ao tamanho da fonte pai.
  static const double fatorEscala = 0.8;

  /// Tamanho de fonte padrão utilizado como fallback caso o estilo pai não especifique.
  static const double tamanhoFontePadrao = 14.0;

  @override
  bool isBlockElement() => false;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final estiloBase = parentStyle ?? DefaultTextStyle.of(context).style;
    final tamanhoFonteOriginal = estiloBase.fontSize ?? tamanhoFontePadrao;
    final estiloReduzido = estiloBase.copyWith(
      fontSize: tamanhoFonteOriginal * fatorEscala,
    );

    final span = _construirSpan(element, estiloReduzido);
    return Text.rich(span);
  }

  InlineSpan _construirSpan(md.Node no, TextStyle estiloAtual) {
    if (no is! md.Element) {
      return TextSpan(text: no.textContent, style: estiloAtual);
    }
    var estiloFilho = estiloAtual;
    if (no.tag == 'strong') {
      estiloFilho = estiloFilho.copyWith(fontWeight: FontWeight.bold);
    } else if (no.tag == 'em') {
      estiloFilho = estiloFilho.copyWith(fontStyle: FontStyle.italic);
    } else if (no.tag == 'del') {
      estiloFilho = estiloFilho.copyWith(decoration: TextDecoration.lineThrough);
    }

    if (no.children != null && no.children!.isNotEmpty) {
      if (no.children!.length == 1 && no.children!.first is md.Text) {
        final textoFilho = (no.children!.first as md.Text).text;
        return TextSpan(text: textoFilho, style: estiloFilho);
      }
      return TextSpan(
        children: no.children!
            .map((filho) => _construirSpan(filho, estiloFilho))
            .toList(),
      );
    }
    return TextSpan(text: no.textContent, style: estiloFilho);
  }
}
