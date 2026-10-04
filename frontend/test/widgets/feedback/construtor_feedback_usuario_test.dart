// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/tipo_feedback.dart';
import 'package:frontend/widgets/feedback/construtor_feedback_usuario.dart';
import 'package:frontend/theme/cores_app.dart';

void main() {
  Widget buildTestWidget({
    required OnSubmit onSubmit,
    String? cragId,
  }) {
    return MaterialApp(
      theme: ThemeData(
        extensions: const [AppColors.dark],
      ),
      home: Scaffold(
        body: BetterFeedback(
          child: Builder(
            builder: (context) {
              return construtorFeedbackUsuario(
                context,
                onSubmit,
                null,
                cragId: cragId,
              );
            },
          ),
        ),
      ),
    );
  }

  group('construtorFeedbackUsuario - Tela com Croqui Ativo', () {
    testWidgets('renderiza título, SegmentedButton desmarcado e aviso comunitário', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          onSubmit: (String text, {Map<String, dynamic>? extras}) async {},
          cragId: 'br_mg_igarape_pedra_grande',
        ),
      );

      expect(find.text('Sobre o que é a sugestão?'), findsOneWidget);
      expect(find.byType(SegmentedButton<TipoFeedback>), findsOneWidget);
      expect(find.text('Sobre o Croqui'), findsOneWidget);
      expect(find.text('Sobre o App'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Enviar'), findsOneWidget);
      expect(
        find.textContaining('GitHub comunitário'),
        findsOneWidget,
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.enabled, isFalse);
    });

    testWidgets(
      'botão Enviar permanece desabilitado se texto for digitado mas nenhum segmento selecionado',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            onSubmit: (String text, {Map<String, dynamic>? extras}) async {},
            cragId: 'pico_teste',
          ),
        );

        await tester.enterText(find.byType(TextField), 'Erro no croqui');
        await tester.pumpAndSettle();

        final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(button.enabled, isFalse);
      },
    );

    testWidgets(
      'botão Enviar permanece desabilitado se segmento for selecionado mas texto for vazio',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            onSubmit: (String text, {Map<String, dynamic>? extras}) async {},
            cragId: 'pico_teste',
          ),
        );

        await tester.tap(find.text('Sobre o Croqui'));
        await tester.pumpAndSettle();

        final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(button.enabled, isFalse);
      },
    );

    testWidgets(
      'selecionar Sobre o Croqui e preencher texto habilita envio e despacha extras com croqui',
      (WidgetTester tester) async {
        String? textoSubmetido;
        Map<String, dynamic>? extrasSubmetidos;

        await tester.pumpWidget(
          buildTestWidget(
            onSubmit: (String text, {Map<String, dynamic>? extras}) async {
              textoSubmetido = text;
              extrasSubmetidos = extras;
            },
            cragId: 'pico_teste',
          ),
        );

        await tester.tap(find.text('Sobre o Croqui'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Via com graduação errada');
        await tester.pumpAndSettle();

        final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(button.enabled, isTrue);

        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        expect(textoSubmetido, 'Via com graduação errada');
        expect(extrasSubmetidos, isNotNull);
        expect(extrasSubmetidos!['tipo_feedback'], 'croqui');
      },
    );

    testWidgets(
      'selecionar Sobre o App e preencher texto despacha extras com app',
      (WidgetTester tester) async {
        String? textoSubmetido;
        Map<String, dynamic>? extrasSubmetidos;

        await tester.pumpWidget(
          buildTestWidget(
            onSubmit: (String text, {Map<String, dynamic>? extras}) async {
              textoSubmetido = text;
              extrasSubmetidos = extras;
            },
            cragId: 'pico_teste',
          ),
        );

        await tester.tap(find.text('Sobre o App'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Bug de renderização');
        await tester.pumpAndSettle();

        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        expect(textoSubmetido, 'Bug de renderização');
        expect(extrasSubmetidos?['tipo_feedback'], 'app');
      },
    );
  });

  group('construtorFeedbackUsuario - Tela Neutra (sem croqui ativo)', () {
    testWidgets('omite SegmentedButton e habilita envio apenas pelo texto, com tipo app', (
      WidgetTester tester,
    ) async {
      String? textoSubmetido;
      Map<String, dynamic>? extrasSubmetidos;

      await tester.pumpWidget(
        buildTestWidget(
          onSubmit: (String text, {Map<String, dynamic>? extras}) async {
            textoSubmetido = text;
            extrasSubmetidos = extras;
          },
          cragId: null, // Tela neutra
        ),
      );

      expect(find.text('Sobre o que é a sugestão?'), findsOneWidget);
      expect(find.byType(SegmentedButton<TipoFeedback>), findsNothing);
      expect(find.text('Sobre o Croqui'), findsNothing);
      expect(find.text('Sobre o App'), findsNothing);
      expect(find.textContaining('GitHub comunitário'), findsOneWidget);

      final buttonAntes = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(buttonAntes.enabled, isFalse);

      await tester.enterText(find.byType(TextField), 'Sugestão na Home');
      await tester.pumpAndSettle();

      final buttonDepois = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(buttonDepois.enabled, isTrue);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(textoSubmetido, 'Sugestão na Home');
      expect(extrasSubmetidos?['tipo_feedback'], 'app');
    });
  });
}
