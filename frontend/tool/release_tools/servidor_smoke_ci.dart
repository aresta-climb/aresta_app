// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';

/// Micro-servidor HTTP local vinculado exclusivamente ao loopback (`127.0.0.1`)
/// para orquestrar OIDC, Supabase GoTrue, catálogo Protobuf v5 e coleta de evidências do Smoke Test no CI.
class ServidorSmokeCi {
  /// Identificador determinístico do croqui Protobuf servido localmente durante o smoke test.
  static const String idCroquiSmoke = 'serra_smoke_ci';

  /// UID determinístico de 14 caracteres Base62 da via esportiva do croqui de smoke.
  static const String uidEscaladaSmoke = 'viaSmokeCi0001';

  static const String _caminhoRelativoCroqui =
      'croquis/serra_smoke_ci/compilado.binarypb';

  final HttpServer _servidor;

  /// Token efêmero exigido para aceitar o relatório final em `/__smoke__/relatorio`.
  final String tokenEsperado;

  final Uint8List _bytesCroqui;
  final Uint8List _bytesIndice;

  final Completer<Map<String, dynamic>> _completerRelatorio =
      Completer<Map<String, dynamic>>();

  String _nomePerfilAtual = 'Escalador Smoke CI';
  String _autorIdPublicoAtual = 'autSmokeCi0001';
  final Map<String, Map<String, dynamic>> _cadenasPorId =
      <String, Map<String, dynamic>>{};

  ServidorSmokeCi._(
    this._servidor,
    this.tokenEsperado,
    this._bytesCroqui,
    this._bytesIndice,
  );

  /// Porta TCP efêmera alocada em `127.0.0.1`.
  int get porta => _servidor.port;

  /// URI base acessível no próprio host ou iOS Simulator (`http://127.0.0.1:<porta>`).
  Uri get uriLocalHost => Uri.parse('http://127.0.0.1:$porta');

  /// URI base acessível a partir do Android Emulator (`http://10.0.2.2:<porta>`).
  Uri get uriEmuladorAndroid => Uri.parse('http://10.0.2.2:$porta');

  static (Uint8List, Uint8List) _gerarArtefatosProtobufSmoke() {
    final via = ViaEsportiva()
      ..nome = 'Aresta da Vitória'
      ..dificuldade = GrauVia_GrauVia.BR_7A
      ..destaque = true
      ..extensao = 22
      ..descricao = 'Via esportiva determinística para validação de smoke pós-build.';

    final setor = Setor()
      ..uid = 'setSmokeCi0001'
      ..nome = 'Setor Principal Smoke'
      ..descricao = 'Trilha plana de 5 minutos.'
      ..escaladas.add(
        Escalada()
          ..uid = uidEscaladaSmoke
          ..viaEsportiva = via,
      );

    final pico = Pico()
      ..nome = 'Serra do Smoke'
      ..descricao = 'Pico determinístico do servidor local de CI.'
      ..estado = 'MG'
      ..cidade = 'Santana do Riacho'
      ..setoresOuGrupos.add(
        SetorOuGrupo()..setor = (ArquivoSetor()..conteudo = setor),
      );

    final croqui = Croqui()
      ..id = idCroquiSmoke
      ..uid = 'crqSmokeCi0001'
      ..nome = 'Serra do Smoke'
      ..picos.add(pico);

    final bytesCroqui = croqui.writeToBuffer();
    final checksumCroqui = sha256.convert(bytesCroqui).toString();

    final resumo = ResumoCroqui()
      ..id = idCroquiSmoke
      ..nome = 'Serra do Smoke'
      ..caminhoRelativo = _caminhoRelativoCroqui
      ..checksumSha256Croqui = checksumCroqui
      ..precomputados = (PrecomputadosResumoCroqui()
        ..totalSetores = 1
        ..totalEscaladas = 1
        ..totalEsportivas = 1);

    final indice = Indice()..croquis.add(resumo);
    return (bytesCroqui, indice.writeToBuffer());
  }

