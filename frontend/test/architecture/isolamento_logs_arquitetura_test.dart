// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Nenhum arquivo em lib/ deve utilizar print() ou debugPrint() diretamente, exceto app_logger.dart',
    () {
      final libDirectory = Directory('lib');

      // Escaneia todos os arquivos .dart recursivamente em lib/
      final dartFiles = libDirectory
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList();

      final violacoes = <String>[];
      final regexDebugPrint = RegExp(r'\bdebugPrint\s*\(');
      final regexPrint = RegExp(r'(?<![a-zA-Z0-9_])print\s*\(');

      for (final file in dartFiles) {
        final normalizedPath = file.path.replaceAll('\\', '/');

        // Permite debugPrint exclusivamente na implementação interna do AppLogger
        if (normalizedPath.endsWith('lib/services/firebase/app_logger.dart')) {
          continue;
        }

        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          final trimmed = line.trimLeft();

          // Ignora linhas de comentário
          if (trimmed.startsWith('//') || trimmed.startsWith('/*') || trimmed.startsWith('*')) {
            continue;
          }

          if (regexDebugPrint.hasMatch(line) || regexPrint.hasMatch(line)) {
            violacoes.add('$normalizedPath:${i + 1}: ${line.trim()}');
          }
        }
      }

      expect(
        violacoes,
        isEmpty,
        reason:
            'Foram encontradas chamadas diretas a print() ou debugPrint() violando a arquitetura de logging:\n'
            '${violacoes.join('\n')}\n\n'
            'Solução: Substitua essas chamadas por métodos do AppLogger.instance (ex: logInfo, logAviso ou logError com stackTrace obrigatório).',
      );
    },
  );
}
