// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frontend/services/http/baixador_atualizacoes.dart';
import 'package:frontend/services/http/cliente_http_aresta.dart';

void main() {
  late Directory stagingDir;

  setUp(() async {
    stagingDir = await Directory.systemTemp.createTemp('baixador_test_');
  });

  tearDown(() async {
    if (await stagingDir.exists()) {
      await stagingDir.delete(recursive: true);
    }
  });

  group('UpdateDownloader (Baixador de Atualizações)', () {
    test('baixa e valida checksum SHA-256 usando ClienteHttpAresta injetado', () async {
      final bytesConteudo = utf8.encode('conteudo-valido-123');
      final hashEsperado = sha256.convert(bytesConteudo).toString();

      final mockClient = MockClient((request) async {
        return http.Response.bytes(bytesConteudo, 200);
      });

      final downloader = UpdateDownloader(
        client: ClienteHttpAresta.paraTestes(mockClient),
      );

      await downloader.downloadAndVerifyUpdates(
        filesToUpdate: [
          IndexEntry(
            filename: 'arquivo.bin',
            expectedSha256: hashEsperado,
            downloadUrl: 'https://serving.arestaclimb.com/v4/arquivo.bin',
          ),
        ],
        stagingDir: stagingDir,
      );

      final arquivoFinal = File('${stagingDir.path}/arquivo.bin');
      expect(await arquivoFinal.exists(), isTrue);
      expect(await arquivoFinal.readAsBytes(), equals(bytesConteudo));
    });

    test('lança exceção e remove arquivo quando checksum diverge', () async {
      final bytesConteudo = utf8.encode('conteudo-adulterado');
      final mockClient = MockClient((request) async {
        return http.Response.bytes(bytesConteudo, 200);
      });

      final downloader = UpdateDownloader(
        client: ClienteHttpAresta.paraTestes(mockClient),
      );

      await expectLater(
        () => downloader.downloadAndVerifyUpdates(
          filesToUpdate: [
            IndexEntry(
              filename: 'corrompido.bin',
              expectedSha256: 'hash_diferente',
              downloadUrl: 'https://serving.arestaclimb.com/v4/corrompido.bin',
            ),
          ],
          stagingDir: stagingDir,
        ),
        throwsException,
      );

      final arquivoFinal = File('${stagingDir.path}/corrompido.bin');
      expect(await arquivoFinal.exists(), isFalse);
    });
  });
}
