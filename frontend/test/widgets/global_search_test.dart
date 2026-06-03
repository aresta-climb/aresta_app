import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/widgets/global_search.dart';

void main() {
  group('Teste do Widget GlobalSearch', () {
    late DatasetRepository repo;
    late EditorDeCroqui editor;

    setUp(() async {
      editor = EditorDeCroqui();
      repo = DatasetRepository(editorDeCroqui: editor);
      // Aguarda configuração de dados se necessário
    });

    testWidgets('Renderiza a barra de pesquisa e expande ao clicar', (WidgetTester tester) async {
      bool switchedTab = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlobalSearch(
              datasetRepo: repo,
              downloadedPicos: const [],
            ),
          ),
        ),
      );

      // Verifica o estado inicial colapsado procurando pelo texto de dica
      expect(find.text('Pesquisar em seus guias baixados...'), findsOneWidget);
      
      // Toca no TextField para expandir
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      // Verifica a expansão procurando pelo dropdown de filtro
      expect(find.text('Filtro: Todos'), findsOneWidget);
      expect(find.textContaining('Dica: você também pode pesquisar por dificuldade'), findsOneWidget);

      // Digita algo
      await tester.enterText(find.byType(TextField), '7a');
      await tester.pumpAndSettle();
      
      // Os resultados devem ser "Nenhum resultado" (já que nosso repo está vazio)
      expect(find.text('Nenhum resultado encontrado.'), findsOneWidget);
    });
  });
}
