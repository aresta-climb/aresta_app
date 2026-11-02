// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/modelos/cadena.dart';
import '../../data/modelos/perfil_escalador.dart';

/// Adaptador modular de persistência local em disco da Caderneta Esportiva e Perfil.
///
/// Isola a serialização JSON, as chaves de armazenamento em [SharedPreferences] e a
/// recuperação resiliente contra dados corrompidos, mantendo [RepositorioCadernetaLocal]
/// focado exclusivamente no estado reativo em memória e nas consultas de domínio.
class ArmazenamentoLocalCaderneta {
  /// Chave de armazenamento persistente da lista de ascensões ([Cadena]).
  static const String chaveCadenas = 'aresta_cadenas_v1';

  /// Chave de armazenamento persistente da identidade esportiva ([PerfilEscalador]).
  static const String chavePerfil = 'aresta_perfil_escalador_v1';

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

  /// Persiste atomicamente a lista completa de [cadenas] quando o armazenamento está inicializado.
  Future<void> salvarCadenas(List<Cadena> cadenas) async {
    final prefs = _preferencias;
    if (prefs == null) return;
    final listaMapas = cadenas.map((c) => c.toMap()).toList();
    await prefs.setString(chaveCadenas, json.encode(listaMapas));
  }

  /// Persiste atomicamente o [perfil] do escalador quando o armazenamento está inicializado.
  Future<void> salvarPerfil(PerfilEscalador perfil) async {
    await _preferencias?.setString(chavePerfil, perfil.toJson());
  }
}
