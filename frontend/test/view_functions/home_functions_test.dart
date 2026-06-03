import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/view_functions/home_functions.dart';

void main() {
  late DatasetRepository mockRepo;
  late EditorDeCroqui mockEditor;

  setUp(() {
    mockEditor = EditorDeCroqui();
    mockRepo = DatasetRepository(editorDeCroqui: mockEditor);
  });

  Widget buildTestableWidget(List<Map<String, dynamic>> downloadedPicos) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return buildHomeBody(
              context,
              mockRepo,
              downloadedPicos,
              {}, // downloadingCrags
              onAddCrag: () {},
            );
          },
        ),
      ),
    );
  }

  testWidgets('buildHomeBody shows "Explorar guias" and hides dropdown when no guides downloaded', (WidgetTester tester) async {
    // Rendereiza o widget com lista vazia
    await tester.pumpWidget(buildTestableWidget([]));
    await tester.pumpAndSettle();

    // Deve mostrar "Nenhum guia baixado ainda."
    expect(find.text('Nenhum guia baixado ainda.'), findsOneWidget);

    // Deve mostrar o botão "Explorar guias"
    final explorarGuiasFinder = find.widgetWithText(ElevatedButton, 'Explorar guias');
    expect(explorarGuiasFinder, findsOneWidget);

    // NÃO deve mostrar o dropdown "Todos os guias baixados"
    expect(find.text('Todos os guias baixados'), findsNothing);
  });

  testWidgets('buildHomeBody shows dropdown and hides "Explorar guias" when guides are downloaded', (WidgetTester tester) async {
    // Um pico fictício baixado
    final dummyPico = {
      'id': 'test-pico-1',
      'nome': 'Pico de Teste',
      'local': 'Local de Teste',
    };

    await tester.pumpWidget(buildTestableWidget([dummyPico]));
    await tester.pumpAndSettle();

    // NÃO deve mostrar "Nenhum guia baixado ainda."
    expect(find.text('Nenhum guia baixado ainda.'), findsNothing);

    // NÃO deve mostrar o botão "Explorar guias"
    final explorarGuiasFinder = find.widgetWithText(ElevatedButton, 'Explorar guias');
    expect(explorarGuiasFinder, findsNothing);

    // Deve mostrar o dropdown "Todos os guias baixados"
    expect(find.text('Todos os guias baixados'), findsOneWidget);
  });
}
