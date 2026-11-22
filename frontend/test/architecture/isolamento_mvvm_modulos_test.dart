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

  test(
    'Modelos de domínio em lib/data/modelos permanecem puros sem acoplamento com serviços ou UI',
    () {
      final violacoes = <String>[];
      for (final arquivo in listarArquivosDart('lib/data/modelos')) {
        final caminho = arquivo.path.replaceAll('\\', '/');
        final conteudo = arquivo.readAsStringSync();
        for (final match in regexImport.allMatches(conteudo)) {
          final importado = match.group(1)!;
          if (importado.contains('services/') ||
              importado.contains('view/') ||
              importado.contains('widgets/') ||
              importado.contains('pages/')) {
            violacoes.add('$caminho -> $importado');
          }
        }
      }

      expect(
        violacoes,
        isEmpty,
        reason:
            'Modelos em lib/data/modelos não podem depender de camadas superiores:\n'
            '${violacoes.join('\n')}',
      );
    },
  );

  test(
    'Módulos refatorados possuem espelhamento 1:1 de testes e tamanho modular (< 650 linhas)',
    () {
      const escopos = <String>[
        'lib/data/modelos',
        'lib/utils/modelos_apresentacao_via.dart',
        'lib/utils/extrator_detalhes_tecnicos_via.dart',
        'lib/services/autenticacao',
        'lib/services/caderneta',
        'lib/services/comunidade',
        'lib/widgets/autenticacao',
        'lib/widgets/caderneta',
        'lib/widgets/perfil',
        'lib/widgets/via',
        'lib/view/view_models',
        'lib/pages/login.dart',
        'lib/pages/caderneta.dart',
        'lib/pages/hub_perfil_caderneta.dart',
        'lib/pages/via.dart',
      ];

      final semTeste = <String>[];
      final monolitos = <String>[];

      for (final escopo in escopos) {
        for (final arquivo in listarArquivosDart(escopo)) {
          final caminhoLib = arquivo.path.replaceAll('\\', '/');
          final relativo = caminhoLib.substring('lib/'.length);
          final caminhoTeste =
              'test/${relativo.substring(0, relativo.length - 5)}_test.dart';
          if (!File(caminhoTeste).existsSync()) {
            semTeste.add('$caminhoLib (esperado: $caminhoTeste)');
          }

          final totalLinhas = arquivo.readAsLinesSync().length;
          if (totalLinhas > 650) {
            monolitos.add('$caminhoLib ($totalLinhas linhas)');
          }
        }
      }

      expect(
        semTeste,
        isEmpty,
        reason: 'Espelhamento 1:1 obrigatório violado:\n${semTeste.join('\n')}',
      );
      expect(
        monolitos,
        isEmpty,
        reason:
            'Arquivos excedendo limite modular de responsabilidade única:\n'
            '${monolitos.join('\n')}',
      );
    },
  );
}
