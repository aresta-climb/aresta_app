class MarkdownUtils {
  /// Limpa o conteúdo markdown antes de exibi-lo em um modal.
  /// - Remove blocos de frontmatter delimitados por `---` no início do texto.
  /// - Remove o primeiro título (Heading `#`) se ele for parecido ou igual ao [modalTitle],
  ///   para evitar repetição do título que já está na barra do modal.
  static String cleanModalContent(String rawContent, String modalTitle) {
    // Remove BOM character caso exista
    String content = rawContent.replaceAll('\uFEFF', '').trimLeft();

    // Remove frontmatter delimitado por 3 ou mais hífens (ex: --- ou ----), permitindo espaços no final da linha e meio vazio
    final frontmatterRegex = RegExp(
      r'^---+\s*\r?\n(?:[\s\S]*?\r?\n)?---+\s*\r?\n?',
    );
    content = content.replaceFirst(frontmatterRegex, '').trimLeft();

    final lines = content.split('\n');
    if (lines.isNotEmpty) {
      final firstLine = lines.first.trim();
      final cleanFirstLine = firstLine
          .replaceAll(RegExp(r'^#+\s*'), '')
          .trim()
          .toLowerCase();
      final cleanTitle = modalTitle.toLowerCase().trim();

      // Se a primeira linha for muito parecida com o título do modal (e não for um texto gigante)
      if (cleanFirstLine.isNotEmpty &&
          cleanFirstLine.length < 100 &&
          (cleanFirstLine.contains(cleanTitle) ||
              cleanTitle.contains(cleanFirstLine))) {
        int linesToRemove = 1;
        // Verifica se a segunda linha é um sublinhado de título Markdown (ex: === ou ---)
        if (lines.length > 1) {
          final secondLine = lines[1].trim();
          if (RegExp(r'^[=\-]+$').hasMatch(secondLine)) {
            linesToRemove = 2;
          }
        }

        content = lines.skip(linesToRemove).join('\n').trimLeft();
      }
    }

    return content;
  }
}
