// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
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

    group('Motor de Cache Volátil e Integridade (Tasks 2.1 - 2.5)', () {
      test('TDD 2.1: exige checksumSha256 para salvar em temp_cache; na ausência, emite telemetria e recorre a NetworkImage', () async {
        final cliente = _ClienteHttpEspiao();
        final provedor = await ProvedorImagemAresta.resolver(
          picoId: 'pico_remoto',
          caminho: 'setor/foto.png',
          checksumSha256: null,
          baseUrl: 'https://cdn.arestaclimb.com',
          caminhoDownloads: tempDownloadsDir.path,
          caminhoCacheVolatil: tempCacheDir.path,
          clienteHttp: cliente,
        );

        expect(provedor, isA<NetworkImage>());
        final netImg = provedor as NetworkImage;
        expect(netImg.url, contains('foto.png'));
        expect(netImg.url, isNot(contains('?v=')));

        // Verifica que NENHUM arquivo foi gravado no temp_cache
        final pastaPico = Directory('${tempCacheDir.path}/pico_remoto');
        expect(pastaPico.existsSync(), isFalse);
        expect(cliente.chamadas, equals(0));

        // Verifica telemetria de erro
        expect(mockLogger.recordedErrors.any((e) =>
          e['contextMessage'].contains('ausente ou nulo') &&
          e['contextMessage'].contains('pico_remoto')
        ), isTrue);
      });

      test('TDD 2.2: baixa imagem da CDN, persiste em temp_cache com <caminho>.<hash> e resolve localmente na segunda chamada', () async {
        final cliente = _ClienteHttpEspiao();
        const hash = 'hash_sha256_valido_123';

        // 1ª chamada: Baixa e salva no temp_cache
        final provedor1 = await ProvedorImagemAresta.resolver(
          picoId: 'pico_remoto',
          caminho: 'setor1/foto.png',
          checksumSha256: hash,
          baseUrl: 'https://cdn.arestaclimb.com',
          caminhoDownloads: tempDownloadsDir.path,
          caminhoCacheVolatil: tempCacheDir.path,
          clienteHttp: cliente,
        );

        expect(provedor1, isA<ImagemArquivoAresta>());
        expect(cliente.chamadas, equals(1));

        final arquivoCache = File('${tempCacheDir.path}/pico_remoto/setor1/foto.png.$hash');
        expect(arquivoCache.existsSync(), isTrue);

        // 2ª chamada: Lê do temp_cache sem chamar a rede
        final provedor2 = await ProvedorImagemAresta.resolver(
          picoId: 'pico_remoto',
          caminho: 'setor1/foto.png',
          checksumSha256: hash,
          baseUrl: 'https://cdn.arestaclimb.com',
          caminhoDownloads: tempDownloadsDir.path,
          caminhoCacheVolatil: tempCacheDir.path,
          clienteHttp: cliente,
        );

        expect(provedor2, isA<ImagemArquivoAresta>());
        expect(cliente.chamadas, equals(1), reason: 'Não deve disparar requisição HTTP adicional');
      });

      test('TDD 2.3: expurga arquivos com hashes anteriores da mesma mídia após salvar nova versão', () async {
        final pastaSetor = Directory('${tempCacheDir.path}/pico_remoto/setor1');
        await pastaSetor.create(recursive: true);

        final versaoAntiga = File('${pastaSetor.path}/foto.png.hash_antigo_000');
        await versaoAntiga.writeAsBytes([1, 2, 3]);

        final outraMidia = File('${pastaSetor.path}/outra.png.hash_outra_111');
        await outraMidia.writeAsBytes([4, 5, 6]);

        expect(versaoAntiga.existsSync(), isTrue);
        expect(outraMidia.existsSync(), isTrue);

        final cliente = _ClienteHttpEspiao();
        await ProvedorImagemAresta.resolver(
          picoId: 'pico_remoto',
          caminho: 'setor1/foto.png',
          checksumSha256: 'hash_novo_999',
          baseUrl: 'https://cdn.arestaclimb.com',
          caminhoDownloads: tempDownloadsDir.path,
          caminhoCacheVolatil: tempCacheDir.path,
          clienteHttp: cliente,
        );

        final versaoNova = File('${pastaSetor.path}/foto.png.hash_novo_999');
        expect(versaoNova.existsSync(), isTrue);
        expect(versaoAntiga.existsSync(), isFalse, reason: 'Versão antiga deve ser expurgada');
        expect(outraMidia.existsSync(), isTrue, reason: 'Outras mídias não devem ser afetadas');
      });

      test('TDD 2.4: deduplica downloads concorrentes para a mesma mídia em paralelo', () async {
        final cliente = _ClienteHttpEspiao(atraso: const Duration(milliseconds: 30));
        const hash = 'hash_concorrente_888';

        final resultados = await Future.wait([
          ProvedorImagemAresta.resolver(
            picoId: 'pico_remoto',
            caminho: 'setor/concorrente.png',
            checksumSha256: hash,
            baseUrl: 'https://cdn.arestaclimb.com',
            caminhoDownloads: tempDownloadsDir.path,
            caminhoCacheVolatil: tempCacheDir.path,
            clienteHttp: cliente,
          ),
          ProvedorImagemAresta.resolver(
            picoId: 'pico_remoto',
            caminho: 'setor/concorrente.png',
            checksumSha256: hash,
            baseUrl: 'https://cdn.arestaclimb.com',
            caminhoDownloads: tempDownloadsDir.path,
            caminhoCacheVolatil: tempCacheDir.path,
            clienteHttp: cliente,
          ),
          ProvedorImagemAresta.resolver(
            picoId: 'pico_remoto',
            caminho: 'setor/concorrente.png',
            checksumSha256: hash,
            baseUrl: 'https://cdn.arestaclimb.com',
            caminhoDownloads: tempDownloadsDir.path,
            caminhoCacheVolatil: tempCacheDir.path,
            clienteHttp: cliente,
          ),
        ]);

        expect(resultados.length, equals(3));
        for (final res in resultados) {
          expect(res, isA<ImagemArquivoAresta>());
        }
        expect(cliente.chamadas, equals(1), reason: 'Múltiplas chamadas simultâneas devem reutilizar a mesma Future');
      });

      test('TDD 2.5: resolve e cacheia miniatura global sob temp_cache/thumbnails/<picoId>.webp.<hash>', () async {
        final cliente = _ClienteHttpEspiao();
        const hashThumb = 'hash_thumb_777';

        final provedor = await ProvedorImagemAresta.resolver(
          picoId: 'pico_global',
          caminho: 'thumbnails/pico_global.webp',
          checksumSha256: hashThumb,
          baseUrl: 'https://cdn.arestaclimb.com',
          caminhoDownloads: tempDownloadsDir.path,
          caminhoCacheVolatil: tempCacheDir.path,
          clienteHttp: cliente,
        );

        expect(provedor, isA<ImagemArquivoAresta>());
        expect(cliente.chamadas, equals(1));

        final arquivoThumb = File('${tempCacheDir.path}/thumbnails/pico_global.webp.$hashThumb');
        expect(arquivoThumb.existsSync(), isTrue);

        final provedor2 = await ProvedorImagemAresta.resolver(
          picoId: 'pico_global',
          caminho: 'thumbnails/pico_global.webp',
          checksumSha256: hashThumb,
          baseUrl: 'https://cdn.arestaclimb.com',
          caminhoDownloads: tempDownloadsDir.path,
          caminhoCacheVolatil: tempCacheDir.path,
          clienteHttp: cliente,
        );
        expect(provedor2, isA<ImagemArquivoAresta>());
        expect(cliente.chamadas, equals(1));
      });

      test('resolve caminho relativo com prefixo ./ e normaliza busca em diretório', () async {
        final picoDir = Directory('${tempDownloadsDir.path}/pico_relativo');
        await picoDir.create(recursive: true);
        final img = File('${picoDir.path}/foto_ponto_barra.webp');
        await img.writeAsBytes([10, 20, 30]);

        final provedor = await ProvedorImagemAresta.resolver(
          picoId: 'pico_relativo',
          caminho: './foto_ponto_barra.webp',
          caminhoDownloads: tempDownloadsDir.path,
          caminhoCacheVolatil: tempCacheDir.path,
          checksumSha256: 'hash_relativo',
        );

        expect(provedor, isA<ImagemArquivoAresta>());
      });

      test('resolve miniatura em downloadsRoot quando nao existir na raiz de documentos', () async {
        final thumbDownloadsDir = Directory('${tempDownloadsDir.path}/thumbnails');
        await thumbDownloadsDir.create(recursive: true);
        final thumbFile = File('${thumbDownloadsDir.path}/pico_secundario.webp');
        await thumbFile.writeAsBytes([1, 2, 3, 4]);

        final provedor = await ProvedorImagemAresta.resolver(
          picoId: 'pico_secundario',
          caminho: 'thumbnails/pico_secundario.webp',
          caminhoDownloads: tempDownloadsDir.path,
          caminhoCacheVolatil: tempCacheDir.path,
          checksumSha256: 'hash_secundario',
        );

        expect(provedor, isA<ImagemArquivoAresta>());
      });

      test('trata excecao de rede durante o download e recorre a NetworkImage sem falhar', () async {
        final clienteQuebrado = _ClienteHttpComExcecao();

        final provedor = await ProvedorImagemAresta.resolver(
          picoId: 'pico_erro_rede',
          caminho: 'foto_falha.webp',
          checksumSha256: 'hash_falha',
          baseUrl: 'https://cdn.arestaclimb.com',
          caminhoDownloads: tempDownloadsDir.path,
          caminhoCacheVolatil: tempCacheDir.path,
          clienteHttp: clienteQuebrado,
        );

        expect(provedor, isA<NetworkImage>());
        expect(mockLogger.recordedErrors, isNotEmpty);
      });

      test('TDD: resolve miniatura local permanente quando caminho for URL remota legada contendo imagens/thumbnail.webp', () async {
        final thumbDocsDir = Directory('${tempDownloadsDir.path}/thumbnails');
        await thumbDocsDir.create(recursive: true);
        final thumbFile = File('${thumbDocsDir.path}/pico_legado_local.webp');
        await thumbFile.writeAsBytes([1, 2, 3, 4]);

        final provedor = await ProvedorImagemAresta.resolver(
          picoId: 'pico_legado_local',
          caminho: 'https://serving.arestaclimb.com/v4/pico_legado_local/imagens/thumbnail.webp',
          caminhoDownloads: tempDownloadsDir.path,
          caminhoCacheVolatil: tempCacheDir.path,
          checksumSha256: 'hash_legado_local',
        );

        expect(provedor, isA<ImagemArquivoAresta>());
        final img = provedor as ImagemArquivoAresta;
        expect(img.arquivo.path.replaceAll(r'\', '/'), endsWith('thumbnails/pico_legado_local.webp'));
      });

      test('TDD: resolve e baixa miniatura remota sob thumbnails/<picoId>.webp quando caminho for imagens/thumbnail.webp', () async {
        final cliente = _ClienteHttpEspiao();
        const hashThumb = 'hash_thumb_canonica';

        final provedor = await ProvedorImagemAresta.resolver(
          picoId: 'pico_legado_remoto',
          caminho: 'https://serving.arestaclimb.com/v4/pico_legado_remoto/imagens/thumbnail.webp',
          checksumSha256: hashThumb,
          baseUrl: 'https://cdn.arestaclimb.com',
          caminhoDownloads: tempDownloadsDir.path,
          caminhoCacheVolatil: tempCacheDir.path,
          clienteHttp: cliente,
        );

        expect(provedor, isA<ImagemArquivoAresta>());
        expect(cliente.chamadas, equals(1));
        // A requisição enviada à CDN DEVE usar a rota canônica /thumbnails/<picoId>.webp, NUNCA imagens/thumbnail.webp
        expect(cliente.urlsRequisitadas.first.path, equals('/thumbnails/pico_legado_remoto.webp'));
        expect(cliente.urlsRequisitadas.first.queryParameters['v'], equals(hashThumb));

        final arquivoSalvo = File('${tempCacheDir.path}/thumbnails/pico_legado_remoto.webp.$hashThumb');
        expect(arquivoSalvo.existsSync(), isTrue);
      });
    });
  });
}

class _ClienteHttpComExcecao extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    throw const SocketException('Conexão recusada na rede de teste');
  }
}

class _ClienteHttpEspiao extends http.BaseClient {
  final Map<String, List<int>> respostas;
  final int statusCode;
  final Duration atraso;
  int chamadas = 0;
  final List<Uri> urlsRequisitadas = [];

  _ClienteHttpEspiao({
    this.respostas = const {},
    this.statusCode = 200,
    this.atraso = Duration.zero,
  });

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    chamadas++;
    urlsRequisitadas.add(request.url);
    if (atraso > Duration.zero) {
      await Future.delayed(atraso);
    }

    List<int> bytes = const [
      137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 10, 73, 68, 65, 84, 120, 156, 99, 0, 1, 0, 0, 5, 0, 1, 13, 10, 45, 180, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130
    ];
    for (var entry in respostas.entries) {
      if (request.url.path.contains(entry.key)) {
        bytes = entry.value;
        break;
      }
    }

    return http.StreamedResponse(
      Stream.value(bytes),
      statusCode,
      contentLength: bytes.length,
      headers: {'content-type': 'image/png'},
    );
  }
}



