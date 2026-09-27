// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/daos/indice_dao.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';

void main() {
  late Directory tempDir;
  late IndiceDao dao;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('aresta_indice_dao_test_');
    dao = IndiceDao();
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('IndiceDao Tests', () {
    test('carregarIndice lê arquivo indice.binarypb do disco com sucesso', () async {
      final indiceEsperado = Indice(
        croquis: [
          ResumoCroqui(id: 'bau', nome: 'Pedra do Baú'),
          ResumoCroqui(id: 'cipo', nome: 'Serra do Cipó'),
        ],
      );

      final arquivoIndice = File('${tempDir.path}/indice.binarypb');
      await arquivoIndice.writeAsBytes(indiceEsperado.writeToBuffer());

      final indiceCarregado = await dao.carregarDoDisco(arquivoIndice.path);

      expect(indiceCarregado, isNotNull);
      expect(indiceCarregado!.croquis.length, equals(2));
      expect(indiceCarregado.croquis[0].id, equals('bau'));
      expect(indiceCarregado.croquis[1].id, equals('cipo'));
    });

    test('carregarDoDisco retorna null se arquivo não existe', () async {
      final indiceCarregado = await dao.carregarDoDisco('${tempDir.path}/inexistente.binarypb');
      expect(indiceCarregado, isNull);
    });

    test('salvarNoDisco grava Indice em bytes binários no arquivo', () async {
      final indice = Indice(
        croquis: [
          ResumoCroqui(id: 'itacoatiara', nome: 'Itacoatiara'),
        ],
      );

      final caminhoArquivo = '${tempDir.path}/novo_indice.binarypb';
      final sucesso = await dao.salvarNoDisco(caminhoArquivo, indice);

      expect(sucesso, isTrue);
      expect(File(caminhoArquivo).existsSync(), isTrue);

      final lido = await dao.carregarDoDisco(caminhoArquivo);
      expect(lido?.croquis.first.id, equals('itacoatiara'));
    });
  });
}
