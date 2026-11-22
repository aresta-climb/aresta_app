// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/view/view_models/registro_cadena_view_model.dart';
import 'package:frontend/widgets/caderneta/secao_contribuicao_publica_cadena.dart';

void main() {
  const opcoesPadrao = <OpcaoDeltaGrauApresentacao>[
    OpcaoDeltaGrauApresentacao(delta: -2, rotulo: '-2 (6º)', selecionado: false),
    OpcaoDeltaGrauApresentacao(delta: -1, rotulo: '-1 (6ºsup)', selecionado: false),
    OpcaoDeltaGrauApresentacao(delta: 0, rotulo: 'Justo (7a)', selecionado: true),
    OpcaoDeltaGrauApresentacao(delta: 1, rotulo: '+1 (7b)', selecionado: false),
    OpcaoDeltaGrauApresentacao(delta: 2, rotulo: '+2 (7c)', selecionado: false),
  ];

  Widget envolver(Widget filho) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
      home: Scaffold(body: SingleChildScrollView(child: filho)),
    );
  }

  testWidgets('renderiza chips pré-formatados de percepção de grau e campo de comentário quando autenticado', (tester) async {
    var deltaEscolhido = 0;
    final controlador = TextEditingController();
    addTearDown(controlador.dispose);

    await tester.pumpWidget(
      envolver(
        SecaoContribuicaoPublicaAscensao(
          opcoesDelta: opcoesPadrao,
          aoSelecionarDelta: (novo) => deltaEscolhido = novo,
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
          opcoesDelta: const [
            OpcaoDeltaGrauApresentacao(
              delta: 1,
              rotulo: '+1 (7b)',
              selecionado: true,
            ),
          ],
          aoSelecionarDelta: (_) {},
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
              opcoesDelta: opcoesPadrao,
              aoSelecionarDelta: (_) {},
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
