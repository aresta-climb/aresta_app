// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/navigation/arvore_navegacao.dart';
import 'package:frontend/navigation/wrapper_navegacao_arvore.dart';
import 'package:frontend/services/autenticacao/servico_autenticacao.dart';
import 'package:frontend/services/caderneta/repositorio_caderneta.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/theme/cores_app.dart';
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
    'ArestaHomeAppBar renderiza botão de configurações por padrão quando perfilHabilitado é false e alterna para botão de perfil quando habilitado',
    (tester) async {
      ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(false);
      ControladorInteracoesUsuario.redefinirParaTestes();

      await tester.pumpWidget(
        criarAppTeste(
          child: const ArestaHomeAppBar(),
        ),
      );
      await tester.pump();

      expect(find.text('ARESTA CLIMB'), findsOneWidget);
      expect(find.byType(MicroBadgeBeta), findsOneWidget);
      expect(find.byIcon(Icons.sync), findsOneWidget);
      expect(find.byKey(const Key('btn_home_perfil')), findsNothing);
      expect(find.byIcon(Icons.settings), findsOneWidget);

      ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(true);
      await tester.pumpWidget(
        criarAppTeste(
          child: const ArestaHomeAppBar(),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('btn_home_perfil')), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsNothing);

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

  tearDown(() {
    ConfiguracaoRecursos.redefinirParaTestes();
    ControladorInteracoesUsuario.redefinirParaTestes();
    ServicoAutenticacaoLocal.redefinirParaTestes();
  });

  testWidgets(
    'ArestaHomeAppBar exibe botão de configurações quando exibirBotaoPerfil é false e botão de perfil quando exibirBotaoPerfil é true',
    (tester) async {
      bool abriuConfiguracoes = false;
      await tester.pumpWidget(
        criarAppTeste(
          child: ArestaHomeAppBar(
            exibirBotaoPerfil: false,
            onSettings: () => abriuConfiguracoes = true,
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('btn_home_perfil')), findsNothing);
      expect(find.byIcon(Icons.settings), findsOneWidget);

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pump();
      expect(abriuConfiguracoes, isTrue);

      await tester.pumpWidget(
        criarAppTeste(
          child: const ArestaHomeAppBar(exibirBotaoPerfil: true),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('btn_home_perfil')), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsNothing);
    },
  );

  testWidgets(
    'ArestaHomeAppBar aciona callback onProfile ao tocar no botão de perfil',
    (tester) async {
      ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(true);
      ControladorInteracoesUsuario.redefinirParaTestes();
      bool abriuPerfil = false;

      await tester.pumpWidget(
        criarAppTeste(
          child: ArestaHomeAppBar(
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
    'ArestaHomeAppBar alterna visibilidade reativamente entre perfil e configurações via exibirBotaoPerfilListenable',
    (tester) async {
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
      expect(find.byIcon(Icons.settings), findsNothing);

      visibilidadeNotifier.value = false;
      await tester.pump();
      expect(find.byKey(const Key('btn_home_perfil')), findsNothing);
      expect(find.byIcon(Icons.settings), findsOneWidget);

      visibilidadeNotifier.value = true;
      await tester.pump();
      expect(find.byKey(const Key('btn_home_perfil')), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsNothing);
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
    'ArestaHomeAppBar executa sincronização padrão, roteia para SettingsNode quando perfilHabilitado é false e para LoginNode/PerfilNode quando habilitado',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repoCaderneta = RepositorioCadernetaLocal(preferencias: prefs);
      await repoCaderneta.inicializar();
      RepositorioCadernetaLocal.instancia = repoCaderneta;
      final servicoAuth = ServicoAutenticacaoLocal(
        repositorio: repoCaderneta,
        obterAnonKeySupabase: () => '',
      );
      ServicoAutenticacaoLocal.instancia = servicoAuth;

      final datasetRepo = DatasetRepository(editorDeCroqui: EditorDeCroqui());
      final syncService = SyncService(datasetRepository: datasetRepo);
      final treeController = TreeNavigationController();

      ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(false);
      ControladorInteracoesUsuario.redefinirParaTestes();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
          home: TreeNavigationWrapper(
            key: TreeNavigationWrapper.navKey,
            datasetRepo: datasetRepo,
            syncService: syncService,
            treeController: treeController,
            child: const Scaffold(
              body: SafeArea(child: ArestaHomeAppBar()),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.sync));
      await tester.pump();

      // Com perfilHabilitado = false -> tocar em Icons.settings abre SettingsNode
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      expect(treeController.currentNode, isA<SettingsNode>());

      // Agora com perfilHabilitado = true
      treeController.navigateTo(const HomeNode());
      ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(true);
      await ControladorInteracoesUsuario.instancia.definirInteracoesAtivas(
        false,
      );
      await ControladorInteracoesUsuario.instancia.definirInteracoesAtivas(
        true,
      );
      await tester.pumpAndSettle();

      // Deslogado -> tocar em btn_home_perfil abre LoginNode
      await tester.tap(find.byKey(const Key('btn_home_perfil')));
      await tester.pumpAndSettle();
      expect(treeController.currentNode, isA<LoginNode>());

      // Logado -> tocar em btn_home_perfil abre diretamente PerfilNode
      treeController.navigateTo(const HomeNode());
      await servicoAuth.entrarComGoogle();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_home_perfil')));
      await tester.pumpAndSettle();
      expect(treeController.currentNode, isA<PerfilNode>());
    },
  );
}
