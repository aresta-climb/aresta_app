// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/modelos/item_fila_interacao.dart';
import '../../data/modelos/mutacao_fila_interacao.dart';

/// Adaptador dedicado à persistência local da fila de envio offline (*outbox*)
/// e do cache local de alertas da Caderneta via [SharedPreferences].
class ArmazenamentoFilaInteracoes {
  /// Chave de armazenamento persistente da fila de interações pendentes.
  static const String chaveFilaPendente = 'fila_pendente_interacoes_via_v1';

  /// Chave de armazenamento persistente das edições e exclusões pendentes de envio.
  static const String chaveMutacoesPendentes =
      'fila_mutacoes_interacoes_via_v1';

  /// Chave de cache local dos eventos de alerta ligados ao perfil para leitura offline na Caderneta.
  static const String chaveCacheAlertasUsuario =
      'cache_alertas_usuario_caderneta_v1';

  SharedPreferences? _preferencias;
  final Map<String, List<ItemFilaInteracao>> _eventosAlertasPorVia = {};

  /// Cria uma instância de [ArmazenamentoFilaInteracoes].
  ArmazenamentoFilaInteracoes({SharedPreferences? preferencias})
    : _preferencias = preferencias;

  /// Eventos de alertas de segurança cacheados localmente por `escaladaUid`.
  Map<String, List<ItemFilaInteracao>> get eventosAlertasPorVia =>
      _eventosAlertasPorVia;

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
      itens
          .map((i) => i.toJson(incluirAvatarLocal: true))
          .toList(growable: false),
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

  /// Hidrata em memória [_eventosAlertasPorVia] a partir do disco.
  Future<void> hidratarMemoriaAlertas() async {
    for (final ev in await carregarCacheAlertasUsuario()) {
      _eventosAlertasPorVia
          .putIfAbsent(ev.escaladaUid, () => <ItemFilaInteracao>[])
          .add(ev);
    }
  }

  /// Substitui todos os eventos de alertas em memória e persiste em disco.
  Future<void> substituirTodosEventosAlertas(
    Iterable<ItemFilaInteracao> itens,
  ) async {
    _eventosAlertasPorVia.clear();
    for (final item in itens) {
      _eventosAlertasPorVia
          .putIfAbsent(item.escaladaUid, () => <ItemFilaInteracao>[])
          .add(item);
    }
    await persistirMemoriaAlertas();
  }

  /// Atualiza em memória os eventos de alerta de uma única [uidVia].
  void atualizarEventosDaVia(
    String uidVia,
    Iterable<ItemFilaInteracao> itens,
  ) {
    final filtrados = itens
        .where(
          (i) =>
              i.tipo == TipoFilaInteracao.alertaSeguranca ||
              i.tipo == TipoFilaInteracao.confirmacaoAlerta,
        )
        .toList();
    if (filtrados.isEmpty) {
      _eventosAlertasPorVia.remove(uidVia);
    } else {
      _eventosAlertasPorVia[uidVia] = filtrados;
    }
  }

  /// Adiciona um evento local de alerta em memória e persiste em disco.
  Future<void> adicionarEventoAlerta(ItemFilaInteracao evento) async {
    _eventosAlertasPorVia
        .putIfAbsent(evento.escaladaUid, () => <ItemFilaInteracao>[])
        .add(evento);
    await persistirMemoriaAlertas();
  }

  /// Aplica uma mutação de alerta em memória para [uidVia] e persiste em disco.
  Future<void> aplicarMutacaoAlertaNaVia(
    String uidVia,
    MutacaoFilaInteracao mutacao,
  ) async {
    final existentes = _eventosAlertasPorVia[uidVia];
    if (existentes == null) return;
    final filtrados = aplicarMutacoesSobreItens(existentes, [mutacao]);
    if (filtrados.isEmpty) {
      _eventosAlertasPorVia.remove(uidVia);
    } else {
      _eventosAlertasPorVia[uidVia] = filtrados;
    }
    await persistirMemoriaAlertas();
  }

  /// Persiste em disco o mapa [_eventosAlertasPorVia] atual.
  Future<void> persistirMemoriaAlertas() => salvarCacheAlertasUsuario([
    for (final lista in _eventosAlertasPorVia.values) ...lista,
  ]);

  /// Carrega as mutações de edição/exclusão retidas offline.
  Future<List<MutacaoFilaInteracao>> carregarMutacoesPendentes() async {
    final prefs = await _obterPrefs();
    final bruto = prefs.getString(chaveMutacoesPendentes);
    if (bruto == null || bruto.isEmpty) return const [];
    try {
      final lista = jsonDecode(bruto) as List<dynamic>;
      return lista
          .whereType<Map<String, dynamic>>()
          .map(MutacaoFilaInteracao.fromJson)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  /// Salva as mutações de edição/exclusão pendentes em disco (removendo a chave quando vazia).
  Future<void> salvarMutacoesPendentes(
    List<MutacaoFilaInteracao> mutacoes,
  ) async {
    final prefs = await _obterPrefs();
    if (mutacoes.isEmpty) {
      await prefs.remove(chaveMutacoesPendentes);
      return;
    }
    final serializado = jsonEncode(
      mutacoes.map((m) => m.toJson()).toList(growable: false),
    );
    await prefs.setString(chaveMutacoesPendentes, serializado);
  }

  /// Remove integralmente a fila offline persistida em disco.
  Future<void> limparFila() async {
    final prefs = await _obterPrefs();
    await prefs.remove(chaveFilaPendente);
    await prefs.remove(chaveMutacoesPendentes);
  }
}
