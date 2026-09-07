// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'gerenciador_semver.dart';

/// Executa o cálculo da versão de release a partir dos argumentos de linha de comando.
///
/// Permite injeção de [saida] e [erro] para facilidade de testes unitários e automação.
Future<int> executarCalcularVersaoRelease(
  List<String> argumentos, {
  StringSink? saida,
  StringSink? erro,
}) async {
  final out = saida ?? stdout;
  final err = erro ?? stderr;

  String tipo = 'patch';
  String? custom;
  String caminhoPubspec = 'pubspec.yaml';
  String formato = 'semver';
  String? caminhoExportarEnv;

  for (var i = 0; i < argumentos.length; i++) {
    final arg = argumentos[i];
    if (arg == '--tipo' && i + 1 < argumentos.length) {
      tipo = argumentos[++i];
    } else if (arg == '--custom' && i + 1 < argumentos.length) {
      custom = argumentos[++i];
    } else if (arg == '--pubspec' && i + 1 < argumentos.length) {
      caminhoPubspec = argumentos[++i];
    } else if (arg == '--formato' && i + 1 < argumentos.length) {
      formato = argumentos[++i];
    } else if (arg == '--exportar-env' && i + 1 < argumentos.length) {
      caminhoExportarEnv = argumentos[++i];
    }
  }

  try {
    final arquivoPubspec = File(caminhoPubspec);
    if (!arquivoPubspec.existsSync()) {
      err.writeln('Erro: Arquivo pubspec não encontrado em "$caminhoPubspec".');
      return 1;
    }

    final conteudo = arquivoPubspec.readAsStringSync();
    final regexVersao = RegExp(r'^version:\s*(.+)$', multiLine: true);
    final match = regexVersao.firstMatch(conteudo);

    if (match == null) {
      err.writeln(
        'Erro: Padrão "version:" não encontrado no arquivo "$caminhoPubspec".',
      );
      return 1;
    }

    final versaoAtual = match.group(1)!.trim();
    final infoAtual = GerenciadorSemver.decompor(versaoAtual);

    final versaoRelease = GerenciadorSemver.calcularVersaoRelease(
      versaoAtual: versaoAtual,
      tipo: tipo,
      custom: custom,
    );

    final buildAtual = infoAtual.build ?? 0;
    final novoBuild = buildAtual + 1;
    final versaoCompleta = '$versaoRelease+$novoBuild';
    final tagName = 'v$versaoCompleta';

    if (caminhoExportarEnv != null) {
      final arquivoEnv = File(caminhoExportarEnv);
      arquivoEnv.writeAsStringSync(
        'versao_release=$versaoRelease\n'
        'novo_build=$novoBuild\n'
        'versao_completa=$versaoCompleta\n'
        'tag_name=$tagName\n',
        mode: FileMode.append,
      );
    }

    switch (formato.toLowerCase().trim()) {
      case 'completo':
        out.writeln(versaoCompleta);
        break;
      case 'tag':
        out.writeln(tagName);
        break;
      case 'build':
        out.writeln(novoBuild.toString());
        break;
      case 'semver':
      default:
        out.writeln(versaoRelease);
        break;
    }

    return 0;
  } catch (e) {
    err.writeln('Erro ao calcular versão de release: $e');
    return 1;
  }
}

/// Ponto de entrada padrão da CLI.
Future<void> main(List<String> args) async {
  final codigo = await executarCalcularVersaoRelease(args);
  exit(codigo);
}
