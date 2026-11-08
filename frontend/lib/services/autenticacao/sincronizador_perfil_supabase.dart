// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import '../../data/modelos/perfil_escalador.dart';
import '../../utils/gerador_uid.dart';
import '../http/cliente_http_aresta.dart';
import 'servico_autenticacao.dart';

/// Serviço modular responsável por sincronizar metadados do perfil do escalador
/// com a tabela `public.perfis` (PostgREST), o bucket `avatars` (Supabase Storage)
/// e os metadados de conta no GoTrue (`PUT /auth/v1/user`).
class SincronizadorPerfilSupabase {
  final ClienteHttpAresta _clienteHttp;

  /// Cria uma instância de [SincronizadorPerfilSupabase].
  SincronizadorPerfilSupabase({ClienteHttpAresta? clienteHttp})
    : _clienteHttp = clienteHttp ?? ClienteHttpAresta.instancia;

  /// Extrai os campos de identidade do payload `user` retornado pelo GoTrue e
  /// sincroniza com a tabela `public.perfis` quando há um [accessToken] ativo.
  Future<ResultadoProvedorAutenticacao> extrairESincronizarUsuario({
    required String baseUrl,
    required String anonKey,
    required String? accessToken,
    required Map<String, dynamic> usuario,
    required String autorIdPublicoLocal,
    required String nomeFallback,
  }) async {
    final userId = usuario['id'].toString();
    final metadados = usuario['user_metadata'] as Map<String, dynamic>?;
    var nomeEfetivo =
        (metadados?['autor_nome_publico'] ??
                metadados?['full_name'] ??
                metadados?['name'])
            as String? ??
        nomeFallback;
    var fotoEfetiva =
        (metadados?['foto_url'] ??
                metadados?['avatar_url'] ??
                metadados?['picture'])
            as String?;
    var autorIdEfetivo = validarUid(metadados?['autor_id_publico'] as String?)
        ? (metadados!['autor_id_publico'] as String)
        : autorIdPublicoLocal;

    if (accessToken != null && accessToken.isNotEmpty) {
      final sincronizado = await sincronizarLinhaPerfis(
        baseUrl: baseUrl,
        anonKey: anonKey,
        accessToken: accessToken,
        userId: userId,
        autorIdPublico: autorIdEfetivo,
        nomePublico: nomeEfetivo,
        fotoUrl: fotoEfetiva,
      );
      autorIdEfetivo = sincronizado.autorIdPublico;
      nomeEfetivo = sincronizado.nomePublico;
      fotoEfetiva = sincronizado.fotoUrl ?? fotoEfetiva;
    }

    return ResultadoProvedorAutenticacao(
      userId: userId,
      nomeExibicao: nomeEfetivo,
      fotoUrl: fotoEfetiva,
      accessToken: accessToken,
      autorIdPublicoRemoto: autorIdEfetivo,
    );
  }
}
