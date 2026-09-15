// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:frontend/view_functions/offline_markdown.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String tempPath;
  MockPathProviderPlatform(this.tempPath);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempPath;
  @override
  Future<String?> getApplicationSupportPath() async => tempPath;
  @override
  Future<String?> getLibraryPath() async => tempPath;
  @override
  Future<String?> getTemporaryPath() async => tempPath;
  @override
  Future<String?> getExternalStoragePath() async => tempPath;
  @override
  Future<List<String>?> getExternalCachePaths() async => [];
  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async => [];
  @override
  Future<String?> getDownloadsPath() async => tempPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('offline_md_test_');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);
    EditorDeCroqui(); // Inicializa o singleton
  });

  tearDownAll(() async {
    try {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  // Bytes válidos de PNG de 1x1 pixel transparente
  final bytesPng1 = <int>[
    137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82,
    0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0,
    0, 13, 73, 68, 65, 84, 120, 156, 99, 100, 248, 207, 80, 15, 0, 3,
    134, 1, 128, 90, 52, 125, 107, 0, 0, 0, 0, 73, 69, 78, 68, 174,
    66, 96, 130
  ];

  group('OfflineMarkdown Tests', () {
    testWidgets('didUpdateWidget não expurga cache quando data e cragId forem idênticos', (
      WidgetTester tester,
    ) async {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      final downloadsDir = Directory('${tempDir.path}/downloads/test_crag')
        ..createSync(recursive: true);
      final imgFile = File('${downloadsDir.path}/imagem.png');
      imgFile.writeAsBytesSync(bytesPng1);

      // Renderiza pela primeira vez
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineMarkdown(
              key: const ValueKey('md_widget'),
              data: '![Imagem](imagem.png)',
              cragId: 'test_crag',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(PaintingBinding.instance.imageCache.liveImageCount, greaterThan(0));

      // Re-renderiza com os mesmos dados (simulando rebuild do widget pai)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineMarkdown(
              key: const ValueKey('md_widget'),
              data: '![Imagem](imagem.png)',
              cragId: 'test_crag',
            ),
          ),
        ),
      );
      await tester.pump();

      // Como data e cragId não mudaram, a imagem NÃO deve ter sido expurgada da memória
      expect(PaintingBinding.instance.imageCache.liveImageCount, greaterThan(0));

      // Agora re-renderiza com data alterada
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineMarkdown(
              key: const ValueKey('md_widget'),
              data: 'Texto sem imagem',
              cragId: 'test_crag',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Com a alteração de dados, as imagens anteriores devem ter sido expurgadas do cache
      expect(PaintingBinding.instance.imageCache.liveImageCount, equals(0));
    });
    testWidgets('Tocar em imagem deve abrir um modal com o botão de bug_report', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineMarkdown(
              data:
                  '![Imagem de teste](https://aresta-climb.github.io/aresta_serving/fake_image.png)',
              cragId: 'test_crag',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Encontra a imagem que foi renderizada pelo markdown
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      // Toca na imagem
      await tester.tap(imageFinder);
      await tester.pumpAndSettle();

      // Verifica se o dialog abriu contendo um InteractiveViewer
      expect(find.byType(InteractiveViewer), findsOneWidget);

      // Verifica se o botão de close e o de bug_report estão presentes na sobreposição da imagem
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byIcon(Icons.bug_report), findsOneWidget);

      // Fecha o dialog
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsNothing);
    });
  });
}
