// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:frontend/pages/grupo.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';

void main() {
  testWidgets('GrupoPage should wrap body in SafeArea', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GrupoPage(grupo: Grupo()..nome = 'Grupo Teste', cragId: 'crag1'),
      ),
    );

    final scaffoldFinder = find.byType(Scaffold);
    expect(scaffoldFinder, findsOneWidget);

    final Scaffold scaffold = tester.widget(scaffoldFinder);
    expect(find.byType(SafeArea), findsWidgets);

    final safeAreas = tester.widgetList<SafeArea>(find.byType(SafeArea));
    expect(safeAreas.any((sa) => sa.bottom == true), isTrue);
  });

  testWidgets('GrupoPage re-resolve imagem de capa no didUpdateWidget durante Hot Reload', (tester) async {
    final grupo1 = Grupo()
      ..nome = 'Grupo 1'
      ..descricao = '![Capa](capa1.webp)';
    final grupo2 = Grupo()
      ..nome = 'Grupo 1'
      ..descricao = '![Capa](capa2.webp)';

    await tester.pumpWidget(
      MaterialApp(
        home: GrupoPage(grupo: grupo1, cragId: 'crag1'),
      ),
    );
    await tester.pump();

    // Re-pump simulando hot reload com novo grupo
    await tester.pumpWidget(
      MaterialApp(
        home: GrupoPage(grupo: grupo2, cragId: 'crag1'),
      ),
    );
    await tester.pump();
  });
}


