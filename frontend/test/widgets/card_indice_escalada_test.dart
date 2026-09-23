// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/utils/indexador_escaladas.dart';
import 'package:frontend/widgets/card_indice_escalada.dart';

void main() {
  Widget criarAmbiente(Widget child) {
    return MaterialApp(
      theme: construirTemaEscuro(),
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('CardIndiceEscalada - Widget Tests', () {
    testWidgets('renderiza informações da escalada e localização com setor direto', (tester) async {
      final via = Escalada()
        ..viaEsportiva = (ViaEsportiva()
          ..nome = 'Cerveja Pura'
          ..dificuldade = GrauVia_GrauVia.BR_7A
          ..quantidadeProtecoesIntermediarias = 7
          ..quantidadeProtecoesParada = 2
          ..destaque = false);

      final setor = Setor()..nome = 'Falésia dos Ventos';

      final item = ItemIndiceEscalada(
        escalada: via,
        setor: setor,
        cragId: 'bau',
      );

      await tester.pumpWidget(
        criarAmbiente(
          CardIndiceEscalada(item: item, onTap: () {}),
        ),
      );

      expect(find.text('Cerveja Pura'), findsOneWidget);
      expect(find.text('7a'), findsOneWidget);
      expect(find.textContaining('Esportiva'), findsOneWidget);
      expect(find.textContaining('7+2'), findsOneWidget);
      expect(find.text('Falésia dos Ventos'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('renderiza estrela dourada quando escalada for destaque', (tester) async {
      final via = Escalada()
        ..viaEsportiva = (ViaEsportiva()
          ..nome = 'O Vigilante'
          ..dificuldade = GrauVia_GrauVia.BR_7B
          ..destaque = true);

      final setor = Setor()..nome = 'Face Norte';
      final grupo = Grupo()..nome = 'Complexo do Baú';

      final item = ItemIndiceEscalada(
        escalada: via,
        setor: setor,
        grupo: grupo,
        cragId: 'bau',
      );

      await tester.pumpWidget(
        criarAmbiente(
          CardIndiceEscalada(item: item, onTap: () {}),
        ),
      );

      expect(find.text('O Vigilante'), findsOneWidget);
      expect(find.text('7b'), findsOneWidget);
      expect(find.text('Complexo do Baú › Face Norte'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('dispara callback onTap ao ser acionado', (tester) async {
      bool clicado = false;
      final via = Escalada()
        ..boulder = (Boulder()
          ..nome = 'Bloco Dinâmico'
          ..dificuldade = GrauBoulder_GrauBoulder.V5);

      final setor = Setor()..nome = 'Vale dos Boulders';

      final item = ItemIndiceEscalada(
        escalada: via,
        setor: setor,
        cragId: 'bau',
      );

      await tester.pumpWidget(
        criarAmbiente(
          CardIndiceEscalada(
            item: item,
            onTap: () {
              clicado = true;
            },
          ),
        ),
      );

      await tester.tap(find.byType(CardIndiceEscalada));
      await tester.pump();

      expect(clicado, isTrue);
    });
  });
}
