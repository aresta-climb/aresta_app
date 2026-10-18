// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../aresta_api/proto/generated/indice.pb.dart';
import '../../../constants/constantes_rede.dart';
import '../../firebase/app_logger.dart';

/// Extrai os assets pré-embutidos (pre-bundled) do pacote do aplicativo
/// para o diretório de documentos do dispositivo no primeiro acesso.
class ExtratorAssetsPreload {
  /// Copia o `catalogo.db` pré-embutido no bundle para o armazenamento local
  /// caso ainda não exista no disco (ou quando [sobrescrever] for `true`).
  Future<void> extrairCatalogoPreload({
    required String docsPath,
    String? catalogoPath,
    AssetBundle? bundle,
    bool sobrescrever = false,
  }) async {
    final destinoCatalogo = File(catalogoPath ?? '$docsPath/catalogo.db');
    if (!sobrescrever && destinoCatalogo.existsSync()) {
      return;
    }
    try {
      final bundleAtivo = bundle ?? rootBundle;
      final catalogoData = await bundleAtivo.load('assets/preload/catalogo.db');
      if (!destinoCatalogo.parent.existsSync()) {
        destinoCatalogo.parent.createSync(recursive: true);
      }
      await destinoCatalogo.writeAsBytes(
        catalogoData.buffer.asUint8List(
          catalogoData.offsetInBytes,
          catalogoData.lengthInBytes,
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        '[ExtratorAssetsPreload] Preload de catalogo.db não encontrado ou erro ao carregar',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Desempacota o `indice.binarypb`, o `catalogo.db` e as thumbnails pré-baixadas do bundle de assets
  /// para `$docsPath/downloads/thumbnails/`, removendo o diretório legado `$docsPath/thumbnails/`
  /// caso ainda exista no dispositivo.
  Future<void> desempacotarAssetsPreload({
    required String docsPath,
    required String indicePath,
    String? catalogoPath,
    AssetBundle? bundle,
  }) async {
    try {
      final bundleAtivo = bundle ?? rootBundle;

      ByteData? indiceData;
      try {
        indiceData = await bundleAtivo.load('assets/preload/indice.binarypb');
      } catch (e, stackTrace) {
        AppLogger.instance.logError(
          '[ExtratorAssetsPreload] Preload de indice.binarypb não encontrado ou erro ao carregar',
          error: e,
          stackTrace: stackTrace,
        );
        return;
      }

      final indiceFile = File(indicePath);
      await indiceFile.writeAsBytes(
        indiceData.buffer.asUint8List(
          indiceData.offsetInBytes,
          indiceData.lengthInBytes,
        ),
      );

      await extrairCatalogoPreload(
        docsPath: docsPath,
        catalogoPath: catalogoPath,
        bundle: bundleAtivo,
        sobrescrever: true,
      );

      final indice = Indice.fromBuffer(
        indiceData.buffer.asUint8List(
          indiceData.offsetInBytes,
          indiceData.lengthInBytes,
        ),
      );

      final legacyThumbnailsDir = Directory('$docsPath/thumbnails');
      if (legacyThumbnailsDir.existsSync()) {
        try {
          legacyThumbnailsDir.deleteSync(recursive: true);
        } catch (_) {}
      }

      final thumbnailsDir = Directory('$docsPath/downloads/thumbnails');
      if (!thumbnailsDir.existsSync()) {
        thumbnailsDir.createSync(recursive: true);
      }

      for (var resumo in indice.croquis) {
        final urlRelativa = resumo.caminhoRelativo;
        final lastSlash = urlRelativa.lastIndexOf('/');
        if (lastSlash != -1) {
          final baseDir = urlRelativa.substring(0, lastSlash);
          final String cragId = resumo.id.isNotEmpty
              ? resumo.id
              : baseDir.replaceAll('/', '_');

          try {
            final thumbData = await bundleAtivo.load(
              'assets/preload/thumbnails/$cragId.webp',
            );
            final thumbFile = File('${thumbnailsDir.path}/$cragId.webp');
            await thumbFile.writeAsBytes(
              thumbData.buffer.asUint8List(
                thumbData.offsetInBytes,
                thumbData.lengthInBytes,
              ),
            );
          } catch (e, stackTrace) {
            AppLogger.instance.logError(
              '[ExtratorAssetsPreload] Erro ao carregar thumbnail $cragId do preload',
              error: e,
              stackTrace: stackTrace,
            );
          }
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('cached_data_version', NetworkConstants.kDataVersion);
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        '[ExtratorAssetsPreload] Erro geral ao descompactar assets',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
