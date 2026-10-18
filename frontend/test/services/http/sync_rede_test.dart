// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/http/cliente_http_aresta.dart';
import 'package:frontend/services/http/sync_rede.dart';

void main() {
  late HttpServer servidor;
  late String urlBase;
  late Future<void> Function(HttpRequest request) tratadorRequisicao;

  setUp(() async {
    EditorDeCroqui().isExperimentalMode.value = false;
    servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    urlBase = 'http://127.0.0.1:${servidor.port}';
    tratadorRequisicao = (request) async {
      request.response.statusCode = 404;
      await request.response.close();
    };
    servidor.listen((request) async {
      await tratadorRequisicao(request);
    });
  });

  tearDown(() async {
    EditorDeCroqui().isExperimentalMode.value = false;
    await servidor.close(force: true);
  });

  group('SyncNetwork - fetchIndiceWithRetries', () {
    test('deve buscar indice.binarypb com ETag e forceBypassCache retornando IndiceUpdated', () async {
      String? etagRecebido;
      String? queryRecebida;
      final indiceProto = Indice(versaoCatalogo: 'hash_v1');

      tratadorRequisicao = (request) async {
        etagRecebido = request.headers.value('if-none-match');
        queryRecebida = request.uri.query;
        request.response.statusCode = 200;
        request.response.headers.set('etag', '"etag-novo"');
        request.response.add(indiceProto.writeToBuffer());
        await request.response.close();
      };

      final rede = SyncNetwork(null, Duration.zero);
      final resultado = await rede.fetchIndiceWithRetries(
        urlBase,
        '"etag-antigo"',
        forceBypassCache: true,
      );

      expect(resultado, isA<IndiceUpdated>());
      final atualizado = resultado as IndiceUpdated;
      expect(atualizado.newIndice.versaoCatalogo, equals('hash_v1'));
      expect(atualizado.newEtag, equals('"etag-novo"'));
      expect(etagRecebido, equals('"etag-antigo"'));
      expect(queryRecebida, startsWith('t='));
    });

    test('deve retornar IndiceUnchanged quando o servidor responder 304 Not Modified', () async {
      tratadorRequisicao = (request) async {
        request.response.statusCode = 304;
        await request.response.close();
      };

      final rede = SyncNetwork(null, Duration.zero);
      final resultado = await rede.fetchIndiceWithRetries(urlBase, '"etag-atual"');

      expect(resultado, isA<IndiceUnchanged>());
    });

    test('deve retornar IndiceOffline quando os bytes do indice forem corrompidos ou houver falha de conexao', () async {
      tratadorRequisicao = (request) async {
        request.response.statusCode = 200;
        // Bytes invalidos para Protobuf wire format
        request.response.add(Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF, 0xFF]));
        await request.response.close();
      };

      final rede = SyncNetwork(null, Duration.zero);
      final resultadoCorrompido = await rede.fetchIndiceWithRetries(urlBase, null);
      expect(resultadoCorrompido, isA<IndiceOffline>());

      // Falha de conexao e erro generico com retries
      int tentativas = 0;
      final clienteFalho = ClienteHttpAresta.paraTestes(
        MockClient(( _) async {
          tentativas++;
          if (tentativas == 1) {
            throw const SocketException('Sem rede');
          }
          throw StateError('Falha inesperada');
        }),
      );
      final redeFalha = SyncNetwork(clienteFalho, Duration.zero);
      final resultadoOffline = await redeFalha.fetchIndiceWithRetries(
        urlBase,
        null,
        retries: 2,
      );
      expect(resultadoOffline, isA<IndiceOffline>());
      expect(tentativas, equals(2));
    });

    test('deve retornar IndiceErroServidor para status 503, experimental 404 e erro 500 padrao', () async {
      int codigoStatus = 503;
      tratadorRequisicao = (request) async {
        request.response.statusCode = codigoStatus;
        await request.response.close();
      };

      final rede = SyncNetwork(null, Duration.zero);

      final res503 = await rede.fetchIndiceWithRetries(urlBase, null);
      expect(res503, isA<IndiceErroServidor>());
      expect((res503 as IndiceErroServidor).statusCode, equals(503));

      codigoStatus = 500;
      final res500 = await rede.fetchIndiceWithRetries(urlBase, null);
      expect(res500, isA<IndiceErroServidor>());
      expect((res500 as IndiceErroServidor).statusCode, equals(500));

      EditorDeCroqui().isExperimentalMode.value = true;
      codigoStatus = 404;
      final resExp = await rede.fetchIndiceWithRetries(urlBase, null);
      expect(resExp, isA<IndiceErroServidor>());
      expect((resExp as IndiceErroServidor).statusCode, equals(404));
    });
  });

  group('SyncNetwork - downloadFile e baixarCatalogoCompleto', () {
    test('deve baixar catalogo.db com e sem versaoCatalogo e tratar status de erro', () async {
      final urlsRequisitadas = <String>[];
      int statusResposta = 200;

      tratadorRequisicao = (request) async {
        urlsRequisitadas.add(request.uri.toString());
        request.response.statusCode = statusResposta;
        if (statusResposta == 200) {
          request.response.add([1, 2, 3, 4]);
        }
        await request.response.close();
      };

      final rede = SyncNetwork(null, Duration.zero);

      final bytesSemVersao = await rede.baixarCatalogoCompleto(urlBase);
      expect(bytesSemVersao, equals([1, 2, 3, 4]));

      final bytesComVersao = await rede.baixarCatalogoCompleto(
        urlBase,
        versaoCatalogo: 'abc12345',
      );
      expect(bytesComVersao, equals([1, 2, 3, 4]));
      expect(
        urlsRequisitadas,
        equals(['/catalogo.db', '/catalogo.db?v=abc12345']),
      );

      statusResposta = 503;
      expect(await rede.downloadFile('$urlBase/arq.bin'), isNull);

      statusResposta = 500;
      expect(await rede.downloadFile('$urlBase/arq.bin'), isNull);

      EditorDeCroqui().isExperimentalMode.value = true;
      statusResposta = 404;
      expect(await rede.downloadFile('$urlBase/arq.bin'), isNull);
    });
  });

  group('SyncNetwork - consultarSyncCatalogo', () {
    test('deve consultar GET /sync enviando versao_local e versao_destino e decodificar RespostaSyncCatalogo', () async {
      Uri? uriRecebida;
      tratadorRequisicao = (request) async {
        uriRecebida = request.uri;
        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'acao': 'apply_delta',
            'versao_local': 'v1',
            'versao_destino': 'v2',
            'total_deltas': 1,
            'upserts': {
              'croquis': [
                {
                  'croqui_uid': 'c1',
                  'id_slug': 'br_mg_pico',
                  'nome': 'Pico Teste',
                  'cidade': 'Igarapé',
                  'estado': 'MG',
                  'atualizado_em': 100,
                },
              ],
              'entidades': [],
            },
            'deletes': {
              'croquis': [],
              'entidades': ['uid_del'],
            },
          }),
        );
        await request.response.close();
      };

      final rede = SyncNetwork(null, Duration.zero);
      final resposta = await rede.consultarSyncCatalogo(
        versaoLocal: 'v1',
        versaoDestino: 'v2',
        urlBaseCatalogo: urlBase,
      );

      expect(uriRecebida?.path, equals('/sync'));
      expect(uriRecebida?.queryParameters['versao_local'], equals('v1'));
      expect(uriRecebida?.queryParameters['versao_destino'], equals('v2'));
      expect(resposta, isNotNull);
      expect(resposta!.acao, equals('apply_delta'));
      expect(resposta.upserts!.croquis.single.idSlug, equals('br_mg_pico'));
      expect(resposta.deletes!.entidades, equals(['uid_del']));
    });

    test('deve retornar null quando /sync responder erro HTTP ou JSON invalido', () async {
      int statusCode = 500;
      String corpo = 'erro interno';

      tratadorRequisicao = (request) async {
        request.response.statusCode = statusCode;
        request.response.write(corpo);
        await request.response.close();
      };

      final rede = SyncNetwork(null, Duration.zero);

      final respErroHttp = await rede.consultarSyncCatalogo(
        versaoLocal: 'v1',
        versaoDestino: 'v2',
        urlBaseCatalogo: urlBase,
        retries: 1,
      );
      expect(respErroHttp, isNull);

      statusCode = 200;
      corpo = '{json_invalido';
      final respJsonInvalido = await rede.consultarSyncCatalogo(
        versaoLocal: 'v1',
        versaoDestino: 'v2',
        urlBaseCatalogo: urlBase,
        retries: 1,
      );
      expect(respJsonInvalido, isNull);
    });
  });
}
