// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/navigation/arvore_navegacao.dart';
import 'package:frontend/navigation/wrapper_navegacao_arvore.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/widgets/navegacao/botao_voltar_com_retorno_inicio.dart';

void main() {
  Widget envolverComTema(Widget filho) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
      home: Scaffold(
        appBar: AppBar(leading: filho),
        body: const SizedBox.expand(),
      ),
    );
  }

  group('BotaoVoltarComRetornoInicio', () {
    testWidgets(
      'toque rápido aciona aoVoltar imediatamente sem acionar aoIrParaInicio nem exibir pílula de início',
      (tester) async {
        var toquesVoltar = 0;
        var retornosInicio = 0;

        await tester.pumpWidget(
          envolverComTema(
            BotaoVoltarComRetornoInicio(
              key: const Key('btn_voltar_teste'),
              aoVoltar: () => toquesVoltar++,
              aoIrParaInicio: () => retornosInicio++,
            ),
          ),
        );

        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
        expect(find.text('Início'), findsNothing);

        await tester.tap(find.byKey(const Key('btn_voltar_teste')));
        expect(toquesVoltar, equals(1));
        expect(retornosInicio, equals(0));
        expect(find.text('Início'), findsNothing);
      },
    );

    testWidgets(
      'segurar continuamente anima anel radial, ícone de início e pílula flutuante até disparar aoIrParaInicio sem disparar aoVoltar ao soltar',
      (tester) async {
        var toquesVoltar = 0;
        var retornosInicio = 0;

        await tester.pumpWidget(
          envolverComTema(
            BotaoVoltarComRetornoInicio(
              key: const Key('btn_voltar_segurar'),
              corIcone: Colors.white,
              corDestaque: AppColors.brandColor,
              duracaoSegurar: const Duration(milliseconds: 600),
              aoVoltar: () => toquesVoltar++,
              aoIrParaInicio: () => retornosInicio++,
            ),
          ),
        );

        final centro = tester.getCenter(
          find.byKey(const Key('btn_voltar_segurar')),
        );
        final gesto = await tester.startGesture(centro);
        await tester.pump();

        // Avança além do limiar visual inicial (~120ms) para meio do progresso (300ms)
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Início'), findsOneWidget);
        expect(find.byIcon(Icons.home_rounded), findsWidgets);
        expect(
          find.descendant(
            of: find.byKey(const Key('btn_voltar_segurar')),
            matching: find.byType(CustomPaint),
          ),
          findsOneWidget,
        );
        expect(retornosInicio, equals(0));

        // Reconstrói no mesmo frame de progresso para exercitar comparação idêntica do pintor
        await tester.pump(Duration.zero);

        // Conclui os 600ms totais com o dedo ainda pressionado
        await tester.pump(const Duration(milliseconds: 320));

        expect(retornosInicio, equals(1));
        expect(toquesVoltar, equals(0));
        expect(find.text('Início'), findsNothing);

        // Soltar o dedo após já ter completado NÃO deve acionar aoVoltar
        await gesto.up();
        await tester.pumpAndSettle();

        expect(toquesVoltar, equals(0));
        expect(retornosInicio, equals(1));
      },
    );

    testWidgets(
      'soltar no meio da animação de segurar cancela suavemente e reverte ao estado inicial sem navegar',
      (tester) async {
        var toquesVoltar = 0;
        var retornosInicio = 0;

        await tester.pumpWidget(
          envolverComTema(
            BotaoVoltarComRetornoInicio(
              key: const Key('btn_voltar_cancelar_meio'),
              duracaoSegurar: const Duration(milliseconds: 600),
              aoVoltar: () => toquesVoltar++,
              aoIrParaInicio: () => retornosInicio++,
            ),
          ),
        );

        final centro = tester.getCenter(
          find.byKey(const Key('btn_voltar_cancelar_meio')),
        );
        final gesto = await tester.startGesture(centro);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 320));

        expect(find.text('Início'), findsOneWidget);

        // Solta antes de completar 100%
        await gesto.up();
        await tester.pump(const Duration(milliseconds: 80));
        await tester.pumpAndSettle();

        expect(toquesVoltar, equals(0));
        expect(retornosInicio, equals(0));
        expect(find.text('Início'), findsNothing);
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      },
    );

    testWidgets(
      'cancelamento de ponteiro (PointerCancelEvent), eventos sem pressão ativa e ações semânticas operam com segurança',
      (tester) async {
        final handleSemantica = tester.ensureSemantics();

        var toquesVoltar = 0;
        var retornosInicio = 0;

        await tester.pumpWidget(
          envolverComTema(
            BotaoVoltarComRetornoInicio(
              key: const Key('btn_voltar_semantica'),
              dica: 'Voltar página',
              aoVoltar: () => toquesVoltar++,
              aoIrParaInicio: () => retornosInicio++,
            ),
          ),
        );

        final centro = tester.getCenter(
          find.byKey(const Key('btn_voltar_semantica')),
        );
        final gesto = await tester.startGesture(centro);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 280));
        expect(find.text('Início'), findsOneWidget);

        // Cancela o gesto no meio da pressão
        await gesto.cancel();
        await tester.pumpAndSettle();

        expect(toquesVoltar, equals(0));
        expect(retornosInicio, equals(0));
        expect(find.text('Início'), findsNothing);

        // Se o gesto já concluiu o retorno ao início e depois sofre cancelamento do SO, ignora com segurança
        final gestoConcluidoDepoisCancelado = await tester.startGesture(centro);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 650));
        expect(retornosInicio, equals(1));
        await gestoConcluidoDepoisCancelado.cancel();
        await tester.pumpAndSettle();
        expect(toquesVoltar, equals(0));
        expect(retornosInicio, equals(1));

        // Ações de acessibilidade (TalkBack / VoiceOver): toque simples e toque longo
        final noSemantico = tester.getSemantics(
          find.bySemanticsLabel('Voltar página'),
