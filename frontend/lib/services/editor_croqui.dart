// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import 'package:frontend/services/firebase/remote_config_service.dart';
import 'package:yaml/yaml.dart';

/// Evento disparado quando o Editor Desktop solicita uma atualização em tempo real (Live Reload).
class LiveReloadEvent {
  final String? setorId;
  final DateTime timestamp;

  const LiveReloadEvent({this.setorId, required this.timestamp});
}

/// Gerencia a conexão com um repositório editor externo (servidor local) e o modo experimental.
class EditorDeCroqui {
  static String get _officialBaseUrl =>
      RemoteConfigService.instance.officialServerUrl;
  static const String _configFileName = 'editor_config.yaml';
  static const String dominioPrevia = 'previa.arestaclimb.com';

  static EditorDeCroqui? _instance;
  static EditorDeCroqui get instance {
    assert(_instance != null, 'EditorDeCroqui não foi inicializado.');
    return _instance!;
  }

  /// URL do editor ativo. Null = modo oficial.
  final ValueNotifier<String?> editorUrl = ValueNotifier(null);

  /// Se o modo experimental (zip importado) está ativo.
  final ValueNotifier<bool> isExperimentalMode = ValueNotifier(false);

  /// Se as opções de desenvolvedor/experimental estão visíveis na UI.
  final ValueNotifier<bool> isDevModeEnabled = ValueNotifier(false);

  /// Tempo restante para a auto-destruição dos dados experimentais.
  final ValueNotifier<Duration?> timeRemaining = ValueNotifier(null);

  /// Notificador de eventos push de recarregamento em tempo real.
  final ValueNotifier<LiveReloadEvent?> eventoLiveReload = ValueNotifier(null);

  /// Notificador de gatilho para feedback visual de recarga (pulso luminoso no banner).
  final ValueNotifier<int> notificadorGatilhoRecarregamento = ValueNotifier(0);

  /// Dispara um pulso de recarregamento para animar o feedback visual nos componentes ouvintes.
  void dispararPulsoRecarregamento() {
    notificadorGatilhoRecarregamento.value++;
  }

  DateTime? _expirationTime;
  Timer? _countdownTimer;
  WebSocket? _wsLiveReload;

  EditorDeCroqui() {
    _instance = this;
  }

  String get activeBaseUrl {
    if (!isExperimentalMode.value) return _officialBaseUrl;

    String? url = editorUrl.value;
    if (url == null || url.isEmpty) return '';

    // Garante que tenha scheme
    if (!url.contains('://')) {
      url = 'https://$url';
    }

    return url;
  }

  bool get isEditorActive => isExperimentalMode.value;

  /// Normaliza códigos de 8 caracteres alfanuméricos em Base36.
  static String normalizarCodigo(String codigo) {
    return codigo.replaceAll(RegExp(r'[\s\-]+'), '').toLowerCase();
  }

  /// Formata um código de 8 caracteres adicionando um hífen no meio para facilitar a leitura (ex: k9x2-p83a).
  static String formatarCodigo(String codigo) {
    final norm = normalizarCodigo(codigo);
    if (norm.length == 8) {
      return '${norm.substring(0, 4)}-${norm.substring(4)}';
    }
    return norm;
  }

  /// Extrai o código de 8 caracteres de uma URL canônica previa.arestaclimb.com ou de uma string digitada.
  /// Suporta tanto o formato contínuo ("abcdefgh") quanto o formato com hífen ("abcd-efgh").
  static String? extrairCodigoPrevia(String input) {
    final limpo = input.trim();
    if (limpo.isEmpty) return null;

    final uri = Uri.tryParse(limpo.contains('://') ? limpo : 'https://$limpo');
    if (uri != null) {
      if (uri.host.toLowerCase() == dominioPrevia ||
          (uri.scheme == 'aresta' && uri.host == 'previa')) {
        final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
        if (segments.isNotEmpty) {
          final code = normalizarCodigo(segments.first);
          if (code.length == 8 && RegExp(r'^[0-9a-z]{8}$').hasMatch(code)) {
            return code;
          }
        }
      }
    }

    // Se for apenas o código digitado
    final direto = normalizarCodigo(limpo);
    if (direto.length == 8 && RegExp(r'^[0-9a-z]{8}$').hasMatch(direto)) {
      return direto;
    }

    return null;
  }

