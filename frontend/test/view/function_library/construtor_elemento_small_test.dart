// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:frontend/view/function_library/construtor_elemento_small.dart';
import 'package:frontend/view/function_library/sintaxe_tag_small.dart';

void main() {
  group('ConstrutorElementoSmall', () {
    test('isBlockElement deve retornar false para garantir comportamento inline', () {
      final construtor = ConstrutorElementoSmall();
      expect(construtor.isBlockElement(), isFalse);
    });

    testWidgets('deve reduzir a fonte em 80% em relação ao estilo base do parágrafo', (
      WidgetTester tester,
    ) async {
      const estiloParagrafo = TextStyle(fontSize: 20.0, color: Colors.black);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownBody(
              data: 'Texto normal <small>texto reduzido</small>.',
              inlineSyntaxes: [SintaxeTagSmall()],
              builders: {'small': ConstrutorElementoSmall()},
              styleSheet: MarkdownStyleSheet(p: estiloParagrafo),
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.byType(Text));
      expect(textWidget.textSpan, isNotNull);
      final spanPrincipal = textWidget.textSpan! as TextSpan;

      // Localiza o span correspondente ao texto reduzido
      bool encontrouSpanReduzido = false;
      spanPrincipal.visitChildren((span) {
        if (span is TextSpan && span.text == 'texto reduzido') {
          encontrouSpanReduzido = true;
          expect(span.style?.fontSize, closeTo(16.0, 0.01)); // 80% de 20.0
        }
        return true;
      });

      expect(encontrouSpanReduzido, isTrue);
    });

    testWidgets('deve preservar negrito e itálico aninhados com fonte reduzida', (
      WidgetTester tester,
    ) async {
      const estiloParagrafo = TextStyle(fontSize: 15.0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownBody(
              data: 'Nota: <small>**negrito** e *itálico*</small>.',
              inlineSyntaxes: [SintaxeTagSmall()],
              builders: {'small': ConstrutorElementoSmall()},
              styleSheet: MarkdownStyleSheet(p: estiloParagrafo),
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.byType(Text));
      final spanPrincipal = textWidget.textSpan! as TextSpan;

      bool encontrouNegrito = false;
      bool encontrouItalico = false;

      spanPrincipal.visitChildren((span) {
        if (span is TextSpan) {
          if (span.text == 'negrito') {
            encontrouNegrito = true;
            expect(span.style?.fontWeight, equals(FontWeight.bold));
            expect(span.style?.fontSize, closeTo(12.0, 0.01)); // 80% de 15.0
          } else if (span.text == 'itálico') {
            encontrouItalico = true;
            expect(span.style?.fontStyle, equals(FontStyle.italic));
            expect(span.style?.fontSize, closeTo(12.0, 0.01)); // 80% de 15.0
          }
        }
        return true;
      });

      expect(encontrouNegrito, isTrue);
      expect(encontrouItalico, isTrue);
    });

    testWidgets('deve usar fallback de tamanho de fonte quando estilo pai não especificar fontSize', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownBody(
              data: '<small>texto sem estilo pai</small>',
              inlineSyntaxes: [SintaxeTagSmall()],
              builders: {'small': ConstrutorElementoSmall()},
              styleSheet: MarkdownStyleSheet(p: const TextStyle()),
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.byType(Text));
      final spanPrincipal = textWidget.textSpan! as TextSpan;

      bool encontrouSpan = false;
      spanPrincipal.visitChildren((span) {
        if (span is TextSpan && span.text == 'texto sem estilo pai') {
          encontrouSpan = true;
          // Fallback padrão é 14.0 * 0.8 = 11.2
          expect(span.style?.fontSize, closeTo(11.2, 0.01));
        }
        return true;
      });
      expect(encontrouSpan, isTrue);
    });

    testWidgets('deve suportar texto tachado (del) dentro de small', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownBody(
              data: '<small>~~tachado~~</small>',
              inlineSyntaxes: [SintaxeTagSmall()],
              builders: {'small': ConstrutorElementoSmall()},
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.byType(Text));
      final spanPrincipal = textWidget.textSpan! as TextSpan;

      bool encontrouTachado = false;
      spanPrincipal.visitChildren((span) {
        if (span is TextSpan && span.text == 'tachado') {
          encontrouTachado = true;
          expect(span.style?.decoration, equals(TextDecoration.lineThrough));
        }
        return true;
      });

      expect(encontrouTachado, isTrue);
    });

    testWidgets('deve usar estilo do contexto quando parentStyle for totalmente nulo', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final construtor = ConstrutorElementoSmall();
                final elemento = md.Element('small', [md.Text('texto solto')]);
                final widget = construtor.visitElementAfterWithContext(
                  context,
                  elemento,
                  null,
                  null,
                );
                return widget!;
              },
            ),
          ),
        ),
      );

      expect(find.text('texto solto'), findsOneWidget);
    });

    testWidgets('deve lidar com elemento sem filhos sem lançar exceções', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final construtor = ConstrutorElementoSmall();
                final elementoVazio = md.Element('small', []);
                final widget = construtor.visitElementAfterWithContext(
                  context,
                  elementoVazio,
                  null,
                  null,
                );
                return widget!;
              },
            ),
          ),
        ),
      );

      expect(find.byType(Text), findsOneWidget);
    });
  });
}
