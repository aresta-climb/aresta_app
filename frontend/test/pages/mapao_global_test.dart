/// Testes de widget para a tela principal do Mapão Global.
///
/// Assegura que a página [MapaoGlobalPage] seja capaz de instanciar o mapa
/// e renderizar a barra de navegação corretamente sem quebrar a árvore
/// de widgets, utilizando uma carga simulada de picos.
library;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/pages/mapao_global.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/editor_croqui.dart';

class FakeDatasetRepository extends DatasetRepository {
  FakeDatasetRepository(EditorDeCroqui editor) : super(editorDeCroqui: editor);
}

class FakeSyncService extends SyncService {
  FakeSyncService(DatasetRepository repo) : super(datasetRepository: repo);
}

void main() {
  testWidgets('MapaoGlobalPage renders correctly with crags', (WidgetTester tester) async {
    final mockEditor = EditorDeCroqui();
    final mockRepo = FakeDatasetRepository(mockEditor);
    final mockSync = FakeSyncService(mockRepo);

    final crags = [
      {
        'id': 'crag1',
        'nome': 'Pico 1',
        'local': 'Local 1',
        'latitude': -20.0,
        'longitude': -40.0,
      },
    ];

    await tester.pumpWidget(MaterialApp(
      home: MapaoGlobalPage(
        crags: crags,
        datasetRepo: mockRepo,
        syncService: mockSync,
      ),
    ));

    // Verifica AppBar
    expect(find.text('Mapão Global'), findsOneWidget);
    
    // Verifica se o GoogleMap é renderizado
    expect(find.byType(GoogleMap), findsOneWidget);
  });
}
