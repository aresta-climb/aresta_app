// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

/// Este arquivo atua como o 'Trabalhador' (Worker) de Sistema/Dispositivo.
/// É responsável por vasculhar o SO do aparelho (versão, modelo, conectividade) para popular os metadados.
library;

import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import 'package:frontend/main.dart'; // Para acessar TreeNavigationWrapper
import 'package:frontend/navigation/navigation_tree.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/feedback_metadata.dart';

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
/// - Auditoria de integridade criptográfica de hash (`indice.binarypb`, `compilado.binarypb`, `thumbnail.webp`)
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

  /// Função opcional para sobrescrever a data/hora do feedback.
  final DateTime Function()? getTimestampOverride;

  /// Função opcional para sobrescrever o UUID (útil para testes).
  final String Function()? getUuidOverride;

  /// Função opcional para sobrescrever o diretório de documentos (útil para testes).
  final Future<String> Function()? getDocsPathOverride;

  /// Função opcional para sobrescrever o diretório de cache temporário (útil para testes).
  final Future<String> Function()? getTempCachePathOverride;

  /// Função opcional para sobrescrever o identificador do croqui ativo (útil para testes).
  final String? Function()? getCragIdOverride;

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
    this.getTimestampOverride,
    this.getUuidOverride,
    this.getDocsPathOverride,
    this.getTempCachePathOverride,
    this.getCragIdOverride,
  });

  /// Executa a coleta de todas as informações de metadados.
  /// Se um `context` for fornecido, coleta informações da árvore de Widgets (Tela e Tema).
  ///
  /// Retorna um objeto [FeedbackMetadata] fortemente tipado.
  /// Variáveis que falharem durante a coleta adotarão o valor `'unknown'`.
  Future<FeedbackMetadata> collect({BuildContext? context}) async {
    String screenSize = 'unknown';
    String isDarkMode = 'unknown';
    String deviceOrientation = 'unknown';
    try {
      if (context != null) {
        final size = MediaQuery.of(context).size;
        screenSize = '${size.width.toInt()}x${size.height.toInt()}';
        isDarkMode = Theme.of(context).brightness == Brightness.dark
            ? 'true'
            : 'false';
        deviceOrientation = MediaQuery.of(context).orientation.name;
      }
    } catch (_) {}

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

    String submittedAt = 'unknown';
    String submittedAtTimestamp = 'unknown';
    try {
      DateTime utcTime;
      if (getTimestampOverride != null) {
        utcTime = getTimestampOverride!();
      } else {
        utcTime = DateTime.now().toUtc();
      }
      final gmt3Time = utcTime.subtract(const Duration(hours: 3));

      final day = gmt3Time.day.toString().padLeft(2, '0');

      final monthNames = [
        '',
        'janeiro',
        'fevereiro',
        'março',
        'abril',
        'maio',
        'junho',
        'julho',
        'agosto',
        'setembro',
        'outubro',
        'novembro',
        'dezembro',
      ];
      final monthName = monthNames[gmt3Time.month];

      final year = gmt3Time.year.toString();
      final hour = gmt3Time.hour.toString().padLeft(2, '0');
      final minute = gmt3Time.minute.toString().padLeft(2, '0');
      final second = gmt3Time.second.toString().padLeft(2, '0');

      submittedAtTimestamp =
          '${gmt3Time.toIso8601String().split('Z').first}-03:00';
      submittedAt =
          '$day de $monthName de $year às $hour:$minute:$second (GMT-3)';
    } catch (_) {}

    // Coleta de auditoria criptográfica de integridade (índice, croqui e miniatura)
    String? indiceSha256;
    String? croquiId;
    String? croquiSha256Esperado;
    String? croquiSha256Real;
    String? croquiStatus;
    String? thumbnailSha256Esperado;
    String? thumbnailSha256Real;
    String? thumbnailStatus;

    try {
      final docsPath = getDocsPathOverride != null
          ? await getDocsPathOverride!()
          : (await getApplicationDocumentsDirectory()).path;

      final tempCachePath = getTempCachePathOverride != null
          ? await getTempCachePathOverride!()
          : '${(await getTemporaryDirectory()).path}/temp_cache';

      // 1. Auditoria do indice.binarypb local
      final indiceFile = File('$docsPath/indice.binarypb');
      Indice? indice;
      if (await indiceFile.exists()) {
        final indiceBytes = await indiceFile.readAsBytes();
        indiceSha256 = sha256.convert(indiceBytes).toString();
        try {
          indice = Indice.fromBuffer(indiceBytes);
        } catch (e) {
          AppLogger.instance.logAviso(
            '[FeedbackCollector] Erro ao decodificar indice.binarypb para auditoria: $e',
          );
        }
      }

      // Determina o cragId ativo em visualização
      if (getCragIdOverride != null) {
        croquiId = getCragIdOverride!();
      } else {
        final treeController = TreeNavigationWrapper.currentTreeController;
        if (treeController != null) {
          NavNode? current = treeController.currentNode;
          while (current != null) {
            if (current is PicoContextNode) {
              croquiId = current.cragId;
              break;
            }
            current = current.parent;
          }
        }
      }

      // 2. Se houver um croqui ativo, audita o croqui e a thumbnail
      if (croquiId != null && croquiId.isNotEmpty) {
        ResumoCroqui? resumo;
        if (indice != null) {
          for (final r in indice.croquis) {
            if (r.id == croquiId) {
              resumo = r;
              break;
            }
          }
        }

        if (resumo != null) {
          if (resumo.hasChecksumSha256Croqui() &&
              resumo.checksumSha256Croqui.isNotEmpty) {
            croquiSha256Esperado = resumo.checksumSha256Croqui;
          }
          if (resumo.hasChecksumSha256Thumbnail() &&
              resumo.checksumSha256Thumbnail.isNotEmpty) {
            thumbnailSha256Esperado = resumo.checksumSha256Thumbnail;
          }
        }

        // Procura arquivo de croqui local (downloads permanente, legado ou temp_cache)
        File? croquiFile;
        final caminhoPermanente =
            File('$docsPath/downloads/$croquiId/compilado.binarypb');
        final caminhoLegado =
            File('$docsPath/downloads/$croquiId/$croquiId.binarypb');

        if (await caminhoPermanente.exists()) {
          croquiFile = caminhoPermanente;
        } else if (await caminhoLegado.exists()) {
          croquiFile = caminhoLegado;
        } else {
          // Busca no temp_cache
          if (croquiSha256Esperado != null) {
            final cacheComHash = File(
                '$tempCachePath/$croquiId/compilado.binarypb.$croquiSha256Esperado');
            if (await cacheComHash.exists()) {
              croquiFile = cacheComHash;
            }
          }
          if (croquiFile == null) {
            final cacheSemHash =
                File('$tempCachePath/$croquiId/compilado.binarypb');
            if (await cacheSemHash.exists()) {
              croquiFile = cacheSemHash;
            }
          }
        }

        if (croquiFile != null && await croquiFile.exists()) {
          final croquiBytes = await croquiFile.readAsBytes();
          croquiSha256Real = sha256.convert(croquiBytes).toString();
          if (croquiSha256Esperado != null &&
              croquiSha256Esperado.isNotEmpty) {
            croquiStatus = (croquiSha256Real == croquiSha256Esperado)
                ? 'INTEGRO'
                : 'DIVERGENTE';
          } else {
            croquiStatus = 'INTEGRO';
          }
        } else {
          croquiStatus = 'NAO_BAIXADO';
        }

        // Procura arquivo de thumbnail local
        File? thumbFile;
        final thumbDocs = File('$docsPath/thumbnails/$croquiId.webp');
        final thumbDownloads =
            File('$docsPath/downloads/$croquiId/thumbnail.webp');
        final thumbCache = File('$tempCachePath/thumbnails/$croquiId.webp');

        if (await thumbDocs.exists()) {
          thumbFile = thumbDocs;
        } else if (await thumbDownloads.exists()) {
          thumbFile = thumbDownloads;
        } else if (await thumbCache.exists()) {
          thumbFile = thumbCache;
        }

        if (thumbFile != null && await thumbFile.exists()) {
          final thumbBytes = await thumbFile.readAsBytes();
          thumbnailSha256Real = sha256.convert(thumbBytes).toString();
          if (thumbnailSha256Esperado != null &&
              thumbnailSha256Esperado.isNotEmpty) {
            thumbnailStatus = (thumbnailSha256Real == thumbnailSha256Esperado)
                ? 'INTEGRO'
                : 'DIVERGENTE';
          } else {
            thumbnailStatus = 'INTEGRO';
          }
        } else {
          thumbnailStatus = 'NAO_BAIXADO';
        }
      }
    } catch (e, stackTrace) {
      AppLogger.instance.logAviso(
        '[FeedbackCollector] Falha ao coletar integridade criptográfica: $e\n$stackTrace',
      );
    }

    return FeedbackMetadata(
      navigationTree: navigationTree.isEmpty ? 'unknown' : navigationTree,
      submittedAt: submittedAt,
      submittedAtTimestamp: submittedAtTimestamp,
      feedbackId: getUuidOverride != null
          ? getUuidOverride!()
          : const Uuid().v4(),
      appInstanceId: appInstanceId ?? 'unknown',
      os: os,
      osVersion: osVersion,
      deviceModel: deviceModel,
      appVersion: packageInfo?.version ?? 'unknown',
      screenSize: screenSize,
      deviceOrientation: deviceOrientation,
      isDarkMode: isDarkMode,
      connectivity: connectivity,
      indiceSha256: indiceSha256,
      croquiId: croquiId,
      croquiSha256Esperado: croquiSha256Esperado,
      croquiSha256Real: croquiSha256Real,
      croquiStatus: croquiStatus,
      thumbnailSha256Esperado: thumbnailSha256Esperado,
      thumbnailSha256Real: thumbnailSha256Real,
      thumbnailStatus: thumbnailStatus,
    );
  }

  /// Constrói uma representação em string do caminho canônico mais curto percorrido na árvore.
  String _getNodePath(dynamic node) {
    if (node == null) return '';
    if (node is NavNode) {
      if (globalActiveNodeOverride != null) {
        final parentPath = node.parent?.obterCaminhoCurto();
        if (parentPath != null && parentPath.isNotEmpty) {
          return '$parentPath -> $globalActiveNodeOverride';
        }
        return globalActiveNodeOverride!;
      }
      return node.obterCaminhoCurto();
    }
    String path = globalActiveNodeOverride ?? node.toString();
    var current = node.parent;
    while (current != null) {
      path = '${current.toString()} -> $path';
      current = current.parent;
    }
    return path;
  }
}
