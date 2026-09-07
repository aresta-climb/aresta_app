// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'gerenciador_semver.dart';

/// Executa o cálculo da próxima versão de desenvolvimento contínuo (-dev).
///
/// Permite injeção de [saida] e [erro] para facilidade de testes unitários e automação.
Future<int> executarCalcularProximoDev(
  List<String> argumentos, {
  StringSink? saida,
  StringSink? erro,
}) async {
  final out = saida ?? stdout;
  final err = erro ?? stderr;

  String? versaoLancada;
  int? buildLancado;
  String formato = 'semver';
  String? caminhoExportarEnv;

  for (var i = 0; i < argumentos.length; i++) {
    final arg = argumentos[i];
    if (arg == '--versao' && i + 1 < argumentos.length) {
      versaoLancada = argumentos[++i];
    } else if (arg == '--build' && i + 1 < argumentos.length) {
      buildLancado = int.tryParse(argumentos[++i]);
    } else if (arg == '--formato' && i + 1 < argumentos.length) {
      formato = argumentos[++i];
    } else if (arg == '--exportar-env' && i + 1 < argumentos.length) {
      caminhoExportarEnv = argumentos[++i];
    } else if (!arg.startsWith('--') && versaoLancada == null) {
      versaoLancada = arg;
    }
  }

  if (versaoLancada == null || versaoLancada.trim().isEmpty) {
    err.writeln('Erro: Versão de lançamento é obrigatória.');
    return 1;
  }

  try {
    final info = GerenciadorSemver.decompor(versaoLancada);
    final proximoDev = GerenciadorSemver.calcularProximoDev(versaoLancada);

    // Se o build não foi passado via flag, verificar se estava embutido no SemVer
    final buildBase = buildLancado ?? info.build;
    final int? proximoBuild = buildBase != null ? buildBase + 1 : null;

    final versaoDevCompleta = proximoBuild != null
        ? '$proximoDev+$proximoBuild'
        : proximoDev;

    if (caminhoExportarEnv != null) {
      final arquivoEnv = File(caminhoExportarEnv);
      arquivoEnv.writeAsStringSync(
        'versao_dev=$proximoDev\n'
        'build_dev=${proximoBuild ?? ''}\n'
        'versao_dev_completa=$versaoDevCompleta\n',
        mode: FileMode.append,
      );
    }

    switch (formato.toLowerCase().trim()) {
      case 'completo':
        out.writeln(versaoDevCompleta);
        break;
      case 'build':
        out.writeln(proximoBuild?.toString() ?? '');
        break;
      case 'semver':
      default:
        out.writeln(proximoDev);
        break;
    }

    return 0;
  } catch (e) {
    err.writeln('Erro ao calcular próxima versão de desenvolvimento: $e');
    return 1;
  }
}

/// Ponto de entrada padrão da CLI.
Future<void> main(List<String> args) async {
  final codigo = await executarCalcularProximoDev(args);
  exit(codigo);
}
