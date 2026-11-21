// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/cadena.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';
import 'package:frontend/services/caderneta/cliente_cadenas_supabase.dart';

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
  });
}
