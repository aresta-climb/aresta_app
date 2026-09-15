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

    test(
      'downloadIsolateMain deve recuperar com sucesso na segunda tentativa após receber HTTP 504 transitório',
      () async {
        final imgBytes = utf8.encode('image-bytes-sucesso');
        final imgHash = sha256.convert(imgBytes).toString();

        final croqui = Croqui()
          ..id = 'pico_retry_504'
          ..nome = 'Pico Retry 504'
          ..arquivosExternos.add(
            ArquivoExterno()
              ..caminho = 'foto_504.jpg'
              ..checksumSha256 = imgHash,
          );
        final croquiBytes = croqui.writeToBuffer();
        final croquiHash = sha256.convert(croquiBytes).toString();

        int requisicoesFoto = 0;

        localServer.listen((request) async {
          if (request.uri.path.endsWith('pico_retry_504.binarypb')) {
            request.response.headers.contentType = ContentType.binary;
            request.response.statusCode = 200;
            request.response.add(croquiBytes);
            await request.response.close();
          } else if (request.uri.path.contains('foto_504.jpg')) {
            requisicoesFoto++;
            if (requisicoesFoto == 1) {
              // 1ª tentativa falha com 504 Gateway Timeout
              request.response.statusCode = 504;
              request.response.write('Gateway Timeout');
              await request.response.close();
            } else {
              // 2ª tentativa responde 200 OK
              request.response.statusCode = 200;
              request.response.add(imgBytes);
              await request.response.close();
            }
          }
        });

        final resumo = ResumoCroqui()
          ..id = 'pico_retry_504'
          ..nome = 'Pico Retry 504'
          ..caminhoRelativo = 'picos/pico_retry_504/pico_retry_504.binarypb'
          ..checksumSha256Croqui = croquiHash;

        final receivePort = ReceivePort();
        final args = DownloadIsolateArgs(
          newResumoBytes: resumo.writeToBuffer(),
          downloadsDirPath: tempDir.path,
          baseUrl: 'http://${localServer.address.address}:${localServer.port}',
          sendPort: receivePort.sendPort,
          timeoutDuration: const Duration(seconds: 1),
        );

        final resultCompleter = Completer<DownloadIsolateResult>();

        receivePort.listen((msg) {
          if (msg is DownloadIsolateResult) {
            resultCompleter.complete(msg);
            receivePort.close();
          }
        });

        await downloadIsolateMain(args);

        final result = await resultCompleter.future.timeout(
          const Duration(seconds: 5),
        );

        expect(result.error, isNull,
            reason: 'O download deve se recuperar do HTTP 504 na segunda tentativa');
        expect(requisicoesFoto, equals(2),
            reason: 'Deve ter realizado exatamente 2 tentativas');
        expect(result.newPicoDataBytes, isNotNull);
      },
    );

    test(
      'downloadIsolateMain deve preencher rastreamentoPilha no DownloadIsolateResult quando esgotar todas as tentativas de falha',
      () async {
        final croqui = Croqui()
          ..id = 'pico_falha_persistente'
          ..nome = 'Pico Falha Persistente'
          ..arquivosExternos.add(
            ArquivoExterno()
              ..caminho = 'foto_invalida.jpg'
              ..checksumSha256 = 'HASH_INEXISTENTE',
          );
        final croquiBytes = croqui.writeToBuffer();
        final croquiHash = sha256.convert(croquiBytes).toString();

        localServer.listen((request) async {
          if (request.uri.path.endsWith('pico_falha_persistente.binarypb')) {
            request.response.headers.contentType = ContentType.binary;
            request.response.statusCode = 200;
            request.response.add(croquiBytes);
            await request.response.close();
          } else if (request.uri.path.contains('foto_invalida.jpg')) {
            // Falha persistente com 504 em todas as requisições
            request.response.statusCode = 504;
            request.response.write('Gateway Timeout Persistente');
            await request.response.close();
          }
        });

        final resumo = ResumoCroqui()
          ..id = 'pico_falha_persistente'
          ..nome = 'Pico Falha Persistente'
          ..caminhoRelativo = 'picos/pico_falha_persistente/pico_falha_persistente.binarypb'
          ..checksumSha256Croqui = croquiHash;

        final receivePort = ReceivePort();
        final args = DownloadIsolateArgs(
          newResumoBytes: resumo.writeToBuffer(),
          downloadsDirPath: tempDir.path,
          baseUrl: 'http://${localServer.address.address}:${localServer.port}',
          sendPort: receivePort.sendPort,
          timeoutDuration: const Duration(milliseconds: 200),
        );

        final resultCompleter = Completer<DownloadIsolateResult>();

        receivePort.listen((msg) {
          if (msg is DownloadIsolateResult) {
            resultCompleter.complete(msg);
            receivePort.close();
          }
        });

        await downloadIsolateMain(args);

        final result = await resultCompleter.future.timeout(
          const Duration(seconds: 5),
        );

        expect(result.error, isNotNull);
        expect(result.rastreamentoPilha, isNotNull,
            reason: 'O resultado com erro deve conter a rastreamentoPilha do isolate');
        expect(result.rastreamentoPilha, contains('sync_isolate.dart'));
      },
    );

    test(
      'downloadIsolateMain deve reaproveitar mídia presente em temp_cache sem realizar requisição HTTP',
      () async {
        final tempCacheDir = Directory('${tempDir.path}/temp_cache')..createSync(recursive: true);
        final downloadsDir = Directory('${tempDir.path}/downloads')..createSync(recursive: true);

        final conteudoFoto = utf8.encode('bytes_da_imagem_ja_em_cache');
        final hashFoto = sha256.convert(conteudoFoto).toString();

        // Cria o arquivo já em temp_cache com a convenção <caminho>.<hash>
        final arquivoCache = File('${tempCacheDir.path}/pico_cache/foto1.jpg.$hashFoto');
        arquivoCache.parent.createSync(recursive: true);
        arquivoCache.writeAsBytesSync(conteudoFoto);

        final croqui = Croqui()
          ..id = 'pico_cache'
          ..nome = 'Pico do Cache'
          ..arquivosExternos.add(
            ArquivoExterno()
              ..caminho = 'foto1.jpg'
              ..checksumSha256 = hashFoto,
          );
        final croquiBytes = croqui.writeToBuffer();
        final croquiHash = sha256.convert(croquiBytes).toString();

        int requisicoesFoto = 0;

        localServer.listen((request) async {
          if (request.uri.path.endsWith('pico_cache.binarypb')) {
            request.response.headers.contentType = ContentType.binary;
            request.response.statusCode = 200;
            request.response.add(croquiBytes);
            await request.response.close();
          } else if (request.uri.path.contains('foto1.jpg')) {
            requisicoesFoto++;
            request.response.headers.contentType = ContentType.binary;
            request.response.statusCode = 200;
            request.response.add(conteudoFoto);
            await request.response.close();
          }
        });

        final resumo = ResumoCroqui()
          ..id = 'pico_cache'
          ..nome = 'Pico do Cache'
          ..caminhoRelativo = 'picos/pico_cache/pico_cache.binarypb'
          ..checksumSha256Croqui = croquiHash;

        final receivePort = ReceivePort();
        final args = DownloadIsolateArgs(
          newResumoBytes: resumo.writeToBuffer(),
          downloadsDirPath: downloadsDir.path,
          baseUrl: 'http://${localServer.address.address}:${localServer.port}',
          sendPort: receivePort.sendPort,
          tempCacheDirPath: tempCacheDir.path,
        );

        final resultCompleter = Completer<DownloadIsolateResult>();

        receivePort.listen((msg) {
          if (msg is DownloadIsolateResult) {
            resultCompleter.complete(msg);
            receivePort.close();
          }
        });

        await downloadIsolateMain(args);

        final result = await resultCompleter.future.timeout(
          const Duration(seconds: 5),
        );

        expect(result.error, isNull);
        // O arquivo foi copiado diretamente do temp_cache para o .tmp
        expect(
          result.filesToRename,
          containsPair(
            '${downloadsDir.path}/pico_cache/foto1.jpg.tmp',
            '${downloadsDir.path}/pico_cache/foto1.jpg',
          ),
        );
        final tmpFile = File('${downloadsDir.path}/pico_cache/foto1.jpg.tmp');
        expect(tmpFile.existsSync(), isTrue);
        expect(tmpFile.readAsBytesSync(), equals(conteudoFoto));

        // Nenhuma requisição de rede deve ter sido realizada para a foto que já estava no temp_cache
        expect(requisicoesFoto, equals(0));
      },
    );
  });
}
