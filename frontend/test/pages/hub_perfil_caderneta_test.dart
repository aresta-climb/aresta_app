// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/cadena.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';
import 'package:frontend/data/modelos/tipo_escalada.dart';
import 'package:frontend/pages/hub_perfil_caderneta.dart';
import 'package:frontend/pages/caderneta.dart';
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

  Widget criarHubWidget({HubPerfilCadernetaViewModel? viewModel}) {
    final vm = viewModel ?? HubPerfilCadernetaViewModel(repositorio: repositorio);

    return MaterialApp(
      theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
      home: HubPerfilCadernetaPage(viewModel: vm),
    );
  }

  group('HubPerfilCadernetaPage', () {
    testWidgets('renderiza o cabeçalho, as 4 métricas e os itens de menu', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final c1 = Cadena.criar(
        escaladaUid: 'via-1',
        dataAscensao: DateTime(2026, 9, 20),
        tipoAscensao: TipoAscensao.flash,
        tipoEscalada: TipoEscalada.guiado,
      );
      final c2 = Cadena.criar(
        escaladaUid: 'via-2',
        dataAscensao: DateTime(2026, 9, 21),
        tipoAscensao: TipoAscensao.tentativa,
        tipoEscalada: TipoEscalada.boulder,
      );
      await repositorio.salvarCadena(c1);
      await repositorio.salvarCadena(c2);

      await tester.pumpWidget(criarHubWidget());
      await tester.pumpAndSettle();

      // Cabeçalho
      expect(find.text('Escalador Aresta'), findsOneWidget);
      expect(find.text('Escalador'), findsOneWidget);
      expect(find.text('Editar perfil'), findsOneWidget);

      // 4 métricas específicas
      expect(
        find.descendant(
          of: find.byKey(const Key('card_metrica_cadenas')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
      expect(find.text('CADENAS'), findsOneWidget);

      expect(
        find.descendant(
          of: find.byKey(const Key('card_metrica_tentativas')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
      expect(find.text('TENTATIVAS'), findsOneWidget);

      expect(find.text('PICOS'), findsOneWidget);
      expect(find.text('VIAS'), findsOneWidget);

      // Itens de menu
      expect(find.text('Minha caderneta'), findsOneWidget);
      expect(find.text('Configurações'), findsOneWidget);
      expect(find.text('Dados e privacidade'), findsOneWidget);
      expect(find.text('Sair'), findsOneWidget);
    });

    testWidgets('ao tocar em Minha caderneta, navega para a CadernetaPage', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(criarHubWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('item_menu_minha_caderneta')));
      await tester.pumpAndSettle();

      expect(find.byType(CadernetaPage), findsOneWidget);
      expect(find.text('MINHA CADERNETA'), findsOneWidget);
    });

    testWidgets('ao tocar em Editar perfil, abre diálogo e permite alterar o nome', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(criarHubWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_editar_perfil_hub')));
      await tester.pumpAndSettle();

      expect(find.text('Editar Perfil'), findsOneWidget);

      final campoNome = find.byKey(const Key('campo_editar_perfil_nome'));
      await tester.enterText(campoNome, 'Fernanda Rocha');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_salvar_editar_perfil')));
      await tester.pumpAndSettle();

      expect(find.text('Fernanda Rocha'), findsOneWidget);
      expect(repositorio.obterPerfil().autorNomePublico, 'Fernanda Rocha');
    });

    testWidgets('ao tocar em Dados e privacidade, abre modal exibindo o NanoID 14c e permite copiar', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          return null;
        },
      );

      await tester.pumpWidget(criarHubWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('item_menu_dados_privacidade')));
      await tester.pumpAndSettle();

      expect(find.text('Dados e Privacidade'), findsOneWidget);
      expect(find.text(repositorio.obterPerfil().autorIdPublico), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_copiar_id_privacidade')));
      await tester.pumpAndSettle();

      expect(find.text('ID público copiado!'), findsOneWidget);
    });

    testWidgets('ao tocar em Sair, exibe diálogo de confirmação', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(criarHubWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('item_menu_sair')));
      await tester.pumpAndSettle();

      expect(find.text('Deseja realmente sair?'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Deseja realmente sair?'), findsNothing);
    });

  });
}
