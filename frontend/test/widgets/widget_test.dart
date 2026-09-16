// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/pages/meus_croquis.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
  String get whatsappCommunityUrl => "";
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

void main() {
  testWidgets('Teste de carregamento da Home page', (
    WidgetTester tester,
  ) async {
    // Cria instâncias do repositório e do serviço de sincronização para testes.
    final editorDeCroqui = EditorDeCroqui();
    final testRepo = DatasetRepository(editorDeCroqui: editorDeCroqui);
    final testSync = SyncService(datasetRepository: testRepo);

    testRepo.activeDataset.value = ConjuntoDadosCroqui(
      picosDisponiveis: [],
      picosBaixados: [],
    );

    // Fornece as dependências necessárias para o TreeNavigationWrapper
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TreeNavigationWrapper(
            key: TreeNavigationWrapper.navKey,
            datasetRepo: testRepo,
            syncService: testSync,
          ),
        ),
      ),
    );
    await tester.pump();

    // Verifica se a página inicial está presente (o ícone de settings é renderizado pelo Header)
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });

  testWidgets(
    'Botão de sync mostra aviso quando aplicativo está obsoleto (soft block)',
    (WidgetTester tester) async {
      PackageInfo.setMockInitialValues(
        appName: 'Aresta',
        packageName: 'com.aresta.climb',
        version: '1.0.0',
        buildNumber: '10',
        buildSignature: '',
      );

      final fakeRemote = FakeRemoteConfigService();
      fakeRemote._soft = 11; // isNetworkDisabled == true

      final editorDeCroqui = EditorDeCroqui();
      final testRepo = DatasetRepository(editorDeCroqui: editorDeCroqui);
      final testSync = SyncService(
        datasetRepository: testRepo,
        remoteConfigService: fakeRemote,
      );
      testSync.syncStatus.value = SyncStatus.updated;

      testRepo.activeDataset.value = ConjuntoDadosCroqui(
        picosDisponiveis: [],
        picosBaixados: [
          {
            'id': 'pico_teste',
            'nome': 'Pico Teste',
            'local': 'Local Teste',
            'imagem_capa': '',
          },
        ],
      );

      // Pump MeusCroquisPage to render OfflineCragCard which contains the sync button
      await tester.pumpWidget(
        MaterialApp(
          home: MeusCroquisPage(datasetRepo: testRepo, syncService: testSync),
        ),
      );
      await tester.pump();

      final syncButton = find.byIcon(Icons.sync);
      expect(syncButton, findsOneWidget);

      await tester.tap(syncButton);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(
        find.text(
          'Sua versão do Aresta está desatualizada. Atualize para continuar baixando croquis.',
        ),
        findsOneWidget,
      );
    },
  );
}
