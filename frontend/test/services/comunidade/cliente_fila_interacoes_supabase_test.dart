// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/interacao_via.dart';
import 'package:frontend/data/modelos/item_fila_interacao.dart';
import 'package:frontend/services/comunidade/cliente_fila_interacoes_supabase.dart';

void main() {
  late HttpServer servidor;
  late String baseUrl;
  Map<String, dynamic>? ultimoPayloadRecebido;
  String? ultimoAuthHeader;
  int statusResposta = 200;
  Object corpoRespostaGet = <Map<String, dynamic>>[];

  setUp(() async {
    HttpOverrides.global = null;
    ultimoPayloadRecebido = null;
    ultimoAuthHeader = null;
    statusResposta = 200;
    corpoRespostaGet = <Map<String, dynamic>>[];

    servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    baseUrl = 'http://127.0.0.1:${servidor.port}';

    servidor.listen((req) async {
      ultimoAuthHeader = req.headers.value('authorization');
      if (req.method == 'POST') {
        final texto = await utf8.decoder.bind(req).join();
        ultimoPayloadRecebido = jsonDecode(texto) as Map<String, dynamic>;
        req.response.statusCode = statusResposta == 200 ? 201 : statusResposta;
        await req.response.close();
      } else {
        req.response.statusCode = statusResposta;
        req.response.headers.contentType = ContentType.json;
        req.response.write(jsonEncode(corpoRespostaGet));
        await req.response.close();
      }
    });
  });

  tearDown(() async {
    await servidor.close(force: true);
  });

  test('insere voto autenticado sem enviar id NanoID na chave UUID e alerta anônimo com anonKey', () async {
    final cliente = ClienteFilaInteracoesSupabase(
      resolvedorBaseUrl: () => baseUrl,
      resolvedorAnonKey: () => 'anon-key-teste',
    );

    final voto = ItemFilaInteracao.votoGrau(
      autorIdPublico: 'c3Lk9P1x4Vw8Mn',
      autorNomePublico: 'Mariana',
      escaladaUid: 'x8siJek3FiG3aB',
      deltaGrau: 1,
      grauSugerido: 26,
    );
    await cliente.inserirInteracao(voto, accessToken: 'jwt-atleta');
    expect(ultimoAuthHeader, 'Bearer jwt-atleta');
    expect(ultimoPayloadRecebido!.containsKey('id'), isFalse);
    expect(ultimoPayloadRecebido!['tipo'], 'VOTO_GRAU');
    expect(ultimoPayloadRecebido!['delta_grau'], 1);

    final alerta = ItemFilaInteracao.alertaSeguranca(
      autorIdPublico: 'c3Lk9P1x4Vw8Mn',
      autorNomePublico: 'Anônimo',
      escaladaUid: 'x8siJek3FiG3aB',
      alertaAlvoUid: 'alertaAbelha01',
      categoriaAlerta: CategoriaAlertaSeguranca.abelhasInsetos,
    );
    await cliente.inserirInteracao(alerta);
    expect(ultimoAuthHeader, 'Bearer anon-key-teste');
    expect(ultimoPayloadRecebido!['alerta_alvo_uid'], 'alertaAbelha01');
  });
}
