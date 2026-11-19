// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/interacao_via.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/widgets/via/bolha_alerta_seguranca_via.dart';

void main() {
  Widget envolverComTema(Widget filho) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
      home: Scaffold(body: filho),
    );
  }

  testWidgets('BolhasFlutuantesAlertaVia oculta quando lista vazia e renderiza bolha vermelha com emoji e contador', (tester) async {
    await tester.pumpWidget(
      envolverComTema(
        BolhasFlutuantesAlertaVia(
          alertas: const [],
          aoSelecionarAlerta: (_) {},
        ),
      ),
    );
    expect(find.byType(BolhaEmojiAlertaVia), findsNothing);

    AlertaSegurancaVia? selecionado;
    final alertaInicial = AlertaSegurancaVia.criar(
      uid: 'alertaAbelha01',
      escaladaUid: 'x8siJek3FiG3aB',
      categoria: CategoriaAlertaSeguranca.abelhasInsetos,
      detalhe: 'Colmeia na terceira costura',
      confirmacoesAtivas: 1,
    );

    await tester.pumpWidget(
      envolverComTema(
        BolhasFlutuantesAlertaVia(
          alertas: [alertaInicial],
          aoSelecionarAlerta: (alerta) => selecionado = alerta,
        ),
      ),
    );
    expect(find.text('🐝'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    final alertaAbelhas = alertaInicial.copyWith(confirmacoesAtivas: 3);

    await tester.pumpWidget(
      envolverComTema(
        BolhasFlutuantesAlertaVia(
          alertas: [alertaAbelhas],
          aoSelecionarAlerta: (alerta) => selecionado = alerta,
        ),
      ),
    );

    expect(find.text('🐝'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    await tester.tap(find.byKey(const Key('bolha_alerta_ABELHAS_INSETOS')));
    expect(selecionado?.uid, 'alertaAbelha01');
  });

}
