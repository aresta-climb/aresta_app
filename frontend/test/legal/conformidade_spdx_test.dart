// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Linha obrigatória de identificação da licença SPDX.
const String kCabecalhoLicencaEsperado =
    '// SPDX-License-Identifier: MPL-2.0';

/// Expressão regular para validar o cabeçalho de Copyright (aceitando qualquer ano >= 2026 ou intervalos como 2026-2028).
final RegExp kRegexCopyrightSpdx = RegExp(
  r'^// SPDX-FileCopyrightText: Copyright \(C\) (\d{4})(?:-\d{4})? Aresta Climb Contributors$',
);

/// Conjunto de sufixos de arquivos gerados automaticamente que devem ser ignorados.
const List<String> kSufixosIgnorados = <String>[
  '.g.dart',
  '.pb.dart',
  '.pbenum.dart',
  '.pbjson.dart',
  '.pbserver.dart',
];

/// Conjunto de diretórios de submódulos ou artefatos gerados que devem ser ignorados.
const List<String> kDiretoriosIgnorados = <String>[
  '.dart_tool',
  'aresta_api',
  'legal/repo',
  'build',
];

/// Localiza a raiz do frontend de forma resiliente ao diretório de execução atual.
Directory obterDiretorioFrontend() {
  final Directory diretorioAtual = Directory.current;
  if (File('${diretorioAtual.path}/pubspec.yaml').existsSync()) {
    return diretorioAtual;
  }
  final Directory subdiretorioFrontend =
      Directory('${diretorioAtual.path}/frontend');
  if (subdiretorioFrontend.existsSync()) {
    return subdiretorioFrontend;
  }
  return diretorioAtual;
}

/// Coleta recursivamente todos os arquivos `.dart` de autoria do projeto.
List<File> coletarArquivosDartDeAutoria(Directory diretorioRaiz) {
  final List<File> arquivosValidos = <File>[];
  final List<String> pastasParaInspecionar = <String>['lib', 'test', 'tool'];

  for (final String pasta in pastasParaInspecionar) {
    final Directory diretorio = Directory('${diretorioRaiz.path}/$pasta');
    if (!diretorio.existsSync()) {
      continue;
    }

    final List<FileSystemEntity> entidades =
        diretorio.listSync(recursive: true, followLinks: false);

    for (final FileSystemEntity entidade in entidades) {
      if (entidade is! File || !entidade.path.endsWith('.dart')) {
        continue;
      }

      final String caminhoNormalizado = entidade.path.replaceAll(r'\', '/');

      final bool deveIgnorarDiretorio = kDiretoriosIgnorados.any(
        (String dir) => caminhoNormalizado.contains('/$dir/'),
      );
      if (deveIgnorarDiretorio) {
        continue;
      }

      final bool deveIgnorarSufixo = kSufixosIgnorados.any(
        (String sufixo) => caminhoNormalizado.endsWith(sufixo),
      );
      if (deveIgnorarSufixo) {
        continue;
      }

      arquivosValidos.add(entidade);
    }
  }

  return arquivosValidos;
}

/// Valida se a linha de copyright contém formato válido com ano >= 2026 e titular Contributors.
bool validarLinhaCopyright(String linha) {
  final Match? match = kRegexCopyrightSpdx.firstMatch(linha.trim());
  if (match == null) {
    return false;
  }
  final int anoInicio = int.tryParse(match.group(1) ?? '') ?? 0;
  return anoInicio >= 2026;
}

/// Verifica se o arquivo contém as duas linhas obrigatórias de cabeçalho SPDX no início.
bool verificarCabecalhoSpdx(File arquivo) {
  final List<String> linhas = arquivo.readAsLinesSync();
  if (linhas.length < 2) {
    return false;
  }

  final String primeiraLinha = linhas[0].trim();
  final String segundaLinha = linhas[1].trim();

  return validarLinhaCopyright(primeiraLinha) &&
      segundaLinha == kCabecalhoLicencaEsperado;
}

void main() {
  group('Conformidade Legal e Cabeçalhos SPDX (MPL 2.0)', () {
    test(
      'validador aceita anos a partir de 2026 e faixas de anos com Aresta Climb Contributors',
      () {
        expect(
          validarLinhaCopyright(
              '// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors'),
          isTrue,
        );
        expect(
          validarLinhaCopyright(
              '// SPDX-FileCopyrightText: Copyright (C) 2027 Aresta Climb Contributors'),
          isTrue,
        );
        expect(
          validarLinhaCopyright(
              '// SPDX-FileCopyrightText: Copyright (C) 2030 Aresta Climb Contributors'),
          isTrue,
        );
        expect(
          validarLinhaCopyright(
              '// SPDX-FileCopyrightText: Copyright (C) 2026-2029 Aresta Climb Contributors'),
          isTrue,
        );
        expect(
          validarLinhaCopyright(
              '// SPDX-FileCopyrightText: Copyright (C) 2020 Aresta Climb Contributors'),
          isFalse, // Ano anterior a 2026 não é permitido
        );
        expect(
          validarLinhaCopyright(
              '// SPDX-FileCopyrightText: Copyright (C) 2026 Outro Nome'),
          isFalse,
        );
      },
    );

    test(
      'Todos os arquivos Dart de autoria devem conter o cabeçalho SPDX oficial com Aresta Climb Contributors',
      () {
        final Directory diretorioFrontend = obterDiretorioFrontend();
        final List<File> arquivos =
            coletarArquivosDartDeAutoria(diretorioFrontend);

        expect(
          arquivos.isNotEmpty,
          isTrue,
          reason: 'Nenhum arquivo Dart de autoria foi encontrado para validação.',
        );

        final List<String> arquivosNaoConformes = <String>[];

        for (final File arquivo in arquivos) {
          if (!verificarCabecalhoSpdx(arquivo)) {
            final String caminhoRelativo = arquivo.path
                .replaceAll(r'\', '/')
                .replaceFirst('${diretorioFrontend.path.replaceAll(r'\', '/')}/', '');
            arquivosNaoConformes.add(caminhoRelativo);
          }
        }

        expect(
          arquivosNaoConformes,
          isEmpty,
          reason:
              'Os seguintes arquivos Dart não possuem o cabeçalho SPDX obrigatório:\n'
              '${arquivosNaoConformes.join('\n')}\n\n'
              'Formato esperado nas duas primeiras linhas:\n'
              '// SPDX-FileCopyrightText: Copyright (C) <ANO>=2026 Aresta Climb Contributors\n'
              '$kCabecalhoLicencaEsperado\n',
        );
      },
    );
  });
}
