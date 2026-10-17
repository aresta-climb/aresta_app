// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/widgets/modal_sessao_experimental_encerrada.dart';

void main() {
  setUp(() {
    ModalSessaoExperimentalEncerrada.resetarParaTestes();
  });

  Widget criarAppDeTeste({required Widget child}) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        extensions: const [AppColors.dark],
      ),
      home: Scaffold(body: child),
    );
  }

  group('ModalSessaoExperimentalEncerrada', () {
    testWidgets(
      'renderiza título, mensagem de retorno ao catálogo oficial e botão ENTENDI',
      (tester) async {
        await tester.pumpWidget(
          criarAppDeTeste(
            child: const ModalSessaoExperimentalEncerrada(),
          ),
        );

        expect(find.text('Sessão de Prévia Encerrada'), findsOneWidget);
        expect(
          find.textContaining('restauramos automaticamente o catálogo oficial'),
          findsOneWidget,
        );
        expect(find.text('ENTENDI'), findsOneWidget);
        expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'exibir abre o diálogo modal e tocar em ENTENDI fecha o modal',
      (tester) async {
        late BuildContext savedContext;

        await tester.pumpWidget(
          criarAppDeTeste(
            child: Builder(
              builder: (context) {
                savedContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        ModalSessaoExperimentalEncerrada.exibir(savedContext);
        await tester.pumpAndSettle();

        expect(find.byType(ModalSessaoExperimentalEncerrada), findsOneWidget);
        expect(find.text('Sessão de Prévia Encerrada'), findsOneWidget);

        await tester.tap(find.text('ENTENDI'));
        await tester.pumpAndSettle();

        expect(find.byType(ModalSessaoExperimentalEncerrada), findsNothing);
      },
    );

    testWidgets(
      'exibir previne empilhamento duplicado enquanto o modal já estiver aberto',
      (tester) async {
        late BuildContext savedContext;

        await tester.pumpWidget(
          criarAppDeTeste(
            child: Builder(
              builder: (context) {
                savedContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        // Dispara duas chamadas consecutivas enquanto o primeiro modal está aberto
        final future1 = ModalSessaoExperimentalEncerrada.exibir(savedContext);
        final future2 = ModalSessaoExperimentalEncerrada.exibir(savedContext);
        await tester.pumpAndSettle();

        expect(find.byType(ModalSessaoExperimentalEncerrada), findsOneWidget);

        // Ao fechar uma única vez, nenhum modal extra deve restar na pilha
        await tester.tap(find.text('ENTENDI'));
        await tester.pumpAndSettle();

        await Future.wait([future1, future2]);
        expect(find.byType(ModalSessaoExperimentalEncerrada), findsNothing);
      },
    );

    testWidgets(
      'exibir executa callback opcional aoConfirmar antes de fechar o modal',
      (tester) async {
        late BuildContext savedContext;
        bool confirmou = false;

        await tester.pumpWidget(
          criarAppDeTeste(
            child: Builder(
              builder: (context) {
                savedContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        ModalSessaoExperimentalEncerrada.exibir(
          savedContext,
          aoConfirmar: () {
            confirmou = true;
          },
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('ENTENDI'));
        await tester.pumpAndSettle();

        expect(confirmou, isTrue);
        expect(find.byType(ModalSessaoExperimentalEncerrada), findsNothing);
      },
    );
  });
}
