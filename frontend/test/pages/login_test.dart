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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RepositorioCadernetaLocal repositorio;
  late ServicoAutenticacaoLocal servicoAutenticacao;

  setUp(() async {
    ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(true);
    ControladorInteracoesUsuario.redefinirParaTestes();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repositorio = RepositorioCadernetaLocal(preferencias: prefs);
    await repositorio.inicializar();
    RepositorioCadernetaLocal.instancia = repositorio;
    servicoAutenticacao = ServicoAutenticacaoLocal(
      repositorio: repositorio,
      obterAnonKeySupabase: () => '',
    );
    ServicoAutenticacaoLocal.instancia = servicoAutenticacao;
  });

  tearDown(() {
    ConfiguracaoRecursos.redefinirParaTestes();
    ControladorInteracoesUsuario.redefinirParaTestes();
    ServicoAutenticacaoLocal.redefinirParaTestes();
  });

  Widget criarLoginWidget({
    LoginViewModel? viewModel,
    LoginViewModel Function()? construtorViewModel,
  }) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
      home: LoginPage(
        viewModel: viewModel,
        construtorViewModel: construtorViewModel,
      ),
    );
  }

  group('LoginPage', () {
    testWidgets('renderiza elementos principais de login via Google, e-mail e modo offline', (tester) async {
      await tester.pumpWidget(
        criarLoginWidget(
          viewModel: LoginViewModel(servicoAutenticacao: servicoAutenticacao),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Entrar na sua conta'), findsOneWidget);
      expect(find.text('Continuar com o Google'), findsOneWidget);
      expect(find.text('Continuar com a Apple'), findsOneWidget);
      expect(find.byKey(const Key('campo_login_email')), findsOneWidget);
      expect(find.byKey(const Key('campo_login_senha')), findsOneWidget);
      expect(find.byKey(const Key('campo_login_nome')), findsNothing);
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.text('Não tem conta? Criar agora'), findsOneWidget);
      expect(find.text('Continuar sem conta / Offline'), findsOneWidget);
    });

    testWidgets('valida erro no login por e-mail, alterna visibilidade da senha e autentica com sucesso', (tester) async {
      var autenticadoCallback = false;
      final vm = LoginViewModel(
        servicoAutenticacao: servicoAutenticacao,
        aoAutenticarComSucesso: () => autenticadoCallback = true,
      );

      await tester.pumpWidget(criarLoginWidget(viewModel: vm));
      await tester.pumpAndSettle();

      // Tenta submeter vazio -> exibe banner de erro
      await tester.tap(find.byKey(const Key('btn_submeter_email_senha')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('banner_erro_login')), findsOneWidget);
      expect(find.text('Informe um endereço de e-mail válido.'), findsOneWidget);

      // Alterna visibilidade da senha
      await tester.tap(find.byKey(const Key('btn_alternar_visibilidade_senha')));
      await tester.pumpAndSettle();
      expect(vm.ocultarSenha, isFalse);

      // Preenche credenciais válidas e submete
      await tester.enterText(
        find.byKey(const Key('campo_login_email')),
        'escalador@gmail.com',
      );
      await tester.enterText(
        find.byKey(const Key('campo_login_senha')),
        'minhaSenha123',
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('banner_erro_login')), findsNothing);

      await tester.tap(find.byKey(const Key('btn_submeter_email_senha')));
      await tester.pumpAndSettle();

      expect(autenticadoCallback, isTrue);
      expect(servicoAutenticacao.estaAutenticado, isTrue);
    });

    testWidgets('alterna para modo Criar Conta, preenche nome, e-mail e senha e cria conta', (tester) async {
      final vm = LoginViewModel(servicoAutenticacao: servicoAutenticacao);

      await tester.pumpWidget(criarLoginWidget(viewModel: vm));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_alternar_modo_conta')));
      await tester.pumpAndSettle();

      expect(find.text('Criar conta Aresta'), findsOneWidget);
      expect(find.byKey(const Key('campo_login_nome')), findsOneWidget);
      expect(find.text('Criar conta'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('campo_login_nome')),
        'Rafael Montanha',
      );
      await tester.enterText(
        find.byKey(const Key('campo_login_email')),
        'rafael@gmail.com',
      );
      await tester.enterText(
        find.byKey(const Key('campo_login_senha')),
        'senha123456',
      );
      await tester.tap(find.byKey(const Key('btn_submeter_email_senha')));
      await tester.pumpAndSettle();

      expect(servicoAutenticacao.estaAutenticado, isTrue);
      expect(
        repositorio.obterPerfil().autorNomePublico,
        equals('Rafael Montanha'),
      );
    });

    testWidgets('exibe banner de confirmação de e-mail e alterna para modo Entrar quando o servidor exige confirmação no cadastro', (tester) async {
      final servicoPendente = ServicoAutenticacaoLocal(
        repositorio: repositorio,
        obterAnonKeySupabase: () => '',
        provedorCriarConta: (nome, email, senha) async =>
            ResultadoProvedorAutenticacao(
              userId: 'usr-pendente',
              nomeExibicao: nome,
              requerConfirmacaoEmail: true,
            ),
      );
      final vmPendente = LoginViewModel(servicoAutenticacao: servicoPendente);
      await tester.pumpWidget(criarLoginWidget(viewModel: vmPendente));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_alternar_modo_conta')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('campo_login_nome')),
        'Helena Rocha',
      );
      await tester.enterText(
        find.byKey(const Key('campo_login_email')),
        'helena@gmail.com',
      );
      await tester.enterText(
        find.byKey(const Key('campo_login_senha')),
        'senha123456',
      );
      await tester.tap(find.byKey(const Key('btn_submeter_email_senha')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('banner_confirmacao_email_login')),
        findsOneWidget,
      );
      expect(find.textContaining('helena@gmail.com'), findsWidgets);
      expect(servicoPendente.estaAutenticado, isFalse);
    });

    testWidgets('entrar com Google e continuar sem conta navegam para PerfilNode na árvore quando sem callbacks customizados', (tester) async {
      final datasetRepo = DatasetRepository(editorDeCroqui: EditorDeCroqui());
      final syncService = SyncService(datasetRepository: datasetRepo);
      final treeController = TreeNavigationController(
        estadoInicial: const ArvoreNavegacao(
          noAtual: LoginNode(HomeNode()),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
          home: TreeNavigationWrapper(
            key: TreeNavigationWrapper.navKey,
            datasetRepo: datasetRepo,
            syncService: syncService,
            treeController: treeController,
            child: LoginPage(
              construtorViewModel: () =>
                  LoginViewModel(servicoAutenticacao: servicoAutenticacao),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Toca em Continuar sem conta / Offline -> navega para PerfilNode(HomeNode)
      await tester.ensureVisible(find.byKey(const Key('btn_continuar_sem_conta')));
      await tester.tap(find.byKey(const Key('btn_continuar_sem_conta')));
      await tester.pumpAndSettle();

      expect(treeController.currentNode, isA<PerfilNode>());
      expect(treeController.currentNode.parent, isA<HomeNode>());
      expect(servicoAutenticacao.estaAutenticado, isFalse);

      // 2. Volta para LoginNode e toca em Continuar com o Google -> autentica e navega para PerfilNode(HomeNode)
      treeController.navigateTo(const LoginNode(HomeNode()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_login_google')));
      await tester.pumpAndSettle();

      expect(servicoAutenticacao.estaAutenticado, isTrue);
      expect(treeController.currentNode, isA<PerfilNode>());
      expect(treeController.currentNode.parent, isA<HomeNode>());

      // 3. Encerra sessão, volta para LoginNode e toca em Continuar com a Apple -> autentica e navega para PerfilNode(HomeNode)
      await servicoAutenticacao.encerrarSessao();
      treeController.navigateTo(const LoginNode(HomeNode()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_login_apple')));
      await tester.pumpAndSettle();

      expect(servicoAutenticacao.estaAutenticado, isTrue);
      expect(treeController.currentNode, isA<PerfilNode>());
      expect(treeController.currentNode.parent, isA<HomeNode>());
    });

    testWidgets('botão voltar desempilha a LoginPage e LoginPage gerencia ciclo de vida de ViewModel interno', (tester) async {
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
      expect(find.text('Abrir Login'), findsOneWidget);
    });

    testWidgets('não causa overflow em tela ultracompacta (320x568) com escala de texto 1.5x', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final vm = LoginViewModel(servicoAutenticacao: servicoAutenticacao);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
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

      // Alterna para Criar Conta e força erro para validar ausência de overflow com todos os elementos visíveis
      vm.alternarModoConta();
      await vm.submeterEmailSenha();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
