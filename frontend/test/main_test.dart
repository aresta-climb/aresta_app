// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:frontend/services/firebase/remote_config_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/navigation/navigation_tree.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/pages/terms_of_use.dart';
import 'package:frontend/pages/database_migration_screen.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/constants/legal_version.g.dart';
import 'package:frontend/constants/network_constants.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'mocks/mock_telemetry_service.dart';
import 'mocks/mock_geolocator_platform.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';

class MockAssetBundle extends Fake implements AssetBundle {
  final Map<String, String> mockFiles;

  MockAssetBundle(this.mockFiles);

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (mockFiles.containsKey(key)) {
      return mockFiles[key]!;
    }
    throw FlutterError('Unable to load asset: $key');
  }
}

class FakeRemoteConfigService extends Fake
    with ChangeNotifier
    implements RemoteConfigService {
  @override
  int get hardMinVersion => 0;

  @override
  int get recommendedVersion => 0;

  @override
  int get softMinVersion => 0;

  @override
  int getInt(String key) => 0;
  @override
  bool getBool(String key) => false;
  @override
  String getString(String key) => "";

  final String _iosUrl = "";
  @override
  String get storeUrlIos => _iosUrl;

  @override
  void clearInitFuture() {}

  @override
  Future<void> initialize() async {}
}

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
}

class MockDatasetRepository extends Mock implements DatasetRepository {}

class MockSyncService extends Mock implements SyncService {}

class MockWorkmanager extends Mock implements Workmanager {}

