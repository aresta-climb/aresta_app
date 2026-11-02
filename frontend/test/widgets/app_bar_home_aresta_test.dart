// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/view/view_models/home_view_model.dart';
import 'package:frontend/widgets/app_bar_home_aresta.dart';
import 'package:frontend/widgets/micro_badge_beta.dart';
import 'package:frontend/widgets/modal_beta_aberto.dart';
import 'package:frontend/services/configuracao_recursos.dart';
import 'package:frontend/services/controlador_interacoes_usuario.dart';
import 'package:frontend/services/firebase/telemetria.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  tearDown(() {
    ConfiguracaoRecursos.redefinirParaTestes();
    ControladorInteracoesUsuario.redefinirParaTestes();
  });

  testWidgets(
    'ArestaHomeAppBar oculta o botão de perfil por padrão quando desabilitado',
    (tester) async {
      await tester.pumpWidget(
        criarAppTeste(
          child: const ArestaHomeAppBar(),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('btn_home_perfil')), findsNothing);
    },
  );

  testWidgets(
    'ArestaHomeAppBar aciona callback onProfile ao tocar no botão de perfil quando exibirBotaoPerfil é true',
    (tester) async {
      bool abriuPerfil = false;

      await tester.pumpWidget(
        criarAppTeste(
          child: ArestaHomeAppBar(
            exibirBotaoPerfil: true,
            onProfile: () => abriuPerfil = true,
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('btn_home_perfil')), findsOneWidget);
      await tester.tap(find.byKey(const Key('btn_home_perfil')));
      await tester.pump();

      expect(abriuPerfil, isTrue);
    },
  );

  testWidgets(
    'ArestaHomeAppBar alterna visibilidade reativamente via exibirBotaoPerfilListenable e via HomeViewModel',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(true);

      // 1. Modo exibirBotaoPerfilListenable (Dumb UI puro sem ViewModel)
      final visibilidadeNotifier = ValueNotifier<bool>(true);
      addTearDown(visibilidadeNotifier.dispose);

      await tester.pumpWidget(
        criarAppTeste(
          child: ArestaHomeAppBar(
            exibirBotaoPerfilListenable: visibilidadeNotifier,
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('btn_home_perfil')), findsOneWidget);

      visibilidadeNotifier.value = false;
      await tester.pump();
      expect(find.byKey(const Key('btn_home_perfil')), findsNothing);

      // 2. Modo HomeViewModel reativo
      final controlador = ControladorInteracoesUsuario(preferencias: prefs);
      await controlador.inicializar();
      final datasetRepo = DatasetRepository(editorDeCroqui: EditorDeCroqui());
      final syncService = SyncService(datasetRepository: datasetRepo);
      final homeVm = HomeViewModel(
        datasetRepo: datasetRepo,
        syncService: syncService,
        controladorInteracoes: controlador,
      );

      await tester.pumpWidget(
        criarAppTeste(
          child: ArestaHomeAppBar(viewModel: homeVm),
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('btn_home_perfil')), findsOneWidget);

      await controlador.definirInteracoesAtivas(false);
      await tester.pump();
      expect(find.byKey(const Key('btn_home_perfil')), findsNothing);

      await controlador.definirInteracoesAtivas(true);
      await tester.pump();
      expect(find.byKey(const Key('btn_home_perfil')), findsOneWidget);
    },
  );

  testWidgets(
    'ArestaHomeAppBar abre ModalBetaAberto ao tocar na marca',
    (tester) async {
      await tester.pumpWidget(
        criarAppTeste(
          child: const ArestaHomeAppBar(),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('ARESTA CLIMB'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ModalBetaAberto), findsOneWidget);
    },
  );

  testWidgets(
    'ArestaHomeAppBar funciona como PreferredSizeWidget em Scaffold.appBar',
    (tester) async {
      await tester.pumpWidget(
        criarAppTeste(
          child: const ArestaHomeAppBar(),
          usarScaffoldAppBar: true,
        ),
      );
      await tester.pump();

      expect(find.text('ARESTA CLIMB'), findsOneWidget);
      expect(find.byType(ArestaHomeAppBar), findsOneWidget);
    },
  );

  testWidgets(
    'ArestaHomeAppBar executa ações padrão de sincronização, perfil e configurações quando callbacks opcionais são omitidos',
    (tester) async {
      ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(true);
      ControladorInteracoesUsuario.redefinirParaTestes();

      await tester.pumpWidget(
        criarAppTeste(
          child: const ArestaHomeAppBar(exibirBotaoPerfil: true),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.sync));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pump();

      await tester.tap(find.byKey(const Key('btn_home_perfil')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );
}
