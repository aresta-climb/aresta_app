// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Apenas o arquivo lib/utils/construtor_caminho_trajeto.dart pode importar package:path_drawing',
    () {
      final arquivoAutorizado = File('lib/utils/construtor_caminho_trajeto.dart');
      expect(
        arquivoAutorizado.existsSync(),
        isTrue,
        reason:
            'O arquivo centralizador de caminhos lib/utils/construtor_caminho_trajeto.dart '
            'deve existir para isolar a biblioteca path_drawing.',
      );

      final libDirectory = Directory('lib');
      final dartFiles = libDirectory
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList();

      final infringingFiles = <String>[];

      for (final file in dartFiles) {
        final normalizedPath = file.path.replaceAll('\\', '/');

        // Ignora o único arquivo autorizado a consumir a biblioteca de terceiros
        if (normalizedPath.endsWith('lib/utils/construtor_caminho_trajeto.dart')) {
          continue;
        }

        final content = file.readAsStringSync();

        if (content.contains("import 'package:path_drawing/") ||
            content.contains('import "package:path_drawing/')) {
          infringingFiles.add(normalizedPath);
        }
      }

      expect(
        infringingFiles,
        isEmpty,
        reason:
            'Os seguintes arquivos estão violando a barreira arquitetural importando diretamente '
            'o pacote path_drawing:\n${infringingFiles.join('\n')}\n'
            'Solução: Utilize a classe ConstrutorCaminhoTrajeto para obter caminhos e tracejados.',
      );
    },
  );
}
