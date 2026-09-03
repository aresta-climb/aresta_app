// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/network_constants.dart';
import '../services/dataset_repository.dart';
import '../services/editor_croqui.dart';
import '../services/firebase/app_logger.dart';
import 'imagem_arquivo_aresta.dart';

/// Provedor unificado e em camadas para resolução de imagens do ecossistema Aresta.
///
/// Ordem de precedência:
/// 1. Armazenamento local permanente (`/downloads/<picoId>/...`)
/// 2. Cache temporário volátil do sistema operacional (`/temp_cache/<picoId>/...`)
/// 3. Streaming remoto da CDN HTTP com cache-busting (`?v=<sha256>`).
class ProvedorImagemAresta {
  const ProvedorImagemAresta._();

  /// Resolve e entrega a instância de [ImageProvider] apropriada para a mídia indicada.
  ///
  /// O [checksumSha256] é opcional; quando omitido ou nulo, o provedor tenta
  /// auto-resolvê-lo consultando a tabela de dispersão do [DatasetRepository].
  ///
  /// Se [larguraAlvo] ou [alturaAlvo] forem especificados, o [ImageProvider] resultante
  /// será encapsulado por um [ResizeImage] via [ResizeImage.resizeIfNeeded] para garantir
  /// que a decodificação do bitmap na memória RAM seja otimizada e caiba no orçamento de memória.
  static Future<ImageProvider?> resolver({
    required String picoId,
    required String caminho,
    String? checksumSha256,
    String? baseUrl,
    String? caminhoDownloads,
    String? caminhoCacheVolatil,
    DatasetRepository? datasetRepository,
    int? larguraAlvo,
    int? alturaAlvo,
  }) async {
    try {
      if (picoId.isEmpty || caminho.isEmpty) return null;

      ImageProvider? provedorBase;

      // Auto-resolução do checksum SHA-256 via DatasetRepository se não fornecido
      String? hashEfetivo = checksumSha256;
      if (hashEfetivo == null || hashEfetivo.isEmpty) {
        try {
          final repo = datasetRepository ?? DatasetRepository.instance;
          if (repo != null) {
            hashEfetivo = repo.obterSha256DaMidia(picoId, caminho);
          }
        } catch (_) {}
      }

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
        provedorBase = ImagemArquivoAresta(localFile, checksumSha256: hashEfetivo);
      }

      // 2. Cache Temporário Volátil (/temp_cache)
      if (provedorBase == null) {
        String cacheRoot = caminhoCacheVolatil ?? '';
        if (cacheRoot.isEmpty) {
          final tempDir = await getTemporaryDirectory();
          cacheRoot = '${tempDir.path}/temp_cache';
        }
        final cachePicoPath = '$cacheRoot/$picoId';

        File? cacheFile = _buscarArquivoNoDiretorio(cachePicoPath, caminho);
        if (cacheFile != null && cacheFile.existsSync()) {
          provedorBase = ImagemArquivoAresta(cacheFile, checksumSha256: hashEfetivo);
        }
      }

      // 3. Streaming Remoto / CDN
      if (provedorBase == null) {
        String serverBase = baseUrl ?? '';
        if (serverBase.isEmpty) {
          try {
            serverBase = EditorDeCroqui.instance.activeBaseUrl;
          } catch (_) {
            serverBase = NetworkConstants.officialServerUrl;
          }
        }

        String urlFinal = caminho;
        if (!urlFinal.startsWith('http://') && !urlFinal.startsWith('https://')) {
          String cleanPath =
              urlFinal.startsWith('/') ? urlFinal.substring(1) : urlFinal;

          // Resolve o diretório base do pico no índice remoto (ex: "picos/br_mg_igarape_pedra_grande")
          String baseDir = _obterBaseDirDoIndice(picoId);

          String remotePath = cleanPath;
          if (baseDir.isNotEmpty &&
              !remotePath.startsWith(baseDir) &&
              !remotePath.startsWith('picos/')) {
            remotePath = '$baseDir/$cleanPath';
          }

          urlFinal = '$serverBase/$remotePath';
        }

        if (hashEfetivo != null && hashEfetivo.isNotEmpty) {
          final uri = Uri.parse(urlFinal);
          final queryParams = Map<String, String>.from(uri.queryParameters);
          queryParams['v'] = hashEfetivo;
          urlFinal = uri.replace(queryParameters: queryParams).toString();
        }

        provedorBase = NetworkImage(urlFinal);
      }

      if (larguraAlvo != null || alturaAlvo != null) {
        return ResizeImage.resizeIfNeeded(larguraAlvo, alturaAlvo, provedorBase);
      }

      return provedorBase;
    } catch (e) {
      AppLogger.instance.logError(
        'Erro ao resolver provedor de imagem para $picoId em $caminho',
        error: e,
      );
    }
    return null;
  }


  /// Recupera o diretório base do pico a partir do índice carregado em memória.
  static String _obterBaseDirDoIndice(String picoId) {
    try {
      final repo = DatasetRepository.instance;
      if (repo != null) {
        final indice = repo.indiceData.value;
        if (indice != null) {
          final match = indice.croquis.where((r) => r.id == picoId);
          if (match.isNotEmpty) {
            final caminhoRelativo = match.first.caminhoRelativo;
            final lastSlash = caminhoRelativo.lastIndexOf('/');
            if (lastSlash != -1) {
              return caminhoRelativo.substring(0, lastSlash);
            }
          }
        }
      }
    } catch (_) {}
    return 'picos/$picoId';
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
