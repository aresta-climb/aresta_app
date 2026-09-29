// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/navigation/arvore_navegacao.dart';
import 'package:frontend/navigation/construtor_view_arvore.dart';
import 'package:frontend/pages/gps.dart';
import 'package:frontend/pages/mapa_global.dart';
import 'package:frontend/pages/configuracoes.dart';
import 'package:frontend/pages/sobre_time.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/http/sync_service.dart';

class MockDatasetRepository extends Mock implements DatasetRepository {}

class MockSyncService extends Mock implements SyncService {}

class MockEditorDeCroqui extends Mock implements EditorDeCroqui {}

class DummyNavNode extends NavNode {
  const DummyNavNode();

  @override
  String get rotuloAmigavel => 'Dummy';
}

void main() {
  group('Resolvedor de Rotas da Árvore (construirPaginaParaNo)', () {
    late MockDatasetRepository mockRepo;
    late MockSyncService mockSync;
    late MockEditorDeCroqui mockEditor;

    setUp(() {
      mockRepo = MockDatasetRepository();
      mockSync = MockSyncService();
      mockEditor = MockEditorDeCroqui();

      when(() => mockRepo.editorDeCroqui).thenReturn(mockEditor);
      when(() => mockEditor.isExperimentalMode).thenReturn(ValueNotifier(false));
      when(() => mockEditor.editorUrl).thenReturn(ValueNotifier(null));
      when(() => mockRepo.activeDataset).thenReturn(ValueNotifier(null));
      when(() => mockRepo.gerenciadorSessaoOnline).thenReturn(GerenciadorSessaoOnline());
    });

    testWidgets('resolve GPSNode para GPSPage', (tester) async {
      final widget = construirPaginaParaNo(
        node: const GPSNode(cragId: 'pico_1', parent: HomeNode()),
        datasetRepo: mockRepo,
        syncService: mockSync,
      );

      expect(widget, isA<GPSPage>());
    });

    testWidgets('resolve SettingsNode para SettingsPage', (tester) async {
      final widget = construirPaginaParaNo(
        node: const SettingsNode(HomeNode()),
        datasetRepo: mockRepo,
        syncService: mockSync,
      );

      expect(widget, isA<SettingsPage>());
    });

    testWidgets('resolve SobreTimeNode para SobreTimePage', (tester) async {
      final widget = construirPaginaParaNo(
        node: const SobreTimeNode(HomeNode()),
        datasetRepo: mockRepo,
        syncService: mockSync,
      );

      expect(widget, isA<SobreTimePage>());
    });

    testWidgets('resolve MapaGlobalNode para MapaGlobalPage', (tester) async {
      final widget = construirPaginaParaNo(
        node: const MapaGlobalNode(parent: HomeNode()),
        datasetRepo: mockRepo,
        syncService: mockSync,
      );

      expect(widget, isA<MapaGlobalPage>());
    });

    testWidgets('retorna mensagem para nó desconhecido', (tester) async {
      final widget = construirPaginaParaNo(
        node: const DummyNavNode(),
        datasetRepo: mockRepo,
        syncService: mockSync,
      );

      await tester.pumpWidget(MaterialApp(home: widget));
      expect(find.text('Unknown Node'), findsOneWidget);
    });
  });

  group('Resolvedor de Modais da Árvore (construirModalParaNo)', () {
    testWidgets('cria página modal para TextNode', (tester) async {
      const node = TextNode(
        title: 'Ajuda',
        content: 'Conteúdo explicativo',
        cragId: 'pico_1',
        parent: HomeNode(),
      );

      final page = construirPaginaModalParaNo(node);
      expect(page, isNotNull);
    });

    testWidgets('cria página modal para TextCarouselNode', (tester) async {
      final node = TextCarouselNode(
        texts: const [
          TextCarouselData(
            title: 'Página 1',
            content: 'Item 1',
          ),
        ],
        cragId: 'pico_1',
        parent: const HomeNode(),
      );

      final page = construirPaginaModalParaNo(node);
      expect(page, isNotNull);
    });

    testWidgets('retorna nulo se o nó não for modal', (tester) async {
      final page = construirPaginaModalParaNo(const HomeNode());
      expect(page, isNull);
    });
  });
}
