// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';

/// Cabeçalho padrão obrigatório de conformidade legal e licenciamento para o ano atual.
const String kCabecalhoCompleto =
    '// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors\n'
    '// SPDX-License-Identifier: MPL-2.0\n\n';

/// Expressão regular para validar se o arquivo já possui cabeçalho SPDX com ano válido (>= 2026).
final RegExp kRegexCopyrightSpdx = RegExp(
  r'^// SPDX-FileCopyrightText: Copyright \(C\) (\d{4})(?:-\d{4})? Aresta Climb Contributors$',
);

/// Sufixos de arquivos autogerados que não devem receber cabeçalho manual.
const List<String> kSufixosIgnorados = <String>[
  '.g.dart',
  '.pb.dart',
  '.pbenum.dart',
  '.pbjson.dart',
  '.pbserver.dart',
];

/// Diretórios que devem ser ignorados.
const List<String> kDiretoriosIgnorados = <String>[
  '.dart_tool',
  'aresta_api',
  'legal/repo',
  'build',
];

/// Valida se uma linha de cabeçalho é um copyright SPDX válido a partir de 2026.
bool validarLinhaCopyright(String linha) {
  final Match? match = kRegexCopyrightSpdx.firstMatch(linha.trim());
  if (match == null) {
    return false;
  }
  final int anoInicio = int.tryParse(match.group(1) ?? '') ?? 0;
  return anoInicio >= 2026;
}

/// Verifica se o arquivo já possui cabeçalho SPDX válido (ano >= 2026 e licença MPL-2.0).
bool possuiCabecalhoValido(File arquivo) {
  final List<String> linhas = arquivo.readAsLinesSync();
  if (linhas.length < 2) {
    return false;
  }
  return validarLinhaCopyright(linhas[0]) &&
      linhas[1].trim() == '// SPDX-License-Identifier: MPL-2.0';
}

/// Aplica o cabeçalho SPDX a todos os arquivos `.dart` de autoria no diretório informado.
int aplicarCabecalhosSpdx(Directory diretorioFrontend) {
  final List<String> pastas = <String>['lib', 'test', 'tool'];
  int arquivosAtualizados = 0;

  for (final String pasta in pastas) {
    final Directory dir = Directory('${diretorioFrontend.path}/$pasta');
    if (!dir.existsSync()) {
      continue;
    }

    final List<FileSystemEntity> entidades =
        dir.listSync(recursive: true, followLinks: false);

    for (final FileSystemEntity entidade in entidades) {
      if (entidade is! File || !entidade.path.endsWith('.dart')) {
        continue;
      }

      final String caminhoNormalizado = entidade.path.replaceAll(r'\', '/');

      final bool deveIgnorarDiretorio = kDiretoriosIgnorados.any(
        (String d) => caminhoNormalizado.contains('/$d/'),
      );
      if (deveIgnorarDiretorio) {
        continue;
      }

      final bool deveIgnorarSufixo = kSufixosIgnorados.any(
        (String s) => caminhoNormalizado.endsWith(s),
      );
      if (deveIgnorarSufixo) {
        continue;
      }

      final String conteudoAtual = entidade.readAsStringSync();

      // Se já possui o cabeçalho com Contributors, pula
      if (possuiCabecalhoValido(entidade)) {
        continue;
      }

      // Se tinha com Authors, atualiza a linha
      if (conteudoAtual.contains('// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Authors')) {
        final String conteudoSubstituido = conteudoAtual.replaceAll(
          '// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Authors',
          '// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors',
        );
        entidade.writeAsStringSync(conteudoSubstituido);
        arquivosAtualizados++;
        continue;
      }

      final String novoConteudo = '$kCabecalhoCompleto$conteudoAtual';
      entidade.writeAsStringSync(novoConteudo);
      arquivosAtualizados++;
    }
  }

  return arquivosAtualizados;
}

void main() {
  final int total = aplicarCabecalhosSpdx(Directory.current);
  print('Processamento concluído. Total de arquivos atualizados: $total');
}
