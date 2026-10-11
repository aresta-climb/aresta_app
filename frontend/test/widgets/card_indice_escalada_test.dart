// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/utils/indexador_escaladas.dart';
import 'package:frontend/view/function_library/setor_functions.dart';
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

    testWidgets('renderiza modo setor com rótulo do croqui no badge, grau no subtítulo e sem localização', (tester) async {
      final via = Escalada()
        ..viaEsportiva = (ViaEsportiva()
          ..nome = 'Fenda da Aranha'
          ..dificuldade = GrauVia_GrauVia.BR_8A
          ..quantidadeProtecoesIntermediarias = 10
          ..quantidadeProtecoesParada = 2);

      final setor = Setor()..nome = 'Setor Central';

      final item = ItemIndiceEscalada(
        escalada: via,
        setor: setor,
        cragId: 'bau',
      );

      await tester.pumpWidget(
        criarAmbiente(
          CardIndiceEscalada(
            item: item,
            rotuloCroqui: const RotulosVia(mapIndicator: 'M1', resolvedLabel: '4'),
            mostrarLocalizacao: false,
            onTap: () {},
          ),
        ),
      );

      // Nome da via
      expect(find.text('Fenda da Aranha'), findsOneWidget);
      // Rótulo do croqui no badge
      expect(find.text('M1'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      // Subtítulo técnico com modalidade, grau e proteções
      expect(find.textContaining('Esportiva | 8a'), findsOneWidget);
      expect(find.textContaining('10+2'), findsOneWidget);
      // Não exibe a linha de localização
      expect(find.text('Setor Central'), findsNothing);
      expect(find.byIcon(Icons.location_on), findsNothing);
    });

    testWidgets('renderiza ícone no badge quando rotuloCroqui for vazio no modo setor', (tester) async {
      final via = Escalada()
        ..boulder = (Boulder()
          ..nome = 'Teto Sem Fim'
          ..dificuldade = GrauBoulder_GrauBoulder.V7);

      final setor = Setor()..nome = 'Vale do Teto';

      final item = ItemIndiceEscalada(
        escalada: via,
        setor: setor,
        cragId: 'bau',
      );

      await tester.pumpWidget(
        criarAmbiente(
          CardIndiceEscalada(
            item: item,
            rotuloCroqui: const RotulosVia(mapIndicator: '', resolvedLabel: ''),
            mostrarLocalizacao: false,
            onTap: () {},
          ),
        ),
      );

      expect(find.text('Teto Sem Fim'), findsOneWidget);
      expect(find.byIcon(Icons.terrain_outlined), findsOneWidget);
      expect(find.textContaining('Boulder | v7'), findsOneWidget);
    });

    testWidgets('renderiza com efeito de realce quando isTarget for true', (tester) async {
      final via = Escalada()
        ..viaEsportiva = (ViaEsportiva()
          ..nome = 'Via de Foco'
          ..dificuldade = GrauVia_GrauVia.BR_6);

      final setor = Setor()..nome = 'Setor Alvo';

      final item = ItemIndiceEscalada(
        escalada: via,
        setor: setor,
        cragId: 'bau',
      );

      await tester.pumpWidget(
        criarAmbiente(
          CardIndiceEscalada(
            item: item,
            isTarget: true,
            onTap: () {},
          ),
        ),
      );

      expect(find.text('Via de Foco'), findsOneWidget);
      // Avança a animação de realce
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(CardIndiceEscalada), findsOneWidget);
    });
  });
}
