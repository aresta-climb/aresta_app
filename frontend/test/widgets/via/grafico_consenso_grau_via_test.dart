// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pbenum.dart';
import 'package:frontend/data/modelos/interacao_via.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/widgets/via/grafico_consenso_grau_via.dart';

void main() {
  Widget envolver(Widget filho) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
      home: Scaffold(body: SingleChildScrollView(child: filho)),
    );
  }

  testWidgets('AnelConsensoGrauVia e BarrasDistribuicaoGrauVia renderizam distribuição por grau (-2..+2) e repintam ao atualizar votos', (tester) async {
    const consensoInicial = ConsensoGrauVia(
      grauSugerido: '7b',
      totalVotos: 10,
      distribuicaoDeltas: {-1: 1, 0: 2, 1: 7},
    );

    await tester.pumpWidget(
      envolver(
        Column(
          children: [
            const AnelConsensoGrauVia(consenso: consensoInicial),
            BarrasDistribuicaoGrauVia(
              consenso: consensoInicial,
              codigoGrauOficial: GrauVia_GrauVia.BR_7A.value,
              ehBoulder: false,
            ),
          ],
        ),
      ),
    );

    expect(find.byKey(const Key('anel_consenso_grau_via')), findsOneWidget);
    expect(find.byKey(const Key('grafico_distribuicao_grau_via')), findsOneWidget);
    expect(find.text('DISTRIBUIÇÃO DE VOTOS (10)'), findsOneWidget);
    expect(find.byKey(const Key('barra_delta_grau_-2')), findsOneWidget);
    expect(find.byKey(const Key('barra_delta_grau_0')), findsOneWidget);
    expect(find.byKey(const Key('barra_delta_grau_1')), findsOneWidget);
    expect(find.text('6º (-2)'), findsOneWidget);
    expect(find.text('6ºsup (-1)'), findsOneWidget);
    expect(find.text('7a (0)'), findsOneWidget);
    expect(find.text('7b (+1)'), findsOneWidget);
    expect(find.text('7c (+2)'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);

    // Atualiza distribuição em boulder e sem grau oficial (exercita shouldRepaint do anel)
    const consensoMaisFacil = ConsensoGrauVia(
      grauSugerido: 'v3',
      totalVotos: 4,
      distribuicaoDeltas: {-1: 3, 0: 1},
    );
    await tester.pumpWidget(
      envolver(
        Column(
          children: [
            const AnelConsensoGrauVia(consenso: consensoMaisFacil),
            BarrasDistribuicaoGrauVia(
              consenso: consensoMaisFacil,
              codigoGrauOficial: GrauBoulder_GrauBoulder.V4.value,
              ehBoulder: true,
            ),
          ],
        ),
      ),
    );
    expect(find.text('v3 (-1)'), findsOneWidget);
    expect(find.text('v4 (0)'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    await tester.pumpWidget(
      envolver(
        const Column(
          children: [
            AnelConsensoGrauVia(consenso: ConsensoGrauVia.vazio()),
            BarrasDistribuicaoGrauVia(
              consenso: consensoMaisFacil,
              codigoGrauOficial: null,
              ehBoulder: false,
            ),
          ],
        ),
      ),
    );

    expect(find.text('-1'), findsOneWidget);
    expect(find.text('Justo (0)'), findsOneWidget);
    expect(find.text('+1'), findsOneWidget);
  });

  testWidgets('oculta BarrasDistribuicaoGrauVia quando sem votos e não causa overflow em 220px @ 1.5x', (tester) async {
    await tester.pumpWidget(
      envolver(
        const BarrasDistribuicaoGrauVia(
          consenso: ConsensoGrauVia.vazio(),
          codigoGrauOficial: null,
          ehBoulder: false,
        ),
      ),
    );
    expect(find.byKey(const Key('grafico_distribuicao_grau_via')), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.5),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 220,
              child: BarrasDistribuicaoGrauVia(
                consenso: const ConsensoGrauVia(
                  grauSugerido: '7a',
                  totalVotos: 5,
                  distribuicaoDeltas: {0: 5},
                ),
                codigoGrauOficial: GrauVia_GrauVia.BR_7A.value,
                ehBoulder: false,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