void main() {
  late Directory tempDir;
  late DatasetRepository mockRepo;
  late SyncService mockSync;
  late EditorDeCroqui mockEditor;
  late MockTelemetryService mockTelemetry;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('main_test_');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);
    GeolocatorPlatform.instance = MockGeolocatorPlatform();
    mockEditor = EditorDeCroqui();
    mockRepo = DatasetRepository(editorDeCroqui: mockEditor);
    mockSync = SyncService(datasetRepository: mockRepo);
    mockSync.syncStatus.value = SyncStatus.updated;

    mockTelemetry = MockTelemetryService();
    TelemetryService.instance = mockTelemetry;

    SharedPreferences.setMockInitialValues({});

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          const EventChannel('dev.fluttercommunity.plus/connectivity_status'),
          MockStreamHandler.inline(
            onListen: (args, sink) {
              sink.success(['wifi']);
            },
          ),
        );

    PackageInfo.setMockInitialValues(
      appName: 'Aresta',
      packageName: 'com.aresta.climb',
      version: '1.0.0',
      buildNumber: '10',
      buildSignature: '',
    );
  });

  tearDown(() async {
    try {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  testWidgets(
    'MyApp shows TermsOfUsePage when acceptedLegalVersion is 0 (first launch)',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MyApp(
          datasetRepo: mockRepo,
          syncService: mockSync,
          needsMigration: false,
          remoteConfigService: FakeRemoteConfigService(),
          acceptedLegalVersion: 0,
        ),
      );
      await tester.pump();
      debugDumpApp();
      expect(find.byType(TermsOfUsePage), findsOneWidget);
      expect(find.byType(TreeNavigationWrapper), findsNothing);
    },
  );

  test(
    'setupAppServices awaits datasetRepo.init() before calling syncIndex',
    () async {
      final mockRepo = MockDatasetRepository();
      final mockSync = MockSyncService();

      // The order of calls is important
      bool initCalled = false;

      when(() => mockRepo.init()).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        initCalled = true;
      });

      when(() => mockSync.checkNeedsMigration()).thenAnswer((_) async => false);
      when(() => mockSync.syncIndex()).thenAnswer((_) async {
        expect(
          initCalled,
          isTrue,
          reason: 'init() should be awaited before syncIndex()',
        );
        return [];
      });

      final result = await setupAppServices(mockRepo, mockSync);

      expect(result, isFalse);
      verify(() => mockRepo.init()).called(1);
      verify(() => mockSync.syncIndex()).called(1);
    },
  );

  testWidgets(
    'MyApp shows TreeNavigationWrapper when acceptedLegalVersion matches kLegalVersion',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MyApp(
          datasetRepo: mockRepo,
          syncService: mockSync,
          needsMigration: false,
          remoteConfigService: FakeRemoteConfigService(),
          acceptedLegalVersion: kLegalVersion,
        ),
      );
      await tester.pump();

      expect(find.byType(TermsOfUsePage), findsNothing);
      expect(find.byType(TreeNavigationWrapper), findsOneWidget);
    },
  );

  testWidgets(
    'MyApp shows TermsOfUsePage with update flag when acceptedLegalVersion is > 0 but < kLegalVersion',
    (WidgetTester tester) async {
      // If kLegalVersion is 1, an accepted version of 1 would mean it's up to date.
      // For this test, we must mock a scenario where it's outdated, but we can't change kLegalVersion dynamically.
      // We can simulate acceptedLegalVersion = -1 to pretend it's > 0 if kLegalVersion is 1, or we just pass kLegalVersion - 1
      // if kLegalVersion > 1. Let's just pass kLegalVersion - 1 (but ensure it's > 0 or at least valid).
      // Actually, if kLegalVersion == 1, then the first update hasn't happened. We can test this by passing acceptedLegalVersion = 1, but then it's not outdated!
      // Since we know kLegalVersion is at least 1, if it's 1, we can't test isUpdatingTerms = true perfectly without a hack.
      // But since the actual generated kLegalVersion is currently 2, this will pass gracefully.
      final outdatedVersion = kLegalVersion > 1 ? kLegalVersion - 1 : 1;

      // If kLegalVersion is 1, skip test because we can't have an accepted version that is > 0 AND < 1
      if (kLegalVersion == 1) return;

      await tester.pumpWidget(
        MyApp(
          datasetRepo: mockRepo,
          syncService: mockSync,
          needsMigration: false,
          remoteConfigService: FakeRemoteConfigService(),
          acceptedLegalVersion: outdatedVersion,
        ),
      );
      await tester.pump();

      final termsFinder = find.byType(TermsOfUsePage);
      expect(termsFinder, findsOneWidget);
      expect(find.byType(TreeNavigationWrapper), findsNothing);

      final TermsOfUsePage termsPage = tester.widget(termsFinder);
      expect(termsPage.isUpdatingTerms, isTrue);
    },
  );

  testWidgets('MyApp shows SnackBar when background sync fails', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MyApp(
        datasetRepo: mockRepo,
        syncService: mockSync,
        needsMigration: false,
        remoteConfigService: FakeRemoteConfigService(),
        acceptedLegalVersion: kLegalVersion,
      ),
    );
    await tester.pump();

    // Finish building the initial frame
    await tester.pump();

    // Trigger an automatic sync failure
    mockSync.lastSyncWasAuto.value = true;
    mockSync.syncStatus.value = SyncStatus.error;

    // Pump to let the listener trigger the SnackBar
    await tester.pump();

    // The SnackBar should appear
    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.text('Erro ao sincronizar os dados. Tente novamente mais tarde.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'MyApp shows SnackBar when background sync updates downloaded croquis',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MyApp(
          datasetRepo: mockRepo,
          syncService: mockSync,
          needsMigration: false,
          remoteConfigService: FakeRemoteConfigService(),
          acceptedLegalVersion: kLegalVersion,
        ),
      );
      await tester.pump();
      await tester.pump();

      // Configura sincronização automática com 1 croqui baixado atualizado
      mockSync.lastSyncWasAuto.value = true;
      mockSync.quantidadeCroquisBaixadosAtualizadosNoUltimoSync.value = 1;
      mockSync.syncStatus.value = SyncStatus.justUpdated;

      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('Seus croquis baixados foram atualizados!'),
        findsOneWidget,
      );

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      final BuildContext context = tester.element(find.byType(TreeNavigationWrapper));
      expect(snackBar.backgroundColor, context.colors.dryMoss);
    },
  );

  testWidgets(
    'MyApp remains silent when background sync has only index/catalog updates (0 downloaded croquis updated)',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MyApp(
          datasetRepo: mockRepo,
          syncService: mockSync,
          needsMigration: false,
          remoteConfigService: FakeRemoteConfigService(),
          acceptedLegalVersion: kLegalVersion,
        ),
      );
      await tester.pump();
      await tester.pump();

      // Sincronização automática com 0 croquis baixados atualizados
      mockSync.lastSyncWasAuto.value = true;
      mockSync.quantidadeCroquisBaixadosAtualizadosNoUltimoSync.value = 0;
      mockSync.syncStatus.value = SyncStatus.justUpdated;

      await tester.pump();

      expect(find.byType(SnackBar), findsNothing);
    },
  );

  testWidgets(
    'MyApp remains silent when background sync has no new updates (HTTP 304)',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MyApp(
          datasetRepo: mockRepo,
          syncService: mockSync,
          needsMigration: false,
          remoteConfigService: FakeRemoteConfigService(),
          acceptedLegalVersion: kLegalVersion,
        ),
      );
      await tester.pump();
      await tester.pump();

      // Sincronização automática sem atualizações
      mockSync.lastSyncWasAuto.value = true;
      mockSync.quantidadeCroquisBaixadosAtualizadosNoUltimoSync.value = 0;
      mockSync.syncStatus.value = SyncStatus.noNewUpdates;

      await tester.pump();

      expect(find.byType(SnackBar), findsNothing);
    },
  );

  testWidgets(
    'TreeNavigationWrapper does not show auto-update SnackBar when sync is manual',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MyApp(
          datasetRepo: mockRepo,
          syncService: mockSync,
          needsMigration: false,
          remoteConfigService: FakeRemoteConfigService(),
          acceptedLegalVersion: kLegalVersion,
        ),
      );
      await tester.pump();
      await tester.pump();

      // Sincronização manual não deve disparar SnackBar no TreeNavigationWrapper
      mockSync.lastSyncWasAuto.value = false;
      mockSync.quantidadeCroquisBaixadosAtualizadosNoUltimoSync.value = 2;
      mockSync.syncStatus.value = SyncStatus.justUpdated;

      await tester.pump();

      expect(find.byType(SnackBar), findsNothing);
    },
  );

  testWidgets(
    'MyApp does not show auto-update SnackBar when in experimental mode',
    (WidgetTester tester) async {
      mockEditor.isExperimentalMode.value = true;

      await tester.pumpWidget(
        MyApp(
          datasetRepo: mockRepo,
          syncService: mockSync,
          needsMigration: false,
          remoteConfigService: FakeRemoteConfigService(),
          acceptedLegalVersion: kLegalVersion,
        ),
      );
      await tester.pump();
      await tester.pump();

      // Sincronização automática com croquis atualizados
      mockSync.lastSyncWasAuto.value = true;
      mockSync.quantidadeCroquisBaixadosAtualizadosNoUltimoSync.value = 1;
      mockSync.syncStatus.value = SyncStatus.justUpdated;

      await tester.pump();

      expect(find.byType(SnackBar), findsNothing);
    },
  );

  testWidgets(
    'MyApp renders BannerModoExperimental and exits on clicking Sair',
    (WidgetTester tester) async {
      mockEditor.isExperimentalMode.value = true;

      await tester.pumpWidget(
        MyApp(
          datasetRepo: mockRepo,
          syncService: mockSync,
          needsMigration: false,
          remoteConfigService: FakeRemoteConfigService(),
          acceptedLegalVersion: kLegalVersion,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('MODO EXPERIMENTAL ATIVO'), findsOneWidget);
      expect(find.textContaining('SAIR'), findsOneWidget);

      final sairFinder = find.textContaining('SAIR');
      await tester.tap(sairFinder);
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (!mockEditor.isExperimentalMode.value) break;
      }

      expect(mockEditor.isExperimentalMode.value, isFalse);
    },
  );

  testWidgets(
    'MyApp registers AppColors extension in both light and dark themes',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MyApp(
          datasetRepo: mockRepo,
          syncService: mockSync,
          needsMigration: false,
          remoteConfigService: FakeRemoteConfigService(),
          acceptedLegalVersion: kLegalVersion,
        ),
      );
      await tester.pump();

      // Finish building
      await tester.pump(const Duration(seconds: 1));

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.theme?.extensions.values.whereType<AppColors>(), isNotEmpty);
      expect(app.darkTheme?.extensions.values.whereType<AppColors>(), isNotEmpty);
    },
  );

  testWidgets('MyApp saves timestamp and version when terms are accepted', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({}); // Initialize empty mock

    await tester.pumpWidget(
      MyApp(
        datasetRepo: mockRepo,
        syncService: mockSync,
        needsMigration: false,
        remoteConfigService: FakeRemoteConfigService(),
        acceptedLegalVersion: 0,
        assetBundle: MockAssetBundle({
          'legal/repo/public/docs/termos-de-uso.md': 'Terms',
          'legal/repo/public/docs/politica-de-privacidade.md': 'Privacy',
        }),
      ),
    );
    await tester.pump();

    await tester.pump();

    final termsFinder = find.byType(TermsOfUsePage);
    expect(termsFinder, findsOneWidget);

    // Tap checkbox
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();

    // Tap accept button
    await tester.tap(
      find.widgetWithText(FilledButton, 'Aceitar Termos e Continuar'),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Verify SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('accepted_legal_version'), kLegalVersion);
    expect(prefs.getString('accepted_legal_timestamp'), isNotNull);

    // Verify TreeNavigationWrapper is now shown
    expect(find.byType(TreeNavigationWrapper), findsOneWidget);
  });

  testWidgets(
    'MyApp updates timestamp and version when terms are updated and accepted again',
    (WidgetTester tester) async {
      final oldTimestamp = DateTime(2025, 1, 1).toIso8601String();
      final outdatedVersion = kLegalVersion > 1 ? kLegalVersion - 1 : 0;
      SharedPreferences.setMockInitialValues({
        'accepted_legal_version': outdatedVersion,
        'accepted_legal_timestamp': oldTimestamp,
      });

      await tester.pumpWidget(
        MyApp(
          datasetRepo: mockRepo,
          syncService: mockSync,
          needsMigration: false,
          remoteConfigService: FakeRemoteConfigService(),
          acceptedLegalVersion: outdatedVersion,
          assetBundle: MockAssetBundle({
            'legal/repo/public/docs/termos-de-uso.md': 'Terms',
            'legal/repo/public/docs/politica-de-privacidade.md': 'Privacy',
          }),
        ),
      );
      await tester.pump();

      await tester.pump();

      final termsFinder = find.byType(TermsOfUsePage);
      expect(termsFinder, findsOneWidget);

      // Verify update banner is visible
      expect(
        find.textContaining('Atualizamos nossos documentos legais'),
        findsOneWidget,
      );

      // Tap checkbox
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();

      // Tap accept button
      await tester.tap(
        find.widgetWithText(FilledButton, 'Aceitar Termos e Continuar'),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Verify SharedPreferences updated
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('accepted_legal_version'), kLegalVersion);
      final newTimestamp = prefs.getString('accepted_legal_timestamp');
      expect(newTimestamp, isNotNull);
      expect(newTimestamp, isNot(equals(oldTimestamp)));

      // Verify TreeNavigationWrapper is now shown
      expect(find.byType(TreeNavigationWrapper), findsOneWidget);
    },
  );

  testWidgets(
    'MyApp shows DatabaseMigrationScreen when needsMigration is true AND terms are accepted',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MyApp(
          datasetRepo: mockRepo,
          syncService: mockSync,
          needsMigration: true,
          remoteConfigService: FakeRemoteConfigService(),
          acceptedLegalVersion: kLegalVersion,
        ),
      );
      await tester.pump();

      // Since terms are accepted (kLegalVersion matches) and needsMigration is true,
      // DatabaseMigrationScreen should be shown instead of TreeNavigationWrapper.
      expect(find.byType(DatabaseMigrationScreen), findsOneWidget);
      expect(find.byType(TermsOfUsePage), findsNothing);
    },
  );

  testWidgets(
    'MyApp shows TermsOfUsePage even if needsMigration is true BUT terms are NOT accepted',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MyApp(
          datasetRepo: mockRepo,
          syncService: mockSync,
          needsMigration: true,
          remoteConfigService: FakeRemoteConfigService(),
          acceptedLegalVersion: 0, // Not accepted yet
        ),
      );
      await tester.pump();

      // terms are NOT accepted, so TermsOfUsePage must show up first
      expect(find.byType(TermsOfUsePage), findsOneWidget);
      // DatabaseMigrationScreen should NOT be shown yet
      expect(find.byType(DatabaseMigrationScreen), findsNothing);
    },
  );
  testWidgets(
    'TreeNavigationWrapper atualiza pico_aberto_id quando a rota muda',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TreeNavigationWrapper(
            datasetRepo: mockRepo,
            syncService: mockSync,
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      final wrapperState =
          tester.state<State<TreeNavigationWrapper>>(
                find.byType(TreeNavigationWrapper),
              )
              as dynamic;
      final treeController = wrapperState.treeController;

      expect(mockSync.pico_aberto_id.value, isNull);

      // Navega para um Pico
      treeController.navigateTo(
        PicoNode(cragId: 'pico_99', parent: const HomeNode()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(mockSync.pico_aberto_id.value, 'pico_99');

      // Volta para Home
      treeController.navigateTo(const HomeNode());
      await tester.pump(const Duration(milliseconds: 500));

      expect(mockSync.pico_aberto_id.value, isNull);
    },
  );

  group('setupAppServices & Foreground Takeover Tests', () {
    late MockWorkmanager mockWorkmanager;

    setUp(() {
      mockWorkmanager = MockWorkmanager();
    });

    test('setupAppServices deve cancelar tarefa de segundo plano e sincronizar se não precisa de migração', () async {
      SharedPreferences.setMockInitialValues({
        'cached_data_version': NetworkConstants.kDataVersion,
      });
      when(() => mockWorkmanager.cancelByUniqueName(any())).thenAnswer((_) async {});

      final result = await setupAppServices(
        mockRepo,
        mockSync,
        workmanager: mockWorkmanager,
      );

      verify(() => mockWorkmanager.cancelByUniqueName('migracao_pos_update')).called(1);
      expect(result, isFalse);
    });

    test('setupAppServices deve cancelar tarefa de segundo plano e indicar necessidade de migração', () async {
      final indiceFile = File(mockEditor.indicePath(tempDir.path));
      indiceFile.parent.createSync(recursive: true);
      indiceFile.writeAsBytesSync(Indice().writeToBuffer());

      SharedPreferences.setMockInitialValues({
        'cached_data_version': 0,
      });
      when(() => mockWorkmanager.cancelByUniqueName(any())).thenAnswer((_) async {});

      final result = await setupAppServices(
        mockRepo,
        mockSync,
        workmanager: mockWorkmanager,
      );

      verify(() => mockWorkmanager.cancelByUniqueName('migracao_pos_update')).called(1);
      expect(result, isTrue);
    });

    test('registrarOuvintesLiveReload deve sincronizar indice e inicializar datasetRepo quando eventoLiveReload emitir', () async {
      final mockDataset = MockDatasetRepository();
      final mockSyncSvc = MockSyncService();
      final editorLocal = EditorDeCroqui();

      when(() => mockSyncSvc.syncIndex()).thenAnswer((_) async => <String>[]);
      when(() => mockDataset.init()).thenAnswer((_) async {});

      registrarOuvintesLiveReload(editorLocal, mockDataset, mockSyncSvc);

      // Emite um evento de recarregamento
      editorLocal.eventoLiveReload.value = LiveReloadEvent(
        setorId: 'br_mg_ferros_setor1',
        timestamp: DateTime.now(),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      verify(() => mockSyncSvc.syncIndex()).called(1);
      verify(() => mockDataset.init()).called(1);
    });
  });
}

