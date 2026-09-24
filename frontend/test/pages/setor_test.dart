// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:frontend/pages/setor.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import '../mocks/mock_telemetry_service.dart';

void main() {
  testWidgets('SetorPage should wrap body in SafeArea', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SetorPage(setor: Setor()..nome = 'Setor Teste', cragId: 'crag1'),
      ),
    );

    final scaffoldFinder = find.byType(Scaffold);
    expect(scaffoldFinder, findsOneWidget);

    expect(find.byType(SafeArea), findsWidgets);
    final safeAreas = tester.widgetList<SafeArea>(find.byType(SafeArea));
    expect(safeAreas.any((sa) => sa.bottom == true), isTrue);
  });

  testWidgets('SetorPage should handle scrollToEscalada gracefully without crashing', (tester) async {
    final via1 = Escalada(viaEsportiva: ViaEsportiva(nome: 'Via 1'));
    final via2 = Escalada(viaEsportiva: ViaEsportiva(nome: 'Via 2'));
    final setor = Setor()
      ..nome = 'Setor Teste'
      ..escaladas.addAll([via1, via2]);

    await tester.pumpWidget(
      MaterialApp(
        home: SetorPage(
          setor: setor,
          cragId: 'crag1',
          scrollToEscalada: via2,
        ),
      ),
    );

    // Avança o timer de 400ms do delay do scroll e processa o post-frame callback
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Via 2'), findsOneWidget);

    // Atualiza o widget com outra via para exercitar o didUpdateWidget
    await tester.pumpWidget(
      MaterialApp(
        home: SetorPage(
          setor: setor,
          cragId: 'crag1',
          scrollToEscalada: via1,
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Via 1'), findsOneWidget);
  });

  testWidgets('SetorPage re-resolve imagem de capa no didUpdateWidget durante Hot Reload', (tester) async {
    final setor1 = Setor()
      ..nome = 'Setor 1'
      ..descricao = '![Capa](capa1.webp)';
    final setor2 = Setor()
      ..nome = 'Setor 1'
      ..descricao = '![Capa](capa2.webp)';

    await tester.pumpWidget(
      MaterialApp(
        home: SetorPage(setor: setor1, cragId: 'crag1'),
      ),
    );
    await tester.pump();

    // Re-pump simulando hot reload com novo setor
    await tester.pumpWidget(
      MaterialApp(
        home: SetorPage(setor: setor2, cragId: 'crag1'),
      ),
    );
    await tester.pump();
  });

  testWidgets('SetorPage dispara logAlterarOrdenacao ao alternar critérios de ordenação', (tester) async {
    final mockTelemetria = MockTelemetryService();
    TelemetryService.instance = mockTelemetria;

    final via1 = Escalada(viaEsportiva: ViaEsportiva(nome: 'Beta'));
    final via2 = Escalada(viaEsportiva: ViaEsportiva(nome: 'Alfa'));
    final setor = Setor()
      ..nome = 'Setor Ordenação'
      ..escaladas.addAll([via1, via2]);

    await tester.pumpWidget(
      MaterialApp(
        home: SetorPage(setor: setor, cragId: 'crag1'),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Toca em ALFABÉTICO
    mockTelemetria.clear();
    await tester.tap(find.text('ALFABÉTICO'));
    await tester.pumpAndSettle();

    expect(mockTelemetria.recordedEvents, contains('alterar_ordenacao'));
    var params = mockTelemetria.recordedParams['alterar_ordenacao']!;
    expect(params['acao'], 'alterar_ordenacao');
    expect(params['origem'], 'setor');
    expect(params['detalhe'], 'alphaAsc');

    // 2. Toca em DIFICULDADE
    mockTelemetria.clear();
    await tester.tap(find.text('DIFICULDADE'));
    await tester.pumpAndSettle();

    expect(mockTelemetria.recordedEvents, contains('alterar_ordenacao'));
    params = mockTelemetria.recordedParams['alterar_ordenacao']!;
    expect(params['acao'], 'alterar_ordenacao');
    expect(params['origem'], 'setor');
    expect(params['detalhe'], 'gradeAsc');
  });
}

