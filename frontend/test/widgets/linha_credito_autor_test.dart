// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/linha_credito_autor.dart';

void main() {
  group('LinhaCreditoAutor', () {
    testWidgets('renderiza ícone e autores quando houver créditos válidos', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LinhaCreditoAutor(
              creditos: ['João Silva', 'Maria Santos'],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      expect(find.text('Croqui por João Silva, Maria Santos'), findsOneWidget);
    });

    testWidgets('não renderiza nada quando créditos estiverem vazios', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LinhaCreditoAutor(
              creditos: [],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.person_outline), findsNothing);
    });

    testWidgets('não renderiza nada quando créditos contiverem apenas placeholders', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LinhaCreditoAutor(
              creditos: ['Autores do Croqui Original'],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.person_outline), findsNothing);
      expect(find.textContaining('Autores do Croqui Original'), findsNothing);
    });
  });
}
