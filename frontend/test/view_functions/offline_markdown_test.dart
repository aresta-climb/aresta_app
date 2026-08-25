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
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('offline_md_test_');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);
    EditorDeCroqui(); // Inicializa o singleton
  });

  tearDownAll(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('OfflineMarkdown Tests', () {
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
