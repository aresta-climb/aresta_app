// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/navigation/arvore_navegacao.dart';
import 'package:frontend/navigation/wrapper_navegacao_arvore.dart';
import 'package:frontend/pages/login.dart';
import 'package:frontend/services/autenticacao/servico_autenticacao.dart';
import 'package:frontend/services/caderneta/repositorio_caderneta.dart';
import 'package:frontend/services/configuracao_recursos.dart';
import 'package:frontend/services/controlador_interacoes_usuario.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/view/view_models/login_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/autenticacao/servico_autenticacao_fake.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RepositorioCadernetaLocal repositorio;
  late ServicoAutenticacaoFake servicoFake;

  setUp(() async {
    ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(true);
    ControladorInteracoesUsuario.redefinirParaTestes();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repositorio = RepositorioCadernetaLocal(preferencias: prefs);
    await repositorio.inicializar();
    RepositorioCadernetaLocal.instancia = repositorio;
    servicoFake = ServicoAutenticacaoFake(repositorio: repositorio);
    ServicoAutenticacaoLocal.instancia = servicoFake;
  });

  tearDown(() {
    ConfiguracaoRecursos.redefinirParaTestes();
    ControladorInteracoesUsuario.redefinirParaTestes();
    ServicoAutenticacaoLocal.redefinirParaTestes();
  });

  Widget criarLoginWidget({
    LoginViewModel? viewModel,
    LoginViewModel Function()? construtorViewModel,
    TargetPlatform plataforma = TargetPlatform.android,
  }) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        platform: plataforma,
        extensions: const [AppColors.dark],
      ),
      home: LoginPage(
        viewModel: viewModel,
        construtorViewModel: construtorViewModel,
      ),
    );
  }

  group('LoginPage (Sem Senha e Por Plataforma)', () {
    testWidgets('no Android exibe Google, código OTP por e-mail e modo offline, ocultando o botão da Apple e qualquer campo de senha', (tester) async {
      await tester.pumpWidget(
        criarLoginWidget(
          plataforma: TargetPlatform.android,
          viewModel: LoginViewModel(servicoAutenticacao: servicoFake),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Entrar na sua conta'), findsOneWidget);
      expect(find.byKey(const Key('btn_login_google')), findsOneWidget);
      expect(find.byKey(const Key('btn_login_apple')), findsNothing);
      expect(find.byKey(const Key('campo_login_email')), findsOneWidget);
      expect(find.textContaining('Senha'), findsNothing);
      expect(find.text('Continuar sem conta / Offline'), findsOneWidget);
    });

    testWidgets('no iOS exibe tanto Continuar com o Google quanto Continuar com a Apple e não exibe alerta quando cancelado', (tester) async {
      servicoFake.cancelarProximoLoginSocial = true;
      final vm = LoginViewModel(servicoAutenticacao: servicoFake);

      await tester.pumpWidget(
        criarLoginWidget(
          plataforma: TargetPlatform.iOS,
          viewModel: vm,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_login_google')), findsOneWidget);
      expect(find.byKey(const Key('btn_login_apple')), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_login_apple')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('banner_erro_login')), findsNothing);
    });

    testWidgets('realiza fluxo completo de Magic Code OTP de 6 dígitos por e-mail e exibe erros globais no BannerAvisoLogin', (tester) async {
      var autenticadoCallback = false;
      final vm = LoginViewModel(
        servicoAutenticacao: servicoFake,
        aoAutenticarComSucesso: () => autenticadoCallback = true,
      );

      await tester.pumpWidget(criarLoginWidget(viewModel: vm));
      await tester.pumpAndSettle();

      // 1. Submissão com e-mail vazio exibe banner_erro_login
      await tester.tap(find.byKey(const Key('btn_enviar_codigo_otp')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('banner_erro_login')), findsOneWidget);
      expect(find.text('Informe um endereço de e-mail válido.'), findsOneWidget);

      // 2. Digita e-mail válido e solicita o código OTP
      await tester.enterText(
        find.byKey(const Key('campo_login_email')),
        'escalador@aresta.com',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('banner_erro_login')), findsNothing);

      await tester.tap(find.byKey(const Key('btn_enviar_codigo_otp')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('banner_info_otp_login')), findsOneWidget);
      expect(find.byKey(const Key('campo_login_codigo_otp')), findsOneWidget);

      // Reenvia o código e testa retorno à Etapa 1 ("Usar outro e-mail") antes de confirmar
      await tester.enterText(
        find.byKey(const Key('campo_login_codigo_otp')),
        '999',
      );
      await tester.tap(find.byKey(const Key('btn_reenviar_codigo_otp')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_alterar_email_otp')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('campo_login_codigo_otp')), findsNothing);

      await tester.tap(find.byKey(const Key('btn_enviar_codigo_otp')));
      await tester.pumpAndSettle();

      // 3. Digita o código de 6 dígitos correto e confirma
      await tester.enterText(
        find.byKey(const Key('campo_login_codigo_otp')),
        '123456',
      );
      await tester.tap(find.byKey(const Key('btn_confirmar_codigo_otp')));
      await tester.pumpAndSettle();

      expect(autenticadoCallback, isTrue);
      expect(servicoFake.estaAutenticado, isTrue);
    });

    testWidgets('navega para PerfilNode ao autenticar via Google, Apple (iOS) ou OTP e ao continuar sem conta', (tester) async {
      final datasetRepo = DatasetRepository(editorDeCroqui: EditorDeCroqui());
      final syncService = SyncService(datasetRepository: datasetRepo);
      final treeController = TreeNavigationController(
        estadoInicial: const ArvoreNavegacao(
          noAtual: LoginNode(HomeNode()),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            platform: TargetPlatform.iOS,
            extensions: const [AppColors.dark],
          ),
          home: TreeNavigationWrapper(
            key: TreeNavigationWrapper.navKey,
            datasetRepo: datasetRepo,
            syncService: syncService,
            treeController: treeController,
            child: LoginPage(
              construtorViewModel: () =>
                  LoginViewModel(servicoAutenticacao: servicoFake),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Continuar sem conta / Offline
      await tester.ensureVisible(find.byKey(const Key('btn_continuar_sem_conta')));
      await tester.tap(find.byKey(const Key('btn_continuar_sem_conta')));
      await tester.pumpAndSettle();
      expect(treeController.currentNode, isA<PerfilNode>());
      expect(servicoFake.estaAutenticado, isFalse);

      // 2. Google -> PerfilNode
      treeController.navigateTo(const LoginNode(HomeNode()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_login_google')));
      await tester.pumpAndSettle();
      expect(servicoFake.estaAutenticado, isTrue);
      expect(treeController.currentNode, isA<PerfilNode>());

      // 3. Apple -> PerfilNode
      await servicoFake.encerrarSessao();
      treeController.navigateTo(const LoginNode(HomeNode()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_login_apple')));
      await tester.pumpAndSettle();
      expect(servicoFake.estaAutenticado, isTrue);
      expect(treeController.currentNode, isA<PerfilNode>());

      // 4. Código OTP -> PerfilNode
      await servicoFake.encerrarSessao();
      treeController.navigateTo(const LoginNode(HomeNode()));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('campo_login_email')),
        'montanha@aresta.com',
      );
      await tester.tap(find.byKey(const Key('btn_enviar_codigo_otp')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('campo_login_codigo_otp')),
        '123456',
      );
      await tester.tap(find.byKey(const Key('btn_confirmar_codigo_otp')));
      await tester.pumpAndSettle();
      expect(servicoFake.estaAutenticado, isTrue);
      expect(treeController.currentNode, isA<PerfilNode>());
    });

    testWidgets('botão voltar desempilha a LoginPage, gerencia ViewModel interno e preserva feature flag perfilHabilitado inativa por padrão', (tester) async {
      // Confirma que fora do override de teste, a flag perfilHabilitado segue inativa por padrão
      ConfiguracaoRecursos.redefinirParaTestes();
      expect(ConfiguracaoRecursos.perfilHabilitado, isFalse);
      ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(true);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              child: const Text('Abrir Login'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Login'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_voltar_login')));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsNothing);
    });

    testWidgets('não causa overflow em tela ultracompacta (320x568) com escala de texto 1.5x nas duas etapas do OTP', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final vm = LoginViewModel(servicoAutenticacao: servicoFake);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            platform: TargetPlatform.iOS,
            extensions: const [AppColors.dark],
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.5),
            ),
            child: child!,
          ),
          home: LoginPage(viewModel: vm),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      vm.definirEmail('compacto@aresta.com');
      await vm.solicitarCodigoEmail();
      await vm.confirmarCodigoEmail();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
