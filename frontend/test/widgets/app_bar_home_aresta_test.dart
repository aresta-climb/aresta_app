// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/widgets/app_bar_home_aresta.dart';
import 'package:frontend/widgets/micro_badge_beta.dart';
import 'package:frontend/widgets/modal_beta_aberto.dart';
import 'package:frontend/services/firebase/telemetria.dart';
import '../mocks/mock_telemetria.dart';

void main() {
  setUpAll(() {
    TelemetryService.instance = MockTelemetryService();
  });

  Widget criarAppTeste({
    required Widget child,
    bool usarScaffoldAppBar = false,
  }) {
    return MaterialApp(
      theme: ThemeData(
        extensions: const [AppColors.dark],
      ),
      home: usarScaffoldAppBar
          ? Scaffold(appBar: child as PreferredSizeWidget)
          : Scaffold(body: SafeArea(child: child)),
    );
  }

  testWidgets(
    'ArestaHomeAppBar renderiza elementos da marca e ações principais',
    (tester) async {
      await tester.pumpWidget(
        criarAppTeste(
          child: const ArestaHomeAppBar(),
        ),
      );
      await tester.pump();

      expect(find.text('ARESTA CLIMB'), findsOneWidget);
      expect(find.byType(MicroBadgeBeta), findsOneWidget);
      expect(find.byIcon(Icons.sync), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);

      const appBar = ArestaHomeAppBar();
      expect(appBar.preferredSize.height, greaterThan(0));
    },
  );

  testWidgets(
    'ArestaHomeAppBar aciona callback onSync ao tocar no botão de sincronização',
    (tester) async {
      bool sincronizado = false;

      await tester.pumpWidget(
        criarAppTeste(
          child: ArestaHomeAppBar(
            onSync: () => sincronizado = true,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.sync));
      await tester.pump();

      expect(sincronizado, isTrue);
    },
  );

  testWidgets(
    'ArestaHomeAppBar aciona callback onSettings ao tocar no botão de configurações',
    (tester) async {
      bool abriuConfiguracoes = false;

      await tester.pumpWidget(
        criarAppTeste(
          child: ArestaHomeAppBar(
            onSettings: () => abriuConfiguracoes = true,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pump();

      expect(abriuConfiguracoes, isTrue);
    },
  );
}
