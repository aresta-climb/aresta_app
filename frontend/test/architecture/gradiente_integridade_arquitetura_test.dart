// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Todo LinearGradient no código fonte em lib/ deve ter colors e stops com o mesmo comprimento',
    () {
      final libDir = Directory('lib');
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();

      final violacoes = <String>[];

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        if (!content.contains('LinearGradient')) continue;

        final normalizedPath = file.path.replaceAll('\\', '/');
        final lines = file.readAsLinesSync();

        for (var i = 0; i < lines.length; i++) {
          if (lines[i].contains('LinearGradient')) {
            // Captura o bloco do construtor LinearGradient(...)
            final buffer = StringBuffer();
            var j = i;
            var parentesesAbertos = 0;
            var encontrouAbertura = false;

            while (j < lines.length) {
              final line = lines[j];
              buffer.writeln(line);

              for (var charIndex = 0; charIndex < line.length; charIndex++) {
                final char = line[charIndex];
                if (char == '(') {
                  parentesesAbertos++;
                  encontrouAbertura = true;
                } else if (char == ')' && encontrouAbertura) {
                  parentesesAbertos--;
                  if (parentesesAbertos == 0) break;
                }
              }

              if (encontrouAbertura && parentesesAbertos == 0) break;
              j++;
            }

            final gradientBlock = buffer.toString();

            // Verifica se possui 'stops:'
            if (gradientBlock.contains('stops:')) {
              final colorsMatch = RegExp(r'colors:\s*(?:const\s*)?\[([^\]]*)\]')
                  .firstMatch(gradientBlock);
              final stopsMatch = RegExp(r'stops:\s*(?:const\s*)?\[([^\]]*)\]')
                  .firstMatch(gradientBlock);

              if (colorsMatch != null && stopsMatch != null) {
                final colorsContent = colorsMatch.group(1)!.trim();
                final stopsContent = stopsMatch.group(1)!.trim();

                // Conta itens separados por vírgula no topo do array
                final totalColors = _contarElementosEmLista(colorsContent);
                final totalStops = _contarElementosEmLista(stopsContent);

                if (totalColors != totalStops) {
                  violacoes.add(
                    '$normalizedPath:${i + 1} -> colors tem $totalColors itens, mas stops tem $totalStops itens.',
                  );
                }
              }
            }
          }
        }
      }

      expect(
        violacoes,
        isEmpty,
        reason:
            'Foram encontrados LinearGradients com tamanhos divergentes entre colors e stops:\n'
            '${violacoes.join('\n')}\n\n'
            'Solução: Certifique-se de que a lista colors e a lista stops tenham rigorosamente o mesmo número de elementos para evitar ArgumentError fatal no motor gráfico.',
      );
    },
  );
}

/// Conta os elementos de uma lista Dart separada por vírgulas, ignorando parênteses internos.
int _contarElementosEmLista(String content) {
  if (content.isEmpty) return 0;

  var count = 0;
  var parenteses = 0;
  var chaves = 0;
  var colchetes = 0;
  var temConteudoNoItem = false;

  for (var i = 0; i < content.length; i++) {
    final char = content[i];

    if (char == '(') parenteses++;
    if (char == ')') parenteses--;
    if (char == '{') chaves++;
    if (char == '}') chaves--;
    if (char == '[') colchetes++;
    if (char == ']') colchetes--;

    if (char == ',' && parenteses == 0 && chaves == 0 && colchetes == 0) {
      if (temConteudoNoItem) {
        count++;
        temConteudoNoItem = false;
      }
    } else if (char.trim().isNotEmpty) {
      temConteudoNoItem = true;
    }
  }

  if (temConteudoNoItem) {
    count++;
  }

  return count;
}
