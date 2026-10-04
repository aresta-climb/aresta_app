// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/utils/filtro_grau_escalada.dart';
import 'package:frontend/widgets/barra_ordenacao_exploracao.dart';

void main() {
  group('BarraOrdenacaoExploracao Widget Tests', () {
    testWidgets('renderiza os três botões de ordenação e o botão de direção', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BarraOrdenacaoExploracao(
              ordenacaoAtual: TipoOrdenacaoExploracao.padrao,
              direcaoCrescente: true,
              onOrdenacaoChanged: (_) {},
              onDirecaoChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('PADRÃO'), findsOneWidget);
      expect(find.text('GRAU'), findsOneWidget);
      expect(find.text('ALFABÉTICO'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    });

    testWidgets('dispara onOrdenacaoChanged ao tocar em GRAU e ALFABÉTICO', (tester) async {
      TipoOrdenacaoExploracao? novaOrdenacao;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BarraOrdenacaoExploracao(
              ordenacaoAtual: TipoOrdenacaoExploracao.padrao,
              direcaoCrescente: true,
              onOrdenacaoChanged: (modo) => novaOrdenacao = modo,
              onDirecaoChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('GRAU'));
      await tester.pumpAndSettle();
      expect(novaOrdenacao, TipoOrdenacaoExploracao.grau);

      await tester.tap(find.text('ALFABÉTICO'));
      await tester.pumpAndSettle();
      expect(novaOrdenacao, TipoOrdenacaoExploracao.alfabetico);

      await tester.tap(find.text('PADRÃO'));
      await tester.pumpAndSettle();
      expect(novaOrdenacao, TipoOrdenacaoExploracao.padrao);
    });

    testWidgets('dispara onDirecaoChanged e inverte ícone ao alternar direção', (tester) async {
      bool? novaDirecao;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BarraOrdenacaoExploracao(
              ordenacaoAtual: TipoOrdenacaoExploracao.grau,
              direcaoCrescente: true,
              onOrdenacaoChanged: (_) {},
              onDirecaoChanged: (dir) => novaDirecao = dir,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_upward));
      await tester.pumpAndSettle();
      expect(novaDirecao, isFalse);

      // Renderiza com direção decrescente
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BarraOrdenacaoExploracao(
              ordenacaoAtual: TipoOrdenacaoExploracao.grau,
              direcaoCrescente: false,
              onOrdenacaoChanged: (_) {},
              onDirecaoChanged: (dir) => novaDirecao = dir,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_downward));
      await tester.pumpAndSettle();
      expect(novaDirecao, isTrue);
    });

    testWidgets('aplica acabamento visual com cores ativas (brandColor) e inativas (graniteEdge)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [
              AppColors(
                beastHide: Colors.black,
                fishBone: Colors.white,
                leatherWork: Colors.brown,
                obsidianBrown: Colors.brown,
                slateStone: Colors.grey,
                mossRock: Colors.green,
                clayEarth: Colors.orange,
                weatheredIron: Colors.blueGrey,
              ),
            ],
          ),
          home: Scaffold(
            body: BarraOrdenacaoExploracao(
              ordenacaoAtual: TipoOrdenacaoExploracao.padrao,
              direcaoCrescente: true,
              onOrdenacaoChanged: (_) {},
              onDirecaoChanged: (_) {},
            ),
          ),
        ),
      );

      // Card ativo (PADRÃO) tem borda de destaque
      final containerPadrao = tester.widget<Container>(
        find.ancestor(of: find.text('PADRÃO'), matching: find.byType(Container)).first,
      );
      final boxPadrao = containerPadrao.decoration as BoxDecoration;
      expect((boxPadrao.border as Border).top.color, AppColors.brandColor);

      // Card inativo (GRAU) tem borda graniteEdge (0xFF2A2A2A)
      final containerGrau = tester.widget<Container>(
        find.ancestor(of: find.text('GRAU'), matching: find.byType(Container)).first,
      );
      final boxGrau = containerGrau.decoration as BoxDecoration;
      expect((boxGrau.border as Border).top.color, const Color(0xFF2A2A2A));
    });
  });
}
