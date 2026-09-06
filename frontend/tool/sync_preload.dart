// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

/// Script `sync_preload.dart`
///
/// Realiza o pre-bundling do arquivo `indice.binarypb` e todas as thumbnails.
/// Utilizado principalmente via GitHub Actions no momento do version bump (build).
/// Como rodar localmente:
/// `dart run tool/sync_preload.dart`
///
/// Isso fará com que o aplicativo embuta (via assets/preload) uma versão inicial
/// que será descompactada na primeira abertura do app pelo usuário offline.
library;

import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/constants/network_constants.dart';

class SyncPreloadRunner {
  final http.Client client;
  final String baseUrl;
  final String outputDir;

  SyncPreloadRunner({
    required this.client,
    required this.baseUrl,
    required this.outputDir,
  });

  Future<void> run() async {
    final dir = Directory(outputDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final etagFile = File('$outputDir/indice.etag');
    String? existingEtag;
    if (etagFile.existsSync()) {
      existingEtag = etagFile.readAsStringSync().trim();
    }

    final headers = <String, String>{};
    if (existingEtag != null && existingEtag.isNotEmpty) {
      headers['If-None-Match'] = existingEtag;
    }

    // 1. Fetch indice.binarypb
    final response = await client.get(
      Uri.parse('$baseUrl/indice.binarypb'),
      headers: headers,
    );

    if (response.statusCode == 304) {
      print('Preload não modificado (304 Not Modified).');
      return;
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to download indice.binarypb: ${response.statusCode}',
      );
    }

    final newIndice = Indice.fromBuffer(response.bodyBytes);

    // Construir mapa de hashes antigos
    final oldCroquiHashes = <String, String>{};
    final oldThumbnailHashes = <String, String>{};
    final indiceFile = File('$outputDir/indice.binarypb');
    if (indiceFile.existsSync()) {
      try {
        final oldIndice = Indice.fromBuffer(indiceFile.readAsBytesSync());
        for (var croqui in oldIndice.croquis) {
          final lastSlash = croqui.caminhoRelativo.lastIndexOf('/');
          if (lastSlash != -1) {
            final baseDir = croqui.caminhoRelativo.substring(0, lastSlash);
            final cragId = croqui.id.isNotEmpty
                ? croqui.id
                : baseDir.replaceAll('/', '_');
            oldCroquiHashes[cragId] = croqui.checksumSha256Croqui;
            oldThumbnailHashes[cragId] = croqui.checksumSha256Thumbnail;
          }
        }
      } catch (_) {}
    }

    // 2. Fetch thumbnails
    final thumbnailsDir = Directory('$outputDir/thumbnails');
    if (!thumbnailsDir.existsSync()) {
      thumbnailsDir.createSync(recursive: true);
    }

    for (var resumo in newIndice.croquis) {
      final urlRelativa = resumo.caminhoRelativo;
      final lastSlash = urlRelativa.lastIndexOf('/');
      if (lastSlash != -1) {
        final baseDir = urlRelativa.substring(0, lastSlash);
        final String cragId = resumo.id.isNotEmpty
            ? resumo.id
            : baseDir.replaceAll('/', '_');

        final thumbFile = File('${thumbnailsDir.path}/$cragId.webp');
        final bool thumbExists = thumbFile.existsSync();
        final bool isChanged =
            oldThumbnailHashes[cragId] != resumo.checksumSha256Thumbnail;

        if (resumo.checksumSha256Thumbnail.isEmpty) {
          continue; // Não há thumbnail para baixar
        }

        if (thumbExists && !isChanged) {
          continue; // Thumbnail já existe e não sofreu alterações
        }

        final thumbUrl = '$baseUrl/thumbnails/$baseDir.webp';
        final thumbResponse = await client.get(Uri.parse(thumbUrl));

        if (thumbResponse.statusCode == 200) {
          thumbFile.writeAsBytesSync(thumbResponse.bodyBytes);
        } else {
          throw Exception(
            'Falha em baixar thumbnail para $cragId: ${thumbResponse.statusCode}',
          );
        }
      }
    }

    // 3. Salvar indice e etag
    indiceFile.writeAsBytesSync(response.bodyBytes);
    final newEtag = response.headers['etag'];
    if (newEtag != null) {
      etagFile.writeAsStringSync(newEtag);
    }
  }
}

Future<void> main(List<String> args) async {
  final runner = SyncPreloadRunner(
    client: http.Client(),
    baseUrl: NetworkConstants.kDefaultOfficialServerUrl,
    outputDir: 'assets/preload',
  );

  try {
    print('Iniciando pre-load...');
    await runner.run();
    print('Pre-load concluído com sucesso!');
  } catch (e) {
    print('Erro no pre-load: $e');
    exit(1);
  }
}
