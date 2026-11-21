// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Isolamento Arquitetural do Smoke Test CI', () {
    test(
      'nenhum arquivo em lib/ fora de lib/services/smoke_ci/ deve importar smoke_ci ou referenciar o canal app.escalada.croquis/smoke_ci',
      () {
        final dirSmoke = Directory('lib/services/smoke_ci');
        expect(
          dirSmoke.existsSync(),
          isTrue,
          reason: 'O módulo isolado lib/services/smoke_ci/ deve existir.',
        );

        final arquivosLib = Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            .toList();

        final violacoes = <String>[];
        for (final arq in arquivosLib) {
          final caminho = arq.path.replaceAll('\\', '/');
          if (caminho.contains('lib/services/smoke_ci/')) continue;

          final linhas = arq.readAsLinesSync();
          for (var i = 0; i < linhas.length; i++) {
            final linha = linhas[i];
            final limpa = linha.trimLeft();
            if (limpa.startsWith('//') ||
                limpa.startsWith('/*') ||
                limpa.startsWith('*')) {
              continue;
            }
            if (linha.contains('smoke_ci') ||
                linha.contains('app.escalada.croquis/smoke_ci') ||
                linha.contains('/__smoke__/')) {
              violacoes.add('$caminho:${i + 1}: ${linha.trim()}');
            }
          }
        }

        expect(
          violacoes,
          isEmpty,
          reason:
              'Código de produção fora de lib/services/smoke_ci/ não pode referenciar artefatos de smoke test:\n'
              '${violacoes.join('\n')}',
        );
      },
    );
  });
}
