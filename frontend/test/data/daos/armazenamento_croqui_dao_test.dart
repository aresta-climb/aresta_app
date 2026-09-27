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
