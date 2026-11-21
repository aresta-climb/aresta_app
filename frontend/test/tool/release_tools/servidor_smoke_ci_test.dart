// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import '../../../tool/release_tools/servidor_smoke_ci.dart';

void main() {
  HttpOverrides.global = null;

  group('ServidorSmokeCi', () {
    late ServidorSmokeCi servidor;

    setUp(() async {
      HttpOverrides.global = null;
      servidor = await ServidorSmokeCi.iniciar(tokenEsperado: 'tok_secreto');
    });

    tearDown(() async {
      await servidor.encerrar();
    });

    test(
      'emite id_token OIDC, valida sessão GoTrue, serve Indice/Croqui Protobuf v5 com SHA-256 exato e recebe relatório',
      () async {
        final client = HttpClient();
        addTearDown(client.close);

        // 1. Solicita idToken OIDC vinculado a rawNonce
        final reqOidc = await client.postUrl(
          servidor.uriLocalHost.replace(path: '/__smoke__/oidc-token'),
        );
        reqOidc.headers.contentType = ContentType.json;
        reqOidc.write(jsonEncode(<String, dynamic>{
          'rawNonce': 'nonce_bruto_123',
          'webClientId': 'client-aresta',
        }));
        final respOidc = await reqOidc.close();
        expect(respOidc.statusCode, 200);
        final jsonOidc = jsonDecode(
          await utf8.decoder.bind(respOidc).join(),
        ) as Map<String, dynamic>;
        final idToken = jsonOidc['idToken'] as String;
        expect(idToken.split('.').length, 3);

        // 2. Rejeita nonce divergente em /auth/v1/token
        final reqInvalido = await client.postUrl(
          servidor.uriLocalHost.replace(
            path: '/auth/v1/token',
            query: 'grant_type=id_token',
          ),
        );
        reqInvalido.headers.contentType = ContentType.json;
        reqInvalido.write(jsonEncode(<String, dynamic>{
          'provider': 'google',
          'id_token': idToken,
          'nonce': 'nonce_errado',
        }));
        final respInvalido = await reqInvalido.close();
        await respInvalido.drain<void>();
        expect(respInvalido.statusCode, 401);

        // 3. Aceita nonce válido em /auth/v1/token
        final reqToken = await client.postUrl(
          servidor.uriLocalHost.replace(
            path: '/auth/v1/token',
            query: 'grant_type=id_token',
          ),
        );
        reqToken.headers.contentType = ContentType.json;
        reqToken.write(jsonEncode(<String, dynamic>{
          'provider': 'google',
          'id_token': idToken,
          'nonce': 'nonce_bruto_123',
        }));
        final respToken = await reqToken.close();
        expect(respToken.statusCode, 200);
        final sessao = jsonDecode(
          await utf8.decoder.bind(respToken).join(),
        ) as Map<String, dynamic>;
        expect(sessao['access_token'], isNotEmpty);

        // 4. Serve Indice e Croqui Protobuf reais com SHA-256 consistente
        final reqIndice = await client.getUrl(
          servidor.uriLocalHost.replace(path: '/indice.binarypb'),
        );
        final respIndice = await reqIndice.close();
        expect(respIndice.statusCode, 200);
        final bytesIndice = await respIndice.fold<List<int>>(
          <int>[],
          (acc, chunk) => acc..addAll(chunk),
        );
        final indice = Indice.fromBuffer(bytesIndice);
        expect(indice.croquis, isNotEmpty);
        final resumo = indice.croquis.first;
        expect(resumo.id, ServidorSmokeCi.idCroquiSmoke);

        final reqCroqui = await client.getUrl(
          servidor.uriLocalHost.replace(path: '/${resumo.caminhoRelativo}'),
        );
        final respCroqui = await reqCroqui.close();
        expect(respCroqui.statusCode, 200);
        final bytesCroqui = await respCroqui.fold<List<int>>(
          <int>[],
          (acc, chunk) => acc..addAll(chunk),
        );
        expect(
          sha256.convert(bytesCroqui).toString(),
          equals(resumo.checksumSha256Croqui),
        );
        final croqui = Croqui.fromBuffer(bytesCroqui);
        expect(croqui.picos, isNotEmpty);

        // 5. Rejeita token errado em /__smoke__/relatorio e aceita o correto
        final reqProibido = await client.postUrl(
          servidor.uriLocalHost.replace(path: '/__smoke__/relatorio'),
        );
        reqProibido.write(jsonEncode(<String, dynamic>{'token': 'errado'}));
        final respProibido = await reqProibido.close();
        await respProibido.drain<void>();
        expect(respProibido.statusCode, 403);

        final futuroRelatorio = servidor.aguardarRelatorio();
        final reqRel = await client.postUrl(
          servidor.uriLocalHost.replace(path: '/__smoke__/relatorio'),
        );
        reqRel.write(jsonEncode(<String, dynamic>{
          'token': 'tok_secreto',
          'sucesso': true,
          'etapas': <String>['login_oidc_ok', 'croqui_aberto', 'cadena_salva'],
        }));
        final respRel = await reqRel.close();
        await respRel.drain<void>();
        expect(respRel.statusCode, 200);

        final recebido = await futuroRelatorio;
        expect(recebido['sucesso'], isTrue);
      },
    );
  });
}
