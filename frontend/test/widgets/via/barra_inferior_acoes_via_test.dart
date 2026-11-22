// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/widgets/via/barra_inferior_acoes_via.dart';

void main() {
  Widget envolver(Widget filho) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
      home: Scaffold(body: filho),
    );
  }

  testWidgets(
    'BarraInferiorAcoesVia oculta quando vazia e aciona callbacks nos estados antes e após cadena',
    (tester) async {
      await tester.pumpWidget(
        envolver(
          BarraInferiorAcoesVia(
            exibirBotaoCroqui: false,
            aoAbrirCroqui: () {},
            exibirBotaoCaderneta: false,
            possuiCadena: false,
            rotuloBotaoCaderneta: '',
            aoRegistrarCadena: () {},
          ),
        ),
      );
      expect(find.byKey(const Key('btn_dock_croqui_via')), findsNothing);
      expect(find.byKey(const Key('btn_registrar_cadena')), findsNothing);

      var clicouCroqui = false;
      var clicouCadena = false;

      await tester.pumpWidget(
        envolver(
          Column(
            children: [
              BarraInferiorAcoesVia(
                exibirBotaoCroqui: true,
                aoAbrirCroqui: () => clicouCroqui = true,
                exibirBotaoCaderneta: true,
                possuiCadena: false,
                rotuloBotaoCaderneta: 'Registrar Cadena / Tentativa',
                aoRegistrarCadena: () => clicouCadena = true,
              ),
              BarraInferiorAcoesVia(
                exibirBotaoCroqui: false,
                aoAbrirCroqui: () {},
                exibirBotaoCaderneta: true,
                possuiCadena: true,
                rotuloBotaoCaderneta: 'Nova Ascensão / Tentativa',
                aoRegistrarCadena: () {},
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('btn_dock_croqui_via')));
      expect(clicouCroqui, isTrue);

      await tester.tap(find.text('Registrar Cadena / Tentativa'));
      expect(clicouCadena, isTrue);
      expect(find.text('Nova Ascensão / Tentativa'), findsOneWidget);
    },
  );
}
