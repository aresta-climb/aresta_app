// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/idioma/tradutor_app.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/widgets/idioma/botao_bolha_idioma.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ControladorIdiomaApp.instancia.restaurarPadraoEmMemoria();
  });

  tearDown(() {
    ControladorIdiomaApp.instancia.restaurarPadraoEmMemoria();
  });

  Widget montarApp(Widget filho) {
    return MaterialApp(
      theme: ThemeData(extensions: const [AppColors.dark]),
      home: Scaffold(body: Center(child: filho)),
    );
  }

  group('BotaoBolhaIdioma', () {
    testWidgets(
      'renderiza bandeira do país do idioma ativo sem abreviações textuais tanto em superfície padrão quanto sobre fundo fotográfico',
      (tester) async {
        await tester.pumpWidget(
          montarApp(const BotaoBolhaIdioma(key: Key('bolha_padrao'))),
        );
        expect(
          find.byKey(const Key('bandeira_bolha_ativa_pt')),
          findsOneWidget,
        );
        expect(find.text('PT'), findsNothing);

        final ctrl = ControladorIdiomaApp.criarIsolado(
          idiomaInicial: IdiomaApp.alemao,
        );
        await tester.pumpWidget(
          montarApp(
            BotaoBolhaIdioma(
              key: const Key('bolha_foto'),
              controlador: ctrl,
              sobreFundoFotografico: true,
            ),
          ),
        );
        expect(
          find.byKey(const Key('bandeira_bolha_ativa_de')),
          findsOneWidget,
        );
        expect(find.text('DE'), findsNothing);
      },
    );

    testWidgets(
      'abre painel flutuante com bandeiras ao tocar e aplica o idioma selecionado fechando o diálogo',
      (tester) async {
        await tester.pumpWidget(
          montarApp(
            Builder(
              builder: (context) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BotaoBolhaIdioma(key: Key('bolha_interativa')),
                  TextButton(
                    key: const Key('abrir_direto'),
                    onPressed: () => exibirSeletorBolhasIdioma(context),
                    child: const Text('Abrir'),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.tap(find.byKey(const Key('bolha_interativa')));
        await tester.pumpAndSettle();

