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
/// para orquestrar OTP, OIDC, PKCE, Refresh Token, Supabase PostgREST (`perfis`,
/// `cadenas`, `fila_interacoes`), catálogo Protobuf v5 e coleta de evidências do Smoke Test no CI.
class ServidorSmokeCi {
  /// Identificador determinístico do croqui Protobuf servido localmente durante o smoke test.
  static const String idCroquiSmoke = 'serra_smoke_ci';

  /// UID determinístico de 14 caracteres Base62 da via esportiva do croqui de smoke.
  static const String uidEscaladaSmoke = 'viaSmokeCi0001';

  /// Código OTP numérico de 6 dígitos aceito por `/auth/v1/verify` no smoke test.
  static const String codigoOtpSmoke = '654321';

  /// UID determinístico do alerta inicial criado por terceiro em [uidEscaladaSmoke].
  static const String uidAlertaInicialSmoke = 'altFaunaSmk001';

  /// Identificador público do terceiro autor do alerta semeado inicialmente.
  static const String autorIdOutroSmoke = 'autOutroSmk001';

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
  final List<Map<String, dynamic>> _filaInteracoes = <Map<String, dynamic>>[];
  final Map<String, String> _codigosPkcePendentes = <String, String>{};
  final Set<String> _emailsOtpSolicitados = <String>{};

  int _contadorPkce = 0;
  int _contadorRenovacoes = 0;
  int _contadorFilaIds = 10;
  int _falhasEscritaFilaRestantes = 0;

  ServidorSmokeCi._(
    this._servidor,
    this.tokenEsperado,
    this._bytesCroqui,
    this._bytesIndice,
  ) {
    _filaInteracoes.add(<String, dynamic>{
      'id': '00000000-0000-4000-8000-000000000001',
      'autor_id_publico': autorIdOutroSmoke,
      'autor_nome_publico': 'Escaladora Local',
      'escalada_uid': uidEscaladaSmoke,
      'tipo': 'ALERTA_SEGURANCA',
      'alerta_alvo_uid': uidAlertaInicialSmoke,
      'categoria_alerta': 'FAUNA',
      'texto_comentario': 'Marimbondos no crux',
      'status': 'PENDENTE',
      'criado_em': '2026-11-20T10:00:00.000Z',
    });
  }

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

