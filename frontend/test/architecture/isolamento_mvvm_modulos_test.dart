// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final regexImport = RegExp(r'''import\s+['"]([^'"]+)['"]''');

  List<File> listarArquivosDart(String caminhoRelativo) {
    final entidade = FileSystemEntity.typeSync(caminhoRelativo);
    if (entidade == FileSystemEntityType.file) {
      return [File(caminhoRelativo)];
    }
    final dir = Directory(caminhoRelativo);
    if (!dir.existsSync()) return const [];
    return dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();
  }

  test(
    'Camada de interface declarativa (Dumb UI / MVVM) não importa serviços diretamente',
    () {
      const alvosUiModular = <String>[
        'lib/pages/login.dart',
        'lib/pages/caderneta.dart',
        'lib/pages/hub_perfil_caderneta.dart',
        'lib/pages/via.dart',
        'lib/widgets/autenticacao',
        'lib/widgets/caderneta',
        'lib/widgets/perfil',
        'lib/widgets/via',
        'lib/view/function_library/funcoes_caderneta.dart',
        'lib/view/function_library/funcoes_hub_perfil_caderneta.dart',
        'lib/view/function_library/via_functions.dart',
      ];

      final violacoes = <String>[];
      for (final alvo in alvosUiModular) {
        for (final arquivo in listarArquivosDart(alvo)) {
          final caminho = arquivo.path.replaceAll('\\', '/');
          final conteudo = arquivo.readAsStringSync();
          for (final match in regexImport.allMatches(conteudo)) {
            final importado = match.group(1)!;
            if (importado.contains('services/')) {
              violacoes.add('$caminho -> $importado');
            }
          }
        }
      }

      expect(
        violacoes,
        isEmpty,
        reason:
            'Páginas e widgets Dumb UI devem delegar acesso a serviços e repositórios '
            'exclusivamente aos seus ViewModels:\n${violacoes.join('\n')}',
      );
    },
  );
}
