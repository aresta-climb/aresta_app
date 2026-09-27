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
