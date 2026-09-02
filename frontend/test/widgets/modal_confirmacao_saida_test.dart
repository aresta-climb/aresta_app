// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/modal_confirmacao_saida.dart';

void main() {
  setUp(() {
    ModalConfirmacaoSaida.resetarSessaoParaTestes();
  });

  group('ModalConfirmacaoSaida', () {
    testWidgets('exibe aviso de montanha, botao de feedback e opcoes de salvar ou sair', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ModalConfirmacaoSaida.mostrar(
                    context: context,
                    nomePico: 'Gruta do Baú',
                    tamanhoFormatado: '18.4 MB',
                    onSalvar: () {},
                    onSairSemSalvar: () {},
                  );
                },
                child: const Text('Abrir Guardião'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Guardião'));
      await tester.pumpAndSettle();

      expect(find.text('SALVAR PARA A PEDRA?'), findsOneWidget);
      expect(find.byIcon(Icons.bug_report), findsOneWidget);
      expect(
        find.text(
          'Lembre-se: na rocha não há sinal de internet. Para consultar os croquis e graus de Gruta do Baú sem conexão, salve o guia offline.',
        ),
        findsOneWidget,
      );
      expect(find.text('Salvar Offline'), findsOneWidget);
      expect(find.text('Sair sem Salvar'), findsOneWidget);
    });

    testWidgets('dispara callback de salvar e fecha o modal', (tester) async {
      bool clicouSalvar = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ModalConfirmacaoSaida.mostrar(
                    context: context,
                    nomePico: 'Pedra Grande',
                    tamanhoFormatado: '12 MB',
                    onSalvar: () {
                      clicouSalvar = true;
                    },
                    onSairSemSalvar: () {},
                  );
                },
                child: const Text('Abrir Guardião'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Guardião'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Salvar Offline'));
      await tester.pumpAndSettle();

      expect(clicouSalvar, isTrue);
      expect(find.text('SALVAR PARA A PEDRA?'), findsNothing);
    });

    testWidgets('aparece apenas uma vez por sessao do app', (tester) async {
      bool saiuDireto = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ModalConfirmacaoSaida.mostrar(
                    context: context,
                    nomePico: 'Primeiro Pico',
                    tamanhoFormatado: '10 MB',
                    onSalvar: () {},
                    onSairSemSalvar: () {},
                  );
                },
                child: const Text('Primeira Saida'),
              ),
            ),
          ),
        ),
      );

      // Primeira vez na sessão: modal deve abrir normalmente
      await tester.tap(find.text('Primeira Saida'));
      await tester.pumpAndSettle();
      expect(find.text('SALVAR PARA A PEDRA?'), findsOneWidget);

      // Fecha o modal clicando em sair sem salvar
      await tester.tap(find.text('Sair sem Salvar'));
      await tester.pumpAndSettle();
      expect(find.text('SALVAR PARA A PEDRA?'), findsNothing);

      // Segunda vez na mesma sessão: NÃO deve exibir o modal e deve chamar onSairSemSalvar diretamente
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ModalConfirmacaoSaida.mostrar(
                    context: context,
                    nomePico: 'Segundo Pico',
                    tamanhoFormatado: '15 MB',
                    onSalvar: () {},
                    onSairSemSalvar: () {
                      saiuDireto = true;
                    },
                  );
                },
                child: const Text('Segunda Saida'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Segunda Saida'));
      await tester.pumpAndSettle();

      expect(find.text('SALVAR PARA A PEDRA?'), findsNothing);
      expect(saiuDireto, isTrue);
    });
  });
}
