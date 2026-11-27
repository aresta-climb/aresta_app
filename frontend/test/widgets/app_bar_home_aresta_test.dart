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
import 'package:frontend/services/firebase/telemetria.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/autenticacao/servico_autenticacao_fake.dart';
import '../mocks/mock_telemetria.dart';

void main() {
  setUpAll(() {
    TelemetryService.instance = MockTelemetryService();
  });

  tearDown(() {
    ServicoAutenticacaoLocal.redefinirParaTestes();
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
    'ArestaHomeAppBar renderiza marca, MicroBadgeBeta, sincronização e botão de perfil sempre ativo',
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
    'ArestaHomeAppBar aciona callbacks customizados onSync e onProfile',
    (tester) async {
      var sincronizado = false;
      var abriuPerfil = false;

      await tester.pumpWidget(
        criarAppTeste(
          child: ArestaHomeAppBar(
            onSync: () => sincronizado = true,
            onProfile: () => abriuPerfil = true,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.sync));
      await tester.pump();
      expect(sincronizado, isTrue);

      await tester.tap(find.byKey(const Key('btn_home_perfil')));
      await tester.pump();
      expect(abriuPerfil, isTrue);
    },
  );

  testWidgets(
    'ArestaHomeAppBar abre ModalBetaAberto ao tocar na marca e funciona como PreferredSizeWidget',
    (tester) async {
      await tester.pumpWidget(
        criarAppTeste(
          child: const ArestaHomeAppBar(),
          usarScaffoldAppBar: true,
        ),
      );
      await tester.pump();

      expect(find.byType(ArestaHomeAppBar), findsOneWidget);
      await tester.tap(find.text('ARESTA CLIMB'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ModalBetaAberto), findsOneWidget);
    },
  );

  testWidgets(
    'ArestaHomeAppBar roteia btn_home_perfil para LoginNode quando deslogado e para PerfilNode quando logado',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repoCaderneta = RepositorioCadernetaLocal(preferencias: prefs);
      await repoCaderneta.inicializar();
      RepositorioCadernetaLocal.instancia = repoCaderneta;
      final servicoAuth = ServicoAutenticacaoFake(
        repositorio: repoCaderneta,
      );
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

      // Deslogado -> abre LoginNode
      await tester.tap(find.byKey(const Key('btn_home_perfil')));
      await tester.pumpAndSettle();
      expect(treeController.currentNode, isA<LoginNode>());

      // Logado -> abre diretamente PerfilNode
      treeController.navigateTo(const HomeNode());
      await servicoAuth.entrarComGoogle();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_home_perfil')));
      await tester.pumpAndSettle();
      expect(treeController.currentNode, isA<PerfilNode>());
    },
  );
}
