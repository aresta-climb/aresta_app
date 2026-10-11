// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Governança Arquitetural - Campos Deprecados de Croqui', () {
    test('nenhum arquivo em lib/ consome campos deprecados de croqui fora do normalizador', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue, reason: 'Diretório lib deve existir');

      final arquivosDart = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) {
            final normalizado = f.path.replaceAll('\\', '/');
            // Ignora bindings gerados pelo Protobuf e o normalizador de entrada
            if (normalizado.contains('lib/aresta_api/')) return false;
            if (normalizado.endsWith('lib/services/dataset/normalizador_croqui.dart')) return false;
            return true;
          })
          .toList();

      final violacoes = <String>[];

      // Padrões proibidos no código de produção
      final padroesProibidos = [
        RegExp(r'\b(hasIndiceMapaAlvo|indiceMapaAlvo)\b'),
        RegExp(r'\b(ref|referencia)\.(escalada|setor|grupo|ids)\b'),
        RegExp(r'\b(ponto|marker|p)\.label\b'),
      ];

      for (final arquivo in arquivosDart) {
        final linhas = arquivo.readAsLinesSync();
        for (var i = 0; i < linhas.length; i++) {
          final linha = linhas[i];
          final numeroLinha = i + 1;

          // Ignora comentários de linha única
          final linhaSemEspaco = linha.trim();
          if (linhaSemEspaco.startsWith('//')) continue;

          for (final padrao in padroesProibidos) {
            if (padrao.hasMatch(linha)) {
              violacoes.add(
                '${arquivo.path}:$numeroLinha: "${linha.trim()}" (corresponde a $padrao)',
              );
            }
          }
        }
      }

      if (violacoes.isNotEmpty) {
        fail(
          'Foram encontradas referências a campos deprecados de Croqui fora do NormalizadorCroqui:\n'
          '${violacoes.join('\n')}\n\n'
          'Use exclusivamente os novos campos da especificação v5 (uid, rotulo, alvoUid, pontosUids).',
        );
      }
    });
  });
}
