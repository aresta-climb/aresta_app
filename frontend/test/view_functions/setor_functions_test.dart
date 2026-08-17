import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/view_functions/setor_functions.dart';

void main() {
  group('buildEscaladaSortGrid', () {
    testWidgets('renderiza botões e chama onSortChanged', (WidgetTester tester) async {
      EscaladaSortMode? selectedMode;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => buildEscaladaSortGrid(
              context,
              EscaladaSortMode.original,
              (mode) {
                selectedMode = mode;
              },
            ),
          ),
        ),
      ));

      expect(find.text('PADRÃO'), findsOneWidget);
      expect(find.text('ALFABÉTICO'), findsOneWidget);
      expect(find.text('DIFICULDADE'), findsOneWidget);

      await tester.tap(find.text('ALFABÉTICO'));
      await tester.pump();
      expect(selectedMode, EscaladaSortMode.alphaAsc);
      
      await tester.tap(find.text('DIFICULDADE'));
      await tester.pump();
      expect(selectedMode, EscaladaSortMode.gradeAsc);
    });
  });
}
