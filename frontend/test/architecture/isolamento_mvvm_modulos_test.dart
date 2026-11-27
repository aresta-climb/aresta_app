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
        'lib/pages/configuracoes.dart',
        'lib/pages/hub_perfil_caderneta.dart',
        'lib/pages/explorar.dart',
        'lib/pages/estatisticas_clima.dart',
        'lib/pages/via.dart',
        'lib/widgets/app_bar_home_aresta.dart',
        'lib/widgets/autenticacao',
        'lib/widgets/caderneta',
        'lib/widgets/clima',
        'lib/widgets/configuracoes',
        'lib/widgets/explorar',
        'lib/widgets/idioma',
        'lib/widgets/navegacao',
        'lib/widgets/perfil',
        'lib/widgets/via',
        'lib/view/function_library/funcoes_caderneta.dart',
        'lib/view/function_library/funcoes_explorar.dart',
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
    'Modelos de domínio em lib/data/modelos e utilitários puros permanecem sem acoplamento com serviços ou UI',
    () {
      const escoposPuros = <String>[
        'lib/data/modelos',
        'lib/utils/codificador_malha_binaria.dart',
        'lib/utils/construtor_rede_viaria_aresta.dart',
        'lib/utils/extrator_curvas_nivel_mundo.dart',
        'lib/utils/geometria_clipping_mapa.dart',
        'lib/utils/modelos_apresentacao_via.dart',
        'lib/utils/extrator_detalhes_tecnicos_via.dart',
      ];
      final violacoes = <String>[];
      for (final escopo in escoposPuros) {
        for (final arquivo in listarArquivosDart(escopo)) {
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
      }

      expect(
        violacoes,
        isEmpty,
        reason:
            'Modelos e algoritmos puros não podem depender de serviços ou UI:\n'
            '${violacoes.join('\n')}',
      );
    },
  );

  test(
    'Pintores e widgets Dumb UI de explorar não mantêm estado estático mutável',
    () {
      final regexStaticMutavel =
          RegExp(r'\bstatic\s+(?!const\b|final\b)[A-Za-z0-9_<>,?]+\s+\w+\s*[;=]');
      final violacoes = <String>[];
      for (final arquivo in listarArquivosDart('lib/widgets/explorar')) {
        final caminho = arquivo.path.replaceAll('\\', '/');
        if (caminho.endsWith('/malha_relevo_lod.dart')) continue;
        final conteudo = arquivo.readAsStringSync();
        for (final match in regexStaticMutavel.allMatches(conteudo)) {
          violacoes.add('$caminho -> ${match.group(0)!.trim()}');
        }
      }

      expect(
        violacoes,
        isEmpty,
        reason:
            'Caches e estado mutável devem residir em instâncias de ViewModel, nunca em campos estáticos de widgets/pintores:\n'
            '${violacoes.join('\n')}',
      );
    },
  );

  test(
    'Módulos refatorados possuem espelhamento 1:1 de testes e tamanho modular (< 650 linhas)',
    () {
      const escopos = <String>[
        'lib/data/modelos',
        'lib/utils/codificador_malha_binaria.dart',
        'lib/utils/construtor_rede_viaria_aresta.dart',
        'lib/utils/extrator_curvas_nivel_mundo.dart',
        'lib/utils/geometria_clipping_mapa.dart',
        'lib/utils/modelos_apresentacao_via.dart',
        'lib/utils/extrator_detalhes_tecnicos_via.dart',
        'lib/services/autenticacao',
        'lib/services/caderneta',
        'lib/services/clima/servico_malha_viaria_offline.dart',
        'lib/services/clima/servico_tiles_elevacao_terrarium.dart',
        'lib/services/comunidade',
        'lib/idioma/controlador_idioma_app.dart',
        'lib/idioma/tradutor_app.dart',
        'lib/widgets/autenticacao',
        'lib/widgets/caderneta',
        'lib/widgets/clima',
        'lib/widgets/configuracoes',
        'lib/widgets/explorar',
        'lib/widgets/idioma',
        'lib/widgets/navegacao',
        'lib/widgets/perfil',
        'lib/widgets/via',
        'lib/view/function_library/funcoes_explorar.dart',
        'lib/view/view_models',
        'lib/pages/login.dart',
        'lib/pages/caderneta.dart',
        'lib/pages/hub_perfil_caderneta.dart',
        'lib/pages/explorar.dart',
        'lib/pages/estatisticas_clima.dart',
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
