// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/caderneta/estatisticas_caderneta.dart';
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

  testWidgets(
      'PainelResumoEstatisticasCaderneta renderiza grade 2x2 com valores e fallbacks para graus nulos',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
        home: Scaffold(
          body: PainelResumoEstatisticasCaderneta(
            estatisticas: EstatisticasCaderneta.vazia(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Total de Cadenas'), findsOneWidget);
    expect(find.text('Taxa À Vista/Flash'), findsOneWidget);
    expect(find.text('Maior Grau (Vias)'), findsOneWidget);
    expect(find.text('Maior Grau (Boulders)'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('-'), findsNWidgets(2));

    const estatisticasPreenchidas = EstatisticasCaderneta(
      totalAscensoes: 5,
      totalCadenas: 4,
      totalTentativas: 1,
      contagemPorEstilo: {},
      piramideVias: {'7b': 3},
      piramideBoulders: {'V5': 1},
      maiorGrauVia: '7b',
      maiorGrauBoulder: 'V5',
      taxaAVistaFlash: 75.0,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
        home: const Scaffold(
          body: PainelResumoEstatisticasCaderneta(
            estatisticas: estatisticasPreenchidas,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('4'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('7b'), findsOneWidget);
    expect(find.text('V5'), findsOneWidget);
  });
}
