// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../aresta_api/proto/generated/indice.pb.dart';
import '../../../constants/network_constants.dart';
import '../../firebase/app_logger.dart';

/// Extrai os assets pré-embutidos (pre-bundled) do pacote do aplicativo
/// para o diretório de documentos do dispositivo no primeiro acesso.
class ExtratorAssetsPreload {
  /// Desempacota o `indice.binarypb` e as thumbnails pré-baixadas do bundle de assets.
  Future<void> desempacotarAssetsPreload({
    required String docsPath,
    required String indicePath,
    AssetBundle? bundle,
  }) async {
    try {
      final bundleAtivo = bundle ?? rootBundle;

      ByteData? indiceData;
      try {
        indiceData = await bundleAtivo.load('assets/preload/indice.binarypb');
      } catch (e) {
        AppLogger.instance.logError(
          '[ExtratorAssetsPreload] Preload de indice.binarypb não encontrado ou erro ao carregar',
          error: e,
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

      final indice = Indice.fromBuffer(
        indiceData.buffer.asUint8List(
          indiceData.offsetInBytes,
          indiceData.lengthInBytes,
        ),
      );

      final thumbnailsDir = Directory('$docsPath/thumbnails');
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
          } catch (e) {
            AppLogger.instance.logError(
              '[ExtratorAssetsPreload] Erro ao carregar thumbnail $cragId do preload',
              error: e,
            );
          }
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('cached_data_version', NetworkConstants.kDataVersion);
    } catch (e) {
      AppLogger.instance.logError(
        '[ExtratorAssetsPreload] Erro geral ao descompactar assets',
        error: e,
      );
    }
  }
}
