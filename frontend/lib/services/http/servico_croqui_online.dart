// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../aresta_api/proto/generated/croqui.pb.dart';
import '../firebase/app_logger.dart';
import '../dataset/sessao_online/gerenciador_sessao_online.dart';
import '../dataset/normalizador_croqui.dart';
import '../../utils/construtor_caminho_trajeto.dart';
import 'cliente_http_aresta.dart';

/// Serviço responsável pelo carregamento sob demanda de arquivos `.binarypb` via HTTP
/// e verificação periódica de ETag para atualizações em tempo real durante a navegação online.
class ServicoCroquiOnline {
  /// Timeouts escalonados por tentativa completa de requisição HTTP (DNS + TCP + TLS + body).
  ///
  /// Divide o orçamento de ~10 segundos em 2 tentativas independentes (`4s` + `6s`),
  /// evitando que um socket Keep-Alive zumbi (após troca de antena 4G/3G ou reciclagem de NAT)
  /// ou um buraco negro pós-TCP trave o download por todo o período sem tentar uma nova conexão.
  static const List<Duration> padraoTimeoutsTentativas = [
    Duration(seconds: 4),
    Duration(seconds: 6),
  ];

  /// Intervalo curto de espera entre a 1ª e a 2ª tentativa para permitir estabilização
  /// do rádio celular (*RRC Idle → Connected*) sem penalizar a resposta rápida em Modo Avião.
  static const Duration padraoIntervaloEntreTentativas =
      Duration(milliseconds: 350);

  final ClienteHttpAresta _client;
  final GerenciadorSessaoOnline _sessaoOnline;
  final String? _caminhoCacheVolatil;
  final bool Function(String picoId)? _verificarPicoBaixado;
  final bool Function()? _verificarLiveReloadAtivo;
  final void Function(String picoId, Croqui croqui)? _aoAtualizarCroqui;
  final List<Duration> _timeoutsTentativas;
  final Duration _intervaloEntreTentativas;

  final Map<String, Timer> _timersPolling = {};

  ServicoCroquiOnline({
    ClienteHttpAresta? client,
    required GerenciadorSessaoOnline sessaoOnline,
    String? caminhoCacheVolatil,
    bool Function(String picoId)? verificarPicoBaixado,
    bool Function()? verificarLiveReloadAtivo,
    void Function(String picoId, Croqui croqui)? aoAtualizarCroqui,
    List<Duration> timeoutsTentativas = padraoTimeoutsTentativas,
    Duration intervaloEntreTentativas = padraoIntervaloEntreTentativas,
  })  : _client = client ?? ClienteHttpAresta.instancia,
        _sessaoOnline = sessaoOnline,
        _caminhoCacheVolatil = caminhoCacheVolatil,
        _verificarPicoBaixado = verificarPicoBaixado,
        _verificarLiveReloadAtivo = verificarLiveReloadAtivo,
        _aoAtualizarCroqui = aoAtualizarCroqui,
        _timeoutsTentativas = timeoutsTentativas,
        _intervaloEntreTentativas = intervaloEntreTentativas;

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
            final croqui = NormalizadorCroqui.deBuffer(bytes);
            _sessaoOnline.registrarCroquiOnline(
              picoId,
              croqui,
              checksumSha256: hashEfetivo,
            );
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

      final response = await _buscarComRetentativas(uri, picoId);

