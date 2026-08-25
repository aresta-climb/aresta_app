// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/aplicar_cabecalhos_spdx.dart';

void main() {
  group('Testes do Script Aplicador de Cabeçalhos SPDX', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('spdx_tool_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('validarLinhaCopyright aceita qualquer ano a partir de 2026 e intervalos com Contributors', () {
      expect(
        validarLinhaCopyright('// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors'),
        isTrue,
      );
      expect(
        validarLinhaCopyright('// SPDX-FileCopyrightText: Copyright (C) 2027 Aresta Climb Contributors'),
        isTrue,
      );
      expect(
        validarLinhaCopyright('// SPDX-FileCopyrightText: Copyright (C) 2030 Aresta Climb Contributors'),
        isTrue,
      );
      expect(
        validarLinhaCopyright('// SPDX-FileCopyrightText: Copyright (C) 2026-2029 Aresta Climb Contributors'),
        isTrue,
      );
      expect(
        validarLinhaCopyright('// SPDX-FileCopyrightText: Copyright (C) 2024 Aresta Climb Contributors'),
        isFalse,
      );
      expect(
        validarLinhaCopyright('// Outro cabecalho'),
        isFalse,
      );
    });

    test('aplica cabecalho spdx corretamente em arquivos validos, preserva anos >= 2026 e ignora gerados', () {
      final Directory libDir = Directory('${tempDir.path}/lib')..createSync(recursive: true);
      final Directory testDir = Directory('${tempDir.path}/test')..createSync(recursive: true);
      final Directory toolDir = Directory('${tempDir.path}/tool')..createSync(recursive: true);
      final Directory ignoredDir = Directory('${tempDir.path}/lib/aresta_api')..createSync(recursive: true);

      // Arquivo sem cabeçalho em lib/ (deve ser atualizado)
      final File fileLib = File('${libDir.path}/minha_classe.dart')
        ..writeAsStringSync('class MinhaClasse {}\n');

      // Arquivo com cabeçalho 2026 em test/ (deve ser mantido intacto)
      final File fileTest2026 = File('${testDir.path}/meu_teste_2026.dart')
        ..writeAsStringSync(
          '// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors\n'
          '// SPDX-License-Identifier: MPL-2.0\n\n'
          'void main() {}\n',
        );

      // Arquivo com cabeçalho 2027 (ano futuro >= 2026) em test/ (deve ser mantido intacto)
      final File fileTest2027 = File('${testDir.path}/meu_teste_2027.dart')
        ..writeAsStringSync(
          '// SPDX-FileCopyrightText: Copyright (C) 2027 Aresta Climb Contributors\n'
          '// SPDX-License-Identifier: MPL-2.0\n\n'
          'void main() {}\n',
        );

      // Arquivo com faixa de anos (2026-2030) (deve ser mantido intacto)
      final File fileTestFaixa = File('${testDir.path}/meu_teste_faixa.dart')
        ..writeAsStringSync(
          '// SPDX-FileCopyrightText: Copyright (C) 2026-2030 Aresta Climb Contributors\n'
          '// SPDX-License-Identifier: MPL-2.0\n\n'
          'void main() {}\n',
        );

      // Arquivo autogerado .g.dart (deve ser ignorado)
      final File fileGerado = File('${libDir.path}/modelo.g.dart')
        ..writeAsStringSync('// GENERATED CODE\n');

      // Arquivo em diretório ignorado (deve ser ignorado)
      final File fileIgnoredDir = File('${ignoredDir.path}/api.pb.dart')
        ..writeAsStringSync('// PROTOBUF\n');

      // Arquivo em tool/ sem cabeçalho (deve ser atualizado)
      final File fileTool = File('${toolDir.path}/meu_script.dart')
        ..writeAsStringSync('void main() {}\n');

      final int atualizados = aplicarCabecalhosSpdx(tempDir);

      // Apenas fileLib e fileTool devem ser atualizados
      expect(atualizados, equals(2));

      expect(
        fileLib.readAsStringSync(),
        startsWith('// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors\n// SPDX-License-Identifier: MPL-2.0'),
      );
      expect(
        fileTool.readAsStringSync(),
        startsWith('// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors\n// SPDX-License-Identifier: MPL-2.0'),
      );

      // Confirma que 2026, 2027 e faixas de anos foram preservadas sem duplicar o cabeçalho
      expect(
        fileTest2026.readAsStringSync(),
        equals(
          '// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors\n'
          '// SPDX-License-Identifier: MPL-2.0\n\n'
          'void main() {}\n',
        ),
      );
      expect(
        fileTest2027.readAsStringSync(),
        equals(
          '// SPDX-FileCopyrightText: Copyright (C) 2027 Aresta Climb Contributors\n'
          '// SPDX-License-Identifier: MPL-2.0\n\n'
          'void main() {}\n',
        ),
      );
      expect(
        fileTestFaixa.readAsStringSync(),
        equals(
          '// SPDX-FileCopyrightText: Copyright (C) 2026-2030 Aresta Climb Contributors\n'
          '// SPDX-License-Identifier: MPL-2.0\n\n'
          'void main() {}\n',
        ),
      );

      expect(fileGerado.readAsStringSync(), equals('// GENERATED CODE\n'));
      expect(fileIgnoredDir.readAsStringSync(), equals('// PROTOBUF\n'));
    });
  });
}
