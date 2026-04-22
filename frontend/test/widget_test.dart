import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/pages/home.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/sync_service.dart';

void main() {
  testWidgets('Teste de carregamento da Home page', (WidgetTester tester) async {
    // Cria instâncias do repositório e do serviço de sincronização para testes.
    final testRepo = DatasetRepository();
    final testSync = SyncService(testRepo);
    
    testRepo.activeDataset.value = TopoDataset(
      availablePicos: [],
      downloadedPicos: [],
    );

    // Fornece as dependências necessárias para o MainNavigationWrapper
    await tester.pumpWidget(MaterialApp(
      home: MainNavigationWrapper(
        datasetRepo: testRepo,
        syncService: testSync,
      ),
    ));

    // Verifica se a HomePage está presente dentro do wrapper de navegação.
    expect(find.byType(HomePage), findsOneWidget);
    
    // Verifica se os rótulos da barra de navegação estão presentes.
    // Usa findsWidgets pois 'Home' pode aparecer tanto na AppBar quanto na BottomNavBar
    expect(find.text('Home'), findsWidgets);
    expect(find.text('GPS'), findsOneWidget);
    expect(find.text('Explorar'), findsOneWidget);
  });
}
