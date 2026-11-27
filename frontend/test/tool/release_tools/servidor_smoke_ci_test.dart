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

        // 4b. Serve CRUD em memória para /rest/v1/cadenas (sincronização da caderneta)
        final reqUpsertCadena = await client.postUrl(
          servidor.uriLocalHost.replace(
            path: '/rest/v1/cadenas',
            query: 'on_conflict=id',
          ),
        );
        reqUpsertCadena.headers.contentType = ContentType.json;
        reqUpsertCadena.write(jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'cad-smoke-1',
            'user_id': 'usr_smoke_ci',
            'escalada_uid': ServidorSmokeCi.uidEscaladaSmoke,
            'data_ascensao': '2026-11-22T00:00:00.000Z',
            'tipo_ascensao': 1,
            'tipo_escalada': 1,
            'tentativas': 1,
            'notas_privadas': 'Smoke',
            'criado_em': '2026-11-22T00:00:00.000Z',
          },
        ]));
        final respUpsertCadena = await reqUpsertCadena.close();
        await respUpsertCadena.drain<void>();
        expect(respUpsertCadena.statusCode, 201);

        final reqGetCadenas = await client.getUrl(
          servidor.uriLocalHost.replace(path: '/rest/v1/cadenas'),
        );
        final respGetCadenas = await reqGetCadenas.close();
        final listaCadenas = jsonDecode(
          await utf8.decoder.bind(respGetCadenas).join(),
        ) as List<dynamic>;
        expect(listaCadenas, hasLength(1));

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

    test(
      'suporta Magic Code OTP, OAuth PKCE S256, refresh_token, fila_interacoes com falha 503 e excluir_minha_conta',
      () async {
        final client = HttpClient();
        addTearDown(client.close);

        // 1. Magic Code OTP (/auth/v1/otp e /auth/v1/verify)
        final reqOtp = await client.postUrl(
          servidor.uriLocalHost.replace(path: '/auth/v1/otp'),
        );
        reqOtp.headers.contentType = ContentType.json;
        reqOtp.write(jsonEncode(<String, dynamic>{
          'email': 'escalador@arestaclimb.com',
          'create_user': true,
        }));
        final respOtp = await reqOtp.close();
        await respOtp.drain<void>();
        expect(respOtp.statusCode, 200);

        final reqVerifyErrado = await client.postUrl(
          servidor.uriLocalHost.replace(path: '/auth/v1/verify'),
        );
        reqVerifyErrado.headers.contentType = ContentType.json;
        reqVerifyErrado.write(jsonEncode(<String, dynamic>{
          'type': 'email',
          'email': 'escalador@arestaclimb.com',
          'token': '000000',
        }));
        final respVerifyErrado = await reqVerifyErrado.close();
        await respVerifyErrado.drain<void>();
        expect(respVerifyErrado.statusCode, 401);

        final reqVerifyOk = await client.postUrl(
          servidor.uriLocalHost.replace(path: '/auth/v1/verify'),
        );
        reqVerifyOk.headers.contentType = ContentType.json;
        reqVerifyOk.write(jsonEncode(<String, dynamic>{
          'type': 'email',
          'email': 'escalador@arestaclimb.com',
          'token': ServidorSmokeCi.codigoOtpSmoke,
        }));
        final respVerifyOk = await reqVerifyOk.close();
        expect(respVerifyOk.statusCode, 200);
        final jsonOtp = jsonDecode(
          await utf8.decoder.bind(respVerifyOk).join(),
        ) as Map<String, dynamic>;
        expect(jsonOtp['access_token'], isNotEmpty);
        expect(jsonOtp['refresh_token'], isNotEmpty);

        // 2. OAuth PKCE S256 (/auth/v1/authorize e /auth/v1/token?grant_type=pkce)
        const verifier = 'verificador_pkce_smoke_ci_seguro_123456';
        final challenge = base64Url
            .encode(sha256.convert(utf8.encode(verifier)).bytes)
            .replaceAll('=', '');

        final reqAuth = await client.getUrl(
          servidor.uriLocalHost.replace(
            path: '/auth/v1/authorize',
            queryParameters: <String, String>{
              'provider': 'google',
              'redirect_to': 'aresta://app.arestaclimb.com/auth-callback',
              'code_challenge': challenge,
              'code_challenge_method': 's256',
            },
          ),
        );
        final respAuth = await reqAuth.close();
        expect(respAuth.statusCode, 200);
        final jsonAuth = jsonDecode(
          await utf8.decoder.bind(respAuth).join(),
        ) as Map<String, dynamic>;
        final callbackUri = Uri.parse(jsonAuth['callbackUrl'] as String);
        final authCode = callbackUri.queryParameters['code'];
        expect(authCode, isNotNull);

        final reqPkceErrado = await client.postUrl(
          servidor.uriLocalHost.replace(
            path: '/auth/v1/token',
            query: 'grant_type=pkce',
          ),
        );
        reqPkceErrado.headers.contentType = ContentType.json;
        reqPkceErrado.write(jsonEncode(<String, dynamic>{
          'auth_code': authCode,
          'code_verifier': 'verifier_invalido',
        }));
        final respPkceErrado = await reqPkceErrado.close();
        await respPkceErrado.drain<void>();
        expect(respPkceErrado.statusCode, 401);

        final reqPkceOk = await client.postUrl(
          servidor.uriLocalHost.replace(
            path: '/auth/v1/token',
            query: 'grant_type=pkce',
          ),
        );
        reqPkceOk.headers.contentType = ContentType.json;
        reqPkceOk.write(jsonEncode(<String, dynamic>{
          'auth_code': authCode,
          'code_verifier': verifier,
        }));
        final respPkceOk = await reqPkceOk.close();
        expect(respPkceOk.statusCode, 200);
        final jsonPkce = jsonDecode(
          await utf8.decoder.bind(respPkceOk).join(),
        ) as Map<String, dynamic>;
        final refreshToken = jsonPkce['refresh_token'] as String;
        expect(refreshToken, isNotEmpty);

        // 3. Renovação via refresh_token
        final reqRefresh = await client.postUrl(
          servidor.uriLocalHost.replace(
            path: '/auth/v1/token',
            query: 'grant_type=refresh_token',
          ),
        );
        reqRefresh.headers.contentType = ContentType.json;
        reqRefresh.write(jsonEncode(<String, dynamic>{
          'refresh_token': refreshToken,
        }));
        final respRefresh = await reqRefresh.close();
        expect(respRefresh.statusCode, 200);
        final jsonRefresh = jsonDecode(
          await utf8.decoder.bind(respRefresh).join(),
        ) as Map<String, dynamic>;
        expect(jsonRefresh['access_token'], contains('renovado'));

        // 4. Fila de interações semeada + falha 503 controlada + CRUD
        final reqGetInicial = await client.getUrl(
          servidor.uriLocalHost.replace(
            path: '/rest/v1/fila_interacoes',
            queryParameters: <String, String>{
              'escalada_uid': 'eq.${ServidorSmokeCi.uidEscaladaSmoke}',
              'status': 'eq.PENDENTE',
            },
          ),
        );
        final respGetInicial = await reqGetInicial.close();
        expect(respGetInicial.statusCode, 200);
        final listaInicial = jsonDecode(
          await utf8.decoder.bind(respGetInicial).join(),
        ) as List<dynamic>;
        expect(listaInicial, hasLength(1));
        expect(listaInicial.first['alerta_alvo_uid'], 'altFaunaSmk001');

        // Ativa 1 falha 503 na próxima escrita
        final reqArmarFalha = await client.postUrl(
          servidor.uriLocalHost.replace(
            path: '/__smoke__/falhar-proxima-escrita-fila',
          ),
        );
        reqArmarFalha.headers.contentType = ContentType.json;
        reqArmarFalha.write(jsonEncode(<String, dynamic>{'quantidade': 1}));
        final respArmarFalha = await reqArmarFalha.close();
        await respArmarFalha.drain<void>();
        expect(respArmarFalha.statusCode, 200);

        final reqPost503 = await client.postUrl(
          servidor.uriLocalHost.replace(path: '/rest/v1/fila_interacoes'),
        );
        reqPost503.headers.contentType = ContentType.json;
        reqPost503.write(jsonEncode(<String, dynamic>{
          'id': '00000000-0000-4000-8000-000000000099',
          'autor_id_publico': 'autSmokeCi0001',
          'autor_nome_publico': 'Escalador Smoke',
          'escalada_uid': ServidorSmokeCi.uidEscaladaSmoke,
          'tipo': 'COMENTARIO',
          'texto_comentario': 'Beta inicial',
        }));
        final respPost503 = await reqPost503.close();
        await respPost503.drain<void>();
        expect(respPost503.statusCode, 503);

        // Segunda escrita deve suceder normalmente
        final reqPost201 = await client.postUrl(
          servidor.uriLocalHost.replace(path: '/rest/v1/fila_interacoes'),
        );
        reqPost201.headers.contentType = ContentType.json;
        reqPost201.write(jsonEncode(<String, dynamic>{
          'id': '00000000-0000-4000-8000-000000000099',
          'autor_id_publico': 'autSmokeCi0001',
          'autor_nome_publico': 'Escalador Smoke',
          'escalada_uid': ServidorSmokeCi.uidEscaladaSmoke,
          'tipo': 'COMENTARIO',
          'texto_comentario': 'Beta inicial',
        }));
        final respPost201 = await reqPost201.close();
        await respPost201.drain<void>();
        expect(respPost201.statusCode, 201);

        // PATCH comentário
        final reqPatch = await client.patchUrl(
          servidor.uriLocalHost.replace(
            path: '/rest/v1/fila_interacoes',
            queryParameters: <String, String>{
              'id': 'eq.00000000-0000-4000-8000-000000000099',
              'autor_id_publico': 'eq.autSmokeCi0001',
              'tipo': 'eq.COMENTARIO',
            },
          ),
        );
        reqPatch.headers.contentType = ContentType.json;
        reqPatch.write(jsonEncode(<String, dynamic>{
          'texto_comentario': 'Beta editado',
        }));
        final respPatch = await reqPatch.close();
        await respPatch.drain<void>();
        expect(respPatch.statusCode, 204);

        // DELETE via RPC excluir_minha_conta remove dados do autor
        final reqExcluirConta = await client.postUrl(
          servidor.uriLocalHost.replace(path: '/rest/v1/rpc/excluir_minha_conta'),
        );
        reqExcluirConta.headers.set('Authorization', 'Bearer token-valido');
        reqExcluirConta.write('{}');
        final respExcluirConta = await reqExcluirConta.close();
        await respExcluirConta.drain<void>();
        expect(respExcluirConta.statusCode, 204);

        final reqGetAposExcluir = await client.getUrl(
          servidor.uriLocalHost.replace(
            path: '/rest/v1/fila_interacoes',
            queryParameters: <String, String>{
              'autor_id_publico': 'eq.autSmokeCi0001',
            },
          ),
        );
        final respGetAposExcluir = await reqGetAposExcluir.close();
        final restantesAutor = jsonDecode(
          await utf8.decoder.bind(respGetAposExcluir).join(),
        ) as List<dynamic>;
        expect(restantesAutor, isEmpty);
      },
    );
  });
}
