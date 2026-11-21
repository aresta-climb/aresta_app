// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';
import '../../data/modelos/cadena.dart';
import '../firebase/app_logger.dart';
import '../firebase/remote_config.dart';
import '../http/cliente_http_aresta.dart';

/// Exceção tipada de transporte da tabela `public.cadenas`, expondo [codigoStatusHttp]
/// para distinguir expiração de JWT (`401`) de falhas transitórias de conectividade.
class ExcecaoHttpCadenas implements HttpException, ExcecaoComStatusHttp {
  /// Código de status HTTP retornado pelo PostgREST.
  @override
  final int codigoStatusHttp;

  @override
  final String message;

  @override
  final Uri? uri;

  /// Cria uma instância imutável de [ExcecaoHttpCadenas].
  const ExcecaoHttpCadenas({
    required this.codigoStatusHttp,
    required this.message,
    this.uri,
  });

  @override
  String toString() => 'ExcecaoHttpCadenas($codigoStatusHttp): $message';
}

/// Contrato de comunicação HTTP com a tabela privada `public.cadenas` (PostgREST).
///
/// Todas as operações exigem sessão autenticada (`Authorization: Bearer <accessToken>`)
/// e operam sob a política RLS `auth.uid() = user_id`.
abstract interface class ClienteCadenas {
  /// Lista todas as ascensões e tentativas registradas por [userId] na nuvem.
  Future<List<Cadena>> listarCadenasDoUsuario({
    required String userId,
    required String accessToken,
  });

  /// Insere ou atualiza em lote ([cadenas]) na tabela `public.cadenas` (`on_conflict=id`).
  Future<void> upsertCadenas(
    List<Cadena> cadenas, {
    required String userId,
    required String accessToken,
  });

  /// Exclui permanentemente o registro [cadenaId] pertencente a [userId] na nuvem.
  Future<void> excluirCadenaRemota(
    String cadenaId, {
    required String userId,
    required String accessToken,
  });
}

/// Implementação de produção de [ClienteCadenas] apoiada no pool Keep-Alive de [ClienteHttpAresta].
class ClienteCadenasSupabase implements ClienteCadenas {
  static const String _colunasSelecao =
      'id,user_id,escalada_uid,data_ascensao,tipo_ascensao,'
      'tipo_escalada,tentativas,grau_sugerido,notas_privadas,criado_em';

  final ClienteHttpAresta _clienteHttp;
  final String Function() _resolvedorBaseUrl;
  final String Function() _resolvedorAnonKey;

  /// Cria uma instância de [ClienteCadenasSupabase].
  ClienteCadenasSupabase({
    ClienteHttpAresta? clienteHttp,
    String Function()? resolvedorBaseUrl,
    String Function()? resolvedorAnonKey,
  }) : _clienteHttp = clienteHttp ?? ClienteHttpAresta.instancia,
       _resolvedorBaseUrl =
           resolvedorBaseUrl ?? (() => RemoteConfigService.instance.supabaseUrl),
       _resolvedorAnonKey =
           resolvedorAnonKey ??
           (() => RemoteConfigService.instance.supabaseAnonKey);

  String get _baseUrl =>
      _resolvedorBaseUrl().trim().replaceAll(RegExp(r'/+$'), '');

  Map<String, String> _construirCabecalhos({
    required String accessToken,
    String? prefer,
    bool comCorpoJson = false,
  }) {
    final anonKey = _resolvedorAnonKey();
    return <String, String>{
      'apikey': anonKey,
      'Authorization': 'Bearer ${accessToken.trim()}',
      if (comCorpoJson) 'Content-Type': 'application/json',
      'Prefer': ?prefer,
    };
  }

  @override
  Future<List<Cadena>> listarCadenasDoUsuario({
    required String userId,
    required String accessToken,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/rest/v1/cadenas'
      '?user_id=eq.${userId.trim()}'
      '&order=data_ascensao.desc,criado_em.desc'
      '&select=$_colunasSelecao',
    );

    final resposta = await _clienteHttp.get(
      uri,
      headers: _construirCabecalhos(accessToken: accessToken),
    );

    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      throw ExcecaoHttpCadenas(
        codigoStatusHttp: resposta.statusCode,
        message: 'HTTP ${resposta.statusCode}: ${resposta.body}',
        uri: uri,
      );
    }

    final decodificado = jsonDecode(resposta.body) as List<dynamic>;
    return decodificado
        .whereType<Map<String, dynamic>>()
        .map(Cadena.fromMap)
        .toList(growable: false);
  }

  @override
  Future<void> upsertCadenas(
    List<Cadena> cadenas, {
    required String userId,
    required String accessToken,
  }) async {
    if (cadenas.isEmpty) return;

    final uri = Uri.parse('$_baseUrl/rest/v1/cadenas?on_conflict=id');
    final payload = cadenas
        .map((c) => c.toPayloadSupabase(userId: userId.trim()))
        .toList(growable: false);

    final resposta = await _clienteHttp.post(
      uri,
      headers: _construirCabecalhos(
        accessToken: accessToken,
        comCorpoJson: true,
        prefer: 'resolution=merge-duplicates,return=minimal',
      ),
      body: jsonEncode(payload),
    );

    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      throw ExcecaoHttpCadenas(
        codigoStatusHttp: resposta.statusCode,
        message: 'HTTP ${resposta.statusCode}: ${resposta.body}',
        uri: uri,
      );
    }
  }

  @override
  Future<void> excluirCadenaRemota(
    String cadenaId, {
    required String userId,
    required String accessToken,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/rest/v1/cadenas'
      '?id=eq.${cadenaId.trim()}'
      '&user_id=eq.${userId.trim()}',
    );
    final requisicao = Request('DELETE', uri)
      ..headers.addAll(
        _construirCabecalhos(
          accessToken: accessToken,
          prefer: 'return=minimal',
        ),
      );

    final resposta = await _clienteHttp.send(requisicao);
    final corpo = await resposta.stream.bytesToString();
    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      throw ExcecaoHttpCadenas(
        codigoStatusHttp: resposta.statusCode,
        message: 'HTTP ${resposta.statusCode}: $corpo',
        uri: uri,
      );
    }
  }
}
