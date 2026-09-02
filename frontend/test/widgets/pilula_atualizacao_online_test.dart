// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/pilula_atualizacao_online.dart';

void main() {
  group('PilulaAtualizacaoOnline', () {
    testWidgets('renderiza texto de nova versão e dispara callback ao tocar', (tester) async {
      bool recarregou = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PilulaAtualizacaoOnline(
              onRecarregar: () {
                recarregou = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Novas informações disponíveis • Recarregar'), findsOneWidget);
      expect(find.byIcon(Icons.sync), findsOneWidget);

      await tester.tap(find.text('Novas informações disponíveis • Recarregar'));
      expect(recarregou, isTrue);
    });
  });
}
