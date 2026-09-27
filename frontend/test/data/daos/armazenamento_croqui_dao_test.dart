// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/daos/armazenamento_croqui_dao.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';

void main() {
  late Directory tempDir;
  late ArmazenamentoCroquiDao dao;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('aresta_croqui_dao_test_');
    dao = ArmazenamentoCroquiDao();
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('ArmazenamentoCroquiDao Tests', () {
    test('carregarCroqui lê com sucesso compilado.binarypb do diretório', () async {
      final picoDir = Directory('${tempDir.path}/pedra_bela')..createSync(recursive: true);
      final croquiEsperado = Croqui(
        id: 'pedra_bela',
        nome: 'Pedra Bela',
        picos: [Pico(nome: 'Pedra Bela')],
      );

      final arquivoBinario = File('${picoDir.path}/compilado.binarypb');
      await arquivoBinario.writeAsBytes(croquiEsperado.writeToBuffer());

      final croquiCarregado = await dao.carregarCroqui(tempDir.path, 'pedra_bela');

      expect(croquiCarregado, isNotNull);
      expect(croquiCarregado!.id, equals('pedra_bela'));
      expect(croquiCarregado.nome, equals('Pedra Bela'));
    });

    test('carregarCroqui migra arquivo legado picoId.binarypb para compilado.binarypb', () async {
      final picoDir = Directory('${tempDir.path}/bau')..createSync(recursive: true);
      final croquiLegado = Croqui(
        id: 'bau',
        nome: 'Pedra do Baú',
      );

      final arquivoLegado = File('${picoDir.path}/bau.binarypb');
      await arquivoLegado.writeAsBytes(croquiLegado.writeToBuffer());

      final croquiCarregado = await dao.carregarCroqui(tempDir.path, 'bau');

      expect(croquiCarregado, isNotNull);
      expect(croquiCarregado!.id, equals('bau'));
      expect(File('${picoDir.path}/compilado.binarypb').existsSync(), isTrue);
    });

    test('verificarPicoBaixado retorna true se compilado.binarypb ou legado existe', () async {
      final picoDir = Directory('${tempDir.path}/cipo')..createSync(recursive: true);
      expect(await dao.verificarPicoBaixado(tempDir.path, 'cipo'), isFalse);

      File('${picoDir.path}/compilado.binarypb').writeAsBytesSync([1, 2, 3]);
      expect(await dao.verificarPicoBaixado(tempDir.path, 'cipo'), isTrue);
    });

    test('excluirPico remove o diretório do pico com sucesso', () async {
      final picoDir = Directory('${tempDir.path}/itacoatiara')..createSync(recursive: true);
      File('${picoDir.path}/compilado.binarypb').writeAsBytesSync([1, 2, 3]);

      final sucesso = await dao.excluirPico(tempDir.path, 'itacoatiara');

      expect(sucesso, isTrue);
      expect(picoDir.existsSync(), isFalse);
    });
  });
}