  /// Constrói a URL canônica de prévia a partir de um código (com hífen por padrão para legibilidade: https://previa.arestaclimb.com/abcd-efgh).
  static String urlPreviaParaCodigo(String codigo, {bool comHifen = true}) {
    final norm = normalizarCodigo(codigo);
    final codExibicao = (comHifen && norm.length == 8)
        ? '${norm.substring(0, 4)}-${norm.substring(4)}'
        : norm;
    return 'https://$dominioPrevia/$codExibicao';
  }

  /// Resolve a melhor URL (Direct LAN vs Cloudflare Relay) testando a rede local concorrentemente.
  Future<String> resolverUrlHibrida(
    String codigoOuUrl, {
    http.Client? client,
    Duration timeoutLan = const Duration(milliseconds: 1000),
  }) async {
    final codigo = extrairCodigoPrevia(codigoOuUrl);
    if (codigo == null) {
      return codigoOuUrl;
    }

    final httpClient = client ?? http.Client();
    final urlRelay = urlPreviaParaCodigo(codigo);

    try {
      // 1. Consulta metadados da sessão na Cloudflare
      final infoResponse = await httpClient
          .get(Uri.parse('$urlRelay/info'))
          .timeout(const Duration(seconds: 3));

      if (infoResponse.statusCode == 200) {
        final data = jsonDecode(infoResponse.body) as Map<String, dynamic>;
        final localUrl = data['local_url'] as String?;

        if (localUrl != null && localUrl.isNotEmpty) {
          // 2. Dispara teste rápido na rede local (Direct LAN)
          try {
            final handshakeResponse = await httpClient
                .get(Uri.parse('$localUrl/handshake'))
                .timeout(timeoutLan);

            if (handshakeResponse.statusCode == 200) {
              AppLogger.instance.logInfo(
                '[EditorCroqui] Conectado via Direct LAN: $localUrl',
              );
              return localUrl;
            }
          } catch (_) {
            // LAN inalcançável (4G ou isolamento de rede)
          }
        }
      }
    } catch (e) {
      AppLogger.instance.logInfo(
        '[EditorCroqui] Descoberta LAN via broker indisponível ($e). Usando Cloudflare Relay.',
      );
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }

    // Fallback: Retransmissor na Nuvem
    AppLogger.instance.logInfo(
      '[EditorCroqui] Conectado via Cloudflare Relay: $urlRelay',
    );
    return urlRelay;
  }

  Timer? _reconnectLiveReloadTimer;

  /// Inicia a escuta de eventos WebSocket para Live Reload.
  void iniciarEscutaLiveReload(String urlBase) {
    encerrarEscutaLiveReload();
    if (urlBase.startsWith('aresta-zip://')) return;

    Uri? wsUri;
    final codigo = extrairCodigoPrevia(urlBase);
    if (codigo != null) {
      wsUri = Uri.parse('wss://$dominioPrevia/$codigo/events');
    } else {
      final uri = Uri.tryParse(urlBase);
      if (uri != null && uri.host.isNotEmpty) {
        final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
        final portSuffix = uri.hasPort ? ':${uri.port}' : '';
        wsUri = Uri.parse('$scheme://${uri.host}$portSuffix/events');
      }
    }

    if (wsUri == null) return;

    try {
      AppLogger.instance.logInfo(
        '[EditorCroqui] Conectando WebSocket de Live Reload em $wsUri...',
      );
      WebSocket.connect(wsUri.toString()).then((ws) {
        _wsLiveReload = ws;
        AppLogger.instance.logInfo(
          '[EditorCroqui] 🟢 WebSocket de Live Reload conectado com sucesso!',
        );
        ws.listen(
          (event) {
            try {
              final dados =
                  jsonDecode(event.toString()) as Map<String, dynamic>;
              if (dados['tipo'] == 'recarregar' ||
                  dados['evento'] == 'recarregar' ||
                  dados['tipo'] == 'evento' ||
                  dados.containsKey('setor')) {
                final setorId = (dados['setor'] ??
                    dados['dados']?['setor'] ??
                    dados['dados']?['id_croqui']) as String?;
                AppLogger.instance.logInfo(
                  '[EditorCroqui] ⚡ Evento Live Reload recebido! Setor/ID: $setorId',
                );
                eventoLiveReload.value = LiveReloadEvent(
                  setorId: setorId,
                  timestamp: DateTime.now(),
                );
                dispararPulsoRecarregamento();
              }
            } catch (e, stackTrace) {
              AppLogger.instance.logError(
                '[EditorCroqui] Erro ao decodificar evento Live Reload',
                error: e,
                stackTrace: stackTrace,
              );
            }
          },
          onDone: () {
            _wsLiveReload = null;
            _agendarReconexaoLiveReload(urlBase);
          },
          onError: (_) {
            _wsLiveReload = null;
            _agendarReconexaoLiveReload(urlBase);
          },
        );
      }).catchError((_) {
        _agendarReconexaoLiveReload(urlBase);
      });
    } catch (_) {}
  }

