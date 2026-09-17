// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/mapa_thumbnail.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/main.dart';
import 'package:frontend/navigation/navigation_tree.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import '../mocks/mock_telemetry_service.dart';

final Uint8List kTransparentImage = Uint8List.fromList([
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

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
  late Directory tempDir;

  setUp(() async {
    EditorDeCroqui();
    tempDir = await Directory.systemTemp.createTemp('mapa_thumb_test_');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);
  });

  tearDown(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  testWidgets('MapaThumbnail calls logAbrirMapa on tap', (tester) async {
    final mockTelemetry = MockTelemetryService();
    TelemetryService.instance = mockTelemetry;

    final mapa = Mapa()
      ..caminhoImagemMapa = 'teste.png'
      ..larguraMapa = 100
      ..alturaMapa = 100;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapaThumbnail(
            mapas: [mapa],
            cragId: 'crag1',
            nomeContexto: 'Contexto Teste',
            imageProviderOverride: MemoryImage(kTransparentImage),
          ),
        ),
      ),
    );

    // Pump to resolve FutureBuilder
    await tester.pumpAndSettle();

    // Tap on the generated button
    await tester.tap(find.text('Abrir Mapa Interativo'));
    await tester.pumpAndSettle();

    expect(mockTelemetry.recordedEvents, contains('abrir_mapa'));
    expect(
      mockTelemetry.recordedParams['abrir_mapa']!['nome_setor'],
      'Contexto Teste',
    );
  });

  testWidgets('MapaThumbnail renders multiple maps text correctly', (tester) async {
    final mapa1 = Mapa()
      ..caminhoImagemMapa = 'teste1.png'
      ..larguraMapa = 100
      ..alturaMapa = 100;
      
    final mapa2 = Mapa()
      ..caminhoImagemMapa = 'teste2.png'
      ..larguraMapa = 100
      ..alturaMapa = 100;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapaThumbnail(
            mapas: [mapa1, mapa2],
            cragId: 'crag1',
            nomeContexto: 'Contexto Teste',
            imageProviderOverride: MemoryImage(kTransparentImage),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Mapas Interativos (2)'), findsOneWidget);
    expect(find.text('Abrir Mapa Interativo'), findsNothing);
  });

  testWidgets('MapaThumbnail re-resolve imagem no didUpdateWidget mesmo com mapas idênticos', (tester) async {
    final mapa = Mapa()
      ..caminhoImagemMapa = 'teste.png'
      ..larguraMapa = 100
      ..alturaMapa = 100;

    final img1 = MemoryImage(kTransparentImage);
    final img2 = MemoryImage(Uint8List.fromList(kTransparentImage));


    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapaThumbnail(
            mapas: [mapa],
            cragId: 'crag1',
            imageProviderOverride: img1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Re-pump simulando hot reload com novo providerOverride e mapa idêntico
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapaThumbnail(
            mapas: [mapa],
            cragId: 'crag1',
            imageProviderOverride: img2,
          ),
        ),
      ),
    );
    await tester.pump();
  });

  group('resolveMapImageProvider & resolveImagePathProvider Downsampling Tests', () {
    test('resolveMapImageProvider aplica larguraAlvo padrão de 400', () async {
      final mapa = Mapa()..caminhoImagemMapa = 'https://cdn.arestaclimb.com/mapa.webp';
      final provider = await resolveMapImageProvider('pico_teste', mapa);
      expect(provider, isA<ResizeImage>());
      final resize = provider as ResizeImage;
      expect(resize.width, equals(400));
    });

    test('resolveImagePathProvider repassa larguraAlvo customizada', () async {
      final provider = await resolveImagePathProvider(
        'pico_teste',
        'https://cdn.arestaclimb.com/foto.webp',
        larguraAlvo: 600,
        alturaAlvo: 400,
      );
      expect(provider, isA<ResizeImage>());
      final resize = provider as ResizeImage;
      expect(resize.width, equals(600));
      expect(resize.height, equals(400));
    });
  });

  group('Renderização Imediata e Não-Bloqueante (Latência Zero)', () {
    testWidgets(
      'renderiza moldura e botão Abrir Mapa Interativo no primeiro frame enquanto imagem está pendente',
      (tester) async {
        final completer = Completer<ImageProvider?>();
        final mapa = Mapa()
          ..caminhoImagemMapa = 'imagem_pendente.png'
          ..larguraMapa = 400
          ..alturaMapa = 200;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MapaThumbnail(
                mapas: [mapa],
                cragId: 'crag1',
                imageProviderFutureOverride: completer.future,
              ),
            ),
          ),
        );

        // Apenas 1 frame inicial (sem pumpAndSettle)
        await tester.pump();

        // O botão DEVE estar presente imediatamente mesmo enquanto a imagem estiver pendente!
        expect(find.text('Abrir Mapa Interativo'), findsOneWidget);
        expect(find.byIcon(Icons.map), findsOneWidget);

        // O container deve respeitar a proporção
        final aspectRatioFinder = find.byType(AspectRatio);
        expect(aspectRatioFinder, findsWidgets);
      },
    );

    testWidgets(
      'toque no botão durante o carregamento assíncrono navega para toMapas sem esperar a imagem',
      (tester) async {
        final completer = Completer<ImageProvider?>();
        final editor = EditorDeCroqui();
        final repo = DatasetRepository(editorDeCroqui: editor);
        final sync = SyncService(datasetRepository: repo);

        final mapa = Mapa()
          ..caminhoImagemMapa = 'imagem_pendente.png'
          ..larguraMapa = 400
          ..alturaMapa = 200;

        await tester.pumpWidget(
          MaterialApp(
            home: TreeNavigationWrapper(
              key: TreeNavigationWrapper.navKey,
              datasetRepo: repo,
              syncService: sync,
              child: Scaffold(
                body: MapaThumbnail(
                  mapas: [mapa],
                  cragId: 'crag1',
                  imageProviderFutureOverride: completer.future,
                ),
              ),
            ),
          ),
        );

        await tester.pump();

        // Toca no botão que já está visível no frame inicial
        await tester.tap(find.text('Abrir Mapa Interativo'));
        await tester.pump();

        // Verifica se a navegação em árvore foi acionada para MapasCarrosselNode
        expect(
          TreeNavigationWrapper.navKey.currentState?.treeController.currentNode,
          isA<MapasCarrosselNode>(),
        );
      },
    );

    testWidgets(
      'imagem de fundo é apresentada por trás do botão quando a resolução é concluída',
      (tester) async {
        final completer = Completer<ImageProvider?>();
        final mapa = Mapa()
          ..caminhoImagemMapa = 'imagem_completa.png'
          ..larguraMapa = 400
          ..alturaMapa = 200;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MapaThumbnail(
                mapas: [mapa],
                cragId: 'crag1',
                imageProviderFutureOverride: completer.future,
              ),
            ),
          ),
        );

        // Inicialmente o botão já está lá, mas a imagem ainda não
        await tester.pump();
        expect(find.text('Abrir Mapa Interativo'), findsOneWidget);
        expect(find.byType(Image), findsNothing);

        // Quando a imagem é resolvida
        completer.complete(MemoryImage(kTransparentImage));
        await tester.pumpAndSettle();

        // Imagem e botão convivem no mesmo Stack
        expect(find.byType(Image), findsOneWidget);
        expect(find.text('Abrir Mapa Interativo'), findsOneWidget);
      },
    );

    testWidgets(
      'dispara preCarregarNoDisco para mapas subsequentes ao montar com múltiplos mapas',
      (tester) async {
        final mapa1 = Mapa()
          ..caminhoImagemMapa = 'mapa_p1.webp'
          ..larguraMapa = 400
          ..alturaMapa = 200;
        final mapa2 = Mapa()
          ..caminhoImagemMapa = 'mapa_p2.webp'
          ..larguraMapa = 400
          ..alturaMapa = 200;
        final mapa3 = Mapa()
          ..caminhoImagemMapa = 'mapa_p3.webp'
          ..larguraMapa = 400
          ..alturaMapa = 200;

        final caminhosPreCarregados = <String>[];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MapaThumbnail(
                mapas: [mapa1, mapa2, mapa3],
                cragId: 'crag_teste',
                imageProviderOverride: MemoryImage(kTransparentImage),
                preCarregadorDisco: ({required String picoId, required String caminho}) async {
                  expect(picoId, equals('crag_teste'));
                  caminhosPreCarregados.add(caminho);
                  return null;
                },
              ),
            ),
          ),
        );

        await tester.pump();

        // Mapa 1 é a miniatura ativa, então apenas mapas 2 e 3 devem ser pré-carregados
        expect(caminhosPreCarregados, equals(['mapa_p2.webp', 'mapa_p3.webp']));
      },
    );

    testWidgets(
      'não dispara pré-carregamento quando houver apenas 1 mapa',
      (tester) async {
        final mapa1 = Mapa()
          ..caminhoImagemMapa = 'mapa_unico.webp'
          ..larguraMapa = 400
          ..alturaMapa = 200;

        final caminhosPreCarregados = <String>[];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MapaThumbnail(
                mapas: [mapa1],
                cragId: 'crag_teste',
                imageProviderOverride: MemoryImage(kTransparentImage),
                preCarregadorDisco: ({required String picoId, required String caminho}) async {
                  caminhosPreCarregados.add(caminho);
                  return null;
                },
              ),
            ),
          ),
        );

        await tester.pump();
        expect(caminhosPreCarregados, isEmpty);
      },
    );

    testWidgets(
      'quando o ImageProvider falha com erro de conexão, errorBuilder impede renderização de ErrorWidget',
      (tester) async {
        final mapa = Mapa()
          ..caminhoImagemMapa = 'mapa_teste.webp'
          ..larguraMapa = 400
          ..alturaMapa = 200;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MapaThumbnail(
                mapas: [mapa],
                cragId: 'crag_teste',
                imageProviderOverride: const ProvedorImagemComFalha(),
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(ErrorWidget), findsNothing);
        expect(tester.takeException(), isNull);
        expect(find.text('Abrir Mapa Interativo'), findsOneWidget);
      },
    );
  });
}

/// Provedor de imagem simulado para testes que dispara erro assíncrono de rede na carga.
class ProvedorImagemComFalha extends ImageProvider<ProvedorImagemComFalha> {
  const ProvedorImagemComFalha();

  @override
  Future<ProvedorImagemComFalha> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<ProvedorImagemComFalha>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    ProvedorImagemComFalha key,
    ImageDecoderCallback decode,
  ) {
    final completer = OneFrameImageStreamCompleter(
      Future<ImageInfo>.error(
        const SocketException('Failed host lookup: serving.arestaclimb.com'),
      ),
    );
    return completer;
  }
}


