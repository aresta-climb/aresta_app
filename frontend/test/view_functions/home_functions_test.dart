// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/view_functions/home_functions.dart';
import 'package:frontend/view_functions/browse_functions.dart';
import 'package:frontend/widgets/nearby_crags_carousel.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'package:geolocator/geolocator.dart';
import '../mocks/mock_geolocator_platform.dart';
import '../mocks/mock_telemetry_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:frontend/main.dart';
import 'package:frontend/navigation/navigation_tree.dart';
import 'package:frontend/services/firebase/registro_primeira_visita.dart';

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
  Future<String?> getTemporaryPath() async => '$tempPath/temp_cache';
}

void main() {
  late DatasetRepository mockRepo;
  late EditorDeCroqui mockEditor;
  late SyncService mockSync;
  late Directory tempDir;

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    RegistroPrimeiraVisita.resetForTesting();
    GeolocatorPlatform.instance = MockGeolocatorPlatform();
    tempDir = await Directory.systemTemp.createTemp('home_fn_test');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);

    mockEditor = EditorDeCroqui();
    mockRepo = DatasetRepository(editorDeCroqui: mockEditor);
    mockSync = SyncService(datasetRepository: mockRepo);
    mockSync.syncStatus.value = SyncStatus.updated;
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Widget buildTestableWidget() {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return buildHomeBody(
              context,
              mockRepo,
              mockSync,
              (index) {}, // onSwitchTab
            );
          },
        ),
      ),
    );
  }

  testWidgets(
    'buildHomeBody renders the new layout including NearbyCragsCarousel and header buttons',
    (WidgetTester tester) async {
      mockRepo.activeDataset.value = TopoDataset(availablePicos: [], downloadedPicos: []);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      // Verify Header buttons exist even when downloadedPicos is empty
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byIcon(Icons.sync), findsOneWidget);
      expect(find.byIcon(Icons.search), findsNWidgets(2));
      expect(find.text('Buscar picos, setores ou vias...'), findsOneWidget);

      // Verify Welcome and H1 text
      expect(find.text('BEM VINDO!'), findsOneWidget);
      expect(find.text('BORA PRA PEDRA?'), findsOneWidget);
      expect(
        find.text(
          'O guia definitivo para facilitar a sua escalada. Explore setores, vias e boulders locais e salve os croquis para acessar totalmente offline.',
        ),
        findsOneWidget,
      );

      // Verify NearbyCragsCarousel exists
      expect(find.byType(NearbyCragsCarousel), findsOneWidget);

      // Verify Guia Rápido em Dark Mode com 4 passos
      expect(find.text('GUIA RÁPIDO DO ARESTA'), findsOneWidget);
      expect(
        find.text('Quatro passos pra você sair do app direto pro paredão.'),
        findsOneWidget,
      );
      expect(find.text('ENCONTRE O PICO'), findsOneWidget);
      expect(find.text('SALVE OFFLINE'), findsOneWidget);
      expect(find.text('CROQUI INTERATIVO'), findsOneWidget);
      expect(find.text('COMPARTILHE'), findsOneWidget);

      // Validação do novo layout refinado:
      // 1. Container externo do Guia Rápido tem fundo transparente/cor do app
      final guiaTitleFinder = find.text('GUIA RÁPIDO DO ARESTA');
      final guiaOuterContainerFinder = find.ancestor(
        of: guiaTitleFinder,
        matching: find.byType(Container),
      ).first;
      final Container guiaOuterContainer = tester.widget(guiaOuterContainerFinder);
      final BoxDecoration outerBox = guiaOuterContainer.decoration as BoxDecoration;
      expect(outerBox.color, equals(Colors.transparent));

      // 2. O card de texto (ao redor de 'ENCONTRE O PICO') tem fundo caveShadow e NÃO engloba o ícone
      final stepTitleFinder = find.text('ENCONTRE O PICO');
      final textCardFinder = find.ancestor(
        of: stepTitleFinder,
        matching: find.byType(Container),
      ).first;
      final Container textCard = tester.widget(textCardFinder);
      final BoxDecoration textBox = textCard.decoration as BoxDecoration;
      expect(textBox.color, equals(AppColors.dark.caveShadow));

      // O ícone de busca NÃO é descendente do textCard
      expect(
        find.descendant(of: textCardFinder, matching: find.byIcon(Icons.search)),
        findsNothing,
      );
    },
  );

  testWidgets(
    'handlePicoSelection dispara telemetria de abrir_croqui com origem, modoAcesso e primeiraVisita',
    (WidgetTester tester) async {
      final mockTelemetry = MockTelemetryService();
      TelemetryService.instance = mockTelemetry;

      final dummyPico = {'id': 'test-pico-1'};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(),
          ),
        ),
      );

      final context = tester.element(find.byType(Container));

      await tester.runAsync(() async {
        await handlePicoSelection(context, mockRepo, dummyPico, source: 'home');
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(mockTelemetry.recordedEvents, contains('acao_croqui'));
      expect(
        mockTelemetry.recordedParams['acao_croqui']!['acao'],
        'abrir_croqui',
      );
      expect(mockTelemetry.recordedParams['acao_croqui']!['origem'], 'home');
      expect(mockTelemetry.recordedParams['acao_croqui']!['modo_acesso'], 'online');
      expect(mockTelemetry.recordedParams['acao_croqui']!['primeira_visita'], 'true');

      // Segunda visita ao mesmo pico: primeira_visita deve ser 'false'
      await tester.runAsync(() async {
        await handlePicoSelection(context, mockRepo, dummyPico, source: 'home');
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(mockTelemetry.recordedParams['acao_croqui']!['primeira_visita'], 'false');
    },
  );

  testWidgets(
    'handlePicoSelection registra croqui online na sessao e navega para PicoNode',
    (WidgetTester tester) async {
      final mockTelemetry = MockTelemetryService();
      TelemetryService.instance = mockTelemetry;

      final dummyCroqui = Croqui(
        id: 'pico_online_1',
        nome: 'Pico Online',
        picos: [Pico(nome: 'Pico Online')],
      );

      mockRepo.indiceData.value = Indice(
        croquis: [
          ResumoCroqui(
            id: 'pico_online_1',
            nome: 'Pico Online',
            checksumSha256Croqui: 'hash123',
            caminhoRelativo: 'picos/pico_online_1/compilado.binarypb',
          ),
        ],
      );

      final tempCacheDir = Directory(
        '${(await mockRepo.servicoCroquiOnline.obterDiretorioCache())}/pico_online_1',
      )..createSync(recursive: true);
      File('${tempCacheDir.path}/compilado.binarypb.hash123')
          .writeAsBytesSync(dummyCroqui.writeToBuffer());

      final dummyPico = {
        'id': 'pico_online_1',
        'url': 'https://serving.arestaclimb.com/v4/picos/pico_online_1/compilado.binarypb?v=hash123',
        'checksum': 'hash123',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: TreeNavigationWrapper(
            key: TreeNavigationWrapper.navKey,
            datasetRepo: mockRepo,
            syncService: mockSync,
          ),
        ),
      );
      await tester.pump();

      final context = tester.element(find.byType(TreeNavigationWrapper));
      await tester.runAsync(() async {
        await handlePicoSelection(
          context,
          mockRepo,
          dummyPico,
          source: 'explorar',
        );
      });

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        mockRepo.gerenciadorSessaoOnline.obterCroquiOnline('pico_online_1')?.nome,
        equals('Pico Online'),
      );
      expect(
        TreeNavigationWrapper.navKey.currentState?.treeController.currentNode,
        isA<PicoNode>(),
      );
    },
  );

  testWidgets(
    'Downloads from activeDataset update Home download cards reactively',
    (WidgetTester tester) async {
      mockRepo.activeDataset.value = TopoDataset(
        availablePicos: [
          {
            'id': 'pico_sync_1',
            'nome': 'Pico Sync',
            'local': 'Local Sync',
            'latitude': -20.0,
            'longitude': -40.0,
          },
        ],
        downloadedPicos: [],
      );

      // Renderiza diretamente o mesmo padrão do NearbyCragsCarousel para evitar
      // dependência em chamadas do Geolocator que rodam infinitamente em testes.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<TopoDataset?>(
              valueListenable: mockRepo.activeDataset,
              builder: (context, dataset, child) {
                final isDownloaded =
                    dataset?.downloadedPicos.any(
                      (p) => p['id'] == 'pico_sync_1',
                    ) ??
                    false;
                return CragCard(
                  crag: {
                    'id': 'pico_sync_1',
                    'nome': 'Pico Browse',
                    'isDownloaded': isDownloaded,
                  },
                  downloadingCrags: mockSync.downloadingCrags,
                  onDownload: () {},
                  onOpen: () {},
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();

      // No início, não deve estar salvo offline
      expect(find.text('SALVO OFFLINE'), findsNothing);

      // 2. Atualiza para mostrar que foi baixado (simula o fim do download)
      mockRepo.activeDataset.value = TopoDataset(
        availablePicos: mockRepo.activeDataset.value!.availablePicos,
        downloadedPicos: [
          {'id': 'pico_sync_1', 'data': {}},
        ],
      );

      await tester.pump();

      // O widget foi reconstruído e o CragCard mostra salvo offline?
      expect(find.text('SALVO OFFLINE'), findsOneWidget);
    },
  );

  testWidgets(
    'buildHomeBody renders unified search bar regardless of downloaded picos',
    (WidgetTester tester) async {
      mockRepo.activeDataset.value = TopoDataset(
        availablePicos: [],
        downloadedPicos: [],
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      // Search icon is visible in search bar and in quick guide (2 total)
      expect(find.byIcon(Icons.search), findsNWidgets(2));
      expect(find.text('Buscar picos, setores ou vias...'), findsOneWidget);

      mockRepo.activeDataset.value = TopoDataset(
        availablePicos: [],
        downloadedPicos: [{'id': 'pico_1', 'nome': 'Pico 1'}],
      );

      await tester.pump();

      expect(find.byIcon(Icons.search), findsNWidgets(2));
      expect(find.text('Buscar picos, setores ou vias...'), findsOneWidget);
    },
  );
}
