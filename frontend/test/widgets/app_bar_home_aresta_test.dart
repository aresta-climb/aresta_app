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
    'ArestaHomeAppBar renderiza elementos da marca, sincronização e perfil sem botão de configurações',
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
    'ArestaHomeAppBar oculta o botão de perfil quando exibirBotaoPerfil é false',
    (tester) async {
      await tester.pumpWidget(
        criarAppTeste(
          child: const ArestaHomeAppBar(exibirBotaoPerfil: false),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('btn_home_perfil')), findsNothing);
    },
  );

  testWidgets(
    'ArestaHomeAppBar aciona callback onProfile ao tocar no botão de perfil',
    (tester) async {
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
    'ArestaHomeAppBar alterna visibilidade reativamente via exibirBotaoPerfilListenable',
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

      visibilidadeNotifier.value = false;
      await tester.pump();
      expect(find.byKey(const Key('btn_home_perfil')), findsNothing);

      visibilidadeNotifier.value = true;
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
    'ArestaHomeAppBar executa sincronização padrão e roteia botão de perfil para LoginNode (deslogado) ou PerfilNode (logado)',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repoCaderneta = RepositorioCadernetaLocal(preferencias: prefs);
      await repoCaderneta.inicializar();
      RepositorioCadernetaLocal.instancia = repoCaderneta;
      final servicoAuth = ServicoAutenticacaoLocal(repositorio: repoCaderneta);
      ServicoAutenticacaoLocal.instancia = servicoAuth;

      final datasetRepo = DatasetRepository(editorDeCroqui: EditorDeCroqui());
      final syncService = SyncService(datasetRepository: datasetRepo);
      final treeController = TreeNavigationController();

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
