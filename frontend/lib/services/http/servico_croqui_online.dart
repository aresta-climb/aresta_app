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
  final bool Function(String picoId)? _verificarPicoBaixado;
  final void Function(String picoId, Croqui croqui)? _aoAtualizarCroqui;

  final Map<String, Timer> _timersPolling = {};

  ServicoCroquiOnline({
    http.Client? client,
    required GerenciadorSessaoOnline sessaoOnline,
    String? caminhoCacheVolatil,
    bool Function(String picoId)? verificarPicoBaixado,
    void Function(String picoId, Croqui croqui)? aoAtualizarCroqui,
  })  : _client = client ?? http.Client(),
        _sessaoOnline = sessaoOnline,
        _caminhoCacheVolatil = caminhoCacheVolatil,
        _verificarPicoBaixado = verificarPicoBaixado,
        _aoAtualizarCroqui = aoAtualizarCroqui;

  /// Retorna a instância do gerenciador de sessão online.
  GerenciadorSessaoOnline get sessaoOnline => _sessaoOnline;

  /// Retorna o caminho customizado para cache volátil, caso tenha sido configurado.
  String? get caminhoCacheVolatil => _caminhoCacheVolatil;

  /// Obtém o diretório de cache temporário volátil do sistema operacional.
  Future<String> obterDiretorioCache() => _obterDiretorioCache();

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
    String? checksumSha256,
  }) async {
    try {
      String? hashEfetivo = checksumSha256;
      final uriOriginal = Uri.parse(url);
      if (hashEfetivo == null || hashEfetivo.isEmpty) {
        hashEfetivo = uriOriginal.queryParameters['v'];
      }

      // Verificação prévia no cache volátil (temp_cache)
      if (hashEfetivo != null && hashEfetivo.isNotEmpty) {
        final cacheDir = await _obterDiretorioCache();
        final arquivoCache = File('$cacheDir/$picoId/compilado.binarypb.$hashEfetivo');
        if (await arquivoCache.exists()) {
          try {
            final bytes = await arquivoCache.readAsBytes();
            final croqui = Croqui.fromBuffer(bytes);
            _sessaoOnline.registrarCroquiOnline(picoId, croqui);
            return croqui;
          } catch (e) {
            AppLogger.instance.logAviso(
              '[ServicoCroquiOnline] Cache corrompido para $picoId, prosseguindo com download de rede: $e',
            );
          }
        }
      }

      // Montagem da URL garantindo parâmetro de versão v=<hash>
      Uri uri = uriOriginal;
      if (hashEfetivo != null && hashEfetivo.isNotEmpty && !uri.queryParameters.containsKey('v')) {
        final queryParams = Map<String, String>.from(uri.queryParameters);
        queryParams['v'] = hashEfetivo;
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final etag = response.headers['etag'];
        final bytes = response.bodyBytes;

        final croqui = Croqui.fromBuffer(bytes);
        await _salvarEmCacheVolatil(picoId, bytes, checksumSha256: hashEfetivo);

        _sessaoOnline.registrarCroquiOnline(picoId, croqui, etag: etag);
        return croqui;
      } else {
        AppLogger.instance.logError(
          '[ServicoCroquiOnline] Falha ao carregar croqui online $picoId. Status: ${response.statusCode}',
          stackTrace: StackTrace.current,
        );
      }
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        '[ServicoCroquiOnline] Erro de rede ao carregar croqui $picoId',
        error: e,
        stackTrace: stackTrace,
      );
    }
    return null;
  }

  /// Recarrega sob demanda o `.binarypb` de um croqui forçando bypass de cache HTTP com timestamp.
  ///
  /// Garante que proxies e CDNs intermediários não entreguem versões obsoletas durante eventos de recarga.
  Future<Croqui?> recarregarCroquiOnline(
    String url, {
    required String picoId,
    String? checksumSha256,
  }) async {
    try {
      final uri = Uri.parse(url);
      final queryParams = Map<String, String>.from(uri.queryParameters);
      queryParams['t'] = DateTime.now().millisecondsSinceEpoch.toString();
      final urlBypass = uri.replace(queryParameters: queryParams).toString();

      return await carregarCroquiRemoto(urlBypass, picoId: picoId, checksumSha256: checksumSha256);
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        '[ServicoCroquiOnline] Erro ao recarregar croqui online $picoId',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Salva uma cópia binária do croqui no diretório de cache volátil do sistema operacional,
  /// indexado pelo checksum quando disponível, e expurga versões anteriores divergentes.
  Future<void> _salvarEmCacheVolatil(
    String picoId,
    Uint8List bytes, {
    String? checksumSha256,
  }) async {
    try {
      final cacheDir = await _obterDiretorioCache();
      final picoCacheDir = Directory('$cacheDir/$picoId');
      if (!await picoCacheDir.exists()) {
        await picoCacheDir.create(recursive: true);
      }
      final nomeArquivo = (checksumSha256 != null && checksumSha256.isNotEmpty)
          ? 'compilado.binarypb.$checksumSha256'
          : 'compilado.binarypb';
      final cacheFile = File('${picoCacheDir.path}/$nomeArquivo');
      await cacheFile.writeAsBytes(bytes);

      _expurgarVersoesAntigas(picoCacheDir, nomeArquivo);
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        '[ServicoCroquiOnline] Falha ao gravar cache volátil',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Expurga arquivos de versões anteriores do croqui no diretório de cache temporário.
  void _expurgarVersoesAntigas(Directory picoCacheDir, String nomeArquivoSalvo) {
    try {
      if (!picoCacheDir.existsSync()) return;
      for (final entity in picoCacheDir.listSync()) {
        if (entity is File) {
          final fileName = entity.path.replaceAll(r'\', '/').split('/').last;
          if (fileName.startsWith('compilado.binarypb') && fileName != nomeArquivoSalvo) {
            try {
              entity.deleteSync();
            } catch (_) {}
          } else if (fileName.endsWith('.binarypb') && fileName != nomeArquivoSalvo) {
            try {
              entity.deleteSync();
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      AppLogger.instance.logAviso(
        '[ServicoCroquiOnline] Erro ao expurgar versões antigas no cache volátil: $e',
      );
    }
  }

  /// Executa uma verificação leve com cabeçalho `If-None-Match: <etag>` para checar atualizações remotas.
  Future<bool> verificarAtualizacaoEtag(
    String picoId,
    String url, {
    void Function(String picoId, Croqui croqui)? aoAtualizar,
  }) async {
    // Se o pico já está baixado no armazenamento local, cancela o polling e não faz requisição de rede
    if (_verificarPicoBaixado != null && _verificarPicoBaixado(picoId)) {
      cancelarPolling(picoId);
      AppLogger.instance.logInfo('[ServicoCroquiOnline] Cancelando polling de ETag: pico $picoId já está baixado offline.');
      return false;
    }

    // Se o pico não estiver mais na sessão online (foi baixado ou encerrado), encerra o polling
    if (_sessaoOnline.obterCroquiOnline(picoId) == null) {
      cancelarPolling(picoId);
      AppLogger.instance.logInfo('[ServicoCroquiOnline] Cancelando polling de ETag: pico $picoId não possui sessão online ativa.');
      return false;
    }

    try {
      final etagAtual = _sessaoOnline.obterEtag(picoId);
      final headers = <String, String>{};
      if (etagAtual != null && etagAtual.isNotEmpty) {
        headers['If-None-Match'] = etagAtual;
      }

      final uri = Uri.parse(url);
      final response = await _client.get(uri, headers: headers);

      if (response.statusCode == 304) {
        AppLogger.instance.logInfo('[ServicoCroquiOnline] ETag 304 Not Modified para $picoId');
        return false;
      } else if (response.statusCode == 200) {
        final novoEtag = response.headers['etag'] ?? '';
        AppLogger.instance.logInfo('[ServicoCroquiOnline] ETag 200 Nova versão detectada para $picoId ($novoEtag)');
        _sessaoOnline.registrarAtualizacaoPendente(picoId, novoEtag);

        final bytes = response.bodyBytes;
        if (bytes.isNotEmpty) {
          try {
            final croqui = Croqui.fromBuffer(bytes);
            await _salvarEmCacheVolatil(picoId, bytes);
            _sessaoOnline.registrarCroquiOnline(picoId, croqui, etag: novoEtag);
            _aoAtualizarCroqui?.call(picoId, croqui);
            aoAtualizar?.call(picoId, croqui);
          } catch (e, stackTrace) {
            AppLogger.instance.logError(
              '[ServicoCroquiOnline] Erro ao desserializar croqui atualizado no ETag',
              error: e,
              stackTrace: stackTrace,
            );
          }
        }
        return true;
      }
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        '[ServicoCroquiOnline] Erro durante verificação de ETag para $picoId',
        error: e,
        stackTrace: stackTrace,
      );
    }
    return false;
  }

  /// Inicia o polling periódico de ETag a cada [intervalo] enquanto o usuário navega no croqui.
  void iniciarPollingEtag(
    String picoId,
    String url, {
    Duration intervalo = const Duration(seconds: 30),
    void Function(String picoId, Croqui croqui)? aoAtualizar,
  }) {
    cancelarPolling(picoId);

    // Se o pico já está baixado no armazenamento local, não inicia polling desnecessário
    if (_verificarPicoBaixado != null && _verificarPicoBaixado(picoId)) {
      AppLogger.instance.logInfo('[ServicoCroquiOnline] Pico $picoId já está baixado offline. Polling de ETag ignorado.');
      return;
    }

    _timersPolling[picoId] = Timer.periodic(intervalo, (_) async {
      await verificarAtualizacaoEtag(picoId, url, aoAtualizar: aoAtualizar);
    });
  }

  /// Verifica se há um timer de polling ativo para o pico indicado.
  bool isPollingAtivo(String picoId) {
    return _timersPolling.containsKey(picoId);
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
