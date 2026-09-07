// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'gerenciador_semver.dart';

/// Atualiza a linha `version:` de um arquivo pubspec.yaml preservando o conteúdo restante.
///
/// Permite injeção de [saida] e [erro] para facilidade de testes unitários e automação.
Future<int> executarAtualizarVersaoPubspec(
  List<String> argumentos, {
  StringSink? saida,
  StringSink? erro,
}) async {
  final out = saida ?? stdout;
  final err = erro ?? stderr;

  String? caminhoPubspec;
  String? novaVersao;

  for (var i = 0; i < argumentos.length; i++) {
    final arg = argumentos[i];
    if (arg == '--pubspec' && i + 1 < argumentos.length) {
      caminhoPubspec = argumentos[++i];
    } else if (arg == '--versao' && i + 1 < argumentos.length) {
      novaVersao = argumentos[++i];
    } else if (!arg.startsWith('--')) {
      if (caminhoPubspec == null) {
        caminhoPubspec = arg;
      } else {
        novaVersao ??= arg;
      }
    }
  }

  if (caminhoPubspec == null || novaVersao == null) {
    err.writeln('Erro: Uso: atualizar_versao_pubspec <caminho_pubspec> <nova_versao>');
    return 1;
  }

  try {
    final arquivo = File(caminhoPubspec);
    if (!arquivo.existsSync()) {
      err.writeln('Erro: Arquivo pubspec não encontrado em "$caminhoPubspec".');
      return 1;
    }

    final versaoLimpa = novaVersao.trim();
    GerenciadorSemver.validarSemver(versaoLimpa);

    final conteudo = arquivo.readAsStringSync();
    final regexVersao = RegExp(r'^version:\s*.+$', multiLine: true);

    if (!regexVersao.hasMatch(conteudo)) {
      err.writeln('Erro: Padrão "version:" não encontrado no arquivo "$caminhoPubspec".');
      return 1;
    }

    final novoConteudo = conteudo.replaceFirst(regexVersao, 'version: $versaoLimpa');
    arquivo.writeAsStringSync(novoConteudo);

    out.writeln('Versão atualizada com sucesso para "$versaoLimpa" em "$caminhoPubspec".');
    return 0;
  } catch (e) {
    err.writeln('Erro ao atualizar pubspec: $e');
    return 1;
  }
}

/// Ponto de entrada padrão da CLI.
Future<void> main(List<String> args) async {
  final codigo = await executarAtualizarVersaoPubspec(args);
  exit(codigo);
}
