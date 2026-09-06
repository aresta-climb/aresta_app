// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/services/firebase/remote_config_service.dart';
import 'package:frontend/services/dataset_repository.dart';

import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/widgets/provedor_imagem_aresta.dart';
import 'package:frontend/widgets/imagem_arquivo_aresta.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import '../mocks/mock_app_logger.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String tempPath;
  MockPathProviderPlatform(this.tempPath);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempPath;
  @override
  Future<String?> getTemporaryPath() async => tempPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDownloadsDir;
  late Directory tempCacheDir;
  late MockPathProviderPlatform mockPlatform;
  late MockAppLogger mockLogger;

  setUp(() async {
    mockLogger = MockAppLogger();
    AppLogger.instance = mockLogger;
    tempDownloadsDir = await Directory.systemTemp.createTemp('downloads_img_test_');
    tempCacheDir = await Directory.systemTemp.createTemp('cache_img_test_');
    mockPlatform = MockPathProviderPlatform(tempDownloadsDir.path);
    PathProviderPlatform.instance = mockPlatform;
  });

  tearDown(() async {
    AppLogger.resetForTesting();
    try {
      if (await tempDownloadsDir.exists()) {
        await tempDownloadsDir.delete(recursive: true);
      }
      if (await tempCacheDir.exists()) {
        await tempCacheDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('ProvedorImagemAresta', () {
    test('resolve para ImagemArquivoAresta se a imagem existir no diretório permanente /downloads', () async {
      final picoDir = Directory('${tempDownloadsDir.path}/pico_1');
      await picoDir.create(recursive: true);
      final imgFile = File('${picoDir.path}/mapa.webp');
      await imgFile.writeAsBytes([1, 2, 3]);

      final provedor = await ProvedorImagemAresta.resolver(
        picoId: 'pico_1',
        caminho: 'mapa.webp',
        checksumSha256: 'sha_local_1',
        caminhoDownloads: tempDownloadsDir.path,
        caminhoCacheVolatil: tempCacheDir.path,
      );

      expect(provedor, isA<ImagemArquivoAresta>());
      final imgAresta = provedor as ImagemArquivoAresta;
      expect(imgAresta.arquivo.path, equals(imgFile.path));
      expect(imgAresta.checksumSha256, equals('sha_local_1'));
    });

    test('resolve para ImagemArquivoAresta no /temp_cache se não estiver no /downloads', () async {
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

      expect(provedor, isA<ImagemArquivoAresta>());
      expect((provedor as ImagemArquivoAresta).arquivo.path, equals(imgFile.path));
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

    test('retorna null se o picoId ou caminho for vazio', () async {
      expect(await ProvedorImagemAresta.resolver(picoId: '', caminho: 'foto.jpg'), isNull);
      expect(await ProvedorImagemAresta.resolver(picoId: 'pico_1', caminho: ''), isNull);
    });

    test('normaliza caminhos com barras iniciais corretamente', () async {
      final provedor = await ProvedorImagemAresta.resolver(
        picoId: 'pico_1',
        caminho: '/imagens/setor.webp',
        checksumSha256: 'hash123',
        baseUrl: 'https://cdn.arestaclimb.com',
        caminhoDownloads: tempDownloadsDir.path,
        caminhoCacheVolatil: tempCacheDir.path,
      );

      expect(provedor, isA<NetworkImage>());
      final netImg = provedor as NetworkImage;
      expect(
        netImg.url,
        equals('https://cdn.arestaclimb.com/picos/pico_1/imagens/setor.webp?v=hash123'),
      );
    });

    test('adiciona &v=<hash> se a URL remota já possuir parâmetros de query', () async {
      final provedor = await ProvedorImagemAresta.resolver(
        picoId: 'pico_1',
        caminho: 'https://servidor.com/imagem.webp?token=abc',
        checksumSha256: 'xyz999',
        caminhoDownloads: tempDownloadsDir.path,
        caminhoCacheVolatil: tempCacheDir.path,
      );

      expect(provedor, isA<NetworkImage>());
      final netImg = provedor as NetworkImage;
      expect(
        netImg.url,
        equals('https://servidor.com/imagem.webp?token=abc&v=xyz999'),
      );
    });

    test('auto-resolve checksumSha256 a partir do DatasetRepository para arquivo local', () async {
      final repo = DatasetRepository(editorDeCroqui: EditorDeCroqui());
      final croqui = Croqui()
        ..arquivosExternos.add(
          ArquivoExterno(
            caminho: 'mapa.webp',
            checksumSha256: 'sha_auto_local_999',
          ),
        );
      repo.indexarMidiasDoCroqui('pico_1', croqui);

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

      expect(provedor, isA<ImagemArquivoAresta>());
      final imgAresta = provedor as ImagemArquivoAresta;
      expect(imgAresta.checksumSha256, equals('sha_auto_local_999'));
    });

    test('auto-resolve checksumSha256 a partir do DatasetRepository para NetworkImage', () async {
      final repo = DatasetRepository(editorDeCroqui: EditorDeCroqui());
      final croqui = Croqui()
        ..arquivosExternos.add(
          ArquivoExterno(
            caminho: 'fotos/via.jpg',
            checksumSha256: 'sha_auto_remote_888',
          ),
        );
      repo.indexarMidiasDoCroqui('pico_1', croqui);

      final provedor = await ProvedorImagemAresta.resolver(
        picoId: 'pico_1',
        caminho: 'fotos/via.jpg',
        baseUrl: 'https://cdn.arestaclimb.com',
        caminhoDownloads: tempDownloadsDir.path,
        caminhoCacheVolatil: tempCacheDir.path,
      );

      expect(provedor, isA<NetworkImage>());
      final netImg = provedor as NetworkImage;
      expect(netImg.url, contains('?v=sha_auto_remote_888'));
    });

    test('TDD 3.3: auto-resolve checksumSha256 para NetworkImage a partir de sessão online com fallback dinâmico', () async {
      final repo = DatasetRepository(editorDeCroqui: EditorDeCroqui());
      final croqui = Croqui()
        ..arquivosExternos.add(
          ArquivoExterno(
            caminho: 'mapas/mapa_online.webp',
            checksumSha256: 'sha_online_live_reload',
          ),
        );
      repo.gerenciadorSessaoOnline.registrarCroquiOnline('pico_online_teste', croqui);

      final provedor = await ProvedorImagemAresta.resolver(
        picoId: 'pico_online_teste',
        caminho: 'mapas/mapa_online.webp',
        baseUrl: 'https://cdn.arestaclimb.com',
        caminhoDownloads: tempDownloadsDir.path,
        caminhoCacheVolatil: tempCacheDir.path,
        datasetRepository: repo,
      );

      expect(provedor, isA<NetworkImage>());
      final netImg = provedor as NetworkImage;
      expect(netImg.url, contains('?v=sha_online_live_reload'));
    });

    test('resolve usando caminhos padrão quando caminhoDownloads e caminhoCacheVolatil são nulos', () async {
      final editor = EditorDeCroqui.instance;
      final docsDownloads = editor.downloadsPath(tempDownloadsDir.path);
      final picoDir = Directory('$docsDownloads/pico_default');
      await picoDir.create(recursive: true);
      final img = File('${picoDir.path}/capa.webp');
      await img.writeAsBytes([1, 2, 3]);

      final provedor = await ProvedorImagemAresta.resolver(
        picoId: 'pico_default',
        caminho: 'capa.webp',
      );

      expect(provedor, isA<ImagemArquivoAresta>());
    });

    test('resolve arquivo local quando caminho é URL completa do servidor oficial', () async {
      final picoDir = Directory('${tempDownloadsDir.path}/pico_1');
      await picoDir.create(recursive: true);
      final img = File('${picoDir.path}/mapa_oficial.webp');
      await img.writeAsBytes([1, 2, 3]);

      final provedor = await ProvedorImagemAresta.resolver(
        picoId: 'pico_1',
        caminho: '${RemoteConfigService.instance.officialServerUrl}/mapa_oficial.webp',
        caminhoDownloads: tempDownloadsDir.path,
      );

      expect(provedor, isA<ImagemArquivoAresta>());
    });

    test('resolve para ImagemArquivoAresta no cache volátil padrão quando não está em downloads', () async {
      final cacheDir = Directory('${tempDownloadsDir.path}/temp_cache/pico_temp');
      await cacheDir.create(recursive: true);
      final img = File('${cacheDir.path}/foto_temp.webp');
      await img.writeAsBytes([1, 2, 3]);

      final provedor = await ProvedorImagemAresta.resolver(
        picoId: 'pico_temp',
        caminho: 'foto_temp.webp',
        caminhoDownloads: '${tempDownloadsDir.path}/downloads_vazios',
      );

      expect(provedor, isA<ImagemArquivoAresta>());
    });

    test('encontra arquivo em subpasta por busca recursiva', () async {
      final picoDir = Directory('${tempDownloadsDir.path}/pico_1/subpasta');
      await picoDir.create(recursive: true);
      final img = File('${picoDir.path}/foto_subpasta.webp');
      await img.writeAsBytes([1, 2, 3]);

      final provedor = await ProvedorImagemAresta.resolver(
        picoId: 'pico_1',
        caminho: 'foto_subpasta.webp',
        caminhoDownloads: tempDownloadsDir.path,
      );

      expect(provedor, isA<ImagemArquivoAresta>());
    });

    test('retorna ResizeImage quando larguraAlvo ou alturaAlvo for especificada para arquivo local', () async {
      final picoDir = Directory('${tempDownloadsDir.path}/pico_1');
      await picoDir.create(recursive: true);
      final imgFile = File('${picoDir.path}/mapa.webp');
      await imgFile.writeAsBytes([1, 2, 3]);

      final provedor = await ProvedorImagemAresta.resolver(
        picoId: 'pico_1',
        caminho: 'mapa.webp',
        caminhoDownloads: tempDownloadsDir.path,
        caminhoCacheVolatil: tempCacheDir.path,
        larguraAlvo: 300,
        alturaAlvo: 200,
      );

      expect(provedor, isA<ResizeImage>());
      final resize = provedor as ResizeImage;
      expect(resize.width, equals(300));
      expect(resize.height, equals(200));
      expect(resize.imageProvider, isA<ImagemArquivoAresta>());
    });

    test('retorna ResizeImage quando larguraAlvo for especificada para NetworkImage', () async {
      final provedor = await ProvedorImagemAresta.resolver(
        picoId: 'pico_1',
        caminho: 'imagens/setor.webp',
        baseUrl: 'https://cdn.arestaclimb.com',
        caminhoDownloads: tempDownloadsDir.path,
        caminhoCacheVolatil: tempCacheDir.path,
        larguraAlvo: 400,
      );

      expect(provedor, isA<ResizeImage>());
      final resize = provedor as ResizeImage;
      expect(resize.width, equals(400));
      expect(resize.height, isNull);
      expect(resize.imageProvider, isA<NetworkImage>());
    });

    test('TDD 2.3: utiliza timestamp de modificação como fallback dinâmico para arquivos locais sem hash explícito', () async {
      final picoDir = Directory('${tempDownloadsDir.path}/pico_1');
      await picoDir.create(recursive: true);
      final imgFile = File('${picoDir.path}/sem_hash.webp');
      await imgFile.writeAsBytes([1, 2, 3]);

      final provedor = await ProvedorImagemAresta.resolver(
        picoId: 'pico_1',
        caminho: 'sem_hash.webp',
        caminhoDownloads: tempDownloadsDir.path,
        caminhoCacheVolatil: tempCacheDir.path,
      );

      expect(provedor, isA<ImagemArquivoAresta>());
      final imgAresta = provedor as ImagemArquivoAresta;
      expect(imgAresta.checksumSha256, equals(imgFile.lastModifiedSync().millisecondsSinceEpoch.toString()));
    });

    test('TDD: dispara erro na telemetria e segue em frente com lastModifiedSync se checksumSha256 for nulo para arquivo local em /downloads', () async {
      final picoDir = Directory('${tempDownloadsDir.path}/pico_1');
      await picoDir.create(recursive: true);
      final imgFile = File('${picoDir.path}/sem_hash_downloads.webp');
      await imgFile.writeAsBytes([1, 2, 3]);

      final provedor = await ProvedorImagemAresta.resolver(
        picoId: 'pico_1',
        caminho: 'sem_hash_downloads.webp',
        caminhoDownloads: tempDownloadsDir.path,
        caminhoCacheVolatil: tempCacheDir.path,
      );

      expect(provedor, isA<ImagemArquivoAresta>());
      final imgAresta = provedor as ImagemArquivoAresta;
      expect(imgAresta.checksumSha256, equals(imgFile.lastModifiedSync().millisecondsSinceEpoch.toString()));

      // Verifica erro registrado na telemetria
      expect(mockLogger.recordedErrors, isNotEmpty);
      final erro = mockLogger.recordedErrors.first;
      expect(erro['contextMessage'], contains('Checksum SHA-256 ausente ou nulo'));
      expect(erro['contextMessage'], contains('pico_1'));
      expect(erro['contextMessage'], contains('sem_hash_downloads.webp'));
    });

    test('TDD: dispara erro na telemetria e segue em frente com lastModifiedSync se checksumSha256 for nulo para arquivo em /temp_cache', () async {
      final picoCacheDir = Directory('${tempCacheDir.path}/pico_1');
      await picoCacheDir.create(recursive: true);
      final imgFile = File('${picoCacheDir.path}/sem_hash_cache.webp');
      await imgFile.writeAsBytes([1, 2, 3]);

      final provedor = await ProvedorImagemAresta.resolver(
        picoId: 'pico_1',
        caminho: 'sem_hash_cache.webp',
        caminhoDownloads: tempDownloadsDir.path,
        caminhoCacheVolatil: tempCacheDir.path,
      );

      expect(provedor, isA<ImagemArquivoAresta>());
      final imgAresta = provedor as ImagemArquivoAresta;
      expect(imgAresta.checksumSha256, equals(imgFile.lastModifiedSync().millisecondsSinceEpoch.toString()));

      // Verifica erro registrado na telemetria
      expect(mockLogger.recordedErrors, isNotEmpty);
      final erro = mockLogger.recordedErrors.first;
      expect(erro['contextMessage'], contains('Checksum SHA-256 ausente ou nulo'));
      expect(erro['contextMessage'], contains('pico_1'));
      expect(erro['contextMessage'], contains('sem_hash_cache.webp'));
    });

    test('não dispara erro na telemetria se checksumSha256 estiver presente para arquivo local', () async {
      final picoDir = Directory('${tempDownloadsDir.path}/pico_1');
      await picoDir.create(recursive: true);
      final imgFile = File('${picoDir.path}/com_hash.webp');
      await imgFile.writeAsBytes([1, 2, 3]);

      final provedor = await ProvedorImagemAresta.resolver(
        picoId: 'pico_1',
        caminho: 'com_hash.webp',
        checksumSha256: 'hash_valido_999',
        caminhoDownloads: tempDownloadsDir.path,
        caminhoCacheVolatil: tempCacheDir.path,
      );

      expect(provedor, isA<ImagemArquivoAresta>());
      expect(mockLogger.recordedErrors, isEmpty);
    });
  });
}



