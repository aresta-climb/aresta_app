// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';
import '../../data/modelos/perfil_escalador.dart';
import '../../utils/gerador_uid.dart';
import '../firebase/app_logger.dart';
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

  void _registrarFalhaSincronizacao(
    String contexto,
    Object erro,
    StackTrace stackTrace,
  ) {
    if (AppLogger.isFalhaConexaoOuTimeout(erro)) {
      AppLogger.instance.logAviso('$contexto ($erro)');
    } else {
      AppLogger.instance.logError(
        contexto,
        error: erro,
        stackTrace: stackTrace,
      );
    }
  }

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

  /// Sincroniza alterações de nome e foto de perfil com o Supabase Storage (`avatars/<userId>/avatar.webp`),
  /// GoTrue (`PUT /auth/v1/user`) e PostgREST (`public.perfis`).
  ///
  /// Retorna a URL pública definitiva da foto (ou a [fotoFinal] original em fallback).
  Future<String?> sincronizarPerfilAtualizado({
    required String baseUrl,
    required String anonKey,
    required String accessToken,
    required String userId,
    required String autorIdPublico,
    required String nomeFinal,
    required String? fotoFinal,
  }) async {
    var urlFotoResolvida = fotoFinal;

    if (fotoFinal != null && fotoFinal.startsWith('data:image/')) {
      final urlStorage = await enviarAvatarParaStorage(
        baseUrl: baseUrl,
        anonKey: anonKey,
        accessToken: accessToken,
        userId: userId,
        dataUri: fotoFinal,
      );
      if (urlStorage != null) {
        urlFotoResolvida = urlStorage;
      }
    }

    await atualizarMetadadosAuthUsuario(
      baseUrl: baseUrl,
      anonKey: anonKey,
      accessToken: accessToken,
      autorIdPublico: autorIdPublico,
      nomePublico: nomeFinal,
      fotoUrl: urlFotoResolvida,
    );

    await upsertLinhaPerfis(
      baseUrl: baseUrl,
      anonKey: anonKey,
      accessToken: accessToken,
      userId: userId,
      autorIdPublico: autorIdPublico,
      nomePublico: nomeFinal,
      fotoUrl: urlFotoResolvida,
    );

    return urlFotoResolvida;
  }

  /// Consulta a linha do escalador em `public.perfis` ou realiza upsert inicial caso ainda não exista.
  Future<({String autorIdPublico, String nomePublico, String? fotoUrl})>
  sincronizarLinhaPerfis({
    required String baseUrl,
    required String anonKey,
    required String accessToken,
    required String userId,
    required String autorIdPublico,
    required String nomePublico,
    required String? fotoUrl,
  }) async {
    var idFinal = autorIdPublico;
    var nomeFinal = nomePublico;
    var fotoFinal = fotoUrl;
    final uri = Uri.parse(
      '$baseUrl/rest/v1/perfis?user_id=eq.$userId&select=autor_id_publico,autor_nome_publico,avatar_url',
    );

    try {
      final consulta = await _clienteHttp.get(
        uri,
        headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (consulta.statusCode >= 200 && consulta.statusCode < 300) {
        final lista = jsonDecode(consulta.body) as List<dynamic>;
        if (lista.isNotEmpty) {
          final linha = lista.first as Map<String, dynamic>;
          final idBanco = linha['autor_id_publico'] as String?;
          final nomeBanco = linha['autor_nome_publico'] as String?;
          final fotoBanco = linha['avatar_url'] as String?;
          if (validarUid(idBanco)) {
            idFinal = idBanco!;
          }
          if (nomeBanco != null &&
              nomeBanco.trim().isNotEmpty &&
              nomeBanco != PerfilEscalador.apelidoPadrao) {
            nomeFinal = nomeBanco.trim();
          }
          if (fotoBanco != null && fotoBanco.trim().isNotEmpty) {
            fotoFinal = fotoBanco.trim();
          }
        } else {
          await upsertLinhaPerfis(
            baseUrl: baseUrl,
            anonKey: anonKey,
            accessToken: accessToken,
            userId: userId,
            autorIdPublico: idFinal,
            nomePublico: nomeFinal,
            fotoUrl: fotoFinal,
          );
        }
      } else {
        throw HttpException(
          'HTTP ${consulta.statusCode}: ${consulta.body}',
          uri: uri,
        );
      }
    } catch (e, stackTrace) {
      _registrarFalhaSincronizacao(
        'Falha ao consultar public.perfis no Supabase',
        e,
        stackTrace,
      );
    }

    return (
      autorIdPublico: idFinal,
      nomePublico: nomeFinal,
      fotoUrl: fotoFinal,
    );
  }

  /// Envia os bytes decodificados de [dataUri] para `avatars/<userId>/avatar.webp` no Supabase Storage.
  Future<String?> enviarAvatarParaStorage({
    required String baseUrl,
    required String anonKey,
    required String accessToken,
    required String userId,
    required String dataUri,
  }) async {
    final indiceVirgula = dataUri.indexOf(',');
    if (indiceVirgula == -1) return null;
    final caminhoObjeto = '$userId/avatar.webp';
    final uri = Uri.parse('$baseUrl/storage/v1/object/avatars/$caminhoObjeto');
    try {
      final bytesImagem = base64Decode(dataUri.substring(indiceVirgula + 1));
      final respStorage = await _clienteHttp.post(
        uri,
        headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'image/webp',
          'x-upsert': 'true',
        },
        body: bytesImagem,
      );
      if (respStorage.statusCode >= 200 && respStorage.statusCode < 300) {
        return '$baseUrl/storage/v1/object/public/avatars/$caminhoObjeto?t=${DateTime.now().millisecondsSinceEpoch}';
      }
      throw HttpException(
        'HTTP ${respStorage.statusCode}: ${respStorage.body}',
        uri: uri,
      );
    } catch (e, stackTrace) {
      _registrarFalhaSincronizacao(
        'Falha ao enviar avatar para o Supabase Storage',
        e,
        stackTrace,
      );
    }
    return null;
  }

  /// Atualiza os metadados públicos do usuário (`user_metadata`) no GoTrue (`PUT /auth/v1/user`).
  Future<void> atualizarMetadadosAuthUsuario({
    required String baseUrl,
    required String anonKey,
    required String accessToken,
    required String autorIdPublico,
    required String nomePublico,
    required String? fotoUrl,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/v1/user');
    try {
      final reqPut = Request('PUT', uri)
        ..headers.addAll({
          'apikey': anonKey,
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        })
        ..body = jsonEncode({
          'data': {
            'autor_id_publico': autorIdPublico,
            'autor_nome_publico': nomePublico,
            'avatar_url': ?fotoUrl,
          },
        });
      final resposta = await _clienteHttp.send(reqPut);
      final corpo = await resposta.stream.bytesToString();
      if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
        throw HttpException('HTTP ${resposta.statusCode}: $corpo', uri: uri);
      }
    } catch (e, stackTrace) {
      _registrarFalhaSincronizacao(
        'Falha ao atualizar metadados do usuário no Supabase Auth',
        e,
        stackTrace,
      );
    }
  }

  /// Realiza upsert da linha do escalador na tabela `public.perfis` via PostgREST.
  Future<void> upsertLinhaPerfis({
    required String baseUrl,
    required String anonKey,
    required String accessToken,
    required String userId,
    required String autorIdPublico,
    required String nomePublico,
    required String? fotoUrl,
  }) async {
    final uri = Uri.parse('$baseUrl/rest/v1/perfis?on_conflict=user_id');
    try {
      final resposta = await _clienteHttp.post(
        uri,
        headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Prefer': 'resolution=merge-duplicates',
        },
        body: jsonEncode({
          'user_id': userId,
          'autor_id_publico': autorIdPublico,
          'autor_nome_publico': nomePublico,
          'avatar_url': ?fotoUrl,
        }),
      );
      if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
        throw HttpException(
          'HTTP ${resposta.statusCode}: ${resposta.body}',
          uri: uri,
        );
      }
    } catch (e, stackTrace) {
      _registrarFalhaSincronizacao(
        'Falha ao realizar upsert em public.perfis no Supabase',
        e,
        stackTrace,
      );
    }
  }
}
