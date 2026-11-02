// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/widgets/configuracoes/cartao_preferencia_caderneta.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CartaoPreferenciaCaderneta', () {
    testWidgets(
      'renderiza título, reflete mudanças reativas do ValueListenable e aciona aoAlternar',
      (tester) async {
        final interacoesNotifier = ValueNotifier<bool>(true);
        addTearDown(interacoesNotifier.dispose);

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
            home: Scaffold(
              body: CartaoPreferenciaCaderneta(
                interacoesAtivasListenable: interacoesNotifier,
                aoAlternar: (ativo) => interacoesNotifier.value = ativo,
              ),
            ),
          ),
        );

        expect(find.text('PERFIL E CADERNETA'), findsOneWidget);
        expect(
          find.text('Exibir Perfil e Caderneta nas telas'),
          findsOneWidget,
        );

        final switchFinder = find.byKey(const Key('switch_interacoes_caderneta'));
        expect(tester.widget<Switch>(switchFinder).value, isTrue);

        // Interação do usuário alterna preferência
        await tester.tap(switchFinder);
        await tester.pump();
        expect(interacoesNotifier.value, isFalse);
        expect(tester.widget<Switch>(switchFinder).value, isFalse);

        // Mudança externa no listenable reflete imediatamente na UI
        interacoesNotifier.value = true;
        await tester.pump();
        expect(tester.widget<Switch>(switchFinder).value, isTrue);
      },
    );
  });
}
