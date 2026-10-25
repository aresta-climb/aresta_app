// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:frontend/pages/home.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/firebase/telemetria.dart';
import '../mocks/mock_telemetria.dart';
import '../mocks/mock_geolocator_platform.dart';
import 'package:frontend/widgets/micro_badge_beta.dart';
import 'package:frontend/widgets/modal_beta_aberto.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/view/view_models/home_view_model.dart';

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
  Future<String?> getTemporaryPath() async => tempPath;
}

class FakeSyncService extends SyncService {
  FakeSyncService(DatasetRepository repo) : super(datasetRepository: repo);

  int syncIndexCallCount = 0;
  SyncStatus statusAoSincronizar = SyncStatus.noNewUpdates;

  @override
  Future<bool> isNetworkDisabled() async => false;

  @override
  Future<List<String>> syncIndex({
    bool auto = true,
    bool forceBypassCache = false,
  }) async {
    syncIndexCallCount++;
    syncStatus.value = statusAoSincronizar;
    return <String>[];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late DatasetRepository repo;
  late FakeSyncService syncService;
  late MockGeolocatorPlatform mockGeolocator;

  setUp(() async {
    TelemetryService.instance = MockTelemetryService();
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('home_page_test_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
    mockGeolocator = MockGeolocatorPlatform();
    GeolocatorPlatform.instance = mockGeolocator;
    repo = DatasetRepository(editorDeCroqui: EditorDeCroqui());
    syncService = FakeSyncService(repo);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Widget createTestWidget({Function(int)? onSwitchTab}) {
    return MaterialApp(
      theme: ThemeData(
        extensions: const [AppColors.dark],
      ),
      home: HomePage(
        viewModel: HomeViewModel(
          datasetRepo: repo,
          syncService: syncService,
        ),
        onSwitchTab: onSwitchTab ?? (_) {},
      ),
    );
  }

  testWidgets(
    'HomePage pull-to-refresh quando não há croquis baixados sincroniza o catálogo',
    (tester) async {
      repo.activeDataset.value = TopoDataset(
        availablePicos: [],
        downloadedPicos: [],
      );
      syncService.statusAoSincronizar = SyncStatus.noNewUpdates;

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, 300),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(
        find.text('Catálogo já está atualizado.'),
        findsOneWidget,
      );
      expect(syncService.syncIndexCallCount, equals(1));
    },
  );

  testWidgets(
    'HomePage pull-to-refresh aciona sincronização se houver croquis baixados',
    (tester) async {
      repo.activeDataset.value = TopoDataset(
        availablePicos: [],
        downloadedPicos: [
          {'id': '1', 'nome': 'Pico 1'},
        ],
      );
      syncService.statusAoSincronizar = SyncStatus.justUpdated;

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, 300),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Croquis foram atualizados!'), findsOneWidget);
      expect(syncService.syncIndexCallCount, equals(1));
    },
  );

  testWidgets('HomePage exibe MicroBadgeBeta no cabeçalho e abre o modal ao tocar', (tester) async {
    repo.activeDataset.value = TopoDataset(availablePicos: [], downloadedPicos: []);

    await tester.pumpWidget(createTestWidget());
    await tester.pump();

    final badgeFinder = find.byType(MicroBadgeBeta);
    expect(badgeFinder, findsOneWidget);

    await tester.tap(badgeFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ModalBetaAberto), findsOneWidget);
  });

  testWidgets('HomePage exibe ARESTA CLIMB no cabeçalho e abre o modal ao tocar no texto da marca', (tester) async {
    repo.activeDataset.value = TopoDataset(availablePicos: [], downloadedPicos: []);

    await tester.pumpWidget(createTestWidget());
    await tester.pump();

    final brandFinder = find.text('ARESTA CLIMB');
    expect(brandFinder, findsOneWidget);

    final mockTelemetry = MockTelemetryService();
    TelemetryService.instance = mockTelemetry;

    await tester.tap(brandFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ModalBetaAberto), findsOneWidget);
    expect(mockTelemetry.recordedEvents, contains('acao_beta_aberto'));
    final params = mockTelemetry.recordedParams['acao_beta_aberto']!;
    expect(params['acao'], 'abrir_modal_beta');
    expect(params['origem'], 'home_header');
  });

  testWidgets('HomePage mantém appbar visível após rolagem do conteúdo', (tester) async {
    repo.activeDataset.value = TopoDataset(availablePicos: [], downloadedPicos: []);

    await tester.pumpWidget(createTestWidget());
    await tester.pump();

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
    await tester.pump();

    expect(find.text('ARESTA CLIMB'), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(find.byIcon(Icons.sync), findsOneWidget);
  });

  testWidgets('HomePage aciona onSwitchTab(1) ao tocar no card VER MAIS -> do carrossel', (tester) async {
    final picos = List.generate(8, (i) {
      return <String, dynamic>{
        'id': 'pico_$i',
        'nome': 'Pico $i',
        'caminhoRelativo': 'picos/pico_$i/pico_$i.binarypb',
        'latitude': -20.0 + (i * 0.05),
        'longitude': -44.0 + (i * 0.05),
        'isDownloaded': false,
        'thumbnailUrl': '',
      };
    });

    repo.activeDataset.value = TopoDataset(
      availablePicos: picos,
      downloadedPicos: [],
    );

    mockGeolocator.currentPositionResult = Position(
      latitude: -20.0,
      longitude: -44.0,
      timestamp: DateTime.now(),
      accuracy: 5.0,
      altitude: 1000.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );

    int? abaSelecionada;
    await tester.pumpWidget(
      createTestWidget(
        onSwitchTab: (index) {
          abaSelecionada = index;
        },
      ),
    );
    await tester.pumpAndSettle();

    final listViewFinder = find.byType(ListView);
    await tester.drag(listViewFinder, const Offset(-2500, 0));
    await tester.pumpAndSettle();

    expect(find.text('VER MAIS ->'), findsOneWidget);
    await tester.tap(find.text('VER MAIS ->'));
    await tester.pumpAndSettle();

    expect(abaSelecionada, equals(1));
  });
}
