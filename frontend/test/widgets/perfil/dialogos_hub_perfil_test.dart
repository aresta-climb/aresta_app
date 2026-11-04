// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/widgets/perfil/dialogos_hub_perfil.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget envolverComTema(Widget filho) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
      home: Scaffold(body: filho),
    );
  }

  group('exibirDialogoEditarPerfil', () {
    testWidgets(
      'pré-preenche nome atual, permite alterar foto e retorna novo nome normalizado ao salvar',
      (tester) async {
        String? resultado;
        var selecionouFoto = false;

        await tester.pumpWidget(
          envolverComTema(
            Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  resultado = await exibirDialogoEditarPerfil(
                    context,
                    nomeAtual: 'Fernanda Rocha',
                    aoSelecionarNovaFoto: () async {
                      selecionouFoto = true;
                      return 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
                    },
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();

        expect(find.text('Editar Perfil'), findsOneWidget);
        final campoFinder = find.byKey(const Key('campo_editar_perfil_nome'));
        expect(tester.widget<TextField>(campoFinder).controller?.text, 'Fernanda Rocha');

        await tester.tap(find.byKey(const Key('btn_alterar_foto_dialogo')));
        await tester.pumpAndSettle();
        expect(selecionouFoto, isTrue);

        await tester.enterText(campoFinder, '  Roberta Rocha  ');
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('btn_salvar_editar_perfil')));
        await tester.pumpAndSettle();

        expect(resultado, equals('Roberta Rocha'));
      },
    );

    testWidgets(
      'retorna null ao tentar salvar nome em branco ou ao cancelar o diálogo',
      (tester) async {
        String? resultado = 'inicial';

        await tester.pumpWidget(
          envolverComTema(
            Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  resultado = await exibirDialogoEditarPerfil(
                    context,
                    nomeAtual: 'Fernanda Rocha',
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        );

        // Caso 1: Salvar com espaços em branco retorna null
        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('campo_editar_perfil_nome')),
          '   ',
        );
        await tester.tap(find.byKey(const Key('btn_salvar_editar_perfil')));
        await tester.pumpAndSettle();
        expect(resultado, isNull);

        // Caso 2: Cancelar retorna null sem exceções de controlador descartado
        resultado = 'inicial';
        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
        expect(resultado, isNull);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('exibirModalDadosPrivacidade', () {
    testWidgets(
      'exibe identificador NanoID público e aciona aoCopiarId fechando o modal',
      (tester) async {
        var copiou = false;

        await tester.pumpWidget(
          envolverComTema(
            Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  exibirModalDadosPrivacidade(
                    context,
                    autorIdPublico: 'abc123xyz78901',
                    aoCopiarId: () => copiou = true,
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();

        expect(find.text('Dados e Privacidade'), findsOneWidget);
        expect(find.text('abc123xyz78901'), findsOneWidget);

        await tester.tap(find.byKey(const Key('btn_copiar_id_privacidade')));
        await tester.pumpAndSettle();

        expect(copiou, isTrue);
        expect(find.text('Dados e Privacidade'), findsNothing);
      },
    );
  });

  group('exibirDialogoConfirmarSaida', () {
    testWidgets(
      'retorna false ao cancelar e true ao confirmar saída',
      (tester) async {
        bool? confirmou;

        await tester.pumpWidget(
          envolverComTema(
            Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  confirmou = await exibirDialogoConfirmarSaida(context);
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();
        expect(find.text('Deseja realmente sair?'), findsOneWidget);

        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
        expect(confirmou, isFalse);

        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('btn_confirmar_saida')));
        await tester.pumpAndSettle();
        expect(confirmou, isTrue);
      },
    );
  });
}
