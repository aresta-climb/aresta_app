// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/navigation/arvore_navegacao.dart';
import 'package:frontend/navigation/construtor_reativo_pagina.dart';
import 'package:frontend/navigation/construtor_view_arvore.dart';
import 'package:frontend/pages/gps.dart';
import 'package:frontend/pages/mapa_global.dart';
import 'package:frontend/pages/pico.dart';
import 'package:frontend/pages/setor.dart';
import 'package:frontend/pages/configuracoes.dart';
import 'package:frontend/pages/hub_perfil_caderneta.dart';
import 'package:frontend/pages/caderneta.dart';
import 'package:frontend/pages/sobre_time.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/http/sync_service.dart';

class _FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String tempPath;
  _FakePathProviderPlatform(this.tempPath);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempPath;
  @override
  Future<String?> getApplicationSupportPath() async => tempPath;
  @override
  Future<String?> getLibraryPath() async => tempPath;
  @override
  Future<String?> getTemporaryPath() async => '$tempPath/temp_cache';
}

class DummyNavNode extends NavNode {
  const DummyNavNode();

  @override
  String get rotuloAmigavel => 'Dummy';
}

void main() {
  group('Resolvedor de Rotas da Árvore (construirPaginaParaNo)', () {
    late Directory tempDir;
    late DatasetRepository repo;
    late SyncService syncService;
    late EditorDeCroqui editor;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('construtor_view_arvore_test_');
      PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
      editor = EditorDeCroqui();
      repo = DatasetRepository(editorDeCroqui: editor);
      syncService = SyncService(datasetRepository: repo);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    testWidgets('resolve GPSNode para GPSPage', (tester) async {
      final widget = construirPaginaParaNo(
        node: const GPSNode(cragId: 'pico_1', parent: HomeNode()),
        datasetRepo: repo,
        syncService: syncService,
      );

      expect(widget, isA<GPSPage>());
    });

    testWidgets('resolve SettingsNode para SettingsPage', (tester) async {
      final widget = construirPaginaParaNo(
        node: const SettingsNode(HomeNode()),
        datasetRepo: repo,
        syncService: syncService,
      );

      expect(widget, isA<SettingsPage>());
    });

    testWidgets('resolve SobreTimeNode para SobreTimePage', (tester) async {
      final widget = construirPaginaParaNo(
        node: const SobreTimeNode(HomeNode()),
        datasetRepo: repo,
        syncService: syncService,
      );

      expect(widget, isA<SobreTimePage>());
    });

    testWidgets('resolve PerfilNode para HubPerfilCadernetaPage', (tester) async {
      final widget = construirPaginaParaNo(
        node: const PerfilNode(HomeNode()),
        datasetRepo: repo,
        syncService: syncService,
      );

      expect(widget, isA<HubPerfilCadernetaPage>());
    });

    testWidgets('resolve CadernetaNode para CadernetaPage', (tester) async {
      final widget = construirPaginaParaNo(
        node: const CadernetaNode(PerfilNode(HomeNode())),
        datasetRepo: repo,
        syncService: syncService,
      );

      expect(widget, isA<CadernetaPage>());
    });

    testWidgets('resolve MapaGlobalNode para MapaGlobalPage', (tester) async {
      final widget = construirPaginaParaNo(
        node: const MapaGlobalNode(parent: HomeNode()),
        datasetRepo: repo,
        syncService: syncService,
      );

      expect(widget, isA<MapaGlobalPage>());
    });

    testWidgets('resolve MapaGlobalNode com picoIds para MapaGlobalPage com ViewModel configurado', (tester) async {
      final widget = construirPaginaParaNo(
        node: const MapaGlobalNode(
          picoIds: ['bau', 'cipo'],
          parent: HomeNode(),
        ),
        datasetRepo: repo,
        syncService: syncService,
      );

      expect(widget, isA<MapaGlobalPage>());
      final page = widget as MapaGlobalPage;
      expect(page.viewModel.picosIniciais, equals(['bau', 'cipo']));
    });

    testWidgets('resolve SetoresNode para PageListenableBuilder', (tester) async {
      final widget = construirPaginaParaNo(
        node: const SetoresNode(cragId: 'pico_1', parent: HomeNode()),
        datasetRepo: repo,
        syncService: syncService,
      );

      expect(widget, isA<PageListenableBuilder>());
    });

    testWidgets('resolve IndiceEscaladasNode para PageListenableBuilder', (tester) async {
      final widget = construirPaginaParaNo(
        node: const IndiceEscaladasNode(cragId: 'pico_1', parent: HomeNode()),
        datasetRepo: repo,
        syncService: syncService,
      );

      expect(widget, isA<PageListenableBuilder>());
    });

    testWidgets('resolve PicoNode com returnToSetorNome e SetorNode com scrollToEscaladaNome via DatasetResolver compartilhado', (tester) async {
      final via = Escalada(
        uid: 'via_alvo',
        viaEsportiva: ViaEsportiva(nome: 'Via Alvo'),
      );
      final setor = Setor(
        uid: 'setor_alvo',
        nome: 'Setor Alvo',
        escaladas: [via],
      );
      final pico = Pico(
        nome: 'Pico Alvo',
        setoresOuGrupos: [
          SetorOuGrupo(setor: ArquivoSetor(conteudo: setor)),
        ],
      );
      final croqui = Croqui(id: 'pico_alvo', nome: 'Pico Alvo', picos: [pico]);

      repo.activeDataset.value = ConjuntoDadosCroqui(
        picosBaixados: [
          ResumoPico(
            id: 'pico_alvo',
            nome: 'Pico Alvo',
            local: 'MG',
            isDownloaded: true,
            pico: pico,
            croqui: croqui,
          ),
        ],
        picosDisponiveis: const [],
        croquisBaixados: [croqui],
      );

      final widgetPico = construirPaginaParaNo(
        node: const PicoNode(
          cragId: 'pico_alvo',
          returnToSetorNome: 'Setor Alvo',
          parent: HomeNode(),
        ),
        datasetRepo: repo,
        syncService: syncService,
      );

      await tester.pumpWidget(MaterialApp(home: widgetPico));
      await tester.pump();

      final picoPage = tester.widget<PicoDetailsPage>(find.byType(PicoDetailsPage));
      expect(picoPage.returnToSetor?.nome, equals('Setor Alvo'));

      final widgetSetor = construirPaginaParaNo(
        node: const SetorNode(
          cragId: 'pico_alvo',
          setorNome: 'Setor Alvo',
          scrollToEscaladaNome: 'Via Alvo',
          parent: HomeNode(),
        ),
        datasetRepo: repo,
        syncService: syncService,
      );

      await tester.pumpWidget(MaterialApp(home: widgetSetor));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final setorPage = tester.widget<SetorPage>(find.byType(SetorPage));
      expect(setorPage.scrollToEscalada?.viaEsportiva.nome, equals('Via Alvo'));
    });

    testWidgets('resolve ControlesNode para widget defensivo sem Unknown Node', (tester) async {
      final widget = construirPaginaParaNo(
        node: const ControlesNode(cragId: 'pico_1', parent: HomeNode()),
        datasetRepo: repo,
        syncService: syncService,
      );

      await tester.pumpWidget(MaterialApp(home: widget));
      expect(find.text('Unknown Node'), findsNothing);
    });

    testWidgets('retorna mensagem para nó desconhecido', (tester) async {
      final widget = construirPaginaParaNo(
        node: const DummyNavNode(),
        datasetRepo: repo,
        syncService: syncService,
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
