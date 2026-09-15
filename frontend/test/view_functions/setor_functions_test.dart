// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/view_functions/setor_functions.dart';

void main() {
  group('resolveRouteLabels e RotulosVia', () {
    test('retorna rótulos vazios quando não há mapas no setor', () {
      final rotulos = resolveRouteLabels(Escalada(), Setor());
      expect(rotulos.mapIndicator, isEmpty);
      expect(rotulos.resolvedLabel, isEmpty);
    });

    test('instancia RotulosVia corretamente com valores tipados', () {
      const rotulos = RotulosVia(
        mapIndicator: 'M1',
        resolvedLabel: '1-A',
      );
      expect(rotulos.mapIndicator, 'M1');
      expect(rotulos.resolvedLabel, '1-A');
    });
  });

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
