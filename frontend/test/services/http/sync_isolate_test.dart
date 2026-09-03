// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/services/http/sync_isolate.dart';

void main() {
  late HttpServer localServer;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sync_isolate_test_');
    localServer = await HttpServer.bind('127.0.0.1', 0);
  });

  tearDown(() async {
    await localServer.close(force: true);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Sync Isolate Timeout and Error Handling Tests', () {
    test(
      'downloadIsolateMain deve retornar erro e não travar quando o download do arquivo principal sofrer timeout',
      () async {
        // Servidor que nunca responde à requisição
        localServer.listen((request) async {
          // Não responde a requisição propositalmente para simular hang/timeout
          await Future.delayed(const Duration(seconds: 2));
          request.response.statusCode = 200;
          await request.response.close();
        });

        final resumo = ResumoCroqui()
          ..id = 'pico_timeout'
          ..nome = 'Pico Timeout'
          ..caminhoRelativo = 'picos/pico_timeout/pico_timeout.binarypb'
          ..checksumSha256Croqui = 'SOME_HASH';

        final receivePort = ReceivePort();
        final args = DownloadIsolateArgs(
          newResumoBytes: resumo.writeToBuffer(),
          downloadsDirPath: tempDir.path,
          baseUrl: 'http://${localServer.address.address}:${localServer.port}',
          sendPort: receivePort.sendPort,
          timeoutDuration: const Duration(milliseconds: 150),
        );

        final resultCompleter = Completer<DownloadIsolateResult>();
        final List<double> progressList = [];

        receivePort.listen((msg) {
          if (msg is double) {
            progressList.add(msg);
          } else if (msg is DownloadIsolateResult) {
            resultCompleter.complete(msg);
            receivePort.close();
          }
        });

        await downloadIsolateMain(args);

        final result = await resultCompleter.future.timeout(
          const Duration(seconds: 2),
        );

        expect(result.error, isNotNull);
        expect(result.error, contains('Falha ao baixar binarypb'));
      },
    );

    test(
      'downloadIsolateMain deve retornar erro sem travar quando o download de imagem externa sofrer timeout ou falhar',
      () async {
        final croqui = Croqui()
          ..id = 'pico_img_timeout'
          ..nome = 'Pico Img Timeout'
          ..arquivosExternos.add(
            ArquivoExterno()
              ..caminho = 'foto1.jpg'
              ..checksumSha256 = 'IMG_HASH',
          );
        final croquiBytes = croqui.writeToBuffer();
        final croquiHash = sha256.convert(croquiBytes).toString();

        localServer.listen((request) async {
          if (request.uri.path.endsWith('pico_img_timeout.binarypb')) {
            request.response.headers.contentType = ContentType.binary;
            request.response.statusCode = 200;
            request.response.add(croquiBytes);
            await request.response.close();
          } else if (request.uri.path.contains('foto1.jpg')) {
            // Simula timeout no download da foto
            await Future.delayed(const Duration(seconds: 2));
            request.response.statusCode = 200;
            request.response.add(utf8.encode('image-bytes'));
            await request.response.close();
          }
        });

        final resumo = ResumoCroqui()
          ..id = 'pico_img_timeout'
          ..nome = 'Pico Img Timeout'
          ..caminhoRelativo = 'picos/pico_img_timeout/pico_img_timeout.binarypb'
          ..checksumSha256Croqui = croquiHash;

        final receivePort = ReceivePort();
        final args = DownloadIsolateArgs(
          newResumoBytes: resumo.writeToBuffer(),
          downloadsDirPath: tempDir.path,
          baseUrl: 'http://${localServer.address.address}:${localServer.port}',
          sendPort: receivePort.sendPort,
          timeoutDuration: const Duration(milliseconds: 150),
        );

        final resultCompleter = Completer<DownloadIsolateResult>();
        final List<double> progressList = [];

        receivePort.listen((msg) {
          if (msg is double) {
            progressList.add(msg);
          } else if (msg is DownloadIsolateResult) {
            resultCompleter.complete(msg);
            receivePort.close();
          }
        });

        await downloadIsolateMain(args);

        final result = await resultCompleter.future.timeout(
          const Duration(seconds: 2),
        );

        expect(result.error, isNotNull);
        expect(result.error, contains('Falha em downloads de imagens'));
        expect(progressList, contains(0.05));
      },
    );
  });
}
