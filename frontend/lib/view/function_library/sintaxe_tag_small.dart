// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:markdown/markdown.dart' as md;

/// Sintaxe inline customizada para reconhecer e processar tags HTML `<small>...</small>` em Markdown.
///
/// Permite que trechos de texto anotados com `<small>` sejam convertidos em elementos
/// estruturados na árvore AST do Markdown, preservando inclusive marcações internas (como negrito ou itálico)
/// por meio da avaliação recursiva do conteúdo inline via [parser.document.parseInline].
class SintaxeTagSmall extends md.InlineSyntax {
  /// Expressão regular para captura de tags `<small>` e `</small>` de forma insensível a maiúsculas e minúsculas.
  static const String _padraoRegex = r'<small>(.*?)</small>';

  /// Cria uma nova instância de [SintaxeTagSmall].
  SintaxeTagSmall() : super(_padraoRegex, caseSensitive: false);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final conteudoInterno = match[1] ?? '';
    final nosFilhos = parser.document.parseInline(conteudoInterno);
    parser.addNode(md.Element('small', nosFilhos));
    return true;
  }
}
