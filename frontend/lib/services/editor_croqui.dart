import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import 'dataset_repository.dart';

/// Gerencia a conexão com um repositório editor externo (servidor local) e o modo experimental.
class EditorDeCroqui {
  static const String _officialBaseUrl = 'https://aresta-climb.github.io/aresta_serving';
  static const String _configFileName = 'editor_config.json';

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

  /// Se devemos buscar arquivos dentro da subpasta "compilado/".
  /// Isso é auto-detectado durante a conexão com repositórios externos.
  final ValueNotifier<bool> useCompiladoFolder = ValueNotifier(false);

  /// Tempo restante para a auto-destruição dos dados experimentais.
  final ValueNotifier<Duration?> timeRemaining = ValueNotifier(null);
  
  DateTime? _expirationTime;
  Timer? _countdownTimer;

  EditorDeCroqui() {
    _instance = this;
  }

  String get activeBaseUrl {
    String? url = editorUrl.value;
    if (url == null || url.isEmpty) return _officialBaseUrl;
    
    // Se for um link local ou aresta-zip, retornamos como está
    if (url.startsWith('aresta-zip')) return url;
    
    // Garante que tenha scheme
    if (!url.contains('://')) {
       url = 'https://$url';
    }
    
    // Se estivermos usando a subpasta compilado, adicionamos ao baseUrl
    if (useCompiladoFolder.value && !url.endsWith('/compilado')) {
       return '$url/compilado';
    }
    
    return url;
  }

  bool get isEditorActive => editorUrl.value != null || isExperimentalMode.value;

