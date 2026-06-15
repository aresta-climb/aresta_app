import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'package:frontend/main.dart'; // Para acessar TreeNavigationWrapper
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Serviço responsável por coletar informações de contexto e ambiente no momento
/// em que o usuário decide enviar um feedback ou relatar um bug.
/// 
/// Os dados coletados incluem:
/// - ID da Instância do App (Firebase Analytics)
/// - Sistema Operacional
/// - Versão do SO e Modelo do Celular
/// - Versão do App
/// - Resolução da Tela e Modo Escuro
/// - Status da Conexão com a Internet
/// - Árvore de navegação atual (`TreeNavigationController`)
class FeedbackMetadataCollector {
  /// Override opcional para substituir a representação string do nó ativo (último nó da árvore)
  static String? globalActiveNodeOverride;

  /// Função opcional para sobrescrever a obtenção do ID da instância (útil para testes).
  final Future<String?> Function()? getAppInstanceIdOverride;
  /// Função opcional para sobrescrever a obtenção das informações do pacote.
  final Future<PackageInfo> Function()? getPackageInfoOverride;
  /// Função opcional para sobrescrever a obtenção do Sistema Operacional.
  final String Function()? getOSOverride;
  /// Função opcional para sobrescrever a obtenção da árvore de navegação.
  final String Function()? getNavigationTreeOverride;
  /// Função opcional para sobrescrever a obtenção de informações do dispositivo.
  final Future<BaseDeviceInfo> Function()? getDeviceInfoOverride;
  /// Função opcional para sobrescrever a obtenção de status de conectividade.
  final Future<List<ConnectivityResult>> Function()? getConnectivityOverride;

  /// Cria um coletor de metadados de feedback.
  /// 
  /// É possível passar funções *override* para facilitar o isolamento em testes unitários.
  FeedbackMetadataCollector({
    this.getAppInstanceIdOverride,
    this.getPackageInfoOverride,
    this.getOSOverride,
    this.getNavigationTreeOverride,
    this.getDeviceInfoOverride,
    this.getConnectivityOverride,
  });

  /// Executa a coleta de todas as informações de metadados.
  /// Se um `context` for fornecido, coleta informações da árvore de Widgets (Tela e Tema).
  /// 
  /// Retorna um mapa contendo todas as propriedades.
  /// Variáveis que falharem durante a coleta adotarão o valor `'unknown'`.
  Future<Map<String, dynamic>> collect({BuildContext? context}) async {
    String? appInstanceId;
    try {
      if (getAppInstanceIdOverride != null) {
        appInstanceId = await getAppInstanceIdOverride!();
      } else {
        appInstanceId = await TelemetryService.instance.getAppInstanceId();
      }
    } catch (_) {}

    PackageInfo? packageInfo;
    try {
      if (getPackageInfoOverride != null) {
        packageInfo = await getPackageInfoOverride!();
      } else {
        packageInfo = await PackageInfo.fromPlatform();
      }
    } catch (_) {}

    String os = '';
    try {
      if (getOSOverride != null) {
        os = getOSOverride!();
      } else {
        os = Platform.operatingSystem;
      }
    } catch (_) {}

    String deviceModel = 'unknown';
    String osVersion = 'unknown';
    try {
      if (getDeviceInfoOverride != null) {
        final info = await getDeviceInfoOverride!();
        if (info is AndroidDeviceInfo) {
          deviceModel = '${info.brand} ${info.model}';
          osVersion = info.version.release;
        } else if (info is IosDeviceInfo) {
          deviceModel = info.utsname.machine;
          osVersion = info.systemVersion;
        }
      } else {
        final deviceInfo = DeviceInfoPlugin();
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          deviceModel = '${androidInfo.brand} ${androidInfo.model}';
          osVersion = androidInfo.version.release;
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          deviceModel = iosInfo.utsname.machine;
          osVersion = iosInfo.systemVersion;
        }
      }
    } catch (_) {}

    String navigationTree = '';
    try {
      if (getNavigationTreeOverride != null) {
        navigationTree = getNavigationTreeOverride!();
        if (globalActiveNodeOverride != null) {
          final parts = navigationTree.split(' -> ');
          if (parts.isNotEmpty) {
            parts[parts.length - 1] = globalActiveNodeOverride!;
            navigationTree = parts.join(' -> ');
          }
        }
      } else {
        final treeController = TreeNavigationWrapper.currentTreeController;
        if (treeController != null) {
          final node = treeController.currentNode;
          navigationTree = _getNodePath(node);
        } else if (globalActiveNodeOverride != null) {
          navigationTree = globalActiveNodeOverride!;
        }
      }
    } catch (_) {}

    String screenSize = 'unknown';
    String isDarkMode = 'unknown';
    String deviceOrientation = 'unknown';
    try {
      if (context != null) {
        final size = MediaQuery.of(context).size;
        screenSize = '${size.width.toInt()}x${size.height.toInt()}';
        isDarkMode = Theme.of(context).brightness == Brightness.dark ? 'true' : 'false';
        deviceOrientation = MediaQuery.of(context).orientation.name;
      }
    } catch (_) {}

    String connectivity = 'unknown';
    try {
      List<ConnectivityResult> results = [];
      if (getConnectivityOverride != null) {
        results = await getConnectivityOverride!();
      } else {
        results = await Connectivity().checkConnectivity();
      }
      
      if (results.contains(ConnectivityResult.none)) {
        connectivity = 'offline';
      } else {
        connectivity = results.map((e) => e.name).join(',');
      }
    } catch (_) {}

    return {
      'navigationTree': navigationTree.isEmpty ? 'unknown' : navigationTree,
      'appInstanceId': appInstanceId ?? 'unknown',
      'os': os,
      'osVersion': osVersion,
      'deviceModel': deviceModel,
      'appVersion': packageInfo?.version ?? 'unknown',
      'screenSize': screenSize,
      'deviceOrientation': deviceOrientation,
      'isDarkMode': isDarkMode,
      'connectivity': connectivity,
    };
  }

  /// Constrói uma representação em string do caminho de nós percorrido na árvore.
  /// 
  /// Utiliza recursão pelo nó `parent` para formar uma string do tipo `Raiz -> Setor -> Via`.
  String _getNodePath(dynamic node) {
    if (node == null) return '';
    String path = globalActiveNodeOverride ?? node.toString();
    var current = node.parent;
    while (current != null) {
      path = '${current.toString()} -> $path';
      current = current.parent;
    }
    return path;
  }
}
