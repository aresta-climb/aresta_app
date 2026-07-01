import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/pages/home.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:frontend/services/firebase/remote_config_service.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class FakeRemoteConfigService implements RemoteConfigService {
  final int _hard = 0;
  int _soft = 0;
  final int _rec = 0;

  @override int get hardMinVersion => _hard;
  @override int get softMinVersion => _soft;
  @override int get recommendedVersion => _rec;
  @override int getInt(String key) => 0;
  @override bool getBool(String key) => false;
  @override String getString(String key) => "";
  
  final String _iosUrl = "";
  @override String get storeUrlIos => _iosUrl;
  @override Future<void> initialize() async {}
  @override FirebaseRemoteConfig? debugRemoteConfig;
  @override void clearInitFuture() {}
}

void main() {
  testWidgets('Teste de carregamento da Home page', (WidgetTester tester) async {
    // Cria instâncias do repositório e do serviço de sincronização para testes.
    final editorDeCroqui = EditorDeCroqui();
    final testRepo = DatasetRepository(editorDeCroqui: editorDeCroqui);
    final testSync = SyncService(datasetRepository: testRepo);
    
    testRepo.activeDataset.value = TopoDataset(
      availablePicos: [],
      downloadedPicos: [],
    );

    // Fornece as dependências necessárias para o TreeNavigationWrapper
    await tester.pumpWidget(MaterialApp(
      home: TreeNavigationWrapper(
        datasetRepo: testRepo,
        syncService: testSync,
      ),
    ));

    // Verifica se a HomePage está presente dentro do wrapper de navegação.
    expect(find.byType(HomePage), findsOneWidget);
    
    // Verifica se os rótulos da barra de navegação estão presentes.
    // Usa findsWidgets pois 'Home' pode aparecer tanto na AppBar quanto na BottomNavBar
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Configurações'), findsOneWidget);
    expect(find.text('Explorar'), findsOneWidget);
  });

  testWidgets('Botão de sync mostra aviso quando aplicativo está obsoleto (soft block)', (WidgetTester tester) async {
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
    final testSync = SyncService(datasetRepository: testRepo, remoteConfigService: fakeRemote);
    
    testRepo.activeDataset.value = TopoDataset(
      availablePicos: [],
      downloadedPicos: [],
    );

    await tester.pumpWidget(MaterialApp(
      home: TreeNavigationWrapper(
        datasetRepo: testRepo,
        syncService: testSync,
      ),
    ));
    await tester.pump();

    final syncButton = find.byIcon(Icons.sync);
    expect(syncButton, findsOneWidget);

    await tester.tap(syncButton);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Sua versão do Aresta está desatualizada. Atualize para continuar baixando croquis.'), findsOneWidget);
  });
}
