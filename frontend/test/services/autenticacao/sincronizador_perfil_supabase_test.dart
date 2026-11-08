// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/autenticacao/sincronizador_perfil_supabase.dart';
import 'package:frontend/services/http/cliente_http_aresta.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('SincronizadorPerfilSupabase', () {
    const baseUrl = 'https://yzkhiaoqtxvvcyyuwmqg.supabase.co';
    const anonKey = 'anon-key-teste';
    const idLocal = 'x8siJek3FiG3aB';

    test('extrairESincronizarUsuario lê linha existente em public.perfis ou faz upsert quando vazia', () async {
      final requisicoes = <http.Request>[];
      final clienteHttp = ClienteHttpAresta.paraTestes(
        MockClient((request) async {
          requisicoes.add(request);
          if (request.url.path.endsWith('/rest/v1/perfis')) {
            if (request.method == 'GET') {
              if (request.url.queryParameters['user_id'] == 'eq.usr-existente') {
                return http.Response(
                  jsonEncode([
                    {
                      'autor_id_publico': 'r9siJek3FiG3aZ',
                      'autor_nome_publico': 'Nome Do Banco',
                      'avatar_url': 'https://supabase.co/avatar.webp',
                    },
                  ]),
                  200,
                );
              }
              return http.Response(jsonEncode([]), 200);
            }
            return http.Response(jsonEncode([{}]), 201);
          }
          return http.Response('{}', 404);
        }),
      );

      final sincronizador = SincronizadorPerfilSupabase(clienteHttp: clienteHttp);

      // 1. Linha já existente em public.perfis sobrescreve metadados locais
      final resExistente = await sincronizador.extrairESincronizarUsuario(
        baseUrl: baseUrl,
        anonKey: anonKey,
        accessToken: 'jwt-1',
        usuario: {
          'id': 'usr-existente',
          'user_metadata': {
            'autor_id_publico': 'm9siJek3FiG3aZ',
            'autor_nome_publico': 'Nome Meta',
          },
        },
        autorIdPublicoLocal: idLocal,
        nomeFallback: 'Fallback',
      );
      expect(resExistente.userId, equals('usr-existente'));
      expect(resExistente.autorIdPublicoRemoto, equals('r9siJek3FiG3aZ'));
      expect(resExistente.nomeExibicao, equals('Nome Do Banco'));
      expect(resExistente.fotoUrl, equals('https://supabase.co/avatar.webp'));

      // 2. Linha inexistente em public.perfis aciona upsert com dados do metadado/fallback
      final resNovo = await sincronizador.extrairESincronizarUsuario(
        baseUrl: baseUrl,
        anonKey: anonKey,
        accessToken: 'jwt-2',
        usuario: {'id': 'usr-novo'},
        autorIdPublicoLocal: idLocal,
        nomeFallback: 'Novo Escalador',
      );
      expect(resNovo.userId, equals('usr-novo'));
      expect(resNovo.autorIdPublicoRemoto, equals(idLocal));
      expect(resNovo.nomeExibicao, equals('Novo Escalador'));
      expect(
        requisicoes.any(
          (r) => r.url.path.endsWith('/rest/v1/perfis') && r.method == 'POST',
        ),
        isTrue,
      );

      // 3. Sem accessToken (confirmação pendente), não realiza chamadas PostgREST
      final resPendente = await SincronizadorPerfilSupabase()
          .extrairESincronizarUsuario(
            baseUrl: baseUrl,
            anonKey: anonKey,
            accessToken: null,
            usuario: {'id': 'usr-pendente'},
            autorIdPublicoLocal: idLocal,
            nomeFallback: 'Pendente',
          );
      expect(resPendente.accessToken, isNull);
      expect(resPendente.nomeExibicao, equals('Pendente'));
    });

    test('extrairESincronizarUsuario respeita prioridade de metadados OAuth (full_name/name, avatar_url/picture) e rejeita NanoID inválido', () async {
      final clienteHttp = ClienteHttpAresta.paraTestes(
        MockClient((request) async {
          if (request.method == 'GET') {
            return http.Response(
              jsonEncode([
                {
                  'autor_id_publico': 'id-curto-invalido',
                  'autor_nome_publico': '   ',
                  'foto_url': '',
                },
              ]),
              200,
            );
          }
          return http.Response('{}', 201);
        }),
      );
      final sincronizador = SincronizadorPerfilSupabase(clienteHttp: clienteHttp);

      final resFullName = await sincronizador.extrairESincronizarUsuario(
        baseUrl: baseUrl,
        anonKey: anonKey,
        accessToken: 'jwt-oauth',
        usuario: {
          'id': 'usr-oauth-1',
          'user_metadata': {
            'autor_id_publico': 'invalido',
            'full_name': 'Escaladora Google',
            'picture': 'https://lh3.googleusercontent.com/foto.webp',
          },
        },
        autorIdPublicoLocal: idLocal,
        nomeFallback: 'Fallback',
      );
      expect(resFullName.autorIdPublicoRemoto, equals(idLocal));
      expect(resFullName.nomeExibicao, equals('Escaladora Google'));
      expect(
        resFullName.fotoUrl,
        equals('https://lh3.googleusercontent.com/foto.webp'),
      );

      final resName = await sincronizador.extrairESincronizarUsuario(
        baseUrl: baseUrl,
        anonKey: anonKey,
        accessToken: null,
        usuario: {
          'id': 'usr-oauth-2',
          'user_metadata': {
            'name': 'Escalador Apple',
            'avatar_url': 'https://apple.com/avatar.webp',
          },
        },
        autorIdPublicoLocal: idLocal,
        nomeFallback: 'Fallback',
      );
      expect(resName.nomeExibicao, equals('Escalador Apple'));
      expect(resName.fotoUrl, equals('https://apple.com/avatar.webp'));
    });
  });
}
