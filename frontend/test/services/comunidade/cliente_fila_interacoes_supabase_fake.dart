// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:frontend/data/modelos/interacao_via.dart';
import 'package:frontend/data/modelos/item_fila_interacao.dart';
import 'package:frontend/services/comunidade/cliente_fila_interacoes_supabase.dart';

/// Biblioteca `test-only` de Fake determinístico em memória para [ClienteFilaInteracoes].
///
/// Simula a tabela `public.fila_interacoes` do Supabase em memória (incluindo RLS de autoria
/// nas edições e exclusões, inspeção de `accessToken` e injeção determinística de falhas).
class ClienteFilaInteracoesFake implements ClienteFilaInteracoes {
  final List<ItemFilaInteracao> _tabelaRemota = [];

  /// Fila opcional de erros consumidos sequencialmente a cada escrita ou mutação.
  final List<Object> filaErrosInsercao = [];

  /// Último `accessToken` recebido em escrita ou mutação.
  String? ultimoAccessTokenInsercao;

  /// Quando definido, lança este erro nas consultas e escritas.
  Object? erroSimulado;

  /// Lista somente-leitura de todos os itens atualmente armazenados na tabela simulada.
  List<ItemFilaInteracao> get itensInseridos => List.unmodifiable(_tabelaRemota);

  /// Semeia itens pendentes previamente existentes no banco remoto.
  void semearItens(Iterable<ItemFilaInteracao> itens) {
    _tabelaRemota.addAll(itens);
  }

  void _consumirErroSeConfigurado() {
    if (filaErrosInsercao.isNotEmpty) {
      throw filaErrosInsercao.removeAt(0);
    }
    if (erroSimulado != null) {
      throw erroSimulado!;
    }
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
  Future<List<ItemFilaInteracao>> buscarInteracoesPendentesEmLote(
    Iterable<String> escaladaUids,
  ) async {
    if (erroSimulado != null) {
      throw erroSimulado!;
    }
    final conjunto = escaladaUids.map((u) => u.trim()).toSet();
    return _tabelaRemota
        .where((i) => conjunto.contains(i.escaladaUid))
        .toList(growable: false);
  }

  @override
  Future<List<ItemFilaInteracao>> buscarInteracoesRelacionadasAoAutor(
    String autorIdPublico,
  ) async {
    if (erroSimulado != null) {
      throw erroSimulado!;
    }
    final autor = autorIdPublico.trim();
    final vias = _tabelaRemota
        .where(
          (i) =>
              i.autorIdPublico == autor &&
              (i.tipo == TipoFilaInteracao.alertaSeguranca ||
                  i.tipo == TipoFilaInteracao.confirmacaoAlerta),
        )
        .map((i) => i.escaladaUid)
        .toSet();
    if (vias.isEmpty) return const [];
    return buscarInteracoesPendentesEmLote(vias);
  }

  @override
  Future<void> inserirInteracao(
    ItemFilaInteracao item, {
    String? accessToken,
  }) async {
    _consumirErroSeConfigurado();
    ultimoAccessTokenInsercao = accessToken;
    _tabelaRemota.add(item);
  }

  @override
  Future<void> atualizarComentario({
    required String comentarioId,
    required String autorIdPublico,
    required String novoTexto,
    String? accessToken,
  }) async {
    _consumirErroSeConfigurado();
    ultimoAccessTokenInsercao = accessToken;
    for (var i = 0; i < _tabelaRemota.length; i++) {
      final atual = _tabelaRemota[i];
      if (atual.tipo == TipoFilaInteracao.comentario &&
          atual.id == comentarioId.trim() &&
          atual.autorIdPublico == autorIdPublico.trim()) {
        _tabelaRemota[i] = atual.comTextoComentario(novoTexto);
      }
    }
  }

  @override
  Future<void> excluirComentario({
    required String comentarioId,
    required String autorIdPublico,
    String? accessToken,
  }) async {
    _consumirErroSeConfigurado();
    ultimoAccessTokenInsercao = accessToken;
    _tabelaRemota.removeWhere(
      (atual) =>
          atual.tipo == TipoFilaInteracao.comentario &&
          atual.id == comentarioId.trim() &&
          atual.autorIdPublico == autorIdPublico.trim(),
    );
  }

  @override
  Future<void> atualizarAlerta({
    required String alertaAlvoUid,
    required String autorIdPublico,
    required CategoriaAlertaSeguranca categoria,
    String? detalhe,
    String? accessToken,
  }) async {
    _consumirErroSeConfigurado();
    ultimoAccessTokenInsercao = accessToken;
    for (var i = 0; i < _tabelaRemota.length; i++) {
      final atual = _tabelaRemota[i];
      if (atual.tipo == TipoFilaInteracao.alertaSeguranca &&
          atual.alertaAlvoUid == alertaAlvoUid.trim() &&
          atual.autorIdPublico == autorIdPublico.trim()) {
        _tabelaRemota[i] = atual.comEdicaoAlerta(
          categoria: categoria,
          detalhe: detalhe,
        );
      }
    }
  }

  @override
  Future<void> excluirAlerta({
    required String alertaAlvoUid,
    required String autorIdPublico,
    String? accessToken,
  }) async {
    _consumirErroSeConfigurado();
    ultimoAccessTokenInsercao = accessToken;
    _tabelaRemota.removeWhere(
      (atual) =>
          atual.tipo == TipoFilaInteracao.alertaSeguranca &&
          atual.alertaAlvoUid == alertaAlvoUid.trim() &&
          atual.autorIdPublico == autorIdPublico.trim(),
    );
  }
}
