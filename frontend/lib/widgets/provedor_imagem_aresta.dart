// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/network_constants.dart';
import '../services/editor_croqui.dart';
import '../services/firebase/app_logger.dart';

/// Provedor unificado e em camadas para resolução de imagens do ecossistema Aresta.
///
/// Ordem de precedência:
/// 1. Armazenamento local permanente (`/downloads/<picoId>/...`)
/// 2. Cache temporário volátil do sistema operacional (`/temp_cache/<picoId>/...`)
/// 3. Streaming remoto da CDN HTTP com cache-busting (`?v=<sha256>`).
class ProvedorImagemAresta {
  const ProvedorImagemAresta._();

  /// Resolve e entrega a instância de [ImageProvider] apropriada para a mídia indicada.
  static Future<ImageProvider?> resolver({
    required String picoId,
    required String caminho,
    String? checksumSha256,
    String? baseUrl,
    String? caminhoDownloads,
    String? caminhoCacheVolatil,
  }) async {
    try {
      if (caminho.isEmpty) return null;

      // 1. Diretório Permanente (/downloads)
      String downloadsRoot = caminhoDownloads ?? '';
      if (downloadsRoot.isEmpty) {
        final docsDir = await getApplicationDocumentsDirectory();
        final editor = EditorDeCroqui.instance;
        downloadsRoot = editor.downloadsPath(docsDir.path);
      }
      final downloadsPicoPath = '$downloadsRoot/$picoId';

      File? localFile = _buscarArquivoNoDiretorio(downloadsPicoPath, caminho);
      if (localFile != null && localFile.existsSync()) {
        return FileImage(localFile);
      }

      // 2. Cache Temporário Volátil (/temp_cache)
      String cacheRoot = caminhoCacheVolatil ?? '';
      if (cacheRoot.isEmpty) {
        final tempDir = await getTemporaryDirectory();
        cacheRoot = '${tempDir.path}/temp_cache';
      }
      final cachePicoPath = '$cacheRoot/$picoId';

      File? cacheFile = _buscarArquivoNoDiretorio(cachePicoPath, caminho);
      if (cacheFile != null && cacheFile.existsSync()) {
        return FileImage(cacheFile);
      }

      // 3. Streaming Remoto / CDN
      final serverBase = baseUrl ?? NetworkConstants.officialServerUrl;
      String urlFinal = caminho;
      if (!urlFinal.startsWith('http://') && !urlFinal.startsWith('https://')) {
        String cleanPath = urlFinal.startsWith('/') ? urlFinal.substring(1) : urlFinal;
        urlFinal = '$serverBase/$cleanPath';
      }

      if (checksumSha256 != null && checksumSha256.isNotEmpty) {
        final uri = Uri.parse(urlFinal);
        final queryParams = Map<String, String>.from(uri.queryParameters);
        queryParams['v'] = checksumSha256;
        urlFinal = uri.replace(queryParameters: queryParams).toString();
      }

      return NetworkImage(urlFinal);
    } catch (e) {
      AppLogger.instance.logError(
        'Erro ao resolver provedor de imagem para $picoId em $caminho',
        error: e,
      );
    }
    return null;
  }

  /// Busca um arquivo em um diretório através de caminho direto ou busca recursiva.
  static File? _buscarArquivoNoDiretorio(String rootDir, String path) {
    if (!Directory(rootDir).existsSync()) return null;

    final baseUrl = '${NetworkConstants.officialServerUrl}/';
    String cleanUrl = Uri.decodeFull(path);
    if (cleanUrl.startsWith(baseUrl)) {
      final relativePath = cleanUrl.replaceFirst(baseUrl, '');
      final directFile = File('$rootDir/$relativePath');
      if (directFile.existsSync()) return directFile;
    }

    String cleanPath = path.startsWith('/') ? path.substring(1) : path;
    final directFile = File('$rootDir/$cleanPath');
    if (directFile.existsSync()) return directFile;

    String fileName = path.split('/').last;
    if (fileName.isNotEmpty) {
      final searchName = Uri.decodeComponent(fileName).toLowerCase();
      String searchBaseName = searchName.contains('.')
          ? searchName.substring(0, searchName.lastIndexOf('.'))
          : searchName;

      try {
        final dir = Directory(rootDir);
        final entities = dir.listSync(recursive: true);
        for (var entity in entities) {
          if (entity is File) {
            final String ePath = entity.path.replaceAll('\\', '/');
            final String eName = ePath.split('/').last;
            final String eNameLower = Uri.decodeComponent(eName).toLowerCase();

            if (eNameLower == searchName) return entity;

            String eBaseName = eNameLower.contains('.')
                ? eNameLower.substring(0, eNameLower.lastIndexOf('.'))
                : eNameLower;

            if (eBaseName == searchBaseName) return entity;
          }
        }
      } catch (_) {}
    }
    return null;
  }
}
