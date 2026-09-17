// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/utils/consolidador_modalidades.dart';
import 'package:frontend/widgets/badges_modalidades.dart';

void main() {
  Widget criarAmbienteDeTeste(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('BadgesModalidades - Widget Tests', () {
    testWidgets('não renderiza nada quando lista de itens está vazia', (tester) async {
      await tester.pumpWidget(
        criarAmbienteDeTeste(
          const BadgesModalidades(itens: []),
        ),
      );

      expect(find.byType(Wrap), findsNothing);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('renderiza chips em Wrap para itens fornecidos diretamente', (tester) async {
      final itens = [
        const ItemModalidade(
          modalidade: ModalidadeEscaladaEnum.esportiva,
          quantidade: 14,
          rotuloFormatado: '14 esportivas',
        ),
        const ItemModalidade(
          modalidade: ModalidadeEscaladaEnum.movel,
          quantidade: 1,
          rotuloFormatado: '1 móvel',
        ),
      ];

      await tester.pumpWidget(
        criarAmbienteDeTeste(
          BadgesModalidades(itens: itens),
        ),
      );

      expect(find.byType(Wrap), findsOneWidget);
      expect(find.text('14 esportivas'), findsOneWidget);
      expect(find.text('1 móvel'), findsOneWidget);
    });

    testWidgets('construtor deSetor renderiza badges de um Setor', (tester) async {
      final setor = Setor()
        ..nome = 'Setor Central'
        ..escaladas.addAll([
          Escalada()..boulder = (Boulder()..nome = 'B1'),
          Escalada()..boulder = (Boulder()..nome = 'B2'),
          Escalada()..viaEsportiva = (ViaEsportiva()..nome = 'E1'),
        ]);

      await tester.pumpWidget(
        criarAmbienteDeTeste(
          BadgesModalidades.deSetor(setor),
        ),
      );

      expect(find.text('1 esportiva'), findsOneWidget);
      expect(find.text('2 boulders'), findsOneWidget);
    });

    testWidgets('construtor deGrupo renderiza badges agregadas de um Grupo', (tester) async {
      final setor1 = Setor()
        ..nome = 'S1'
        ..escaladas.add(Escalada()..viaEsportiva = (ViaEsportiva()..nome = 'E1'));
      final setor2 = Setor()
        ..nome = 'S2'
        ..escaladas.add(Escalada()..viaMovel = (ViaMovel()..nome = 'M1'));

      final grupo = Grupo()
        ..nome = 'Grupo Teste'
        ..setores.addAll([
          ArquivoSetor()..conteudo = setor1,
          ArquivoSetor()..conteudo = setor2,
        ]);

      await tester.pumpWidget(
        criarAmbienteDeTeste(
          BadgesModalidades.deGrupo(grupo),
        ),
      );

      expect(find.text('1 esportiva'), findsOneWidget);
      expect(find.text('1 móvel'), findsOneWidget);
    });

    testWidgets('construtor deEscaladas renderiza badges diretamente de lista de escaladas', (tester) async {
      final escaladas = [
        Escalada()..highline = (Highline()..nome = 'Highline 1'),
        Escalada()..viaMultiplasEnfiadas = (ViaMultiplasEnfiadas()..nome = 'Multi 1'),
      ];

      await tester.pumpWidget(
        criarAmbienteDeTeste(
          BadgesModalidades.deEscaladas(escaladas),
        ),
      );

      expect(find.text('1 multienfiada'), findsOneWidget);
      expect(find.text('1 highline'), findsOneWidget);
    });
  });
}