  void _agendarReconexaoLiveReload(String urlBase) {
    if (!isExperimentalMode.value) return;
    _reconnectLiveReloadTimer?.cancel();
    _reconnectLiveReloadTimer = Timer(const Duration(seconds: 4), () {
      if (isExperimentalMode.value && _wsLiveReload == null) {
        iniciarEscutaLiveReload(urlBase);
      }
    });
  }

  /// Encerra a conexão WebSocket de Live Reload.
  void encerrarEscutaLiveReload() {
    _reconnectLiveReloadTimer?.cancel();
    _reconnectLiveReloadTimer = null;
    try {
      _wsLiveReload?.close();
    } catch (_) {}
    _wsLiveReload = null;
  }

  Future<bool> hasExperimentalData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final indexFile = File(
        '${directory.path}/editor/experimental/indice.binarypb',
      );
      return indexFile.existsSync();
    } catch (e) {
      return false;
    }
  }

  String downloadsPath(String docsPath) {
    if (!isExperimentalMode.value) {
      return '$docsPath/downloads';
    }
    return '$docsPath/editor/experimental/downloads';
  }

  String indicePath(String docsPath) {
    if (!isExperimentalMode.value) {
      return '$docsPath/indice.binarypb';
    }
    return '$docsPath/editor/experimental/indice.binarypb';
  }

  Future<String> getEditedPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final editedDir = Directory('${directory.path}/edited');
    if (!editedDir.existsSync()) {
      editedDir.createSync(recursive: true);
    }
    return editedDir.path;
  }

  Future<Map<String, dynamic>> _readConfig() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final configFile = File('${directory.path}/$_configFileName');
      if (!configFile.existsSync()) return {};
      final content = configFile.readAsStringSync();
      if (content.trim().isEmpty) return {};
      final yamlDoc = loadYaml(content);
      if (yamlDoc is YamlMap) {
        return Map<String, dynamic>.from(yamlDoc);
      }
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        '[EditorConfig] Erro ao ler yaml',
        error: e,
        stackTrace: stackTrace,
      );
    }
    return {};
  }

  Future<void> _writeConfig(Map<String, dynamic> config) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final configFile = File('${directory.path}/$_configFileName');

      final lines = <String>[];
      for (final entry in config.entries) {
        if (entry.value == null) continue;
        if (entry.value is String) {
          lines.add('${entry.key}: "${entry.value}"');
        } else {
          lines.add('${entry.key}: ${entry.value}');
        }
      }
      configFile.writeAsStringSync(lines.join('\n'));
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        '[EditorConfig] Erro ao gravar yaml',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> loadFromDisk() async {
    try {
      final directory = await getApplicationDocumentsDirectory();

      // Migração: se existir o JSON antigo, tentamos excluir para limpar
      final oldJsonFile = File('${directory.path}/editor_config.json');
      if (await oldJsonFile.exists()) {
        try {
          await oldJsonFile.delete();
        } catch (_) {}
      }

      final config = await _readConfig();
      if (config.isNotEmpty) {
        final url = config['editorUrl'] as String?;
        final experimental = config['isExperimental'] as bool? ?? false;
        final devMode = config['isDevMode'] as bool? ?? false;

        // Dev Mode sempre persiste
        if (devMode) {
          isDevModeEnabled.value = true;
          AppLogger.instance.logInfo(
            '[EditorConfig] Modo Desenvolvedor ativado via disco.',
          );
        }

        final expiryStr = config['expiryTime'] as String?;

        // Se o app foi fechado em modo experimental, limpamos tudo ao abrir
        if (experimental) {
          AppLogger.instance.logInfo(
            '[EditorConfig] Modo experimental detectado no boot. Executando Nuke compulsório...',
          );
          await nukeExperimentalData();
          return;
        }

        if (url != null && url.isNotEmpty) {
          editorUrl.value = url;
        }

        if (experimental) {
          isExperimentalMode.value = true;
        }

        if (devMode) {
          isDevModeEnabled.value = true;
        }

        if (expiryStr != null) {
          _expirationTime = DateTime.tryParse(expiryStr);
          if (_expirationTime != null) {
            final now = DateTime.now();
            if (_expirationTime!.isBefore(now)) {
              AppLogger.instance.logInfo(
                '[EditorConfig] Tempo expirado durante o boot. Limpando...',
              );
              nukeExperimentalData();
            } else {
              _startCountdown();
            }
          }
        }
      }
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        '[EditorConfig] Erro ao carregar configuração',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();

    void tick() {
      if (_expirationTime == null) {
        _countdownTimer?.cancel();
        timeRemaining.value = null;
        return;
      }

      final now = DateTime.now();
      final difference = _expirationTime!.difference(now);

      if (difference.isNegative || difference.inSeconds <= 0) {
        _countdownTimer?.cancel();
        timeRemaining.value = Duration.zero;
        AppLogger.instance.logInfo(
          '[EditorConfig] Tempo esgotado! Iniciando Nuke...',
        );
        nukeExperimentalData();
      } else {
        timeRemaining.value = difference;
      }
    }

    tick();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  Future<void> activateExperimental({
    String? url,
    bool forceResetTimer = false,
  }) async {
    if (forceResetTimer ||
        _expirationTime == null ||
        _expirationTime!.isBefore(DateTime.now())) {
      _expirationTime = DateTime.now().add(const Duration(minutes: 20));
      AppLogger.instance.logInfo(
        '[EditorConfig] Definindo novo tempo de expiração: 20 minutos.',
      );
    } else {
      AppLogger.instance.logInfo(
        '[EditorConfig] Mantendo tempo de expiração existente.',
      );
    }

    _startCountdown();

    isExperimentalMode.value = true;
    if (url != null) {
      if (!url.startsWith('http://') &&
          !url.startsWith('https://') &&
          !url.startsWith('aresta-zip://')) {
        url = 'http://$url';
      }
      editorUrl.value = url;
      iniciarEscutaLiveReload(url);
    }

    try {
      final config = await _readConfig();
      if (url != null) {
        config['editorUrl'] = url;
      } else {
        config['editorUrl'] = null;
      }
      config['isExperimental'] = true;
      config['expiryTime'] = _expirationTime?.toIso8601String();

      await _writeConfig(config);
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        '[EditorConfig] Erro ao persistir modo experimental',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> setDevMode(bool enabled) async {
    isDevModeEnabled.value = enabled;
    try {
      final config = await _readConfig();
      config['isDevMode'] = enabled;
      await _writeConfig(config);
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        '[EditorConfig] Erro ao persistir modo dev',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> disconnect() async {
    encerrarEscutaLiveReload();
    try {
      final config = await _readConfig();
      config['isExperimental'] = false;
      await _writeConfig(config);
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        '[EditorConfig] Erro ao desconectar',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      isExperimentalMode.value = false;
    }
  }

  Future<void> nukeExperimentalData() async {
    _expirationTime = null;
    _countdownTimer?.cancel();
    timeRemaining.value = null;
    encerrarEscutaLiveReload();

    try {
      final directory = await getApplicationDocumentsDirectory();
      final experimentalDir = Directory(
        '${directory.path}/editor/experimental',
      );
      if (experimentalDir.existsSync()) {
        experimentalDir.deleteSync(recursive: true);
      }

      final editedDir = Directory('${directory.path}/edited');
      if (editedDir.existsSync()) {
        editedDir.deleteSync(recursive: true);
      }

      final config = await _readConfig();
      config['editorUrl'] = null;
      await _writeConfig(config);
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        '[EditorConfig] Erro ao limpar dados',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      editorUrl.value = null;
      await disconnect();
    }
  }
}
