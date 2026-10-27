// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/view/function_library/funcoes_hub_perfil_caderneta.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithTheme(Widget child) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        extensions: const [AppColors.dark],
      ),
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('funcoes_hub_perfil_caderneta', () {
    testWidgets('buildCabecalhoHubPerfil renderiza nome, função, avatar e aciona editar perfil', (tester) async {
      var editou = false;

      await tester.pumpWidget(
        wrapWithTheme(
          buildCabecalhoHubPerfil(
            nome: 'Fernanda Rocha',
            funcao: 'Escaladora',
            onEditarPerfil: () => editou = true,
          ),
        ),
      );

      expect(find.text('Fernanda Rocha'), findsOneWidget);
      expect(find.text('Escaladora'), findsOneWidget);
      expect(find.text('Editar perfil'), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_editar_perfil_hub')));
      await tester.pump();

      expect(editou, isTrue);
    });

    testWidgets('buildBarraMetricasHub renderiza 4 cartões com valores e rótulos corretos', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          buildBarraMetricasHub(
            totalCadenas: 3,
            totalTentativas: 1,
            totalPicos: 18,
            totalVias: 64,
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);
      expect(find.text('CADENAS'), findsOneWidget);

      expect(find.text('1'), findsOneWidget);
      expect(find.text('TENTATIVAS'), findsOneWidget);

      expect(find.text('18'), findsOneWidget);
      expect(find.text('PICOS'), findsOneWidget);

      expect(find.text('64'), findsOneWidget);
      expect(find.text('VIAS'), findsOneWidget);
    });

    testWidgets('buildBarraMetricasHub mantém os 4 cartões com a mesma altura e escala em telas estreitas', (tester) async {
      tester.view.physicalSize = const Size(360, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        wrapWithTheme(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: buildBarraMetricasHub(
              totalCadenas: 3,
              totalTentativas: 1,
              totalPicos: 18,
              totalVias: 64,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final boxCadenas = tester.getRect(find.byKey(const Key('card_metrica_cadenas')));
      final boxTentativas = tester.getRect(find.byKey(const Key('card_metrica_tentativas')));
      final boxPicos = tester.getRect(find.byKey(const Key('card_metrica_picos')));
      final boxVias = tester.getRect(find.byKey(const Key('card_metrica_vias')));

      // Todos os 4 cartões devem manter estritamente a mesma altura
      expect(boxTentativas.height, equals(boxCadenas.height));
      expect(boxPicos.height, equals(boxCadenas.height));
      expect(boxVias.height, equals(boxCadenas.height));

      // Todos os 4 cartões devem ter larguras proporcionais / homogêneas
      expect((boxTentativas.width - boxCadenas.width).abs(), lessThanOrEqualTo(1.0));
      expect((boxPicos.width - boxCadenas.width).abs(), lessThanOrEqualTo(1.0));
      expect((boxVias.width - boxCadenas.width).abs(), lessThanOrEqualTo(1.0));

      expect(tester.takeException(), isNull);
    });

  });
}
