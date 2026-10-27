// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/view/function_library/funcoes_hub_perfil_caderneta.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithTheme(Widget child) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        extensions: const [AppColors.dark],
      ),
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('funcoes_hub_perfil_caderneta', () {
    testWidgets('buildCabecalhoHubPerfil renderiza nome, função, avatar e aciona editar perfil', (tester) async {
      var editou = false;

      await tester.pumpWidget(
        wrapWithTheme(
          buildCabecalhoHubPerfil(
            nome: 'Fernanda Rocha',
            funcao: 'Escaladora',
            onEditarPerfil: () => editou = true,
          ),
        ),
      );

      expect(find.text('Fernanda Rocha'), findsOneWidget);
      expect(find.text('Escaladora'), findsOneWidget);
      expect(find.text('Editar perfil'), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_editar_perfil_hub')));
      await tester.pump();

      expect(editou, isTrue);
    });

    testWidgets('buildBarraMetricasHub renderiza 4 cartões com valores e rótulos corretos', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          buildBarraMetricasHub(
            totalCadenas: 3,
            totalTentativas: 1,
            totalPicos: 18,
            totalVias: 64,
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);
      expect(find.text('CADENAS'), findsOneWidget);

      expect(find.text('1'), findsOneWidget);
      expect(find.text('TENTATIVAS'), findsOneWidget);

      expect(find.text('18'), findsOneWidget);
      expect(find.text('PICOS'), findsOneWidget);

      expect(find.text('64'), findsOneWidget);
      expect(find.text('VIAS'), findsOneWidget);
    });

    testWidgets('buildBarraMetricasHub mantém os 4 cartões com a mesma altura e escala em telas estreitas', (tester) async {
      tester.view.physicalSize = const Size(360, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        wrapWithTheme(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: buildBarraMetricasHub(
              totalCadenas: 3,
              totalTentativas: 1,
              totalPicos: 18,
              totalVias: 64,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final boxCadenas = tester.getRect(find.byKey(const Key('card_metrica_cadenas')));
      final boxTentativas = tester.getRect(find.byKey(const Key('card_metrica_tentativas')));
      final boxPicos = tester.getRect(find.byKey(const Key('card_metrica_picos')));
      final boxVias = tester.getRect(find.byKey(const Key('card_metrica_vias')));

      // Todos os 4 cartões devem manter estritamente a mesma altura
      expect(boxTentativas.height, equals(boxCadenas.height));
      expect(boxPicos.height, equals(boxCadenas.height));
      expect(boxVias.height, equals(boxCadenas.height));

      // Todos os 4 cartões devem ter larguras proporcionais / homogêneas
      expect((boxTentativas.width - boxCadenas.width).abs(), lessThanOrEqualTo(1.0));
      expect((boxPicos.width - boxCadenas.width).abs(), lessThanOrEqualTo(1.0));
      expect((boxVias.width - boxCadenas.width).abs(), lessThanOrEqualTo(1.0));

      expect(tester.takeException(), isNull);
    });


    testWidgets('buildMenuOpcoesHub renderiza itens e aciona callbacks de navegação', (tester) async {
      var abriuCaderneta = false;
      var abriuConfiguracoes = false;
      var abriuDados = false;
      var confirmouSaida = false;

      await tester.pumpWidget(
        wrapWithTheme(
          buildMenuOpcoesHub(
            onAbrirCaderneta: () => abriuCaderneta = true,
            onAbrirConfiguracoes: () => abriuConfiguracoes = true,
            onAbrirDadosPrivacidade: () => abriuDados = true,
            onConfirmarSaida: () => confirmouSaida = true,
          ),
        ),
      );

      expect(find.text('Minha caderneta'), findsOneWidget);
      expect(find.text('Configurações'), findsOneWidget);
      expect(find.text('Dados e privacidade'), findsOneWidget);
      expect(find.text('Sair'), findsOneWidget);

      await tester.tap(find.byKey(const Key('item_menu_minha_caderneta')));
      await tester.pump();
      expect(abriuCaderneta, isTrue);

      await tester.tap(find.byKey(const Key('item_menu_configuracoes')));
      await tester.pump();
      expect(abriuConfiguracoes, isTrue);

      await tester.tap(find.byKey(const Key('item_menu_dados_privacidade')));
      await tester.pump();
      expect(abriuDados, isTrue);

      await tester.tap(find.byKey(const Key('item_menu_sair')));
      await tester.pump();
      expect(confirmouSaida, isTrue);
    });

    testWidgets('exibirDialogoEditarPerfil permite preencher e salvar novo nome', (tester) async {
      String? resultado;

      await tester.pumpWidget(
        wrapWithTheme(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  resultado = await exibirDialogoEditarPerfil(
                    context,
                    nomeAtual: 'Fernanda Rocha',
                  );
                },
                child: const Text('Abrir'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Editar Perfil'), findsOneWidget);

      final campoFinder = find.byKey(const Key('campo_editar_perfil_nome'));
      expect(campoFinder, findsOneWidget);

      await tester.enterText(campoFinder, 'Roberta Rocha');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_salvar_editar_perfil')));
      await tester.pumpAndSettle();

      expect(resultado, 'Roberta Rocha');
    });

    testWidgets('exibirModalDadosPrivacidade exibe autorIdPublico e aciona cópia', (tester) async {
      var copiou = false;

      await tester.pumpWidget(
        wrapWithTheme(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  exibirModalDadosPrivacidade(
                    context,
                    autorIdPublico: 'abc123xyz78901',
                    onCopiarId: () => copiou = true,
                  );
                },
                child: const Text('Abrir'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Dados e Privacidade'), findsOneWidget);
      expect(find.textContaining('abc123xyz78901'), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_copiar_id_privacidade')));
      await tester.pumpAndSettle();

      expect(copiou, isTrue);
    });

  });
}
