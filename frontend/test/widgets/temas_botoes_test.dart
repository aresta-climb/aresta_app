// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

/// Testes de widget para validar a consistência e segurança dos temas de botões e menus,
/// prevenindo crashes por `Null check operator used on a null value` em `ButtonStyle.merge`.
void main() {
  group('Temas de Botões e Menus - Consistência e Estabilidade', () {
    test('Tema claro deve definir estilos base para IconButton, MenuButton e PopupMenu', () {
      final tema = construirTemaClaro();

      expect(tema.iconButtonTheme.style, isNotNull,
          reason: 'IconButtonThemeData deve possuir estilo base não nulo');
      expect(tema.menuButtonTheme.style, isNotNull,
          reason: 'MenuButtonThemeData deve possuir estilo base não nulo');
      expect(tema.popupMenuTheme, isNotNull,
          reason: 'PopupMenuThemeData deve estar configurado');
    });

    test('Tema escuro deve definir estilos base para IconButton, MenuButton e PopupMenu', () {
      final tema = construirTemaEscuro();

      expect(tema.iconButtonTheme.style, isNotNull,
          reason: 'IconButtonThemeData deve possuir estilo base não nulo no tema escuro');
      expect(tema.menuButtonTheme.style, isNotNull,
          reason: 'MenuButtonThemeData deve possuir estilo base não nulo no tema escuro');
      expect(tema.popupMenuTheme, isNotNull,
          reason: 'PopupMenuThemeData deve estar configurado no tema escuro');
    });

    testWidgets('IconButton com mesclagem de estilo deve ser renderizado e clicado sem erro em ambos os temas',
        (WidgetTester tester) async {
      for (final tema in [construirTemaClaro(), construirTemaEscuro()]) {
        bool clicado = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: tema,
            home: Scaffold(
              body: Center(
                child: IconButton(
                  style: const ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(Colors.blue),
                  ),
                  icon: const Icon(Icons.feedback),
                  onPressed: () {
                    clicado = true;
                  },
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        final botaoFinder = find.byType(IconButton);
        expect(botaoFinder, findsOneWidget);

        await tester.tap(botaoFinder);
        await tester.pumpAndSettle();

        expect(clicado, isTrue);
      }
    });

    testWidgets('PopupMenuButton deve abrir e renderizar itens sem disparar erro de ButtonStyle.merge',
        (WidgetTester tester) async {
      for (final tema in [construirTemaClaro(), construirTemaEscuro()]) {
        String? itemSelecionado;

        await tester.pumpWidget(
          MaterialApp(
            theme: tema,
            home: Scaffold(
              body: Center(
                child: PopupMenuButton<String>(
                  onSelected: (valor) {
                    itemSelecionado = valor;
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'opcao1',
                      child: Text('Opção 1'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'opcao2',
                      child: Text('Opção 2'),
                    ),
                  ],
                  icon: const Icon(Icons.more_vert),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        final menuFinder = find.byType(PopupMenuButton<String>);
        expect(menuFinder, findsOneWidget);

        await tester.tap(menuFinder);
        await tester.pumpAndSettle();

        final itemFinder = find.text('Opção 1');
        expect(itemFinder, findsOneWidget);

        await tester.tap(itemFinder);
        await tester.pumpAndSettle();

        expect(itemSelecionado, equals('opcao1'));
      }
    });
  });
}
