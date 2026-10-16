// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frontend/services/http/cliente_http_aresta.dart';

void main() {
  group('ClienteHttpAresta', () {
    test('retorna sempre a mesma instância singleton e configura timeout de ociosidade em 120 segundos', () {
      final primeira = ClienteHttpAresta.instancia;
      final segunda = ClienteHttpAresta.instancia;

      expect(identical(primeira, segunda), isTrue);
      expect(
        ClienteHttpAresta.tempoOciosidadeKeepAlive,
        equals(const Duration(seconds: 120)),
      );
      expect(
        ClienteHttpAresta.tempoLimiteConexao,
        equals(const Duration(seconds: 10)),
      );
    });

    test('permite criar instância para testes e encaminha chamadas get, post, head e send', () async {
      final metodosRecebidos = <String>[];
      final clienteMock = MockClient((request) async {
        metodosRecebidos.add('${request.method}:${request.url}');
        return http.Response('ok-${request.method}', 200);
      });

      final cliente = ClienteHttpAresta.paraTestes(clienteMock);
      final uri = Uri.parse('https://serving.arestaclimb.com/v4/teste');

      final respGet = await cliente.get(uri, headers: {'X-Teste': '1'});
      expect(respGet.statusCode, equals(200));
      expect(respGet.body, equals('ok-GET'));

      final respPost = await cliente.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'chave': 'valor'}),
        encoding: utf8,
      );
      expect(respPost.statusCode, equals(200));
      expect(respPost.body, equals('ok-POST'));

      final respHead = await cliente.head(uri, headers: {'If-None-Match': '"etag"'});
      expect(respHead.statusCode, equals(200));

      final requisicao = Request('GET', uri);
      final respStream = await cliente.send(requisicao);
      expect(respStream.statusCode, equals(200));

      expect(
        metodosRecebidos,
        equals([
          'GET:https://serving.arestaclimb.com/v4/teste',
          'POST:https://serving.arestaclimb.com/v4/teste',
          'HEAD:https://serving.arestaclimb.com/v4/teste',
          'GET:https://serving.arestaclimb.com/v4/teste',
        ]),
      );
    });

    test('não expõe método close na interface pública de ClienteHttpAresta', () {
      final dynamic cliente = ClienteHttpAresta.instancia;
      expect(
        () => cliente.close(),
        throwsA(isA<NoSuchMethodError>()),
      );
    });
  });
}
