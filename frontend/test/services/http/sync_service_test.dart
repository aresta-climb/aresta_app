import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/constants/network_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/services/http/sync_storage.dart';
import 'package:frontend/services/http/sync_network.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:frontend/services/firebase/remote_config_service.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class FakeRemoteConfigService implements RemoteConfigService {
  int _hard = 0;
  int _soft = 0;
  int _rec = 0;

  @override int get hardMinVersion => _hard;
  @override int get softMinVersion => _soft;
  @override int get recommendedVersion => _rec;
  @override int getInt(String key) => 0;
  @override bool getBool(String key) => false;
  @override String getString(String key) => "";
  
  String _iosUrl = "";
  @override String get storeUrlIos => _iosUrl;
  @override Future<void> initialize() async {}
  @override FirebaseRemoteConfig? debugRemoteConfig;
  @override void clearInitFuture() {}
}

// Mock simple PathProviderPlatform
class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String path;
  MockPathProviderPlatform(this.path);

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return path;
  }
}

void main() {
  late SyncService syncService;
  late SyncStorage storage;
  late DatasetRepository datasetRepository;
  late Directory tempDir;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    
    tempDir = await Directory.systemTemp.createTemp('sync_service_test');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);

    storage = SyncStorage();
    // Inicia a instancia para n dar erro
    final editor = EditorDeCroqui();
    datasetRepository = DatasetRepository(editorDeCroqui: editor);

    syncService = SyncService(
      datasetRepository: datasetRepository,
      storage: storage,
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('checkNeedsMigration deve retornar true se a versão salva for menor', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('cached_data_version', NetworkConstants.kDataVersion - 1);

    final result = await syncService.checkNeedsMigration();
    expect(result, isTrue);
  });

  test('checkNeedsMigration deve retornar false se a versão for igual', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('cached_data_version', NetworkConstants.kDataVersion);

    final result = await syncService.checkNeedsMigration();
    expect(result, isFalse);
  });

  test('confirmMigrationComplete grava a versão correta', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('cached_data_version', NetworkConstants.kDataVersion - 1);

    await syncService.confirmMigrationComplete();

    final updatedVersion = prefs.getInt('cached_data_version');
    expect(updatedVersion, NetworkConstants.kDataVersion);
  });

  test('syncIndex set outdated status if isNetworkDisabled is true', () async {
    PackageInfo.setMockInitialValues(
      appName: 'Aresta',
      packageName: 'com.aresta.climb',
      version: '1.0.0',
      buildNumber: '10',
      buildSignature: '',
    );
    
    final fakeRemote = FakeRemoteConfigService();
    fakeRemote._soft = 11; 
    
    final tempSyncService = SyncService(
      datasetRepository: datasetRepository,
      storage: storage,
      remoteConfigService: fakeRemote,
    );

    await tempSyncService.syncIndex(auto: true);

    expect(tempSyncService.syncStatus.value, SyncStatus.outdated);
  });
}
