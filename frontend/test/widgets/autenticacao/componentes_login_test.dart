// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/widgets/autenticacao/componentes_login.dart';

void main() {
  Widget envolverComTema(Widget filho) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
      home: Scaffold(body: SingleChildScrollView(child: filho)),
    );
  }

  group('Componentes declarativos da tela de Login (Dumb UI)', () {
    testWidgets('BarraTopoLogin, CabecalhoTelaLogin, DivisorSecaoLogin e BotaoContinuarSemContaLogin renderizam e acionam callbacks', (tester) async {
      var voltou = false;
      var continuouOffline = false;

      await tester.pumpWidget(
        envolverComTema(
          Column(
            children: [
              BarraTopoLogin(aoVoltar: () => voltou = true),
              const CabecalhoTelaLogin(
                titulo: 'Entrar na sua conta',
                subtitulo: 'Subtítulo de teste',
              ),
              const DivisorSecaoLogin(texto: 'ou use seu e-mail'),
              BotaoContinuarSemContaLogin(
                aoPressionar: () => continuouOffline = true,
              ),
            ],
          ),
        ),
      );

      expect(find.text('ARESTA CLIMB'), findsOneWidget);
      expect(find.text('Entrar na sua conta'), findsOneWidget);
      expect(find.text('Subtítulo de teste'), findsOneWidget);
      expect(find.text('ou use seu e-mail'), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_voltar_login')));
      expect(voltou, isTrue);

      await tester.tap(find.byKey(const Key('btn_continuar_sem_conta')));
      expect(continuouOffline, isTrue);
    });

    testWidgets('BotaoProvedorOAuthLogin renderiza distintivo, rótulo e dispara callback quando habilitado', (tester) async {
      var acionado = 0;

      await tester.pumpWidget(
        envolverComTema(
          BotaoProvedorOAuthLogin(
            key: const Key('btn_oauth_teste'),
            rotulo: 'Continuar com Provedor',
            distintivo: const Text('P'),
            aoPressionar: () => acionado++,
          ),
        ),
      );

      expect(find.text('Continuar com Provedor'), findsOneWidget);
      expect(find.text('P'), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_oauth_teste')));
      expect(acionado, equals(1));
    });
  });
}
