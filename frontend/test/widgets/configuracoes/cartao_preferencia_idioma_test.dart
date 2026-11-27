// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/idioma/tradutor_app.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/widgets/configuracoes/cartao_preferencia_idioma.dart';
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

  Widget montarCartao({ControladorIdiomaApp? controlador}) {
    return MaterialApp(
      theme: ThemeData(extensions: const [AppColors.dark]),
      home: Scaffold(
        body: SingleChildScrollView(
          child: CartaoPreferenciaIdioma(controlador: controlador),
        ),
      ),
    );
  }

  group('CartaoPreferenciaIdioma', () {
    testWidgets(
      'exibe todas as cinco bolhas de idioma usando o controlador padrão ou injetado',
      (tester) async {
        await tester.pumpWidget(montarCartao());
        expect(
          find.byKey(const Key('cartao_preferencia_idioma')),
          findsOneWidget,
        );
        expect(find.text('IDIOMA'), findsOneWidget);
        for (final idioma in IdiomaApp.values) {
          expect(
            find.byKey(Key('chip_config_idioma_${idioma.codigoIso}')),
            findsOneWidget,
          );
          expect(
            find.byKey(Key('bandeira_chip_config_${idioma.codigoIso}')),
            findsOneWidget,
          );
        }
        for (final siglaRemovida in ['PT', 'EN', 'ES', 'DE', 'NL']) {
          expect(find.text(siglaRemovida), findsNothing);
        }
      },
    );

    testWidgets(
      'atualiza título, subtítulo e seleção ativa imediatamente ao tocar em cada idioma',
      (tester) async {
        final ctrl = ControladorIdiomaApp.criarIsolado();
        await tester.pumpWidget(montarCartao(controlador: ctrl));

        await tester.tap(find.byKey(const Key('chip_config_idioma_en')));
        await tester.pumpAndSettle();
        expect(ctrl.idiomaAtual, IdiomaApp.ingles);
        expect(find.text('LANGUAGE'), findsOneWidget);

        await tester.tap(find.byKey(const Key('chip_config_idioma_es')));
        await tester.pumpAndSettle();
        expect(ctrl.idiomaAtual, IdiomaApp.espanhol);
        expect(find.text('IDIOMA'), findsOneWidget);

        await tester.tap(find.byKey(const Key('chip_config_idioma_de')));
        await tester.pumpAndSettle();
        expect(ctrl.idiomaAtual, IdiomaApp.alemao);
        expect(find.text('SPRACHE'), findsOneWidget);

        await tester.tap(find.byKey(const Key('chip_config_idioma_nl')));
        await tester.pumpAndSettle();
        expect(ctrl.idiomaAtual, IdiomaApp.holandes);
        expect(find.text('TAAL'), findsOneWidget);
      },
    );
  });
}