  Future<bool> hasExperimentalData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final indexFile = File('${directory.path}/editor/experimental/indice.binarypb');
      return await indexFile.exists();
    } catch (e) {
      return false;
    }
  }

  String downloadsPath(String docsPath) {
    if (editorUrl.value == null && !isExperimentalMode.value) {
      return '$docsPath/downloads';
    }
    if (isExperimentalMode.value) {
      return '$docsPath/editor/experimental/downloads';
    }
    return '$docsPath/editor/${_urlToSlug(editorUrl.value!)}/downloads';
  }

  String indicePath(String docsPath) {
    if (editorUrl.value == null && !isExperimentalMode.value) {
      return '$docsPath/indice.binarypb';
    }
    if (isExperimentalMode.value) {
      return '$docsPath/editor/experimental/indice.binarypb';
    }
    return '$docsPath/editor/${_urlToSlug(editorUrl.value!)}/indice.binarypb';
  }

  Future<String> getEditedPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final editedDir = Directory('${directory.path}/edited');
    if (!await editedDir.exists()) {
      await editedDir.create(recursive: true);
    }
    return editedDir.path;
  }

  Future<void> loadFromDisk() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final configFile = File('${directory.path}/$_configFileName');
      if (await configFile.exists()) {
        final content = await configFile.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        
        final url = json['editorUrl'] as String?;
        final experimental = json['isExperimental'] as bool? ?? false;
        final devMode = json['isDevMode'] as bool? ?? false;

        // Dev Mode sempre persiste
        if (devMode) {
          isDevModeEnabled.value = true;
          debugPrint('[EditorConfig] Modo Desenvolvedor ativado via disco.');
        }

        final expiryStr = json['expiryTime'] as String?;

        // Se o app foi fechado em modo experimental, limpamos tudo ao abrir
        if (experimental) {
          debugPrint('[EditorConfig] Modo experimental detectado no boot. Executando Nuke compulsório...');
          await nukeExperimentalData();
          return; 
        }

        if (url != null && url.isNotEmpty) {
          editorUrl.value = url;
        }

        final compilado = json['useCompilado'] as bool? ?? false;
        useCompiladoFolder.value = compilado;

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
              debugPrint('[EditorConfig] Tempo expirado durante o boot. Limpando...');
              nukeExperimentalData();
            } else {
              _startCountdown();
            }
          }
        }
      }
    } catch (e) {
      AppLogger.instance.logError('[EditorConfig] Erro ao carregar configuração', error: e);
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_expirationTime == null) {
        timer.cancel();
        timeRemaining.value = null;
        return;
      }

      final now = DateTime.now();
      final difference = _expirationTime!.difference(now);

      if (difference.isNegative || difference.inSeconds <= 0) {
        timer.cancel();
        timeRemaining.value = Duration.zero;
        debugPrint('[EditorConfig] Tempo esgotado! Iniciando Nuke...');
        nukeExperimentalData();
        DatasetRepository.instance?.loadEmpty();
      } else {
        timeRemaining.value = difference;
      }
    });
  }

  /// Conecta ao repositório editor com a URL fornecida.
  Future<void> connect(String url) async {
    String normalized = url.trim();
    
    // Se não for aresta-zip e não tiver scheme, assumimos https para normalização
    if (!normalized.startsWith('aresta-zip') && !normalized.contains('://')) {
       normalized = 'https://$normalized';
    }

    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final configFile = File('${directory.path}/$_configFileName');
      Map<String, dynamic> currentJson = {};
      if (await configFile.exists()) {
        currentJson = jsonDecode(await configFile.readAsString());
      }
      currentJson['editorUrl'] = normalized;
      currentJson['isExperimental'] = false;
      currentJson['useCompilado'] = useCompiladoFolder.value;
      currentJson['expiryTime'] = null;
      
      await configFile.writeAsString(jsonEncode(currentJson));
      
      isExperimentalMode.value = false;
      editorUrl.value = normalized;
    } catch (e) {
      AppLogger.instance.logError('[EditorConfig] Erro ao conectar', error: e);
    }
  }

  Future<void> activateExperimental({String? url, bool forceResetTimer = false}) async {
    // Só define um novo tempo de expiração se for um reset forçado ou se não houver um tempo válido ativo
    if (forceResetTimer || _expirationTime == null || _expirationTime!.isBefore(DateTime.now())) {
      _expirationTime = DateTime.now().add(const Duration(minutes: 20));
      debugPrint('[EditorConfig] Definindo novo tempo de expiração: 20 minutos.');
    } else {
      debugPrint('[EditorConfig] Mantendo tempo de expiração existente.');
    }
    
    _startCountdown();

    isExperimentalMode.value = true;
    if (url != null) {
      editorUrl.value = url;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final configFile = File('${directory.path}/$_configFileName');
      Map<String, dynamic> currentJson = {};
      if (await configFile.exists()) {
        currentJson = jsonDecode(await configFile.readAsString());
      }
      if (url != null) {
        currentJson['editorUrl'] = url;
      } else {
        currentJson['editorUrl'] = null;
      }
      currentJson['isExperimental'] = true;
      currentJson['useCompilado'] = useCompiladoFolder.value;
      currentJson['expiryTime'] = _expirationTime?.toIso8601String();
      
      await configFile.writeAsString(jsonEncode(currentJson));
    } catch (e) {
      AppLogger.instance.logError('[EditorConfig] Erro ao persistir modo experimental', error: e);
    }
  }

  Future<void> setDevMode(bool enabled) async {
    isDevModeEnabled.value = enabled;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final configFile = File('${directory.path}/$_configFileName');
      Map<String, dynamic> currentJson = {};
      if (await configFile.exists()) {
        currentJson = jsonDecode(await configFile.readAsString());
      }
      currentJson['isDevMode'] = enabled;
      await configFile.writeAsString(jsonEncode(currentJson));
    } catch (e) {
      AppLogger.instance.logError('[EditorConfig] Erro ao persistir modo dev', error: e);
    }
  }

  Future<void> disconnect() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final configFile = File('${directory.path}/$_configFileName');
      Map<String, dynamic> currentJson = {};
      if (await configFile.exists()) {
        currentJson = jsonDecode(await configFile.readAsString());
      }
      currentJson['editorUrl'] = null;
      currentJson['isExperimental'] = false;
      // Mantemos o expiryTime no config para que o tempo continue contando
      
      await configFile.writeAsString(jsonEncode(currentJson));
      
      editorUrl.value = null;
      isExperimentalMode.value = false;
    } catch (e) {
      AppLogger.instance.logError('[EditorConfig] Erro ao desconectar', error: e);
    }
  }

  Future<void> nukeExperimentalData() async {
    _expirationTime = null;
    _countdownTimer?.cancel();
    timeRemaining.value = null;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final experimentalDir = Directory('${directory.path}/editor/experimental');
      if (await experimentalDir.exists()) {
        await experimentalDir.delete(recursive: true);
      }

      final editedDir = Directory('${directory.path}/edited');
      if (await editedDir.exists()) {
        await editedDir.delete(recursive: true);
      }

      await disconnect();
    } catch (e) {
      AppLogger.instance.logError('[EditorConfig] Erro ao limpar dados', error: e);
    }
  }

  String _urlToSlug(String url) {
    return url.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
  }
}
