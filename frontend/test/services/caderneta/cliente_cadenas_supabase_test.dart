// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/cadena.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';
import 'package:frontend/services/caderneta/cliente_cadenas_supabase.dart';
import 'package:frontend/services/http/cliente_http_aresta.dart';
import 'package:http/testing.dart';

void main() {
  late HttpServer servidor;
  late String baseUrl;
  String? ultimoMetodo;
  Uri? ultimaUri;
  String? ultimoAuth;
  String? ultimoPrefer;
  Object? ultimoPayload;
  int statusResposta = 200;
  List<Map<String, dynamic>> linhasGet = [];

  setUp(() async {
    HttpOverrides.global = null;
    ultimoMetodo = null;
    ultimaUri = null;
    ultimoAuth = null;
    ultimoPrefer = null;
    ultimoPayload = null;
    statusResposta = 200;
    linhasGet = [];

    servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    baseUrl = 'http://127.0.0.1:${servidor.port}';

    servidor.listen((req) async {
      ultimoMetodo = req.method;
      ultimaUri = req.uri;
      ultimoAuth = req.headers.value('authorization');
      ultimoPrefer = req.headers.value('prefer');

      if (req.method == 'POST') {
        final corpo = await utf8.decoder.bind(req).join();
        ultimoPayload = jsonDecode(corpo);
        req.response.statusCode = statusResposta == 200 ? 201 : statusResposta;
        await req.response.close();
      } else if (req.method == 'DELETE') {
        req.response.statusCode = statusResposta == 200 ? 204 : statusResposta;
        await req.response.close();
      } else {
        req.response.statusCode = statusResposta;
        req.response.headers.contentType = ContentType.json;
        req.response.write(jsonEncode(linhasGet));
        await req.response.close();
      }
    });
  });

  tearDown(() async {
    await servidor.close(force: true);
  });

  test('realiza upsert em lote, listagem e exclusão em public.cadenas via PostgREST', () async {
    final cliente = ClienteCadenasSupabase(
      resolvedorBaseUrl: () => '$baseUrl/',
      resolvedorAnonKey: () => 'anon-key-1',
    );

    // Lista vazia é no-op sem tráfego HTTP
    await cliente.upsertCadenas(
      const [],
      userId: 'uuid-usr-1',
      accessToken: 'jwt-usr-1',
    );
    expect(ultimoMetodo, isNull);

    final cadena = Cadena(
      id: '123e4567-e89b-12d3-a456-426614174000',
      escaladaUid: 'x8siJek3FiG3aB',
      dataAscensao: DateTime(2026, 9, 14),
      tipoAscensao: TipoAscensao.flash,
      notasPrivadas: 'Costura 3 longa',
      criadoEm: DateTime.utc(2026, 9, 14, 15, 0),
    );

    await cliente.upsertCadenas(
      [cadena],
      userId: 'uuid-usr-1',
      accessToken: 'jwt-usr-1',
    );
    expect(ultimoMetodo, 'POST');
    expect(ultimaUri?.queryParameters['on_conflict'], 'id');
    expect(ultimoAuth, 'Bearer jwt-usr-1');
    expect(ultimoPrefer, contains('resolution=merge-duplicates'));
    final enviado = (ultimoPayload as List<dynamic>).single as Map<String, dynamic>;
    expect(enviado['data_ascensao'], '2026-09-14');
    expect(enviado['user_id'], 'uuid-usr-1');

    linhasGet = [enviado];
    final carregadas = await cliente.listarCadenasDoUsuario(
      userId: 'uuid-usr-1',
      accessToken: 'jwt-usr-1',
    );
    expect(ultimoMetodo, 'GET');
    expect(ultimaUri?.queryParameters['user_id'], 'eq.uuid-usr-1');
    expect(carregadas, hasLength(1));
    expect(carregadas.single.notasPrivadas, 'Costura 3 longa');

    await cliente.excluirCadenaRemota(
      cadena.id,
      userId: 'uuid-usr-1',
      accessToken: 'jwt-usr-1',
    );
    expect(ultimoMetodo, 'DELETE');
    expect(ultimaUri?.queryParameters['id'], 'eq.${cadena.id}');
    expect(ultimaUri?.queryParameters['user_id'], 'eq.uuid-usr-1');
  });

  test('lança ExcecaoHttpCadenas tipada em erros HTTP e suporta resolvedores padrão', () async {
    final cliente = ClienteCadenasSupabase(
      resolvedorBaseUrl: () => baseUrl,
      resolvedorAnonKey: () => 'anon-key-1',
    );
    final cadena = Cadena.criar(
      escaladaUid: 'x8siJek3FiG3aB',
      dataAscensao: DateTime(2026, 10, 1),
    );

    statusResposta = 401;
    await expectLater(
      () => cliente.listarCadenasDoUsuario(
        userId: 'uuid-usr-1',
        accessToken: 'jwt-expirado',
      ),
      throwsA(
        isA<ExcecaoHttpCadenas>()
            .having((e) => e.codigoStatusHttp, 'codigoStatusHttp', 401)
            .having((e) => e.toString(), 'toString', contains('401')),
      ),
    );
    await expectLater(
      () => cliente.upsertCadenas(
        [cadena],
        userId: 'uuid-usr-1',
        accessToken: 'jwt-expirado',
      ),
      throwsA(isA<ExcecaoHttpCadenas>()),
    );
    await expectLater(
      () => cliente.excluirCadenaRemota(
        cadena.id,
        userId: 'uuid-usr-1',
        accessToken: 'jwt-expirado',
      ),
      throwsA(isA<ExcecaoHttpCadenas>()),
    );

    Uri? uriPadrao;
    final padrao = ClienteCadenasSupabase(
      clienteHttp: ClienteHttpAresta.paraTestes(
        MockClient((req) async {
          uriPadrao = req.url;
          return Response('[]', 200);
        }),
      ),
    );
    expect(
      await padrao.listarCadenasDoUsuario(userId: 'usr-1', accessToken: 'jwt'),
      isEmpty,
    );
    expect(uriPadrao?.path, '/rest/v1/cadenas');
  });
}
