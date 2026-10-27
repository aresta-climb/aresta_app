// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/pages/perfil.dart';
import 'package:frontend/services/caderneta/repositorio_caderneta.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/view/view_models/hub_perfil_caderneta_view_model.dart';
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

  group('PerfilPage (Compatibilidade Canônica)', () {
    testWidgets('PerfilPage é instanciável e renderiza o Hub de Perfil e Caderneta', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final vm = HubPerfilCadernetaViewModel(repositorio: repositorio);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
          home: PerfilPage(viewModel: vm),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PerfilPage), findsOneWidget);
      expect(find.byType(HubPerfilCadernetaPage), findsOneWidget);
      expect(find.text('Escalador Aresta'), findsOneWidget);
      expect(find.text('Minha caderneta'), findsOneWidget);
    });
  });
}
