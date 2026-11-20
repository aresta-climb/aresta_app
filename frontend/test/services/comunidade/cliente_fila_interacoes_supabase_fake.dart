// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:frontend/data/modelos/item_fila_interacao.dart';
import 'package:frontend/services/comunidade/cliente_fila_interacoes_supabase.dart';

/// Biblioteca `test-only` de Fake determinístico em memória para [ClienteFilaInteracoes].
///
/// Simula a tabela `public.fila_interacoes` do Supabase em memória (incluindo inspeção
/// de `accessToken` enviado e injeção determinística de falhas de rede ou HTTP).
class ClienteFilaInteracoesFake implements ClienteFilaInteracoes {
  final List<ItemFilaInteracao> _tabelaRemota = [];

  /// Fila opcional de erros consumidos sequencialmente a cada chamada a [inserirInteracao].
  final List<Object> filaErrosInsercao = [];

  /// Último `accessToken` recebido em [inserirInteracao].
  String? ultimoAccessTokenInsercao;

  /// Quando definido, lança este erro em [buscarInteracoesPendentes] e [inserirInteracao].
  Object? erroSimulado;

  /// Lista somente-leitura de todos os itens inseridos na tabela simulada.
  List<ItemFilaInteracao> get itensInseridos => List.unmodifiable(_tabelaRemota);

  /// Semeia itens pendentes previamente existentes no banco remoto.
  void semearItens(Iterable<ItemFilaInteracao> itens) {
    _tabelaRemota.addAll(itens);
  }

  @override
  Future<List<ItemFilaInteracao>> buscarInteracoesPendentes(
    String escaladaUid,
  ) async {
    if (erroSimulado != null) {
      throw erroSimulado!;
    }
    return _tabelaRemota
        .where((i) => i.escaladaUid == escaladaUid)
        .toList(growable: false);
  }

  @override
  Future<void> inserirInteracao(
    ItemFilaInteracao item, {
    String? accessToken,
  }) async {
    if (filaErrosInsercao.isNotEmpty) {
      throw filaErrosInsercao.removeAt(0);
    }
    if (erroSimulado != null) {
      throw erroSimulado!;
    }
    ultimoAccessTokenInsercao = accessToken;
    _tabelaRemota.add(item);
  }
}
