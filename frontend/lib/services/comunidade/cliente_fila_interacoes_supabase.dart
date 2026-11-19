// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';
import '../../data/modelos/item_fila_interacao.dart';
import '../firebase/remote_config.dart';
import '../http/cliente_http_aresta.dart';

/// Contrato de comunicação HTTP com a tabela `public.fila_interacoes` (PostgREST).
///
/// Separa a serialização/transporte de rede da orquestração reativa e da fila
/// offline de [RepositorioInteracoesVia], viabilizando Fakes determinísticos em memória.
abstract interface class ClienteFilaInteracoes {
  /// Consulta todas as interações com `status = 'PENDENTE'` para [escaladaUid].
  Future<List<ItemFilaInteracao>> buscarInteracoesPendentes(
    String escaladaUid, {
    String? accessToken,
  });

  /// Insere um novo evento na tabela `public.fila_interacoes`.
  ///
  /// Quando [accessToken] é informado, autentica como `authenticated` (permitindo
  /// `VOTO_GRAU` e `COMENTARIO`); quando omitido, utiliza a chave `anon` (permitindo
  /// `ALERTA_SEGURANCA` e `CONFIRMACAO_ALERTA` sem barreira de login).
  Future<void> inserirInteracao(
    ItemFilaInteracao item, {
    String? accessToken,
  });
}

/// Implementação de produção de [ClienteFilaInteracoes] apoiada em [ClienteHttpAresta].
class ClienteFilaInteracoesSupabase implements ClienteFilaInteracoes {
  static const String _colunasSelecao =
      'id,autor_id_publico,autor_nome_publico,escalada_uid,tipo,'
      'categoria_alerta,alerta_alvo_uid,alerta_ativo,grau_sugerido,'
      'delta_grau,tipo_ascensao,texto_comentario,criado_em';

  final ClienteHttpAresta _clienteHttp;
  final String Function() _resolvedorBaseUrl;
  final String Function() _resolvedorAnonKey;

  /// Cria uma instância de [ClienteFilaInteracoesSupabase].
  ClienteFilaInteracoesSupabase({
    ClienteHttpAresta? clienteHttp,
    String Function()? resolvedorBaseUrl,
    String Function()? resolvedorAnonKey,
  }) : _clienteHttp = clienteHttp ?? ClienteHttpAresta.instancia,
       _resolvedorBaseUrl =
           resolvedorBaseUrl ?? (() => RemoteConfigService.instance.supabaseUrl),
       _resolvedorAnonKey =
           resolvedorAnonKey ??
           (() => RemoteConfigService.instance.supabaseAnonKey);

  Map<String, String> _construirCabecalhos({
    String? accessToken,
    bool comCorpoJson = false,
  }) {
    final anonKey = _resolvedorAnonKey();
    final bearer = (accessToken != null && accessToken.trim().isNotEmpty)
        ? accessToken.trim()
        : anonKey;
    return <String, String>{
      'apikey': anonKey,
      'Authorization': 'Bearer $bearer',
      if (comCorpoJson) ...{
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal',
      },
    };
  }

  @override
  Future<List<ItemFilaInteracao>> buscarInteracoesPendentes(
    String escaladaUid, {
    String? accessToken,
  }) async {
    final uidLimpo = escaladaUid.trim();
    if (uidLimpo.isEmpty) {
      return const [];
    }

    final baseUrl = _resolvedorBaseUrl();
    final uri = Uri.parse(
      '$baseUrl/rest/v1/fila_interacoes'
      '?escalada_uid=eq.$uidLimpo'
      '&status=eq.PENDENTE'
      '&order=criado_em.asc'
      '&select=$_colunasSelecao',
    );

    final resposta = await _clienteHttp.get(
      uri,
      headers: _construirCabecalhos(accessToken: accessToken),
    );

    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      throw HttpException(
        'HTTP ${resposta.statusCode}: ${resposta.body}',
        uri: uri,
      );
    }

    final decodificado = jsonDecode(resposta.body) as List<dynamic>;
    return decodificado
        .whereType<Map<String, dynamic>>()
        .map(ItemFilaInteracao.fromJson)
        .toList(growable: false);
  }

  @override
  Future<void> inserirInteracao(
    ItemFilaInteracao item, {
    String? accessToken,
  }) async {
    final baseUrl = _resolvedorBaseUrl();
    final uri = Uri.parse('$baseUrl/rest/v1/fila_interacoes');

    final resposta = await _clienteHttp.post(
      uri,
      headers: _construirCabecalhos(
        accessToken: accessToken,
        comCorpoJson: true,
      ),
      body: jsonEncode(item.toJson(incluirId: false)),
    );

    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      throw HttpException(
        'HTTP ${resposta.statusCode}: ${resposta.body}',
        uri: uri,
      );
    }
  }
}