  static String _sha256Base64UrlSemPadding(String texto) {
    return base64Url
        .encode(sha256.convert(utf8.encode(texto)).bytes)
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

  Map<String, dynamic> _montarPayloadSessao({
    required String accessToken,
    required String refreshToken,
    String email = 'smoke-ci@arestaclimb.com',
  }) {
    return <String, dynamic>{
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_type': 'bearer',
      'expires_in': 3600,
      'user': <String, dynamic>{
        'id': 'usr_smoke_ci',
        'email': email,
        'user_metadata': <String, dynamic>{
          'autor_id_publico': _autorIdPublicoAtual,
          'autor_nome_publico': _nomePerfilAtual,
          'full_name': _nomePerfilAtual,
        },
      },
    };
  }

  static bool _itemCasaComFiltrosPostgrest(
    Map<String, dynamic> item,
    Map<String, String> query,
  ) {
    for (final entrada in query.entries) {
      final campo = entrada.key;
      if (campo == 'order' || campo == 'select' || campo == 'on_conflict') {
        continue;
      }
      final condicao = entrada.value;
      final valorItem = item[campo]?.toString();
      if (condicao.startsWith('eq.')) {
        if (valorItem != condicao.substring(3)) return false;
      } else if (condicao.startsWith('in.(') && condicao.endsWith(')')) {
        final lista = condicao
            .substring(4, condicao.length - 1)
            .split(',')
            .map((e) => e.trim())
            .toSet();
        if (valorItem == null || !lista.contains(valorItem)) return false;
      }
    }
    return true;
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

      if (req.method == 'POST' &&
          caminho == '/__smoke__/falhar-proxima-escrita-fila') {
        final corpo = await _lerJsonCorpo(req);
        final qtd = (corpo['quantidade'] as num?)?.toInt() ?? 1;
        _falhasEscritaFilaRestantes += qtd > 0 ? qtd : 1;
        await _responderJson(req.response, 200, <String, dynamic>{
          'falhasArmadas': _falhasEscritaFilaRestantes,
        });
        return;
      }

      if (req.method == 'POST' && caminho == '/auth/v1/otp') {
        final corpo = await _lerJsonCorpo(req);
        final email = (corpo['email'] as String?)?.trim() ?? '';
        if (email.isEmpty || !email.contains('@')) {
          await _responderJson(req.response, 400, <String, dynamic>{
            'error_code': 'validation_failed',
            'msg': 'Unable to validate email address: invalid format',
          });
          return;
        }
        _emailsOtpSolicitados.add(email);
        await _responderJson(req.response, 200, const <String, dynamic>{});
        return;
      }

      if (req.method == 'POST' && caminho == '/auth/v1/verify') {
        final corpo = await _lerJsonCorpo(req);
        final tipo = (corpo['type'] as String?)?.trim() ?? '';
        final email = (corpo['email'] as String?)?.trim() ?? '';
        final token = (corpo['token'] as String?)?.trim() ?? '';
        if (tipo != 'email' || token != codigoOtpSmoke || email.isEmpty) {
          await _responderJson(req.response, 401, <String, dynamic>{
            'error_code': 'otp_expired',
            'msg': 'Token has expired or is invalid',
          });
          return;
        }
        await _responderJson(
          req.response,
          200,
          _montarPayloadSessao(
            accessToken: 'jwt-supabase-smoke-otp',
            refreshToken: 'refresh-smoke-otp-001',
            email: email,
          ),
        );
        return;
      }

      if (req.method == 'GET' && caminho == '/auth/v1/authorize') {
        await req.drain<void>();
        final redirectTo = req.uri.queryParameters['redirect_to'] ??
            'aresta://app.arestaclimb.com/auth-callback';
        final codeChallenge = req.uri.queryParameters['code_challenge'] ?? '';
        final authCode = 'pkce-smoke-code-${++_contadorPkce}';
        _codigosPkcePendentes[authCode] = codeChallenge;
        final uriCallback = Uri.parse(redirectTo).replace(
          queryParameters: <String, String>{'code': authCode},
        );
        await _responderJson(req.response, 200, <String, dynamic>{
          'callbackUrl': uriCallback.toString(),
          'cancelado': false,
        });
        return;
      }

      if (req.method == 'POST' && caminho == '/auth/v1/token') {
        final grantType = req.uri.queryParameters['grant_type'] ?? 'id_token';
        final corpo = await _lerJsonCorpo(req);

        if (grantType == 'pkce') {
          final authCode = (corpo['auth_code'] as String?)?.trim() ?? '';
          final verifier = (corpo['code_verifier'] as String?)?.trim() ?? '';
          final challengeEsperado = _codigosPkcePendentes[authCode];
          if (challengeEsperado == null ||
              verifier.isEmpty ||
              _sha256Base64UrlSemPadding(verifier) != challengeEsperado) {
            await _responderJson(req.response, 401, <String, dynamic>{
              'error_code': 'bad_code_verifier',
              'msg': 'both auth code and code verifier should be non-empty',
            });
            return;
          }
          _codigosPkcePendentes.remove(authCode);
          await _responderJson(
            req.response,
            200,
            _montarPayloadSessao(
              accessToken: 'jwt-supabase-smoke-pkce',
              refreshToken: 'refresh-smoke-pkce-001',
            ),
          );
          return;
        }

        if (grantType == 'refresh_token') {
          final refresh = (corpo['refresh_token'] as String?)?.trim() ?? '';
          if (refresh.isEmpty) {
            await _responderJson(req.response, 401, <String, dynamic>{
              'error_code': 'refresh_token_not_found',
              'msg': 'Invalid Refresh Token',
            });
            return;
          }
          await _responderJson(
            req.response,
            200,
            _montarPayloadSessao(
              accessToken: 'jwt-supabase-smoke-renovado-${++_contadorRenovacoes}',
              refreshToken: 'refresh-smoke-renovado-$_contadorRenovacoes',
            ),
          );
          return;
        }

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

        await _responderJson(
          req.response,
          200,
          _montarPayloadSessao(
            accessToken: 'jwt-supabase-smoke-sessao',
            refreshToken: 'refresh-smoke-oidc-001',
          ),
        );
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

      if (caminho == '/rest/v1/fila_interacoes') {
        if (req.method == 'GET') {
          await req.drain<void>();
          final filtrados = _filaInteracoes
              .where(
                (i) => _itemCasaComFiltrosPostgrest(i, req.uri.queryParameters),
              )
              .toList(growable: false)
            ..sort(
              (a, b) => (a['criado_em'] as String).compareTo(
                b['criado_em'] as String,
              ),
            );
          await _responderJson(req.response, 200, filtrados);
          return;
        }

        if (_falhasEscritaFilaRestantes > 0) {
          _falhasEscritaFilaRestantes--;
          await req.drain<void>();
          await _responderJson(req.response, 503, <String, dynamic>{
            'erro': 'Indisponibilidade transitória simulada pelo Smoke CI',
          });
          return;
        }

        if (req.method == 'POST') {
          final texto = await utf8.decoder.bind(req).join();
          if (texto.trim().isNotEmpty) {
            final decodificado = jsonDecode(texto);
            final itens = decodificado is List<dynamic>
                ? decodificado
                : <dynamic>[decodificado];
            for (final bruto in itens.whereType<Map<String, dynamic>>()) {
              final mapa = Map<String, dynamic>.from(bruto);
              final id = (mapa['id'] as String?)?.trim() ?? '';
              if (id.isEmpty) {
                mapa['id'] =
                    '00000000-0000-4000-8000-${(++_contadorFilaIds).toString().padLeft(12, '0')}';
              }
              mapa['status'] ??= 'PENDENTE';
              mapa['criado_em'] ??= DateTime.now().toUtc().toIso8601String();
              _filaInteracoes.add(mapa);
            }
          }
          await _responderJson(req.response, 201, const <dynamic>[]);
          return;
        }

        if (req.method == 'PATCH') {
          final corpo = await _lerJsonCorpo(req);
          for (final item in _filaInteracoes) {
            if (_itemCasaComFiltrosPostgrest(item, req.uri.queryParameters)) {
              for (final entry in corpo.entries) {
                if (entry.value == null) {
                  item.remove(entry.key);
                } else {
                  item[entry.key] = entry.value;
                }
              }
            }
          }
          req.response.statusCode = 204;
          await req.response.close();
          return;
        }

        if (req.method == 'DELETE') {
          await req.drain<void>();
          _filaInteracoes.removeWhere(
            (i) => _itemCasaComFiltrosPostgrest(i, req.uri.queryParameters),
          );
          req.response.statusCode = 204;
          await req.response.close();
          return;
        }
      }

      if (req.method == 'POST' &&
          caminho == '/rest/v1/rpc/excluir_minha_conta') {
        await req.drain<void>();
        final auth = req.headers.value(HttpHeaders.authorizationHeader) ?? '';
        if (!auth.startsWith('Bearer ') || auth.trim().length <= 7) {
          await _responderJson(req.response, 401, <String, dynamic>{
            'msg': 'JWT ausente para exclusão de conta.',
          });
          return;
        }
        _cadenasPorId.clear();
        _filaInteracoes.removeWhere(
          (i) => i['autor_id_publico'] == _autorIdPublicoAtual,
        );
        _nomePerfilAtual = 'Escalador Smoke CI';
        req.response.statusCode = 204;
        await req.response.close();
        return;
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
