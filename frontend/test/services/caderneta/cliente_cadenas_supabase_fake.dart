// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:frontend/data/modelos/cadena.dart';
import 'package:frontend/services/caderneta/cliente_cadenas_supabase.dart';

/// Biblioteca `test-only` de Fake determinístico em memória para [ClienteCadenas].
///
/// Simula a tabela privada `public.cadenas` do Supabase com isolamento por `user_id`
/// (espelhando a política RLS `auth.uid() = user_id`), inspeção de JWT e injeção de falhas.
class ClienteCadenasFake implements ClienteCadenas {
  final Map<String, Map<String, Cadena>> _porUsuario = {};

  /// Fila opcional de erros lançados sequencialmente na próxima operação.
  final List<Object> filaErros = [];

  /// Exceção contínua opcional lançada em todas as chamadas de rede simuladas.
  Object? erroSimulado;

  /// Último `accessToken` recebido nas operações autenticadas.
  String? ultimoAccessToken;

  void _verificarFalhaInjetada() {
    if (filaErros.isNotEmpty) {
      throw filaErros.removeAt(0);
    }
    if (erroSimulado != null) {
      throw erroSimulado!;
    }
  }

  /// Semeia ascensões remotas previamente salvas na nuvem para [userId].
  void semearCadenas(String userId, Iterable<Cadena> cadenas) {
    final mapa = _porUsuario.putIfAbsent(userId, () => <String, Cadena>{});
    for (final c in cadenas) {
      mapa[c.id] = c.copyWith(userId: userId);
    }
  }

  /// Retorna a visão atual em memória das ascensões salvas na nuvem para [userId].
  List<Cadena> cadenasDaConta(String userId) {
    final mapa = _porUsuario[userId];
    if (mapa == null) return const [];
    final lista = mapa.values.toList()
      ..sort((a, b) => b.dataAscensao.compareTo(a.dataAscensao));
    return List.unmodifiable(lista);
  }

  @override
  Future<List<Cadena>> listarCadenasDoUsuario({
    required String userId,
    required String accessToken,
  }) async {
    _verificarFalhaInjetada();
    ultimoAccessToken = accessToken;
    return cadenasDaConta(userId);
  }

  @override
  Future<void> upsertCadenas(
    List<Cadena> cadenas, {
    required String userId,
    required String accessToken,
  }) async {
    _verificarFalhaInjetada();
    ultimoAccessToken = accessToken;
    if (cadenas.isEmpty) return;
    semearCadenas(userId, cadenas);
  }

  @override
  Future<void> excluirCadenaRemota(
    String cadenaId, {
    required String userId,
    required String accessToken,
  }) async {
    _verificarFalhaInjetada();
    ultimoAccessToken = accessToken;
    _porUsuario[userId]?.remove(cadenaId);
  }
}
