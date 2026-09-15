// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/services/dataset/armazenamento/gerenciador_arquivos_locais.dart';

void main() {
  late Directory tempDir;
  late GerenciadorArquivosLocais gerenciador;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('arquivos_locais_test_');
    gerenciador = GerenciadorArquivosLocais();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('GerenciadorArquivosLocais', () {
    test('carregarCroqui retorna null se o arquivo não existir', () async {
      final croqui = await gerenciador.carregarCroqui(tempDir.path, 'pico_inexistente');
      expect(croqui, isNull);
    });

    test('carregarCroqui carrega compilado.binarypb canônico com sucesso', () async {
      final picoDir = Directory('${tempDir.path}/pico_1');
      await picoDir.create(recursive: true);

      final croquiMock = Croqui(
        id: 'pico_1',
        nome: 'Pedra do Baú',
      );
      final file = File('${picoDir.path}/compilado.binarypb');
      await file.writeAsBytes(croquiMock.writeToBuffer());

      final carregado = await gerenciador.carregarCroqui(tempDir.path, 'pico_1');
      expect(carregado, isNotNull);
      expect(carregado!.nome, equals('Pedra do Baú'));
    });

    test('carregarCroqui migra arquivo legado pico_1.binarypb para compilado.binarypb transparentemente', () async {
      final picoDir = Directory('${tempDir.path}/pico_1');
      await picoDir.create(recursive: true);

      final croquiMock = Croqui(
        id: 'pico_1',
        nome: 'Pedra do Baú (Legado)',
      );
      final arquivoLegado = File('${picoDir.path}/pico_1.binarypb');
      await arquivoLegado.writeAsBytes(croquiMock.writeToBuffer());

      final arquivoNovo = File('${picoDir.path}/compilado.binarypb');
      expect(await arquivoNovo.exists(), isFalse);
      expect(await arquivoLegado.exists(), isTrue);

      final carregado = await gerenciador.carregarCroqui(tempDir.path, 'pico_1');
      expect(carregado, isNotNull);
      expect(carregado!.nome, equals('Pedra do Baú (Legado)'));

      // Verifica que o arquivo legado foi renomeado para o nome canônico
      expect(await arquivoNovo.exists(), isTrue);
      expect(await arquivoLegado.exists(), isFalse);
    });

    test('verificarPicoBaixado identifica presença de compilado.binarypb ou arquivo legado', () async {
      expect(await gerenciador.verificarPicoBaixado(tempDir.path, 'pico_1'), isFalse);

      final picoDir = Directory('${tempDir.path}/pico_1');
      await picoDir.create(recursive: true);

      // Com arquivo legado
      final arquivoLegado = File('${picoDir.path}/pico_1.binarypb');
      await arquivoLegado.writeAsBytes([1, 2, 3]);
      expect(await gerenciador.verificarPicoBaixado(tempDir.path, 'pico_1'), isTrue);

      // Com arquivo canônico
      await arquivoLegado.delete();
      final arquivoCanonico = File('${picoDir.path}/compilado.binarypb');
      await arquivoCanonico.writeAsBytes([1, 2, 3]);
      expect(await gerenciador.verificarPicoBaixado(tempDir.path, 'pico_1'), isTrue);
    });

    test('excluirPico remove a pasta do pico e retorna true', () async {
      final picoDir = Directory('${tempDir.path}/pico_1');
      await picoDir.create(recursive: true);
      final file = File('${picoDir.path}/compilado.binarypb');
      await file.writeAsBytes([1, 2, 3]);

      expect(await picoDir.exists(), isTrue);
      final sucesso = await gerenciador.excluirPico(tempDir.path, 'pico_1');
      expect(sucesso, isTrue);
      expect(await picoDir.exists(), isFalse);
    });

    test('excluirPico retorna false para pico não existente', () async {
      final sucesso = await gerenciador.excluirPico(tempDir.path, 'pico_fantasma');
      expect(sucesso, isFalse);
    });
  });
}