      if (response.statusCode == 200) {
        final etag = response.headers['etag'];
        final bytes = response.bodyBytes;

        // NOTA ARQUITETURAL CRÍTICA (Cache Eviction na CDN vs. Sobrescrita no R2):
        // O carregamento online do croqui é disparado de forma otimista (1 RTT) usando o
        // `?v=<hash_do_indice_local>` sem aguardar um `syncIndex()` bloqueante antes.
        // Embora a Cloudflare CDN possua TTL de 1 ano e Smart Tiered Cache ativo, o cache
        // de borda/upper-tier opera sob política LRU (Least Recently Used) e pode despejar
        // entradas pouco acessadas. Se ocorrer `MISS` na CDN para `?v=<hash_antigo>` após um
        // deploy ter atualizado o pico, a requisição bate no bucket Cloudflare R2, que
        // armazena apenas a versão mais recente em `v1/<picoId>/compilado.binarypb`
        // (ignorando a query string `?v=`) e devolve os bytes da versão NOVA!
        // Por isso, calculamos o SHA-256 real em memória RAM (~0,3 ms) na chegada da
        // resposta HTTP antes de gravar no disco: isso garante que o arquivo em `temp_cache`
        // e o registro na sessão online reflitam o hash verdadeiro do binário recebido,
        // permitindo que o `syncIndex()` em background reconheça que já temos a versão nova.
        final hashReal = sha256.convert(bytes).toString();
        final croqui = NormalizadorCroqui.deBuffer(bytes);
        await _salvarEmCacheVolatil(
          picoId,
          bytes,
          checksumSha256: hashReal,
        );

        _sessaoOnline.registrarCroquiOnline(
          picoId,
          croqui,
          etag: etag,
          checksumSha256: hashReal,
        );
        return croqui;
      } else {
        AppLogger.instance.logFalhaSyncOuDownload(
          '[ServicoCroquiOnline] Falha ao carregar croqui online $picoId. Status: ${response.statusCode}',
          error: response.statusCode,
          stackTrace: StackTrace.current,
        );
      }
    } catch (e, stackTrace) {
      AppLogger.instance.logFalhaSyncOuDownload(
        '[ServicoCroquiOnline] Erro de rede ao carregar croqui $picoId',
        error: e,
        stackTrace: stackTrace,
      );
    }
    return await _carregarVersaoAnteriorDoCacheVolatil(picoId);
  }

  /// Executa o GET HTTP com até `[_timeoutsTentativas.length]` tentativas escalonadas,
  /// repetindo apenas em falhas de conexão/timeout ou status HTTP transitórios (502/503/504/429).
  Future<Response> _buscarComRetentativas(Uri uri, String picoId) async {
    final totalTentativas = _timeoutsTentativas.length;
    for (var i = 0; ; i++) {
      final ehUltimaTentativa = i >= totalTentativas - 1;
      try {
        final response = await _client.get(uri).timeout(_timeoutsTentativas[i]);
        if (!ehUltimaTentativa &&
            AppLogger.isFalhaConexaoOuTimeout(response.statusCode)) {
          AppLogger.instance.logAviso(
            '[ServicoCroquiOnline] Status transitório ${response.statusCode} na tentativa ${i + 1}/$totalTentativas para $picoId; retentando...',
          );
          await Future<void>.delayed(_intervaloEntreTentativas);
          continue;
        }
        return response;
      } catch (e) {
        if (ehUltimaTentativa) rethrow;
        AppLogger.instance.logAviso(
          '[ServicoCroquiOnline] Falha na tentativa ${i + 1}/$totalTentativas ao baixar croqui $picoId; retentando após ${_intervaloEntreTentativas.inMilliseconds}ms: $e',
        );
        await Future<void>.delayed(_intervaloEntreTentativas);
      }
    }
  }

  /// Procura e carrega qualquer versão anterior de `compilado.binarypb.<hash>`
  /// presente no diretório de cache volátil do pico como salva-vidas quando a rede falha.
  Future<Croqui?> _carregarVersaoAnteriorDoCacheVolatil(String picoId) async {
    final cacheDir = await _obterDiretorioCache();
    final picoCacheDir = Directory('$cacheDir/$picoId');
    if (!await picoCacheDir.exists()) return null;

    const prefixo = 'compilado.binarypb.';
    for (final entity in picoCacheDir.listSync()) {
      if (entity is File) {
        final fileName = entity.path.replaceAll(r'\', '/').split('/').last;
        if (fileName.startsWith(prefixo) && !fileName.endsWith('.tmp')) {
          try {
            final bytes = await entity.readAsBytes();
            final croqui = NormalizadorCroqui.deBuffer(bytes);
            final hashAnterior = fileName.substring(prefixo.length);
            _sessaoOnline.registrarCroquiOnline(
              picoId,
              croqui,
              checksumSha256: hashAnterior,
            );
            return croqui;
          } catch (e) {
            AppLogger.instance.logAviso(
              '[ServicoCroquiOnline] Cache anterior corrompido ignorado para $picoId ($fileName): $e',
            );
          }
        }
      }
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
      AppLogger.instance.logFalhaSyncOuDownload(
        '[ServicoCroquiOnline] Erro ao recarregar croqui online $picoId',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Salva atomicamente (via `.tmp` + rename) uma cópia binária do croqui no diretório de
  /// cache volátil do sistema operacional, indexado pelo [checksumSha256] real, e expurga
  /// versões anteriores divergentes somente após a conclusão da gravação.
  Future<void> _salvarEmCacheVolatil(
    String picoId,
    Uint8List bytes, {
    required String checksumSha256,
  }) async {
    try {
      final cacheDir = await _obterDiretorioCache();
      final picoCacheDir = Directory('$cacheDir/$picoId');
      if (!await picoCacheDir.exists()) {
        await picoCacheDir.create(recursive: true);
      }
      final nomeArquivo = 'compilado.binarypb.$checksumSha256';
      final caminhoFinal = '${picoCacheDir.path}/$nomeArquivo';
      final cacheTmpFile = File('$caminhoFinal.tmp');
      await cacheTmpFile.writeAsBytes(bytes, flush: true);
      await cacheTmpFile.rename(caminhoFinal);

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
    for (final entity in picoCacheDir.listSync()) {
      if (entity is File) {
        final fileName = entity.path.replaceAll(r'\', '/').split('/').last;
        if (fileName != nomeArquivoSalvo &&
            (fileName.startsWith('compilado.binarypb') ||
                fileName.endsWith('.binarypb'))) {
          try {
            entity.deleteSync();
          } catch (_) {}
        }
      }
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

    // Se o canal push de Live Reload via WebSocket estiver conectado, mantém o polling dormente
    if (_verificarLiveReloadAtivo != null && _verificarLiveReloadAtivo()) {
      AppLogger.instance.logInfo(
        '[ServicoCroquiOnline] Polling de ETag dormente para $picoId: WebSocket de Live Reload conectado.',
      );
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
            final hashReal = sha256.convert(bytes).toString();
            final croqui = NormalizadorCroqui.deBuffer(bytes);
            await _salvarEmCacheVolatil(
              picoId,
              bytes,
              checksumSha256: hashReal,
            );
            _sessaoOnline.registrarCroquiOnline(
              picoId,
              croqui,
              etag: novoEtag,
              checksumSha256: hashReal,
            );
            ConstrutorCaminhoTrajeto.limparCache();
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
      if (AppLogger.isFalhaConexaoOuTimeout(e)) {
        AppLogger.instance.logAviso(
          '[ServicoCroquiOnline] Verificação de ETag ignorada: sem conexão com a internet ($picoId)',
        );
      } else {
        AppLogger.instance.logError(
          '[ServicoCroquiOnline] Erro durante verificação de ETag para $picoId',
          error: e,
          stackTrace: stackTrace,
        );
      }
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

  /// Descarta todos os timers de polling ativos sem fechar o cliente HTTP compartilhado.
  void dispose() {
    for (var timer in _timersPolling.values) {
      timer.cancel();
    }
    _timersPolling.clear();
  }
}
