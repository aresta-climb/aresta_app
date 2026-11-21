// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/modelos/cadena.dart';
import '../../data/modelos/perfil_escalador.dart';

/// Adaptador modular de persistência local em disco da Caderneta Esportiva e Perfil.
///
/// Isola a serialização JSON, as chaves de armazenamento em [SharedPreferences], a fila
/// de mutações offline pendentes (`upsert` e `delete`) e a recuperação resiliente contra
/// dados corrompidos, mantendo `RepositorioCadernetaLocal` focado no estado reativo.
class ArmazenamentoLocalCaderneta {
  /// Chave de armazenamento persistente da lista de ascensões ([Cadena]).
  static const String chaveCadenas = 'aresta_cadenas_v1';

  /// Chave de armazenamento persistente da identidade esportiva ([PerfilEscalador]).
  static const String chavePerfil = 'aresta_perfil_escalador_v1';

  /// Chave de armazenamento dos IDs de ascensões aguardando envio (`upsert`) ao Supabase.
  static const String chaveIdsUpsertPendentes =
      'aresta_cadenas_upsert_pendentes_v1';

  /// Chave de armazenamento dos IDs de ascensões aguardando exclusão (`delete`) no Supabase.
  static const String chaveIdsExclusaoPendentes =
      'aresta_cadenas_exclusao_pendentes_v1';

  SharedPreferences? _preferencias;

  /// Cria o adaptador de armazenamento aceitando opcionalmente uma instância de [SharedPreferences].
  ArmazenamentoLocalCaderneta({SharedPreferences? preferencias})
    : _preferencias = preferencias;

  /// Inicializa a instância subjacente de [SharedPreferences] caso não tenha sido injetada.
  Future<void> inicializar() async {
    _preferencias ??= await SharedPreferences.getInstance();
  }

  /// Carrega o [PerfilEscalador] persistido localmente ou cria, salva e retorna
  /// um novo perfil padrão caso ainda não exista ou caso o JSON esteja corrompido.
  Future<PerfilEscalador> carregarOuCriarPerfil() async {
    await inicializar();
    final jsonPerfil = _preferencias!.getString(chavePerfil);
    if (jsonPerfil != null && jsonPerfil.isNotEmpty) {
      try {
        return PerfilEscalador.fromJson(jsonPerfil);
      } catch (_) {
        // Prossegue para regeneração resiliente do perfil padrão.
      }
    }
    final perfilPadrao = PerfilEscalador.criarPadrao();
    await salvarPerfil(perfilPadrao);
    return perfilPadrao;
  }

  /// Carrega todas as ascensões ([Cadena]) salvas localmente, retornando lista vazia
  /// quando o armazenamento estiver vazio ou corrompido.
  Future<List<Cadena>> carregarCadenas() async {
    await inicializar();
    final jsonCadenas = _preferencias!.getString(chaveCadenas);
    if (jsonCadenas == null || jsonCadenas.isEmpty) {
      return const [];
    }
    try {
      final lista = json.decode(jsonCadenas) as List<dynamic>;
      return [
        for (final item in lista)
          if (item is Map<String, dynamic>) Cadena.fromMap(item),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// Carrega os IDs de ascensões pendentes de envio (`upsert`) para `public.cadenas`.
  Future<Set<String>> carregarIdsUpsertPendentes() =>
      _carregarConjuntoIds(chaveIdsUpsertPendentes);

  /// Carrega os IDs de ascensões pendentes de exclusão (`delete`) em `public.cadenas`.
  Future<Set<String>> carregarIdsExclusaoPendentes() =>
      _carregarConjuntoIds(chaveIdsExclusaoPendentes);

  Future<Set<String>> _carregarConjuntoIds(String chave) async {
    await inicializar();
    final bruto = _preferencias!.getString(chave);
    if (bruto == null || bruto.isEmpty) {
      return <String>{};
    }
    try {
      final lista = json.decode(bruto) as List<dynamic>;
      return lista.whereType<String>().toSet();
    } catch (_) {
      return <String>{};
    }
  }

  /// Persiste atomicamente a lista completa de [cadenas] quando o armazenamento está inicializado.
  Future<void> salvarCadenas(List<Cadena> cadenas) async {
    final prefs = _preferencias;
    if (prefs == null) return;
    final listaMapas = cadenas.map((c) => c.toMap()).toList();
    await prefs.setString(chaveCadenas, json.encode(listaMapas));
  }

  /// Persiste os conjuntos de IDs de mutações pendentes para sincronização offline-first.
  Future<void> salvarFilaSincronizacao({
    required Set<String> idsUpsertPendentes,
    required Set<String> idsExclusaoPendentes,
  }) async {
    final prefs = _preferencias;
    if (prefs == null) return;

    if (idsUpsertPendentes.isEmpty) {
      await prefs.remove(chaveIdsUpsertPendentes);
    } else {
      await prefs.setString(
        chaveIdsUpsertPendentes,
        json.encode(idsUpsertPendentes.toList(growable: false)),
      );
    }

    if (idsExclusaoPendentes.isEmpty) {
      await prefs.remove(chaveIdsExclusaoPendentes);
    } else {
      await prefs.setString(
        chaveIdsExclusaoPendentes,
        json.encode(idsExclusaoPendentes.toList(growable: false)),
      );
    }
  }

  /// Persiste atomicamente o [perfil] do escalador quando o armazenamento está inicializado.
  Future<void> salvarPerfil(PerfilEscalador perfil) async {
    await _preferencias?.setString(chavePerfil, perfil.toJson());
  }

  /// Remove todas as ascensões, filas de mutação e dados de perfil salvos no dispositivo.
  Future<void> limparDadosLocais() async {
    final prefs = _preferencias;
    if (prefs == null) return;
    await prefs.remove(chaveCadenas);
    await prefs.remove(chaveIdsUpsertPendentes);
    await prefs.remove(chaveIdsExclusaoPendentes);
    await prefs.remove(chavePerfil);
  }
}
