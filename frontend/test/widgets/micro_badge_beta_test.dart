// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/widgets/micro_badge_beta.dart';

void main() {
  Widget criarAppTeste({
    required Widget child,
    double largura = 360,
    double altura = 800,
  }) {
    return MaterialApp(
      home: Theme(
        data: ThemeData(
          extensions: const [AppColors.dark],
        ),
        child: MediaQuery(
          data: MediaQueryData(
            size: Size(largura, altura),
          ),
          child: Scaffold(
            body: child,
          ),
        ),
      ),
    );
  }

  testWidgets('MicroBadgeBeta renderiza texto BETA com dimensões compactas', (tester) async {
    await tester.pumpWidget(
      criarAppTeste(
        child: const Center(
          child: MicroBadgeBeta(),
        ),
      ),
    );

    expect(find.text('BETA'), findsOneWidget);

    final tamanhoBadge = tester.getSize(find.byType(MicroBadgeBeta));
    expect(tamanhoBadge.width, lessThan(130.0));
    expect(tamanhoBadge.height, lessThan(45.0));
  });

  testWidgets('Aciona callback ao receber toque', (tester) async {
    bool clicado = false;

    await tester.pumpWidget(
      criarAppTeste(
        child: Center(
          child: MicroBadgeBeta(
            aoTocar: () {
              clicado = true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(MicroBadgeBeta));
    await tester.pumpAndSettle();

    expect(clicado, isTrue);
  });

  testWidgets('Abre ModalBetaAberto ao ser tocado sem callback customizado', (tester) async {
    await tester.pumpWidget(
      criarAppTeste(
        child: const Center(
          child: MicroBadgeBeta(),
        ),
      ),
    );

    await tester.tap(find.byType(MicroBadgeBeta));
    await tester.pumpAndSettle();

    expect(find.text('Fase Beta Aberta'), findsOneWidget);
  });

  testWidgets('Aplica corTexto customizada quando fornecida', (tester) async {
    const corCustomizada = Color(0xFF00FF00);

    await tester.pumpWidget(
      criarAppTeste(
        child: const Center(
          child: MicroBadgeBeta(corTexto: corCustomizada),
        ),
      ),
    );

    final widgetTexto = tester.widget<Text>(find.text('BETA'));
    expect(widgetTexto.style?.color, equals(corCustomizada));
    expect(widgetTexto.style?.fontSize, equals(8.0));
  });

  testWidgets('Aplica tamanhoFonte customizado quando fornecido', (tester) async {
    await tester.pumpWidget(
      criarAppTeste(
        child: const Center(
          child: MicroBadgeBeta(tamanhoFonte: 10.5),
        ),
      ),
    );

    final widgetTexto = tester.widget<Text>(find.text('BETA'));
    expect(widgetTexto.style?.fontSize, equals(10.5));
  });

  testWidgets('Não causa overflow em tela estreita de 320dp com container protetivo', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      criarAppTeste(
        largura: 320,
        altura: 640,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 28, height: 28, color: Colors.red),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        color: Colors.grey,
                        child: const Text('ARESTA', style: TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(width: 6),
                      const MicroBadgeBeta(),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.sync), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.chat), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(MicroBadgeBeta), findsOneWidget);
  });
}
