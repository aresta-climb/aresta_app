// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

// Como o script de coverage está na pasta tool, importamos de lá.
// Como não é um pacote (não está em lib/), precisamos importar com caminho relativo.
import '../../tool/coverage_report.dart';

void main() {
  group('Coverage Report Script Tests', () {
    late Directory tempDir;
    late String lcovPath;
    late String outHtmlPath;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('coverage_test_');
      lcovPath = '${tempDir.path}/lcov.info';
      outHtmlPath = '${tempDir.path}/coverage_report.html';
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('generateReport missing lcov.info does not crash', () {
      // O arquivo não existe
      expect(() => generateReport(lcovPath, outHtmlPath), returnsNormally);
      expect(File(outHtmlPath).existsSync(), isFalse);
    });

    test('generateReport creates HTML report and ignores lib/aresta_api', () {
      // Cria um lcov.info falso
      final lcovContent = '''
TN:
SF:lib/pages/home.dart
DA:1,1
DA:2,0
LF:2
LH:1
end_of_record
TN:
SF:lib/aresta_api/generated_api.dart
DA:1,0
DA:2,0
LF:2
LH:0
end_of_record
TN:
SF:lib/utils/helper.dart
DA:1,1
DA:2,1
LF:2
LH:2
end_of_record
''';
      File(lcovPath).writeAsStringSync(lcovContent);

      generateReport(lcovPath, outHtmlPath);

      final outFile = File(outHtmlPath);
      expect(outFile.existsSync(), isTrue);

      final htmlContent = outFile.readAsStringSync();

      // Verifica o título e estrutura básica
      expect(
        htmlContent,
        contains('Relatório Detalhado de Cobertura de Testes'),
      );

      // Verifica se os arquivos válidos foram processados
      expect(htmlContent, contains('lib/pages/home.dart'));
      expect(htmlContent, contains('lib/utils/helper.dart'));
      expect(htmlContent, contains('50.00%')); // 1/2 home.dart
      expect(htmlContent, contains('100.00%')); // 2/2 helper.dart

      // Verifica resumo (1 de home + 2 de helper = 3 lines hit, 2 + 2 = 4 lines found -> 75%)
      expect(htmlContent, contains('3 de 4'));
      expect(htmlContent, contains('75.00%'));

      // Verifica que o código gerado foi ignorado
      expect(htmlContent, isNot(contains('lib/aresta_api/generated_api.dart')));
    });
  });
}
