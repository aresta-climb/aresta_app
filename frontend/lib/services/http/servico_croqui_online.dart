// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../aresta_api/proto/generated/croqui.pb.dart';
import '../firebase/app_logger.dart';
import '../dataset/sessao_online/gerenciador_sessao_online.dart';

/// Serviço responsável pelo carregamento sob demanda de arquivos `.binarypb` via HTTP
/// e verificação periódica de ETag para atualizações em tempo real durante a navegação online.
class ServicoCroquiOnline {
  final http.Client _client;
  final GerenciadorSessaoOnline _sessaoOnline;
  final String? _caminhoCacheVolatil;

  final Map<String, Timer> _timersPolling = {};

  ServicoCroquiOnline({
    http.Client? client,
    required GerenciadorSessaoOnline sessaoOnline,
    String? caminhoCacheVolatil,
  })  : _client = client ?? http.Client(),
        _sessaoOnline = sessaoOnline,
        _caminhoCacheVolatil = caminhoCacheVolatil;

  /// Obtém o diretório de cache temporário volátil do sistema operacional.
  Future<String> _obterDiretorioCache() async {
    if (_caminhoCacheVolatil != null) {
      return _caminhoCacheVolatil;
    }
    final tempDir = await getTemporaryDirectory();
    return '${tempDir.path}/temp_cache';
  }

  /// Baixa o `.binarypb` a partir da [url] remota, salva no cache volátil e registra na sessão online.
  Future<Croqui?> carregarCroquiRemoto(
    String url, {
    required String picoId,
  }) async {
    try {
      final uri = Uri.parse(url);
      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final etag = response.headers['etag'];
        final bytes = response.bodyBytes;

        final croqui = Croqui.fromBuffer(bytes);

        // Salva cópia no cache temporário volátil
        try {
          final cacheDir = await _obterDiretorioCache();
          final picoCacheDir = Directory('$cacheDir/$picoId');
          if (!await picoCacheDir.exists()) {
            await picoCacheDir.create(recursive: true);
          }
          final cacheFile = File('${picoCacheDir.path}/$picoId.binarypb');
          await cacheFile.writeAsBytes(bytes);
        } catch (e) {
          debugPrint('[ServicoCroquiOnline] Aviso: falha ao gravar cache volátil: $e');
        }

        _sessaoOnline.registrarCroquiOnline(picoId, croqui, etag: etag);
        return croqui;
      } else {
        AppLogger.instance.logError(
          '[ServicoCroquiOnline] Falha ao carregar croqui online $picoId. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.instance.logError(
        '[ServicoCroquiOnline] Erro de rede ao carregar croqui $picoId',
        error: e,
      );
    }
    return null;
  }

  /// Executa uma verificação leve com cabeçalho `If-None-Match: <etag>` para checar atualizações remotas.
  Future<bool> verificarAtualizacaoEtag(
    String picoId,
    String url,
  ) async {
    try {
      final etagAtual = _sessaoOnline.obterEtag(picoId);
      final headers = <String, String>{};
      if (etagAtual != null && etagAtual.isNotEmpty) {
        headers['If-None-Match'] = etagAtual;
      }

      final uri = Uri.parse(url);
      final response = await _client.get(uri, headers: headers);

      if (response.statusCode == 304) {
        debugPrint('[ServicoCroquiOnline] ETag 304 Not Modified para $picoId');
        return false;
      } else if (response.statusCode == 200) {
        final novoEtag = response.headers['etag'] ?? '';
        debugPrint('[ServicoCroquiOnline] ETag 200 Nova versão detectada para $picoId ($novoEtag)');
        _sessaoOnline.registrarAtualizacaoPendente(picoId, novoEtag);
        return true;
      }
    } catch (e) {
      debugPrint('[ServicoCroquiOnline] Erro durante verificação de ETag para $picoId: $e');
    }
    return false;
  }

  /// Inicia o polling periódico de ETag a cada [intervalo] enquanto o usuário navega no croqui.
  void iniciarPollingEtag(
    String picoId,
    String url, {
    Duration intervalo = const Duration(seconds: 30),
  }) {
    cancelarPolling(picoId);
    _timersPolling[picoId] = Timer.periodic(intervalo, (_) {
      verificarAtualizacaoEtag(picoId, url);
    });
  }

  /// Cancela o polling de verificação de ETag para o pico indicado.
  void cancelarPolling(String picoId) {
    _timersPolling[picoId]?.cancel();
    _timersPolling.remove(picoId);
  }

  /// Descarta todos os timers e fecha o cliente HTTP.
  void dispose() {
    for (var timer in _timersPolling.values) {
      timer.cancel();
    }
    _timersPolling.clear();
    _client.close();
  }
}
