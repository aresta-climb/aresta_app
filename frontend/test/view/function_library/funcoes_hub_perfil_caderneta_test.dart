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

  });
}
