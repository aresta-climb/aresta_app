import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/pages/home.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/sync_service.dart';
import 'package:frontend/services/editor_croqui.dart';

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
}
