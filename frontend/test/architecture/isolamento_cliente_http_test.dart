// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Suíte de testes arquiteturais que garante o isolamento total de clientes HTTP
/// fora de `lib/services/http/cliente_http_aresta.dart`.
void main() {
  const arquivoPermitido = 'lib/services/http/cliente_http_aresta.dart';

  List<File> listarArquivosDartEmLib() {
    final libDirectory = Directory('lib');
    return libDirectory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList();
  }

  bool ehLinhaDeComentario(String linha) {
    final trimmed = linha.trimLeft();
    return trimmed.startsWith('//') ||
        trimmed.startsWith('/*') ||
        trimmed.startsWith('*');
  }

  group('Isolamento Arquitetural do ClienteHttpAresta', () {
    test(
      'Nenhum arquivo em lib/ (exceto cliente_http_aresta.dart) deve importar package:http/ ou instanciar http.Client, IOClient ou HttpClient',
      () {
        final arquivos = listarArquivosDartEmLib();
        final violacoes = <String>[];

        final regexImportHttp = RegExp(r'''import\s+['"]package:http/''');
        final regexClienteBruto = RegExp(
          r'(\bhttp\.Client\b|\bIOClient\s*\(|\bHttpClient\s*\()',
        );

        for (final file in arquivos) {
          final normalizedPath = file.path.replaceAll('\\', '/');
          if (normalizedPath.endsWith(arquivoPermitido)) {
            continue;
          }

          final lines = file.readAsLinesSync();
          for (var i = 0; i < lines.length; i++) {
            final line = lines[i];
            if (ehLinhaDeComentario(line)) continue;

            if (regexImportHttp.hasMatch(line) ||
                regexClienteBruto.hasMatch(line)) {
              violacoes.add('$normalizedPath:${i + 1}: ${line.trim()}');
            }
          }
        }

        expect(
          violacoes,
          isEmpty,
          reason:
              'Foram encontradas importações diretas de package:http/ ou instanciações brutas de clientes HTTP fora de $arquivoPermitido:\n'
              '${violacoes.join('\n')}\n\n'
              'Solução: Importe cliente_http_aresta.dart e utilize ClienteHttpAresta.instancia.',
        );
      },
    );

    test(
      'Nenhum arquivo de produção em lib/ deve invocar ClienteHttpAresta.paraTestes',
      () {
        final arquivos = listarArquivosDartEmLib();
        final violacoes = <String>[];
        final regexParaTestes = RegExp(r'\bClienteHttpAresta\.paraTestes\b');

        for (final file in arquivos) {
          final normalizedPath = file.path.replaceAll('\\', '/');
          final lines = file.readAsLinesSync();

          for (var i = 0; i < lines.length; i++) {
            final line = lines[i];
            if (ehLinhaDeComentario(line)) continue;

            // Permite a declaração da própria factory dentro de cliente_http_aresta.dart
            if (normalizedPath.endsWith(arquivoPermitido) &&
                line.trimLeft().startsWith('factory ClienteHttpAresta.paraTestes')) {
              continue;
            }

            if (regexParaTestes.hasMatch(line)) {
              violacoes.add('$normalizedPath:${i + 1}: ${line.trim()}');
            }
          }
        }

        expect(
          violacoes,
          isEmpty,
          reason:
              'A fábrica ClienteHttpAresta.paraTestes é exclusiva para a suíte em test/ e nunca deve ser invocada em lib/:\n'
              '${violacoes.join('\n')}',
        );
      },
    );

    test(
      'Nenhum arquivo em lib/ deve chamar .close() em clientes HTTP',
      () {
        final arquivos = listarArquivosDartEmLib();
        final violacoes = <String>[];
        final regexCloseCliente = RegExp(
          r'\b(_?client|_?httpClient|_?clienteHttp)\.close\s*\(',
        );

        for (final file in arquivos) {
          final normalizedPath = file.path.replaceAll('\\', '/');
          final lines = file.readAsLinesSync();

          for (var i = 0; i < lines.length; i++) {
            final line = lines[i];
            if (ehLinhaDeComentario(line)) continue;

            if (regexCloseCliente.hasMatch(line)) {
              violacoes.add('$normalizedPath:${i + 1}: ${line.trim()}');
            }
          }
        }

        expect(
          violacoes,
          isEmpty,
          reason:
              'Foram encontradas chamadas a .close() em clientes HTTP dentro de lib/, o que derruba o pool Keep-Alive compartilhado:\n'
              '${violacoes.join('\n')}',
        );
      },
    );
  });
}
