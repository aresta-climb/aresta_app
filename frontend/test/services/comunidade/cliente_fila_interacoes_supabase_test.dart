// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/interacao_via.dart';
import 'package:frontend/data/modelos/item_fila_interacao.dart';
import 'package:frontend/services/comunidade/cliente_fila_interacoes_supabase.dart';
import 'package:frontend/services/http/cliente_http_aresta.dart';
import 'package:http/testing.dart';

void main() {
  late HttpServer servidor;
  late String baseUrl;
  Map<String, dynamic>? ultimoPayloadRecebido;
  String? ultimoMetodoHttp;
  String? ultimoAuthHeader;
  String? ultimoApikeyHeader;
  String? ultimoPreferHeader;
  Uri? ultimaUriRequisitada;
  int statusResposta = 200;
  Object corpoRespostaGet = <Map<String, dynamic>>[];

  setUp(() async {
    HttpOverrides.global = null;
    ultimoPayloadRecebido = null;
    ultimoMetodoHttp = null;
    ultimoAuthHeader = null;
    ultimoApikeyHeader = null;
    ultimoPreferHeader = null;
    ultimaUriRequisitada = null;
    statusResposta = 200;
    corpoRespostaGet = <Map<String, dynamic>>[];

    servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    baseUrl = 'http://127.0.0.1:${servidor.port}/';

    servidor.listen((req) async {
      ultimoMetodoHttp = req.method;
      ultimoAuthHeader = req.headers.value('authorization');
      ultimoApikeyHeader = req.headers.value('apikey');
      ultimoPreferHeader = req.headers.value('prefer');
      ultimaUriRequisitada = req.uri;
      if (req.method == 'POST' || req.method == 'PATCH') {
        final texto = await utf8.decoder.bind(req).join();
        ultimoPayloadRecebido = texto.isNotEmpty
            ? jsonDecode(texto) as Map<String, dynamic>
            : null;
        req.response.statusCode = statusResposta == 200
            ? (req.method == 'POST' ? 201 : 204)
            : statusResposta;
        await req.response.close();
      } else if (req.method == 'DELETE') {
        ultimoPayloadRecebido = null;
        req.response.statusCode = statusResposta == 200 ? 204 : statusResposta;
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

  test('insere voto autenticado com JWT e alerta público sem enviar publishable key como Bearer JWT', () async {
    final cliente = ClienteFilaInteracoesSupabase(
      resolvedorBaseUrl: () => baseUrl,
      resolvedorAnonKey: () => 'sb_publishable_teste123',
    );

    final voto = ItemFilaInteracao.votoGrau(
      autorIdPublico: 'c3Lk9P1x4Vw8Mn',
      autorNomePublico: 'Mariana',
      escaladaUid: 'x8siJek3FiG3aB',
      deltaGrau: 1,
      grauSugerido: 26,
    );
    await cliente.inserirInteracao(voto, accessToken: 'jwt-atleta');
    expect(ultimoApikeyHeader, 'sb_publishable_teste123');
    expect(ultimoAuthHeader, 'Bearer jwt-atleta');
    expect(ultimoPayloadRecebido!.containsKey('id'), isFalse);
    expect(ultimoPayloadRecebido!['tipo'], 'VOTO_GRAU');
    expect(ultimoPayloadRecebido!['delta_grau'], 1);

    final alerta = ItemFilaInteracao.alertaSeguranca(
      autorIdPublico: 'c3Lk9P1x4Vw8Mn',
      autorNomePublico: 'Anônimo',
      escaladaUid: 'x8siJek3FiG3aB',
      alertaAlvoUid: 'alertaAbelha01',
      categoriaAlerta: CategoriaAlertaSeguranca.fauna,
    );
    await cliente.inserirInteracao(alerta);
    expect(ultimoApikeyHeader, 'sb_publishable_teste123');
    expect(ultimoAuthHeader, isNull);
    expect(ultimaUriRequisitada?.path, '/rest/v1/fila_interacoes');
    expect(ultimoPayloadRecebido!['alerta_alvo_uid'], 'alertaAbelha01');
  });

  test('busca interações pendentes individuais e em lote apenas com apikey e lança ExcecaoHttpFilaInteracoes em erro HTTP', () async {
    corpoRespostaGet = [
      {
        'id': 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
        'autor_id_publico': 'c3Lk9P1x4Vw8Mn',
        'autor_nome_publico': 'Mariana',
        'autor_avatar_url': 'https://cdn.aresta.cc/avatars/mariana.webp',
        'escalada_uid': 'x8siJek3FiG3aB',
        'tipo': 'COMENTARIO',
        'texto_comentario': 'Ótimo crux!',
        'tipo_ascensao': 2,
        'status': 'PENDENTE',
        'criado_em': '2026-11-19T18:00:00Z',
      },
    ];

    final cliente = ClienteFilaInteracoesSupabase(
      resolvedorBaseUrl: () => baseUrl,
      resolvedorAnonKey: () => 'sb_publishable_teste123',
    );

    final lista = await cliente.buscarInteracoesPendentes('x8siJek3FiG3aB');
    expect(ultimoApikeyHeader, 'sb_publishable_teste123');
    expect(ultimoAuthHeader, isNull);
    expect(lista, hasLength(1));
    expect(lista.single.textoComentario, 'Ótimo crux!');
    expect(lista.single.autorAvatarUrl, 'https://cdn.aresta.cc/avatars/mariana.webp');

    expect(await cliente.buscarInteracoesPendentes('   '), isEmpty);
    expect(await cliente.buscarInteracoesPendentesEmLote(['  ', '']), isEmpty);
    expect(await cliente.buscarInteracoesRelacionadasAoAutor('   '), isEmpty);
    // Quando o autor só possui COMENTARIO (sem alertas), buscarInteracoesRelacionadasAoAutor retorna vazio
    expect(
      await cliente.buscarInteracoesRelacionadasAoAutor('c3Lk9P1x4Vw8Mn'),
      isEmpty,
    );

    corpoRespostaGet = [
      {
        'id': 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
        'autor_id_publico': 'c3Lk9P1x4Vw8Mn',
        'autor_nome_publico': 'Mariana',
        'escalada_uid': 'x8siJek3FiG3aB',
        'tipo': 'ALERTA_SEGURANCA',
        'categoria_alerta': 'FAUNA',
        'alerta_alvo_uid': 'alertaAbelha01',
        'status': 'PENDENTE',
        'criado_em': '2026-11-19T18:00:00Z',
      },
    ];
    expect(
      await cliente.buscarInteracoesRelacionadasAoAutor('c3Lk9P1x4Vw8Mn'),
      hasLength(1),
    );

    final emLote = await cliente.buscarInteracoesPendentesEmLote([
      'x8siJek3FiG3aB',
      'y9tjKfl4GjH4bC',
      'x8siJek3FiG3aB',
    ]);
    expect(emLote, hasLength(1));
    expect(ultimoAuthHeader, isNull);
    expect(
      ultimaUriRequisitada?.query,
      contains('escalada_uid=in.(x8siJek3FiG3aB,y9tjKfl4GjH4bC)'),
    );

    statusResposta = 403;
    await expectLater(
      () => cliente.buscarInteracoesPendentes('x8siJek3FiG3aB'),
      throwsA(
        isA<ExcecaoHttpFilaInteracoes>()
            .having((e) => e.codigoStatusHttp, 'codigoStatusHttp', 403)
            .having((e) => e.toString(), 'toString', contains('403')),
      ),
    );
    await expectLater(
      () => cliente.buscarInteracoesPendentesEmLote(['x8siJek3FiG3aB']),
      throwsA(
        isA<ExcecaoHttpFilaInteracoes>().having(
          (e) => e.codigoStatusHttp,
          'codigoStatusHttp',
          403,
        ),
      ),
    );
    await expectLater(
      () => cliente.inserirInteracao(lista.single),
      throwsA(
        isA<ExcecaoHttpFilaInteracoes>().having(
          (e) => e.codigoStatusHttp,
          'codigoStatusHttp',
          403,
        ),
      ),
    );

    // Valida resolvedores padrão do RemoteConfig usando ClienteHttpAresta.paraTestes
    Uri? uriPadraoConsultada;
    final clientePadrao = ClienteFilaInteracoesSupabase(
      clienteHttp: ClienteHttpAresta.paraTestes(
        MockClient((req) async {
          uriPadraoConsultada = req.url;
          return Response('[]', 200);
        }),
      ),
    );
    expect(await clientePadrao.buscarInteracoesPendentes('x8siJek3FiG3aB'), isEmpty);
    expect(uriPadraoConsultada?.path, '/rest/v1/fila_interacoes');
  });
}
