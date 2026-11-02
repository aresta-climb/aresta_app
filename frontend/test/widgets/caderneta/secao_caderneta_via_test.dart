// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/data/modelos/cadena.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';
import 'package:frontend/services/caderneta/repositorio_caderneta.dart';
import 'package:frontend/services/configuracao_recursos.dart';
import 'package:frontend/services/controlador_interacoes_usuario.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/view/view_models/secao_caderneta_via_view_model.dart';
import 'package:frontend/widgets/caderneta/secao_caderneta_via.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RepositorioCadernetaLocal repositorio;
  late ControladorInteracoesUsuario controladorInteracoes;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(true);
    final prefs = await SharedPreferences.getInstance();
    repositorio = RepositorioCadernetaLocal(preferencias: prefs);
    await repositorio.inicializar();
    controladorInteracoes = ControladorInteracoesUsuario(preferencias: prefs);
    await controladorInteracoes.inicializar();
  });

  tearDown(() {
    ConfiguracaoRecursos.redefinirParaTestes();
    ControladorInteracoesUsuario.redefinirParaTestes();
  });

  group('SecaoCadernetaVia', () {
    testWidgets(
      'oculta seção quando interações de usuário estão desativadas',
      (tester) async {
        await controladorInteracoes.definirInteracoesAtivas(false);
        final escalada = Escalada()
          ..uid = 'via_oculta'
          ..viaEsportiva = (ViaEsportiva()..nome = 'Via Oculta');
        final vm = SecaoCadernetaViaViewModel(
          escalada: escalada,
          repositorio: repositorio,
          controladorInteracoes: controladorInteracoes,
        );
        addTearDown(vm.dispose);

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
            home: Scaffold(
              body: SecaoCadernetaVia(escalada: escalada, viewModel: vm),
            ),
          ),
        );

        expect(find.byKey(const Key('btn_registrar_cadena')), findsNothing);
      },
    );

    testWidgets(
      'abre modal de registro ao tocar no botão e atualiza selo após salvar cadena',
      (tester) async {
        final escalada = Escalada()
          ..uid = 'via_interativa'
          ..viaEsportiva = (ViaEsportiva()..nome = 'Fenda da Esperança');
        final vm = SecaoCadernetaViaViewModel(
          escalada: escalada,
          repositorio: repositorio,
          controladorInteracoes: controladorInteracoes,
        );
        addTearDown(vm.dispose);

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
            home: Scaffold(
              body: SecaoCadernetaVia(escalada: escalada, viewModel: vm),
            ),
          ),
        );

        expect(find.text('Registrar Cadena / Tentativa'), findsOneWidget);

        await tester.tap(find.byKey(const Key('btn_registrar_cadena')));
        await tester.pumpAndSettle();

        expect(find.text('Registrar Ascensão'), findsOneWidget);
        expect(find.text('Fenda da Esperança'), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('campo_notas_privadas')),
          'Crux no reglete',
        );
        await tester.tap(find.byKey(const Key('btn_salvar_cadena')));
        await tester.pumpAndSettle();

        expect(find.textContaining('Encadenada em'), findsOneWidget);
        expect(find.text('“Crux no reglete”'), findsOneWidget);
        expect(find.text('Nova Ascensão / Tentativa'), findsOneWidget);
      },
    );

    testWidgets(
      'renderiza estado visual de tentativa e instancia viewModel interno quando omitido',
      (tester) async {
        RepositorioCadernetaLocal.instancia = repositorio;
        ControladorInteracoesUsuario.instancia = controladorInteracoes;

        await repositorio.salvarCadena(
          Cadena.criar(
            escaladaUid: 'via_tentativa',
            dataAscensao: DateTime(2026, 8, 10),
            tipoAscensao: TipoAscensao.tentativa,
          ),
        );

        final escalada = Escalada()
          ..uid = 'via_tentativa'
          ..viaEsportiva = (ViaEsportiva()..nome = 'Via Projeto');

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
            home: Scaffold(body: SecaoCadernetaVia(escalada: escalada)),
          ),
        );

        expect(find.text('Tentativa em 10/08'), findsOneWidget);
        expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  });
}
