import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/utils/markdown_utils.dart';

void main() {
  group('MarkdownUtils.cleanModalContent', () {
    test('remove frontmatter YAML delimitado por --- no início do arquivo', () {
      const rawContent = '''---
title: História
date: 2023-10-27
---
Este é o conteúdo principal.''';

      final result = MarkdownUtils.cleanModalContent(rawContent, 'História');
      expect(result, 'Este é o conteúdo principal.');
    });

    test('não remove --- se não estiver no início do arquivo', () {
      const rawContent = '''Este é o conteúdo principal.
---
Rodapé do arquivo
---''';

      final result = MarkdownUtils.cleanModalContent(rawContent, 'História');
      expect(result, rawContent);
    });

    test('remove título se for igual ao título do modal', () {
      const rawContent = '''# História
Este é o conteúdo principal.''';

      final result = MarkdownUtils.cleanModalContent(rawContent, 'História');
      expect(result, 'Este é o conteúdo principal.');
    });

    test('remove título se contiver o título do modal', () {
      const rawContent = '''## História de Igarapé - MG
Este é o conteúdo principal.''';

      final result = MarkdownUtils.cleanModalContent(rawContent, 'História de Igarapé');
      expect(result, 'Este é o conteúdo principal.');
    });

    test('remove título e frontmatter juntos', () {
      const rawContent = '''---
meta: data
---
# História de Igarapé - MG

Este é o conteúdo principal.''';

      final result = MarkdownUtils.cleanModalContent(rawContent, 'História de Igarapé');
      expect(result, 'Este é o conteúdo principal.');
    });

    test('não remove título se for muito diferente do modal', () {
      const rawContent = '''# Regras Locais
Este é o conteúdo principal.''';

      final result = MarkdownUtils.cleanModalContent(rawContent, 'História de Igarapé');
      expect(result, '# Regras Locais\nEste é o conteúdo principal.');
    });

    test('lida corretamente com string vazia', () {
      final result = MarkdownUtils.cleanModalContent('', 'História de Igarapé');
      expect(result, '');
    });

    test('remove frontmatter YAML delimitado por ---- (4 hífens)', () {
      const rawContent = '''---- 
title: História
date: 2023-10-27
----  
Este é o conteúdo principal.''';

      final result = MarkdownUtils.cleanModalContent(rawContent, 'História');
      expect(result, 'Este é o conteúdo principal.');
    });

    test('remove frontmatter com BOM character no inicio', () {
      const rawContent = '\uFEFF---\ntitle: História\n---\nEste é o conteúdo principal.';

      final result = MarkdownUtils.cleanModalContent(rawContent, 'História');
      expect(result, 'Este é o conteúdo principal.');
    });

    test('remove frontmatter vazio (como em igarape/regras.md)', () {
      const rawContent = '---\n---\n\n# SEJA CONSCIENTE!';

      final result = MarkdownUtils.cleanModalContent(rawContent, 'Recomendações e Regras');
      expect(result, '# SEJA CONSCIENTE!');
    });

    test('remove título formatado com underline duplo (H1 alternativo)', () {
      const rawContent = '''História
======
Este é o conteúdo principal.''';

      final result = MarkdownUtils.cleanModalContent(rawContent, 'História');
      expect(result, 'Este é o conteúdo principal.');
    });
  });
}
