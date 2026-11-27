// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';
import '../../data/modelos/interacao_via.dart';
import '../../data/modelos/item_fila_interacao.dart';
import '../firebase/app_logger.dart';
import '../firebase/remote_config.dart';
import '../http/cliente_http_aresta.dart';

/// Exceção tipada de transporte da tabela `public.fila_interacoes`, expondo [codigoStatusHttp]
/// para distinguir expiração de JWT (`401`), violação de RLS (`403`) e falhas transitórias.
class ExcecaoHttpFilaInteracoes implements HttpException, ExcecaoComStatusHttp {
  /// Código de status HTTP retornado pelo PostgREST.
  @override
  final int codigoStatusHttp;

  @override
  final String message;

  @override
  final Uri? uri;

  /// Cria uma instância imutável de [ExcecaoHttpFilaInteracoes].
  const ExcecaoHttpFilaInteracoes({
    required this.codigoStatusHttp,
    required this.message,
    this.uri,
  });

  @override
  String toString() => 'ExcecaoHttpFilaInteracoes($codigoStatusHttp): $message';
}

/// Contrato de comunicação HTTP com a tabela `public.fila_interacoes` (PostgREST).
///
/// Separa a serialização/transporte de rede da orquestração reativa e da fila
/// offline de [RepositorioInteracoesVia], viabilizando Fakes determinísticos em memória.
abstract interface class ClienteFilaInteracoes {
  /// Consulta todas as interações com `status = 'PENDENTE'` para [escaladaUid] via leitura pública.
  Future<List<ItemFilaInteracao>> buscarInteracoesPendentes(String escaladaUid);

  /// Consulta em uma única chamada HTTP todas as interações `PENDENTE` para o conjunto [escaladaUids].
  Future<List<ItemFilaInteracao>> buscarInteracoesPendentesEmLote(
    Iterable<String> escaladaUids,
  );

  /// Localiza as vias em que [autorIdPublico] criou ou confirmou alertas `PENDENTE` e retorna
  /// todos os eventos pendentes dessas vias para consolidar status e contagens na Caderneta.
  Future<List<ItemFilaInteracao>> buscarInteracoesRelacionadasAoAutor(
    String autorIdPublico,
  );

  /// Insere um novo evento na tabela `public.fila_interacoes` autenticado pelo perfil do escalador.
  Future<void> inserirInteracao(
    ItemFilaInteracao item, {
    String? accessToken,
  });

  /// Atualiza o texto de um `COMENTARIO` pendente pertencente a [autorIdPublico] sob RLS.
  Future<void> atualizarComentario({
    required String comentarioId,
    required String autorIdPublico,
    required String novoTexto,
    String? accessToken,
  });

  /// Exclui permanentemente um `COMENTARIO` pendente pertencente a [autorIdPublico] sob RLS.
  Future<void> excluirComentario({
    required String comentarioId,
    required String autorIdPublico,
    String? accessToken,
  });

  /// Atualiza a categoria e/ou o detalhe de um `ALERTA_SEGURANCA` pendente pertencente a [autorIdPublico].
  Future<void> atualizarAlerta({
    required String alertaAlvoUid,
    required String autorIdPublico,
    required CategoriaAlertaSeguranca categoria,
    String? detalhe,
    String? accessToken,
  });

  /// Exclui permanentemente um `ALERTA_SEGURANCA` pendente pertencente a [autorIdPublico] sob RLS.
  Future<void> excluirAlerta({
    required String alertaAlvoUid,
    required String autorIdPublico,
    String? accessToken,
  });
}

/// Implementação de produção de [ClienteFilaInteracoes] apoiada em [ClienteHttpAresta].
class ClienteFilaInteracoesSupabase implements ClienteFilaInteracoes {
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

  String get _baseUrl =>
      _resolvedorBaseUrl().trim().replaceAll(RegExp(r'/+$'), '');

  Map<String, String> _construirCabecalhos({
    String? accessToken,
    bool comCorpoJson = false,
  }) {
    final anonKey = _resolvedorAnonKey().trim();
    final tokenAutenticado = accessToken?.trim();
    return <String, String>{
      'apikey': anonKey,
      if (tokenAutenticado != null && tokenAutenticado.isNotEmpty)
        'Authorization': 'Bearer $tokenAutenticado',
      if (comCorpoJson) ...{
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal',
      },
    };
  }

  @override
  Future<List<ItemFilaInteracao>> buscarInteracoesPendentes(
    String escaladaUid,
  ) async {
    final uidLimpo = escaladaUid.trim();
    if (uidLimpo.isEmpty) {
      return const [];
    }

    final uri = Uri.parse(
      '$_baseUrl/rest/v1/fila_interacoes'
      '?escalada_uid=eq.$uidLimpo'
      '&status=eq.PENDENTE'
      '&order=criado_em.asc'
      '&select=*',
    );
    return _executarGetLista(uri);
  }

