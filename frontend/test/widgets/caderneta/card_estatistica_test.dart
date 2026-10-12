// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/widgets/caderneta/card_estatistica.dart';

void main() {
  testWidgets('CardEstatistica renderiza título, valor e ícone corretamente',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
        home: const Scaffold(
          body: CardEstatistica(
            titulo: 'Cadenas Totais',
            valor: '42',
            icone: Icons.emoji_events_outlined,
            subtitulo: '30 vias, 12 boulders',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cadenas Totais'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('30 vias, 12 boulders'), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events_outlined), findsOneWidget);
  });
}
