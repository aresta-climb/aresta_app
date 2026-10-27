// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/cadena.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';
import 'package:frontend/data/modelos/tipo_escalada.dart';
import 'package:frontend/pages/caderneta.dart';
import 'package:frontend/services/caderneta/repositorio_caderneta.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/view/view_models/perfil_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RepositorioCadernetaLocal repositorio;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repositorio = RepositorioCadernetaLocal(preferencias: prefs);
    await repositorio.inicializar();
  });

  Widget criarCadernetaWidget({PerfilViewModel? viewModel}) {
    final vm =
        viewModel ??
        PerfilViewModel(
          repositorio: repositorio,
          obterGrauDaVia: (uid) => uid == 'via-1' ? '7a' : 'V4',
          obterNomeDaVia: (uid) =>
              uid == 'via-1' ? 'Fenda do Crepúsculo' : 'Bloco Lunar',
        );

    return MaterialApp(
      theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
      home: CadernetaPage(viewModel: vm),
    );
  }

  group('CadernetaPage', () {
    testWidgets('renderiza pirâmide de graus e estado vazio quando não há cadenas', (tester) async {
      await tester.pumpWidget(criarCadernetaWidget());
      await tester.pumpAndSettle();

      expect(find.text('MINHA CADERNETA'), findsOneWidget);
      expect(find.text('Pirâmide de Graduação'), findsOneWidget);
      expect(
        find.text('Nenhuma ascensão registrada nesta modalidade.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Nenhuma ascensão registrada ainda'),
        findsOneWidget,
      );
    });

  });
}