  @override
  Future<List<ItemFilaInteracao>> buscarInteracoesPendentesEmLote(
    Iterable<String> escaladaUids,
  ) async {
    final uidsUnicos = escaladaUids
        .map((u) => u.trim())
        .where((u) => u.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (uidsUnicos.isEmpty) {
      return const [];
    }

    final uri = Uri.parse(
      '$_baseUrl/rest/v1/fila_interacoes'
      '?escalada_uid=in.(${uidsUnicos.join(',')})'
      '&status=eq.PENDENTE'
      '&order=criado_em.asc'
      '&select=*',
    );
    return _executarGetLista(uri);
  }

  @override
  Future<List<ItemFilaInteracao>> buscarInteracoesRelacionadasAoAutor(
    String autorIdPublico,
  ) async {
    final autorLimpo = autorIdPublico.trim();
    if (autorLimpo.isEmpty) {
      return const [];
    }

    final uriAutor = Uri.parse(
      '$_baseUrl/rest/v1/fila_interacoes'
      '?autor_id_publico=eq.$autorLimpo'
      '&status=eq.PENDENTE'
      '&order=criado_em.asc'
      '&select=*',
    );
    final proprios = await _executarGetLista(uriAutor);
    final viasDeAlerta = proprios
        .where(
          (i) =>
              i.tipo == TipoFilaInteracao.alertaSeguranca ||
              i.tipo == TipoFilaInteracao.confirmacaoAlerta,
        )
        .map((i) => i.escaladaUid)
        .toSet();
    if (viasDeAlerta.isEmpty) {
      return const [];
    }
    return buscarInteracoesPendentesEmLote(viasDeAlerta);
  }

  Future<List<ItemFilaInteracao>> _executarGetLista(Uri uri) async {
    final resposta = await _clienteHttp.get(
      uri,
      headers: _construirCabecalhos(),
    );

    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      throw ExcecaoHttpFilaInteracoes(
        codigoStatusHttp: resposta.statusCode,
        message: 'HTTP ${resposta.statusCode}: ${resposta.body}',
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
    final uri = Uri.parse('$_baseUrl/rest/v1/fila_interacoes');
    final incluirUuidProprio = ItemFilaInteracao.ehUuidValido(item.id);

    final resposta = await _clienteHttp.post(
      uri,
      headers: _construirCabecalhos(
        accessToken: accessToken,
        comCorpoJson: true,
      ),
      body: jsonEncode(item.toJson(incluirId: incluirUuidProprio)),
    );

    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      throw ExcecaoHttpFilaInteracoes(
        codigoStatusHttp: resposta.statusCode,
        message: 'HTTP ${resposta.statusCode}: ${resposta.body}',
        uri: uri,
      );
    }
  }

  @override
  Future<void> atualizarComentario({
    required String comentarioId,
    required String autorIdPublico,
    required String novoTexto,
    String? accessToken,
  }) {
    final uri = Uri.parse(
      '$_baseUrl/rest/v1/fila_interacoes'
      '?id=eq.${Uri.encodeQueryComponent(comentarioId.trim())}'
      '&autor_id_publico=eq.${Uri.encodeQueryComponent(autorIdPublico.trim())}'
      '&tipo=eq.COMENTARIO'
      '&status=eq.PENDENTE',
    );
    return _enviarMutacaoRest(
      metodo: 'PATCH',
      uri: uri,
      accessToken: accessToken,
      corpoJson: <String, dynamic>{'texto_comentario': novoTexto.trim()},
    );
  }

  @override
  Future<void> excluirComentario({
    required String comentarioId,
    required String autorIdPublico,
    String? accessToken,
  }) {
    final uri = Uri.parse(
      '$_baseUrl/rest/v1/fila_interacoes'
      '?id=eq.${Uri.encodeQueryComponent(comentarioId.trim())}'
      '&autor_id_publico=eq.${Uri.encodeQueryComponent(autorIdPublico.trim())}'
      '&tipo=eq.COMENTARIO'
      '&status=eq.PENDENTE',
    );
    return _enviarMutacaoRest(
      metodo: 'DELETE',
      uri: uri,
      accessToken: accessToken,
    );
  }

  @override
  Future<void> atualizarAlerta({
    required String alertaAlvoUid,
    required String autorIdPublico,
    required CategoriaAlertaSeguranca categoria,
    String? detalhe,
    String? accessToken,
  }) {
    final uri = Uri.parse(
      '$_baseUrl/rest/v1/fila_interacoes'
      '?alerta_alvo_uid=eq.${Uri.encodeQueryComponent(alertaAlvoUid.trim())}'
      '&autor_id_publico=eq.${Uri.encodeQueryComponent(autorIdPublico.trim())}'
      '&tipo=eq.ALERTA_SEGURANCA'
      '&status=eq.PENDENTE',
    );
    final detalheLimpo = detalhe?.trim();
    return _enviarMutacaoRest(
}
