// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/widgets/provedor_imagem_aresta.dart';

void main() {
  late Directory tempDownloadsDir;
  late Directory tempCacheDir;

  setUp(() async {
    tempDownloadsDir = await Directory.systemTemp.createTemp('downloads_img_test_');
    tempCacheDir = await Directory.systemTemp.createTemp('cache_img_test_');
  });

  tearDown(() async {
    if (await tempDownloadsDir.exists()) {
      await tempDownloadsDir.delete(recursive: true);
    }
    if (await tempCacheDir.exists()) {
      await tempCacheDir.delete(recursive: true);
    }
  });

  group('ProvedorImagemAresta', () {
    test('resolve para FileImage se a imagem existir no diretório permanente /downloads', () async {
      final picoDir = Directory('${tempDownloadsDir.path}/pico_1');
      await picoDir.create(recursive: true);
      final imgFile = File('${picoDir.path}/mapa.webp');
      await imgFile.writeAsBytes([1, 2, 3]);

      final provedor = await ProvedorImagemAresta.resolver(
        picoId: 'pico_1',
        caminho: 'mapa.webp',
        caminhoDownloads: tempDownloadsDir.path,
        caminhoCacheVolatil: tempCacheDir.path,
      );

      expect(provedor, isA<FileImage>());
      expect((provedor as FileImage).file.path, equals(imgFile.path));
    });

    test('resolve para FileImage no /temp_cache se não estiver no /downloads', () async {
      final picoCacheDir = Directory('${tempCacheDir.path}/pico_1');
      await picoCacheDir.create(recursive: true);
      final imgFile = File('${picoCacheDir.path}/mapa.webp');
      await imgFile.writeAsBytes([1, 2, 3]);

      final provedor = await ProvedorImagemAresta.resolver(
        picoId: 'pico_1',
        caminho: 'mapa.webp',
        caminhoDownloads: tempDownloadsDir.path,
        caminhoCacheVolatil: tempCacheDir.path,
      );

      expect(provedor, isA<FileImage>());
      expect((provedor as FileImage).file.path, equals(imgFile.path));
    });

    test('resolve para NetworkImage com baseDir padrão e hash de cache-busting quando não existir localmente', () async {
      final provedor = await ProvedorImagemAresta.resolver(
        picoId: 'pico_1',
        caminho: 'imagens/setor.webp',
        checksumSha256: 'abc123hash',
        baseUrl: 'https://cdn.arestaclimb.com',
        caminhoDownloads: tempDownloadsDir.path,
        caminhoCacheVolatil: tempCacheDir.path,
      );

      expect(provedor, isA<NetworkImage>());
      final netImg = provedor as NetworkImage;
      expect(
        netImg.url,
        equals('https://cdn.arestaclimb.com/picos/pico_1/imagens/setor.webp?v=abc123hash'),
      );
    });

    test('preserva URLs já absolutas que comecem com http ou https', () async {
      final provedor = await ProvedorImagemAresta.resolver(
        picoId: 'pico_1',
        caminho: 'https://cdn.externa.com/fotos/via.jpg',
        checksumSha256: 'xyz789',
        caminhoDownloads: tempDownloadsDir.path,
        caminhoCacheVolatil: tempCacheDir.path,
      );

      expect(provedor, isA<NetworkImage>());
      final netImg = provedor as NetworkImage;
      expect(
        netImg.url,
        equals('https://cdn.externa.com/fotos/via.jpg?v=xyz789'),
      );
    });

    test('resolve para NetworkImage usando baseDir do Indice quando disponível no DatasetRepository', () async {
      final repo = DatasetRepository(editorDeCroqui: EditorDeCroqui());
      repo.indiceData.value = Indice()
        ..croquis.add(
          ResumoCroqui()
            ..id = 'pedra_grande'
            ..caminhoRelativo = 'picos/br_mg_igarape_pedra_grande/compilado.binarypb',
        );

      final provedor = await ProvedorImagemAresta.resolver(
        picoId: 'pedra_grande',
        caminho: 'imagens/setor.webp',
        checksumSha256: 'abc123hash',
        baseUrl: 'https://cdn.arestaclimb.com',
        caminhoDownloads: tempDownloadsDir.path,
        caminhoCacheVolatil: tempCacheDir.path,
      );

      expect(provedor, isA<NetworkImage>());
      final netImg = provedor as NetworkImage;
      expect(
        netImg.url,
        equals('https://cdn.arestaclimb.com/picos/br_mg_igarape_pedra_grande/imagens/setor.webp?v=abc123hash'),
      );
    });
  });
}
