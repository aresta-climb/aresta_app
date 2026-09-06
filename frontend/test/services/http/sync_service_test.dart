// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/constants/network_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/services/http/sync_storage.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/services/http/sync_isolate.dart';
import 'package:frontend/services/firebase/remote_config_service.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class FakeRemoteConfigService extends ChangeNotifier implements RemoteConfigService {
  final int _hard = 0;
  int _soft = 0;
  final int _rec = 0;

  @override
  int get hardMinVersion => _hard;
  @override
  int get softMinVersion => _soft;
  @override
  int get recommendedVersion => _rec;
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
  String get feedbackEdgeFunctionUrl => "";
  @override
  String get servingBaseUrl => "";
  @override
  String get officialServerUrl => "";
  @override
  Future<void> initialize() async {}
  @override
  FirebaseRemoteConfig? debugRemoteConfig;
  @override
  void clearInitFuture() {}
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

  test(
    'checkNeedsMigration deve retornar true se a versão salva for menor',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        'cached_data_version',
        NetworkConstants.kDataVersion - 1,
      );

      final result = await syncService.checkNeedsMigration();
      expect(result, isTrue);
    },
  );

  test(
    'checkNeedsMigration deve retornar false se a versão for igual',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('cached_data_version', NetworkConstants.kDataVersion);

      final result = await syncService.checkNeedsMigration();
      expect(result, isFalse);
    },
  );

  test('confirmMigrationComplete grava a versão correta', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'cached_data_version',
      NetworkConstants.kDataVersion - 1,
    );

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

  test(
    'syncIndex emite logs estruturados de depuração com arquivos atualizados/renomeados e removidos',
    () async {
      final editor = EditorDeCroqui();
      final picoId = 'pico_debug_logs';
      final newIndice = Indice()
        ..croquis.add(
          ResumoCroqui()
            ..id = picoId
            ..caminhoRelativo = 'picos/$picoId.binarypb'
            ..checksumSha256Croqui = 'NEW_HASH',
        );

      final indiceFile = File(editor.indicePath(tempDir.path));
      await indiceFile.parent.create(recursive: true);
      await indiceFile.writeAsBytes(
        (Indice()
              ..croquis.add(
                ResumoCroqui()
                  ..id = picoId
                  ..checksumSha256Croqui = 'OLD_HASH',
              ))
            .writeToBuffer(),
      );

      final picoDir = Directory('${editor.downloadsPath(tempDir.path)}/$picoId');
      await picoDir.create(recursive: true);
      final oldPicoFile = File('${picoDir.path}/$picoId.binarypb');
      await oldPicoFile.writeAsBytes(Croqui().writeToBuffer());

      final logs = <String>[];
      final originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logs.add(message);
      };

      try {
        final fakeClient = _SyncTestFakeClient(newIndice);
        final testSyncService = SyncService(
          datasetRepository: datasetRepository,
          storage: storage,
          client: fakeClient,
        );

        testSyncService.mockIsolateSpawn = (mainFunc, args) async {
          File('${picoDir.path}/$picoId.binarypb.tmp')
              .createSync(recursive: true);
          args.sendPort.send(
            DownloadIsolateResult(
              filesToDelete: ['${picoDir.path}/foto_antiga.jpg'],
              filesToRename: {
                '${picoDir.path}/$picoId.binarypb.tmp':
                    '${picoDir.path}/$picoId.binarypb',
              },
            ),
          );
        };

        await testSyncService.syncIndex(auto: true);

        expect(
          logs.any(
            (l) => l.contains(
              '🔄 [SyncService] Arquivos atualizados/renomeados no syncIndex (1):',
            ),
          ),
          isTrue,
        );
        expect(
          logs.any(
            (l) => l.contains(
              '${picoDir.path}/$picoId.binarypb.tmp -> ${picoDir.path}/$picoId.binarypb',
            ),
          ),
          isTrue,
        );
        expect(
          logs.any(
            (l) => l.contains(
              '🗑️ [SyncService] Arquivos removidos no syncIndex (1):',
            ),
          ),
          isTrue,
        );
        expect(
          logs.any((l) => l.contains('${picoDir.path}/foto_antiga.jpg')),
          isTrue,
        );
      } finally {
        debugPrint = originalDebugPrint;
      }
    },
  );
}

class _SyncTestFakeClient extends http.BaseClient {
  final Indice indice;
  _SyncTestFakeClient(this.indice);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.url.path.endsWith('indice.binarypb')) {
      final bytes = indice.writeToBuffer();
      return http.StreamedResponse(
        Stream.value(bytes),
        200,
        headers: {'etag': 'TEST_ETAG'},
      );
    }
    return http.StreamedResponse(Stream.value([]), 404);
  }
}

