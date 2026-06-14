import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import 'package:yaml/yaml.dart';

/// Gerencia a conexão com um repositório editor externo (servidor local) e o modo experimental.
class EditorDeCroqui {
  static const String _officialBaseUrl =
      'https://aresta-climb.github.io/aresta_serving';
  static const String _configFileName = 'editor_config.yaml';

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

  DateTime? _expirationTime;
  Timer? _countdownTimer;

  EditorDeCroqui() {
    _instance = this;
  }

  String get activeBaseUrl {
    if (!isExperimentalMode.value) return _officialBaseUrl;

    String? url = editorUrl.value;
    if (url == null || url.isEmpty) return '';

    // Se for um link local ou aresta-zip, retornamos como está
    if (url.startsWith('aresta-zip')) return url;

    // Garante que tenha scheme
    if (!url.contains('://')) {
      url = 'https://$url';
    }

    return url;
  }

  bool get isEditorActive => isExperimentalMode.value;

  Future<bool> hasExperimentalData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final indexFile = File(
        '${directory.path}/editor/experimental/indice.binarypb',
      );
      return await indexFile.exists();
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
    if (!await editedDir.exists()) {
      await editedDir.create(recursive: true);
    }
    return editedDir.path;
  }

  Future<Map<String, dynamic>> _readConfig() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final configFile = File('${directory.path}/$_configFileName');
      if (!await configFile.exists()) return {};
      final content = await configFile.readAsString();
      if (content.trim().isEmpty) return {};
      final yamlDoc = loadYaml(content);
      if (yamlDoc is YamlMap) {
        return Map<String, dynamic>.from(yamlDoc);
      }
    } catch (e) {
      AppLogger.instance.logError('[EditorConfig] Erro ao ler yaml', error: e);
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
      await configFile.writeAsString(lines.join('\n'));
    } catch (e) {
      AppLogger.instance.logError(
        '[EditorConfig] Erro ao gravar yaml',
        error: e,
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
          debugPrint('[EditorConfig] Modo Desenvolvedor ativado via disco.');
        }

        final expiryStr = config['expiryTime'] as String?;

        // Se o app foi fechado em modo experimental, limpamos tudo ao abrir
        if (experimental) {
          debugPrint(
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
              debugPrint(
                '[EditorConfig] Tempo expirado durante o boot. Limpando...',
              );
              nukeExperimentalData();
            } else {
              _startCountdown();
            }
          }
        }
      }
    } catch (e) {
      AppLogger.instance.logError(
        '[EditorConfig] Erro ao carregar configuração',
        error: e,
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
        debugPrint('[EditorConfig] Tempo esgotado! Iniciando Nuke...');
        nukeExperimentalData();
      } else {
        timeRemaining.value = difference;
      }
    }

    tick(); // Chama imediatamente para não ter delay de 1 segundo na UI
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  Future<void> activateExperimental({
    String? url,
    bool forceResetTimer = false,
  }) async {
    // Só define um novo tempo de expiração se for um reset forçado ou se não houver um tempo válido ativo
    if (forceResetTimer ||
        _expirationTime == null ||
        _expirationTime!.isBefore(DateTime.now())) {
      _expirationTime = DateTime.now().add(const Duration(minutes: 20));
      debugPrint(
        '[EditorConfig] Definindo novo tempo de expiração: 20 minutos.',
      );
    } else {
      debugPrint('[EditorConfig] Mantendo tempo de expiração existente.');
    }

    _startCountdown();

    isExperimentalMode.value = true;
    if (url != null) {
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'http://$url';
      }
      editorUrl.value = url;
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
    } catch (e) {
      AppLogger.instance.logError(
        '[EditorConfig] Erro ao persistir modo experimental',
        error: e,
      );
    }
  }

  Future<void> setDevMode(bool enabled) async {
    isDevModeEnabled.value = enabled;
    try {
      final config = await _readConfig();
      config['isDevMode'] = enabled;
      await _writeConfig(config);
    } catch (e) {
      AppLogger.instance.logError(
        '[EditorConfig] Erro ao persistir modo dev',
        error: e,
      );
    }
  }

  Future<void> disconnect() async {
    try {
      final config = await _readConfig();
      // Mantemos a URL no yaml para poder reativá-la depois
      config['isExperimental'] = false;
      // Mantemos o expiryTime no config para que o tempo continue contando

      await _writeConfig(config);

      isExperimentalMode.value = false;
    } catch (e) {
      AppLogger.instance.logError(
        '[EditorConfig] Erro ao desconectar',
        error: e,
      );
    }
  }

  Future<void> nukeExperimentalData() async {
    _expirationTime = null;
    _countdownTimer?.cancel();
    timeRemaining.value = null;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final experimentalDir = Directory(
        '${directory.path}/editor/experimental',
      );
      if (await experimentalDir.exists()) {
        await experimentalDir.delete(recursive: true);
      }

      final editedDir = Directory('${directory.path}/edited');
      if (await editedDir.exists()) {
        await editedDir.delete(recursive: true);
      }

      final config = await _readConfig();
      config['editorUrl'] = null;
      await _writeConfig(config);

      editorUrl.value = null;

      await disconnect();
    } catch (e) {
      AppLogger.instance.logError(
        '[EditorConfig] Erro ao limpar dados',
        error: e,
      );
    }
  }
}
