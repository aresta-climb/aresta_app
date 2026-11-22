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

  /// Chave de cache local dos eventos de alerta ligados ao perfil para leitura offline na Caderneta.
  static const String chaveCacheAlertasUsuario =
      'cache_alertas_usuario_caderneta_v1';

  SharedPreferences? _preferencias;

  /// Cria uma instância de [ArmazenamentoFilaInteracoes].
  ArmazenamentoFilaInteracoes({SharedPreferences? preferencias})
    : _preferencias = preferencias;

  Future<SharedPreferences> _obterPrefs() async =>
      _preferencias ??= await SharedPreferences.getInstance();

  Future<List<ItemFilaInteracao>> _carregarLista(String chave) async {
    final prefs = await _obterPrefs();
    final bruto = prefs.getString(chave);
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

  Future<void> _salvarLista(String chave, List<ItemFilaInteracao> itens) async {
    final prefs = await _obterPrefs();
    if (itens.isEmpty) {
      await prefs.remove(chave);
      return;
    }
    final serializado = jsonEncode(
      itens.map((i) => i.toJson()).toList(growable: false),
    );
    await prefs.setString(chave, serializado);
  }

  /// Carrega os itens pendentes salvos em disco, retornando lista vazia quando ausente ou corrompido.
  Future<List<ItemFilaInteracao>> carregarItensPendentes() =>
      _carregarLista(chaveFilaPendente);

  /// Salva a lista atualizada de [itens] pendentes em disco (removendo a chave quando vazia).
  Future<void> salvarItensPendentes(List<ItemFilaInteracao> itens) =>
      _salvarLista(chaveFilaPendente, itens);

  /// Carrega o histórico local de alertas criados/confirmados pelo usuário para a Caderneta offline.
  Future<List<ItemFilaInteracao>> carregarCacheAlertasUsuario() =>
      _carregarLista(chaveCacheAlertasUsuario);

  /// Persiste em disco os eventos de alertas criados/confirmados pelo usuário para acesso offline.
  Future<void> salvarCacheAlertasUsuario(List<ItemFilaInteracao> itens) =>
      _salvarLista(chaveCacheAlertasUsuario, itens);

  /// Remove integralmente a fila offline persistida em disco.
  Future<void> limparFila() async {
    final prefs = await _obterPrefs();
    await prefs.remove(chaveFilaPendente);
  }
}
