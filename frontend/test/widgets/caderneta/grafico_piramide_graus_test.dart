// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/widgets/caderneta/grafico_piramide_graus.dart';

void main() {
  testWidgets('GraficoPiramideGraus renderiza estado vazio quando pirâmide não tem dados',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
        home: const Scaffold(
          body: GraficoPiramideGraus(
            piramide: {},
            modoVias: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pirâmide de Graduação'), findsOneWidget);
    expect(
      find.text('Nenhuma ascensão registrada nesta modalidade.'),
      findsOneWidget,
    );
  });

  testWidgets('GraficoPiramideGraus renderiza barras de graduação e alterna modalidade',
      (tester) async {
    bool? modoAlternado;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
        home: Scaffold(
          body: GraficoPiramideGraus(
            piramide: const {
              '5º': 2,
              '6a': 5,
              '7a': 8,
              '8a': 3,
            },
            modoVias: true,
            onAlternarModo: (vias) {
              modoAlternado = vias;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('5º'), findsOneWidget);
    expect(find.text('6a'), findsOneWidget);
    expect(find.text('7a'), findsOneWidget);
    expect(find.text('8a'), findsOneWidget);

    expect(find.text('8'), findsOneWidget); // Quantidade máxima
    expect(find.text('2'), findsOneWidget);

    // Toca no botão de Boulders
    await tester.tap(find.text('Boulders'));
    await tester.pumpAndSettle();
    expect(modoAlternado, isFalse);

    // Toca no botão de Vias
    await tester.tap(find.text('Vias'));
    await tester.pumpAndSettle();
    expect(modoAlternado, isTrue);
  });

  testWidgets(
      'GraficoPiramideGraus não causa overflow de renderização em larguras compactas (320px)',
      (tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: GraficoPiramideGraus(
              piramide: {'5º': 2, '6a': 5, '7a': 8, '8a': 3},
              modoVias: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Pirâmide de Graduação'), findsOneWidget);
    expect(find.text('Vias'), findsOneWidget);
    expect(find.text('Boulders'), findsOneWidget);
  });

  testWidgets(
      'GraficoPiramideGraus não causa overflow sob escala de fonte 1.8x em tela ultracompacta (320px)',
      (tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.8),
          ),
          child: child!,
        ),
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: GraficoPiramideGraus(
              piramide: {'5º': 2, '6a': 5, '7a': 8, '8a': 3},
              modoVias: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Pirâmide de Graduação'), findsOneWidget);
    expect(find.text('Vias'), findsOneWidget);
    expect(find.text('Boulders'), findsOneWidget);
  });

  testWidgets(
      'GraficoPiramideGraus renderiza barra com LinearGradient válido sem disparar ArgumentError',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
        home: const Scaffold(
          body: GraficoPiramideGraus(
            piramide: {'7a': 4},
            modoVias: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    final containers = tester.widgetList<Container>(find.byType(Container));
    final gradientes = containers
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .map((d) => d.gradient)
        .whereType<LinearGradient>()
        .toList();

    expect(gradientes, isNotEmpty);
    for (final gradiente in gradientes) {
      if (gradiente.stops != null) {
        expect(
          gradiente.colors.length,
          equals(gradiente.stops!.length),
          reason: 'LinearGradient exige que colors e stops tenham tamanho idêntico',
        );
      }
    }
  });
}

