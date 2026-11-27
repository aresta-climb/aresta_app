// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../constants/constantes_rede.dart';
import '../firebase/app_logger.dart';
import '../http/cliente_http_aresta.dart';
import 'armazenamento_clima_local.dart';
import 'calculadora_umidade_pico.dart';
import '../../data/modelos/modelos_clima_pico.dart';

/// Fronteira abstrata de rede para busca dos snapshots públicos de clima e altimetria.
abstract interface class FonteRemotaClimaAltimetria {
  /// Obtém o snapshot remoto de chuva regional (`estado_clima_picos`, ~3 KB) e,
  /// somente quando [incluirAltimetria] for verdadeiro, consulta `snapshots_altimetria_picos`
  /// (recorrendo ao slot `copia_seguranca` quando necessário).
  Future<SnapshotClimaAltimetria> buscarSnapshotRemoto({
    bool incluirAltimetria = false,
  });
}

/// Cliente PostgREST que lê `public.estado_clima_picos` e `public.snapshots_altimetria_picos`
/// no Supabase com suporte transparente aos slots `atual` e `copia_seguranca`.
class ClienteClimaAltimetriaSupabase implements FonteRemotaClimaAltimetria {
  final String urlBaseSupabase;
  final String chaveAnonima;
  final ClienteHttpAresta _clienteHttp;
  final Duration timeoutRequisicao;

  ClienteClimaAltimetriaSupabase({
    String? urlBaseSupabase,
    String? chaveAnonima,
    ClienteHttpAresta? clienteHttp,
    this.timeoutRequisicao = const Duration(seconds: 4),
  })  : urlBaseSupabase =
            (urlBaseSupabase ?? NetworkConstants.kDefaultSupabaseUrl)
                .replaceAll(RegExp(r'/+$'), ''),
        chaveAnonima = chaveAnonima ?? NetworkConstants.kDefaultSupabaseAnonKey,
        _clienteHttp = clienteHttp ?? ClienteHttpAresta.instancia;

  Map<String, String> get _cabecalhos {
    final headers = <String, String>{
      'apikey': chaveAnonima,
      'Accept': 'application/json',
    };
    if (chaveAnonima.startsWith('eyJ')) {
      headers['Authorization'] = 'Bearer $chaveAnonima';
    }
    return headers;
  }

  @override
  Future<SnapshotClimaAltimetria> buscarSnapshotRemoto({
    bool incluirAltimetria = false,
  }) async {
    final linhaClima = await _consultarComFallbackSlot('estado_clima_picos');
    final linhaAlt = incluirAltimetria
        ? await _consultarComFallbackSlot('snapshots_altimetria_picos')
        : null;

    return SnapshotClimaAltimetria.deMapa(<String, dynamic>{
      'gerado_em': linhaClima['gerado_em'] ?? linhaAlt?['gerado_em'],
      'bolhas_chuva': linhaClima['bolhas_chuva'] ?? const <dynamic>[],
      'bolhas_incendio': linhaClima['bolhas_incendio'] ?? const <dynamic>[],
      'chuva_por_pico':
          linhaClima['chuva_por_pico'] ?? const <String, dynamic>{},
      'altimetria_por_pico':
          linhaAlt?['altimetria_por_pico'] ?? const <String, dynamic>{},
    });
  }

  Future<Map<String, dynamic>> _consultarComFallbackSlot(String tabela) async {
    final atual = await _consultarSlot(tabela, 'atual');
    if (atual != null) return atual;

    final seguranca = await _consultarSlot(tabela, 'copia_seguranca');
    if (seguranca != null) {
      AppLogger.instance.logAviso(
        '[ClienteClimaAltimetriaSupabase] Slot atual vazio em $tabela; utilizando slot copia_seguranca.',
      );
      return seguranca;
    }

    throw HttpException('Nenhum registro encontrado em $tabela (atual/copia_seguranca).');
  }

