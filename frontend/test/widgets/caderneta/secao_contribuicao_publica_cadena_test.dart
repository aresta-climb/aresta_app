// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pbenum.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/widgets/caderneta/secao_contribuicao_publica_cadena.dart';

void main() {
  Widget envolver(Widget filho) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
      home: Scaffold(body: SingleChildScrollView(child: filho)),
    );
  }

  testWidgets('renderiza seletor -2..+2 com Grau Justo (0) pré-marcado e campo de comentário quando autenticado', (tester) async {
    var deltaEscolhido = 0;
    final controlador = TextEditingController();
    addTearDown(controlador.dispose);

    await tester.pumpWidget(
      envolver(
        SecaoContribuicaoPublicaAscensao(
          deltaSelecionado: 0,
          aoSelecionarDelta: (novo) => deltaEscolhido = novo,
          codigoGrauOficial: GrauVia_GrauVia.BR_7A.value,
          ehBoulder: false,
          estaAutenticado: true,
          controladorComentario: controlador,
          contadorComentarioTexto: '280/280',
          atingiuLimiteComentario: true,
          limiteCaracteresComentario: 280,
        ),
      ),
    );

    expect(find.text('CONTRIBUIÇÃO PÚBLICA'), findsOneWidget);
    expect(find.text('Justo (7a)'), findsOneWidget);
    expect(find.text('+1 (7b)'), findsOneWidget);
    expect(find.text('-1 (6ºsup)'), findsOneWidget);

    await tester.tap(find.byKey(const Key('chip_delta_grau_1')));
    expect(deltaEscolhido, 1);

    await tester.enterText(
      find.byKey(const Key('campo_comentario_publico_cadena')),
      'Costura 3 longa.',
    );
    expect(controlador.text, 'Costura 3 longa.');

    await tester.pumpWidget(
      envolver(
        SecaoContribuicaoPublicaAscensao(
          deltaSelecionado: 1,
          aoSelecionarDelta: (_) {},
          codigoGrauOficial: GrauVia_GrauVia.BR_7A.value,
          ehBoulder: false,
          estaAutenticado: true,
          controladorComentario: controlador,
          contadorComentarioTexto: '16/280',
          atingiuLimiteComentario: false,
          limiteCaracteresComentario: 280,
        ),
      ),
    );
    expect(find.text('16/280'), findsOneWidget);
  });

  testWidgets('exibe aviso informativo sem campo de comentário público quando não autenticado e não estoura em 320x568 @ 1.5x', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controlador = TextEditingController();
    addTearDown(controlador.dispose);

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
            padding: const EdgeInsets.all(16),
            child: SecaoContribuicaoPublicaAscensao(
              deltaSelecionado: 0,
              aoSelecionarDelta: (_) {},
              codigoGrauOficial: GrauVia_GrauVia.BR_7A.value,
              ehBoulder: false,
              estaAutenticado: false,
              controladorComentario: controlador,
              contadorComentarioTexto: '280/280',
              atingiuLimiteComentario: true,
              limiteCaracteresComentario: 280,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('campo_comentario_publico_cadena')), findsNothing);
    expect(find.textContaining('Conecte sua conta'), findsOneWidget);
  });
}
