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
        find.text('Feedback público. Nenhum dado pessoal é exposto.'),
        findsOneWidget,
      );
      final fittedBoxFinder = find.ancestor(
        of: find.text('Feedback público. Nenhum dado pessoal é exposto.'),
        matching: find.byType(FittedBox),
      );
      expect(fittedBoxFinder, findsOneWidget);
      final fittedBox = tester.widget<FittedBox>(fittedBoxFinder);
      expect(fittedBox.fit, BoxFit.scaleDown);

      final segmentedButton = tester.widget<SegmentedButton<TipoFeedback>>(
        find.byType(SegmentedButton<TipoFeedback>),
      );
      expect(
        segmentedButton.style?.visualDensity,
        VisualDensity.compact,
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.enabled, isFalse);
      expect(button.style?.minimumSize?.resolve({})?.height, 42.0);
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
      expect(
        find.text('Feedback público. Nenhum dado pessoal é exposto.'),
        findsOneWidget,
      );

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
      final scrollView = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(
        scrollView.padding,
        const EdgeInsets.fromLTRB(16, 8, 16, 12),
      );
    });
  });

  group('calcularFracaoAlturaFeedbackSheet', () {
    test(
        'calcula fração com croqui ativo (216 dp) considerando barra de 3 botões, gestos e sem barra',
        () {
      // Tela alta (~892 dp, Galaxy S24) com croqui ativo e barra de 3 botões (48 dp):
      // (216 + 48) / 892 = 264 / 892 ~= 0.29596
      expect(
        calcularFracaoAlturaFeedbackSheet(892.0, 48.0, true),
        closeTo(0.2960, 0.001),
      );

      // Tela alta (~892 dp) com croqui ativo e gestos (16 dp):
      // (216 + 16) / 892 = 232 / 892 ~= 0.26008
      expect(
        calcularFracaoAlturaFeedbackSheet(892.0, 16.0, true),
        closeTo(0.2601, 0.001),
      );

      // Emulador padrão (800 dp) com croqui ativo e SEM barra de SO (0 dp):
      // 216 / 800 = 0.270
      expect(
        calcularFracaoAlturaFeedbackSheet(800.0, 0.0, true),
        closeTo(0.270, 0.001),
      );

      // Tela compacta (640 dp) com croqui ativo e barra de 3 botões (48 dp):
      // (216 + 48) / 640 = 264 / 640 = 0.4125
      expect(
        calcularFracaoAlturaFeedbackSheet(640.0, 48.0, true),
        closeTo(0.4125, 0.001),
      );

      // Tela ultra pequena (400 dp) com barra:
      // (216 + 48) / 400 = 0.66 -> limitado no teto de 0.45
      expect(
        calcularFracaoAlturaFeedbackSheet(400.0, 48.0, true),
        equals(0.45),
      );
    });

    test(
        'calcula fração sem croqui ativo (168 dp) eliminando espaço vazio e mantendo segurança contra cortes',
        () {
      // Tela alta (~892 dp, Galaxy S24) em tela neutra com barra de 3 botões (48 dp):
      // (168 + 48) / 892 = 216 / 892 ~= 0.24215
      expect(
        calcularFracaoAlturaFeedbackSheet(892.0, 48.0, false),
        closeTo(0.2422, 0.001),
      );

      // Emulador padrão (800 dp) em tela neutra sem barra do SO (0 dp):
      // 168 / 800 = 0.210
      expect(
        calcularFracaoAlturaFeedbackSheet(800.0, 0.0, false),
        closeTo(0.210, 0.001),
      );

      // Tela compacta (640 dp) em tela neutra com barra (48 dp):
      // (168 + 48) / 640 = 216 / 640 = 0.3375
      expect(
        calcularFracaoAlturaFeedbackSheet(640.0, 48.0, false),
        closeTo(0.3375, 0.001),
      );

      // Tela ultra alta (1500 dp) em tela neutra sem barra:
      // 168 / 1500 = 0.112 -> limitado no novo piso de 0.18
      expect(
        calcularFracaoAlturaFeedbackSheet(1500.0, 0.0, false),
        equals(0.18),
      );

      // Fallback para nulo, zero ou valores negativos sem croqui:
      // 168 / 800 = 0.210
      expect(calcularFracaoAlturaFeedbackSheet(null), closeTo(0.210, 0.001));
      expect(calcularFracaoAlturaFeedbackSheet(0.0), closeTo(0.210, 0.001));
      expect(calcularFracaoAlturaFeedbackSheet(-50.0, -10.0), closeTo(0.210, 0.001));
    });
  });

  group('temCroquiAtivoNaArvore e GerenciadorFeedbackSheet', () {
    test('temCroquiAtivoNaArvore identifica resolver ou ausência na árvore', () {
      expect(temCroquiAtivoNaArvore(), isFalse);
      expect(
        temCroquiAtivoNaArvore(null, () => 'br_mg_pedra_grande'),
        isTrue,
      );
      expect(
        temCroquiAtivoNaArvore(null, () => null),
        isFalse,
      );
    });

    testWidgets('GerenciadorFeedbackSheet sincroniza dimensões com base no contexto', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(400, 800),
              padding: EdgeInsets.only(bottom: 48),
            ),
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    GerenciadorFeedbackSheet.sincronizarDimensoes(
                      context,
                      temCroquiAtivo: true,
                    );
                  },
                  child: const Text('Sincronizar'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Sincronizar'));
      await tester.pump();

      // (216 + 48) / 800 = 264 / 800 = 0.33
      expect(GerenciadorFeedbackSheet.fracaoAlturaSheet.value, closeTo(0.33, 0.001));
    });

    testWidgets(
      'GerenciadorFeedbackSheet preserva padding da janela mesmo dentro de Scaffold com BottomNavigationBar',
      (WidgetTester tester) async {
        // Configura o padding do FlutterView (barra de navegação física do SO = 48 dp lógicos)
        tester.view.padding = FakeViewPadding(
          bottom: 48 * tester.view.devicePixelRatio,
        );
        addTearDown(tester.view.resetPadding);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                actions: [
                  Builder(
                    builder: (context) {
                      // Dentro da AppBar de um Scaffold com bottomNavigationBar,
                      // o MediaQuery.of(context).padding.bottom é consumido e vira 0.0.
                      return IconButton(
                        icon: const Icon(Icons.warning),
                        onPressed: () {
                          GerenciadorFeedbackSheet.sincronizarDimensoes(
                            context,
                            temCroquiAtivo: false,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              bottomNavigationBar: BottomNavigationBar(
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                  BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
                ],
              ),
            ),
          ),
        );

        await tester.tap(find.byType(IconButton));
        await tester.pump();

        // Altura padrão do tester.view.physicalSize / devicePixelRatio = 600 dp (ou 800 dp)
        // (168 + 48) / alturaTela = 216 / alturaTela
        final alturaTela = tester.view.physicalSize.height / tester.view.devicePixelRatio;
        final fracaoEsperada = 216.0 / alturaTela;
        expect(
          GerenciadorFeedbackSheet.fracaoAlturaSheet.value,
          closeTo(fracaoEsperada, 0.001),
        );
      },
    );
  });
}
