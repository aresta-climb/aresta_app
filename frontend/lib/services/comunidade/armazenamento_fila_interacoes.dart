// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/modelos/item_fila_interacao.dart';

/// Adaptador dedicado à persistência local da fila de envio offline (*outbox*)
/// de interações comunitárias (`public.fila_interacoes`) via [SharedPreferences].
///
/// Isola a serialização JSON de disco do estado reativo de domínio mantido por
/// `RepositorioInteracoesViaMemoria`, espelhando o padrão de `ArmazenamentoLocalCaderneta`.
class ArmazenamentoFilaInteracoes {
  /// Chave de armazenamento persistente da fila de interações pendentes.
  static const String chaveFilaPendente = 'fila_pendente_interacoes_via_v1';

  SharedPreferences? _preferencias;

  /// Cria uma instância de [ArmazenamentoFilaInteracoes].
  ArmazenamentoFilaInteracoes({SharedPreferences? preferencias})
    : _preferencias = preferencias;

  Future<SharedPreferences> _obterPrefs() async =>
      _preferencias ??= await SharedPreferences.getInstance();

  /// Carrega os itens pendentes salvos em disco, retornando lista vazia quando ausente ou corrompido.
  Future<List<ItemFilaInteracao>> carregarItensPendentes() async {
    final prefs = await _obterPrefs();
    final bruto = prefs.getString(chaveFilaPendente);
    if (bruto == null || bruto.isEmpty) {
      return const [];
    }

    try {
      final lista = jsonDecode(bruto) as List<dynamic>;
      return lista
          .whereType<Map<String, dynamic>>()
          .map(ItemFilaInteracao.fromJson)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  /// Salva a lista atualizada de [itens] pendentes em disco (removendo a chave quando vazia).
  Future<void> salvarItensPendentes(List<ItemFilaInteracao> itens) async {
    final prefs = await _obterPrefs();
    if (itens.isEmpty) {
      await prefs.remove(chaveFilaPendente);
      return;
    }
    final serializado = jsonEncode(
      itens.map((i) => i.toJson()).toList(growable: false),
    );
    await prefs.setString(chaveFilaPendente, serializado);
  }

  /// Remove integralmente a fila offline persistida em disco.
  Future<void> limparFila() async {
    final prefs = await _obterPrefs();
    await prefs.remove(chaveFilaPendente);
  }
}
