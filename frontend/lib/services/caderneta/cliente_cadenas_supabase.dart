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


  @override
  Future<List<Cadena>> listarCadenasDoUsuario({
    required String userId,
    required String accessToken,
  }) async => const [];

  @override
  Future<void> upsertCadenas(
    List<Cadena> cadenas, {
    required String userId,
    required String accessToken,
  }) async {}
}
