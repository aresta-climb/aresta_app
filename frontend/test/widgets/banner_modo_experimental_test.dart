// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/widgets/banner_modo_experimental.dart';

void main() {
  late EditorDeCroqui editorDeCroqui;

  setUp(() {
    editorDeCroqui = EditorDeCroqui();
  });

  testWidgets('deve retornar SizedBox.shrink quando não estiver no modo experimental', (
    WidgetTester tester,
  ) async {
    editorDeCroqui.isExperimentalMode.value = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              BannerModoExperimental(
                editorDeCroqui: editorDeCroqui,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(BannerModoExperimental), findsOneWidget);
    expect(find.textContaining('MODO EXPERIMENTAL'), findsNothing);
  });

  testWidgets('deve renderizar o banner e o tempo restante quando em modo experimental', (
    WidgetTester tester,
  ) async {
    editorDeCroqui.isExperimentalMode.value = true;
    editorDeCroqui.timeRemaining.value = const Duration(minutes: 18, seconds: 30);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              BannerModoExperimental(
                editorDeCroqui: editorDeCroqui,
                onSairModoExperimental: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.textContaining('MODO EXPERIMENTAL ATIVO'), findsOneWidget);
    expect(find.textContaining('(18:30)'), findsOneWidget);
    expect(find.textContaining('SAIR'), findsOneWidget);
  });

  testWidgets('deve chamar onSairModoExperimental ao clicar no botão de sair', (
    WidgetTester tester,
  ) async {
    editorDeCroqui.isExperimentalMode.value = true;
    bool saiu = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              BannerModoExperimental(
                editorDeCroqui: editorDeCroqui,
                onSairModoExperimental: () {
                  saiu = true;
                },
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.textContaining('SAIR'), findsOneWidget);
    await tester.tap(find.textContaining('SAIR'));
    await tester.pump();

    expect(saiu, isTrue);
  });

  testWidgets('deve acionar a animação de pulso ao disparar recarregamento', (
    WidgetTester tester,
  ) async {
    editorDeCroqui.isExperimentalMode.value = true;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              BannerModoExperimental(
                editorDeCroqui: editorDeCroqui,
              ),
            ],
          ),
        ),
      ),
    );

    // Dispara pulso
    editorDeCroqui.dispararPulsoRecarregamento();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(BannerModoExperimental), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
  });
}