  /// Inicia o servidor em `127.0.0.1` (porta `0` efêmera por padrão).
  static Future<ServidorSmokeCi> iniciar({
    required String tokenEsperado,
    int porta = 0,
  }) async {
    final httpServer = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      porta,
    );
    final (bytesCroqui, bytesIndice) = _gerarArtefatosProtobufSmoke();
    final instancia = ServidorSmokeCi._(
      httpServer,
      tokenEsperado.trim(),
      bytesCroqui,
      bytesIndice,
    );
    httpServer.listen(instancia._tratarRequisicao);
    return instancia;
  }

  /// Aguarda a chegada do relatório estruturado enviado pelo aplicativo sob teste.
  Future<Map<String, dynamic>> aguardarRelatorio({
    Duration timeout = const Duration(seconds: 120),
  }) {
    return _completerRelatorio.future.timeout(timeout);
  }

  /// Encerra imediatamente o socket de escuta HTTP.
  Future<void> encerrar() async {
    await _servidor.close(force: true);
  }

  static String _codificarBase64UrlSemPadding(Map<String, dynamic> jsonMap) {
    return base64Url
        .encode(utf8.encode(jsonEncode(jsonMap)))
        .replaceAll('=', '');
  }

  Future<Map<String, dynamic>> _lerJsonCorpo(HttpRequest req) async {
    final texto = await utf8.decoder.bind(req).join();
    if (texto.trim().isEmpty) {
      return <String, dynamic>{};
    }
    final decodificado = jsonDecode(texto);
    if (decodificado is Map<String, dynamic>) {
      return decodificado;
    }
    return <String, dynamic>{};
  }

  Future<void> _responderJson(
    HttpResponse res,
    int statusCode,
    Object corpo,
  ) async {
    res.statusCode = statusCode;
    res.headers.contentType = ContentType.json;
    res.write(jsonEncode(corpo));
    await res.close();
  }

  Future<void> _tratarRequisicao(HttpRequest req) async {
    final caminho = req.uri.path;
    try {
      if (req.method == 'GET' && caminho == '/indice.binarypb') {
        await req.drain<void>();
        req.response.statusCode = 200;
        req.response.headers.contentType = ContentType.binary;
        req.response.headers.set('etag', '"etag-smoke-ci-v1"');
        req.response.add(_bytesIndice);
        await req.response.close();
        return;
      }

      if (req.method == 'GET' && caminho == '/$_caminhoRelativoCroqui') {
        await req.drain<void>();
        req.response.statusCode = 200;
        req.response.headers.contentType = ContentType.binary;
        req.response.add(_bytesCroqui);
        await req.response.close();
        return;
      }

      if (req.method == 'POST' && caminho == '/__smoke__/oidc-token') {
        final corpo = await _lerJsonCorpo(req);
        final rawNonce = (corpo['rawNonce'] as String?)?.trim() ?? 'smoke-nonce';
        var nonceHash = (corpo['nonceHash'] as String?)?.trim() ?? '';
        if (nonceHash.isEmpty) {
          nonceHash = sha256.convert(utf8.encode(rawNonce)).toString();
        }
        final agoraSeg = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final headerB64 = _codificarBase64UrlSemPadding(<String, dynamic>{
          'alg': 'HS256',
          'typ': 'JWT',
        });
        final payloadB64 = _codificarBase64UrlSemPadding(<String, dynamic>{
          'iss': 'https://accounts.google.com',
          'sub': 'google-smoke-uid-001',
          'aud': (corpo['webClientId'] as String?) ?? 'smoke-client-id',
          'email': 'smoke-ci@arestaclimb.com',
          'email_verified': true,
          'name': _nomePerfilAtual,
          'nonce': nonceHash,
          'iat': agoraSeg,
          'exp': agoraSeg + 3600,
        });
        final assinaturaB64 = base64Url
            .encode(sha256.convert(utf8.encode('$headerB64.$payloadB64')).bytes)
            .replaceAll('=', '');
        final jwt = '$headerB64.$payloadB64.$assinaturaB64';
        await _responderJson(req.response, 200, <String, dynamic>{
          'idToken': jwt,
          'nonce': rawNonce,
          'email': 'smoke-ci@arestaclimb.com',
          'nomeExibicao': _nomePerfilAtual,
          'cancelado': false,
        });
        return;
      }

      if (req.method == 'POST' && caminho == '/auth/v1/token') {
        final corpo = await _lerJsonCorpo(req);
        final idToken = (corpo['id_token'] as String?)?.trim() ?? '';
        final rawNonce = (corpo['nonce'] as String?)?.trim() ?? '';
        final partes = idToken.split('.');
        if (partes.length != 3) {
          await _responderJson(req.response, 401, <String, dynamic>{
            'error_code': 'bad_jwt',
            'msg': 'Formato de id_token inválido.',
          });
          return;
        }
        final payload = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(partes[1]))),
        ) as Map<String, dynamic>;
        final nonceClaim = (payload['nonce'] as String?) ?? '';
        if (rawNonce.isNotEmpty) {
          final hashEsperado = sha256.convert(utf8.encode(rawNonce)).toString();
          if (nonceClaim.isEmpty ||
              (nonceClaim != rawNonce && nonceClaim != hashEsperado)) {
            await _responderJson(req.response, 401, <String, dynamic>{
              'error_code': 'bad_jwt',
              'msg': 'Vínculo criptográfico de nonce inválido.',
            });
            return;
          }
        }

        await _responderJson(req.response, 200, <String, dynamic>{
          'access_token': 'jwt-supabase-smoke-sessao',
          'token_type': 'bearer',
          'expires_in': 3600,
          'user': <String, dynamic>{
            'id': 'usr_smoke_ci',
            'email': 'smoke-ci@arestaclimb.com',
            'user_metadata': <String, dynamic>{
              'autor_id_publico': _autorIdPublicoAtual,
              'autor_nome_publico': _nomePerfilAtual,
              'full_name': _nomePerfilAtual,
            },
          },
        });
        return;
      }

      if (caminho == '/rest/v1/perfis') {
        if (req.method == 'GET') {
          await req.drain<void>();
          await _responderJson(req.response, 200, <Map<String, dynamic>>[
            <String, dynamic>{
              'user_id': 'usr_smoke_ci',
              'autor_id_publico': _autorIdPublicoAtual,
              'autor_nome_publico': _nomePerfilAtual,
            },
          ]);
          return;
        }
        final corpo = await _lerJsonCorpo(req);
        final novoNome = (corpo['autor_nome_publico'] as String?)?.trim();
        final novoAutorId = (corpo['autor_id_publico'] as String?)?.trim();
        if (novoNome != null && novoNome.isNotEmpty) {
          _nomePerfilAtual = novoNome;
        }
        if (novoAutorId != null && novoAutorId.isNotEmpty) {
          _autorIdPublicoAtual = novoAutorId;
        }
        await _responderJson(req.response, 200, <dynamic>[]);
        return;
      }

      if (caminho == '/rest/v1/cadenas') {
        if (req.method == 'GET') {
          await req.drain<void>();
          await _responderJson(
            req.response,
            200,
            _cadenasPorId.values.toList(growable: false),
          );
          return;
        }
        if (req.method == 'POST') {
          final texto = await utf8.decoder.bind(req).join();
          if (texto.trim().isNotEmpty) {
            final decodificado = jsonDecode(texto);
            final itens = decodificado is List<dynamic>
                ? decodificado
                : <dynamic>[decodificado];
            for (final item in itens.whereType<Map<String, dynamic>>()) {
              final id = (item['id'] as String?)?.trim() ?? '';
              if (id.isNotEmpty) {
                _cadenasPorId[id] = Map<String, dynamic>.from(item);
              }
            }
          }
          await _responderJson(req.response, 201, const <dynamic>[]);
          return;
        }
        if (req.method == 'DELETE') {
          await req.drain<void>();
          final filtroId = req.uri.queryParameters['id'] ?? '';
          if (filtroId.startsWith('eq.')) {
            _cadenasPorId.remove(filtroId.substring(3));
          }
          req.response.statusCode = 204;
          await req.response.close();
          return;
        }
      }

      if (caminho == '/auth/v1/user') {
        final corpo = await _lerJsonCorpo(req);
        final data = corpo['data'];
        if (data is Map<String, dynamic>) {
          final nome = (data['autor_nome_publico'] as String?)?.trim();
          final autorId = (data['autor_id_publico'] as String?)?.trim();
          if (nome != null && nome.isNotEmpty) {
            _nomePerfilAtual = nome;
          }
          if (autorId != null && autorId.isNotEmpty) {
            _autorIdPublicoAtual = autorId;
          }
        }
        await _responderJson(req.response, 200, <String, dynamic>{
          'id': 'usr_smoke_ci',
        });
        return;
      }

      if (req.method == 'POST' && caminho == '/__smoke__/relatorio') {
        final corpo = await _lerJsonCorpo(req);
        if (corpo['token'] != tokenEsperado) {
          await _responderJson(req.response, 403, <String, dynamic>{
            'erro': 'Token de smoke inválido.',
          });
          return;
        }
        await _responderJson(req.response, 200, <String, dynamic>{'ok': true});
        if (!_completerRelatorio.isCompleted) {
          _completerRelatorio.complete(corpo);
        }
        return;
      }

      await req.drain<void>();
      await _responderJson(req.response, 200, <String, dynamic>{'ok': true});
    } catch (e) {
      await _responderJson(req.response, 500, <String, dynamic>{
        'erro': e.toString(),
      });
    }
  }
}
