// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/widgets/folha_estimativa_viagem_pico.dart';

void main() {
  group('FolhaEstimativaViagemPico', () {
    testWidgets(
      'exibe título do pico, tempo médio em fluxo normal, distância por estrada e nota explicativa e fecha ao tocar no botão',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(extensions: [AppColors.dark]),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => FolhaEstimativaViagemPico.exibir(
                    context,
                    tituloPico: 'GRUTA DO BAÚ',
                    tempoMedio: '~1h',
                    distanciaEstradaKm: '54.1 km',
                  ),
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();

        expect(find.text('Estimativa de viagem'), findsOneWidget);
        expect(find.text('GRUTA DO BAÚ'), findsOneWidget);
        expect(find.text('Tempo médio (fluxo normal)'), findsOneWidget);
        expect(find.text('~1h'), findsOneWidget);
        expect(find.text('Distância por estrada'), findsOneWidget);
        expect(find.text('54.1 km'), findsOneWidget);
        expect(find.textContaining('OpenStreetMap'), findsOneWidget);

        await tester.tap(
          find.byKey(const Key('botao_fechar_folha_estimativa_viagem')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Estimativa de viagem'), findsNothing);
      },
    );
  });
}
