import 'package:package_info_plus/package_info_plus.dart';
import 'package:frontend/services/firebase/remote_config_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/pages/terms_of_use.dart';
import 'package:frontend/pages/database_migration_screen.dart';
import 'package:frontend/constants/legal_version.g.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mocks/mock_telemetry_service.dart';
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




class FakeRemoteConfigService implements RemoteConfigService {
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
  @override String get storeUrlIos => _iosUrl;

  @override
  void clearInitFuture() {}

  @override
  var debugRemoteConfig;

  @override
  Future<void> initialize() async {}
}

class MockDatasetRepository extends Mock implements DatasetRepository {}
class MockSyncService extends Mock implements SyncService {}

void main() {
  late DatasetRepository mockRepo;
  late SyncService mockSync;
  late EditorDeCroqui mockEditor;
  late MockTelemetryService mockTelemetry;

  setUp(() {
    mockEditor = EditorDeCroqui();
    mockRepo = DatasetRepository(editorDeCroqui: mockEditor);
    mockSync = SyncService(datasetRepository: mockRepo);
    mockSync.syncStatus.value = SyncStatus.updated;
    
    mockTelemetry = MockTelemetryService();
    TelemetryService.instance = mockTelemetry;

    SharedPreferences.setMockInitialValues({});

    PackageInfo.setMockInitialValues(
      appName: 'Aresta',
      packageName: 'com.aresta.climb',
      version: '1.0.0',
      buildNumber: '10',
      buildSignature: '',
    );
  });

  testWidgets('MyApp shows TermsOfUsePage when acceptedLegalVersion is 0 (first launch)', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(
      datasetRepo: mockRepo,
      syncService: mockSync, needsMigration: false, remoteConfigService: FakeRemoteConfigService(),
      acceptedLegalVersion: 0,
    ));
    await tester.pump();
    debugDumpApp();
    expect(find.byType(TermsOfUsePage), findsOneWidget);
    expect(find.byType(TreeNavigationWrapper), findsNothing);
  });



  test('setupAppServices awaits datasetRepo.init() before calling syncIndex', () async {
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
      expect(initCalled, isTrue, reason: 'init() should be awaited before syncIndex()');
      return [];
    });

    final result = await setupAppServices(mockRepo, mockSync);
    
    expect(result, isFalse);
    verify(() => mockRepo.init()).called(1);
    verify(() => mockSync.syncIndex()).called(1);
  });

  testWidgets('MyApp shows TreeNavigationWrapper when acceptedLegalVersion matches kLegalVersion', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(
      datasetRepo: mockRepo,
      syncService: mockSync, needsMigration: false, remoteConfigService: FakeRemoteConfigService(),
      acceptedLegalVersion: kLegalVersion,
    ));
    await tester.pump();

    expect(find.byType(TermsOfUsePage), findsNothing);
    expect(find.byType(TreeNavigationWrapper), findsOneWidget);
  });

  testWidgets('MyApp shows TermsOfUsePage with update flag when acceptedLegalVersion is > 0 but < kLegalVersion', (WidgetTester tester) async {
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

    await tester.pumpWidget(MyApp(
      datasetRepo: mockRepo,
      syncService: mockSync, needsMigration: false, remoteConfigService: FakeRemoteConfigService(),
      acceptedLegalVersion: outdatedVersion,
    ));
    await tester.pump();

    final termsFinder = find.byType(TermsOfUsePage);
    expect(termsFinder, findsOneWidget);
    expect(find.byType(TreeNavigationWrapper), findsNothing);

    final TermsOfUsePage termsPage = tester.widget(termsFinder);
    expect(termsPage.isUpdatingTerms, isTrue);
  });

  testWidgets('MyApp shows SnackBar when background sync fails', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(
      datasetRepo: mockRepo,
      syncService: mockSync, needsMigration: false, remoteConfigService: FakeRemoteConfigService(),
      acceptedLegalVersion: kLegalVersion,
    ));
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
    expect(find.text('Erro ao sincronizar os dados. Tente novamente mais tarde.'), findsOneWidget);
  });

  testWidgets('MyApp registers AppColors extension in both light and dark themes', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(
      datasetRepo: mockRepo,
      syncService: mockSync, needsMigration: false, remoteConfigService: FakeRemoteConfigService(),
      acceptedLegalVersion: kLegalVersion,
    ));
    await tester.pump();

    // Finish building
    await tester.pump(const Duration(seconds: 1));

    final BuildContext context = tester.element(find.byType(TreeNavigationWrapper));

    final theme = Theme.of(context);
    expect(theme.extension<AppColors>(), isNotNull);
  });

  testWidgets('MyApp saves timestamp and version when terms are accepted', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({}); // Initialize empty mock
    
    await tester.pumpWidget(MyApp(
      datasetRepo: mockRepo,
      syncService: mockSync, needsMigration: false, remoteConfigService: FakeRemoteConfigService(),
      acceptedLegalVersion: 0,
      assetBundle: MockAssetBundle({
        'legal/repo/TERMOS_DE_USO_ARESTA_CLIMB.md': 'Terms',
        'legal/repo/POLITICA_DE_PRIVACIDADE_ARESTA_CLIMB.md': 'Privacy',
      }),
    ));
    await tester.pump();

    await tester.pump();

    final termsFinder = find.byType(TermsOfUsePage);
    expect(termsFinder, findsOneWidget);

    // Tap checkbox
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();

    // Tap accept button
    await tester.tap(find.widgetWithText(FilledButton, 'Aceitar Termos e Continuar'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Verify SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('accepted_legal_version'), kLegalVersion);
    expect(prefs.getString('accepted_legal_timestamp'), isNotNull);

    // Verify TreeNavigationWrapper is now shown
    expect(find.byType(TreeNavigationWrapper), findsOneWidget);
  });

  testWidgets('MyApp updates timestamp and version when terms are updated and accepted again', (WidgetTester tester) async {
    final oldTimestamp = DateTime(2025, 1, 1).toIso8601String();
    final outdatedVersion = kLegalVersion > 1 ? kLegalVersion - 1 : 0;
    SharedPreferences.setMockInitialValues({
      'accepted_legal_version': outdatedVersion,
      'accepted_legal_timestamp': oldTimestamp,
    });
    
    await tester.pumpWidget(MyApp(
      datasetRepo: mockRepo,
      syncService: mockSync, needsMigration: false, remoteConfigService: FakeRemoteConfigService(),
      acceptedLegalVersion: outdatedVersion,
      assetBundle: MockAssetBundle({
        'legal/repo/TERMOS_DE_USO_ARESTA_CLIMB.md': 'Terms',
        'legal/repo/POLITICA_DE_PRIVACIDADE_ARESTA_CLIMB.md': 'Privacy',
      }),
    ));
    await tester.pump();

    await tester.pump();

    final termsFinder = find.byType(TermsOfUsePage);
    expect(termsFinder, findsOneWidget);

    // Verify update banner is visible
    expect(find.textContaining('Atualizamos nossos documentos legais'), findsOneWidget);

    // Tap checkbox
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();

    // Tap accept button
    await tester.tap(find.widgetWithText(FilledButton, 'Aceitar Termos e Continuar'));
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
  });

  testWidgets('MyApp shows DatabaseMigrationScreen when needsMigration is true AND terms are accepted', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(
      datasetRepo: mockRepo,
      syncService: mockSync,
      needsMigration: true,
      remoteConfigService: FakeRemoteConfigService(),
      acceptedLegalVersion: kLegalVersion,
    ));
    await tester.pump();

    // Since terms are accepted (kLegalVersion matches) and needsMigration is true,
    // DatabaseMigrationScreen should be shown instead of TreeNavigationWrapper.
    expect(find.byType(DatabaseMigrationScreen), findsOneWidget); 
    expect(find.byType(TermsOfUsePage), findsNothing);
  });

  testWidgets('MyApp shows TermsOfUsePage even if needsMigration is true BUT terms are NOT accepted', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(
      datasetRepo: mockRepo,
      syncService: mockSync,
      needsMigration: true,
      remoteConfigService: FakeRemoteConfigService(),
      acceptedLegalVersion: 0, // Not accepted yet
    ));
    await tester.pump();

    // terms are NOT accepted, so TermsOfUsePage must show up first
    expect(find.byType(TermsOfUsePage), findsOneWidget);
    // DatabaseMigrationScreen should NOT be shown yet
    expect(find.byType(DatabaseMigrationScreen), findsNothing);
  });
}
