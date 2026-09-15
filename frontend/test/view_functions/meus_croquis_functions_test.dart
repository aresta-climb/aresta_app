// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/view_functions/meus_croquis_functions.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _PlataformaCaminhosMock extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String caminhoTemp;
  _PlataformaCaminhosMock(this.caminhoTemp);

  @override
  Future<String?> getApplicationDocumentsPath() async => caminhoTemp;
  @override
  Future<String?> getTemporaryPath() async => caminhoTemp;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late DatasetRepository repositorio;
  late SyncService servicoSync;

  final bytesPng1 = <int>[
    137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82,
    0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0,
    0, 13, 73, 68, 65, 84, 120, 156, 99, 100, 248, 207, 80, 15, 0, 3,
    134, 1, 128, 90, 52, 125, 107, 0, 0, 0, 0, 73, 69, 78, 68, 174,
    66, 96, 130
  ];

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('meus_croquis_test_');
    PathProviderPlatform.instance = _PlataformaCaminhosMock(tempDir.path);
    final editor = EditorDeCroqui();
    repositorio = DatasetRepository(editorDeCroqui: editor);
    servicoSync = SyncService(datasetRepository: repositorio);
  });

  tearDown(() async {
    try {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('OfflineCragCard - Renderização de Miniaturas', () {
    testWidgets('renderiza miniatura via ProvedorImagemAresta com ResizeImage e larguraAlvo 300', (
      WidgetTester tester,
    ) async {
      final thumbDir = Directory('${tempDir.path}/thumbnails')..createSync(recursive: true);
      final thumbFile = File('${thumbDir.path}/pico_1.webp');
      thumbFile.writeAsBytesSync(bytesPng1);

      final crag = {
        'id': 'pico_1',
        'nome': 'Pico da Falésia',
        'local': 'Serra do Cipó',
        'estatisticas': {'totalSetores': 3, 'totalVias': 15},
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineCragCard(
              crag: crag,
              datasetRepo: repositorio,
              syncService: servicoSync,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      final Image imageWidget = tester.widget(imageFinder);
      expect(imageWidget.image, isA<ResizeImage>());
      final resize = imageWidget.image as ResizeImage;
      expect(resize.width, equals(300));
    });

    testWidgets('exibe ícone de fallback terrain quando miniatura não existe', (
      WidgetTester tester,
    ) async {
      final crag = {
        'id': 'pico_sem_thumb',
        'nome': 'Pico Sem Foto',
        'local': 'Itatiaia',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineCragCard(
              crag: crag,
              datasetRepo: repositorio,
              syncService: servicoSync,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.terrain), findsOneWidget);
    });
  });
}
