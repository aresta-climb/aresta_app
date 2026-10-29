// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feedback/feedback.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:frontend/application_managers/feedback/caso_uso_enviar_feedback.dart';
import 'package:frontend/navigation/arvore_navegacao.dart';
import 'package:frontend/navigation/funcoes_navegacao.dart';
import 'package:frontend/navigation/wrapper_navegacao_arvore.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/pages/comunidade.dart';
import 'package:frontend/pages/explorar.dart';
import 'package:frontend/pages/home.dart';
import 'package:frontend/pages/meus_croquis.dart';
import 'package:frontend/pages/pico.dart';
import 'package:frontend/services/firebase/telemetria.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/theme/cores_app.dart';
import '../mocks/mock_telemetria.dart';
import '../mocks/mock_geolocator_platform.dart';

class _FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String tempPath;
  _FakePathProviderPlatform(this.tempPath);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempPath;
  @override
  Future<String?> getApplicationSupportPath() async => tempPath;
  @override
  Future<String?> getLibraryPath() async => tempPath;
  @override
  Future<String?> getTemporaryPath() async => tempPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TreeNavigationWrapper Widget Tests', () {
    late Directory tempDir;
    late DatasetRepository repo;
    late SyncService syncService;
    late EditorDeCroqui editor;
    late MockGeolocatorPlatform mockGeolocator;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tempDir = await Directory.systemTemp.createTemp('tree_nav_wrapper_test_');
      PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
      mockGeolocator = MockGeolocatorPlatform();
      GeolocatorPlatform.instance = mockGeolocator;

      editor = EditorDeCroqui();
      repo = DatasetRepository(editorDeCroqui: editor);
      syncService = SyncService(datasetRepository: repo);
      syncService.syncStatus.value = SyncStatus.updated;
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    testWidgets('renderiza com sucesso e provê acesso a of e maybeOf', (tester) async {
      late TreeNavigationWrapperState stateOf;
      TreeNavigationWrapperState? stateMaybeOf;

      await tester.pumpWidget(
        MaterialApp(
          home: TreeNavigationWrapper(
            key: TreeNavigationWrapper.navKey,
            datasetRepo: repo,
            syncService: syncService,
            child: Builder(
              builder: (context) {
                stateOf = TreeNavigationWrapper.of(context);
                stateMaybeOf = TreeNavigationWrapper.maybeOf(context);
                return const Scaffold(body: Text('Conteúdo Teste'));
              },
            ),
          ),
        ),
      );

      expect(find.text('Conteúdo Teste'), findsOneWidget);
      expect(stateOf, isNotNull);
      expect(stateMaybeOf, isNotNull);
      expect(TreeNavigationWrapper.currentTreeController, isNotNull);
    });

    testWidgets('switchTab altera a navegação através do controlador', (tester) async {
      final controller = TreeNavigationController();

      await tester.pumpWidget(
        MaterialApp(
          home: TreeNavigationWrapper(
            key: TreeNavigationWrapper.navKey,
            datasetRepo: repo,
            syncService: syncService,
            treeController: controller,
          ),
        ),
      );

      expect(controller.currentNode, isA<HomeNode>());

      TreeNavigationWrapper.switchTab(1);
      await tester.pump(const Duration(milliseconds: 200));
      expect(controller.currentNode, isA<BrowseNode>());

      TreeNavigationWrapper.switchTab(2);
      await tester.pump(const Duration(milliseconds: 200));
      expect(controller.currentNode, isA<MeusCroquisNode>());

      TreeNavigationWrapper.switchTab(3);
      await tester.pump(const Duration(milliseconds: 200));
      expect(controller.currentNode, isA<ComunidadeNode>());
    });

    testWidgets('navegar para ControlesNode não gera Unknown Node nem quebra Navigator', (tester) async {
      final controller = TreeNavigationController();

      await tester.pumpWidget(
        MaterialApp(
          home: TreeNavigationWrapper(
            key: TreeNavigationWrapper.navKey,
            datasetRepo: repo,
            syncService: syncService,
            treeController: controller,
          ),
        ),
      );
      await tester.pump();

      controller.navigateTo(ControlesNode(cragId: 'pedra_bela', parent: controller.currentNode));
      await tester.pump();

      expect(find.text('Unknown Node'), findsNothing);
    });

    testWidgets('registra telemetria de cancelar_feedback ao fechar feedback sem envio', (tester) async {
      final mockTelemetry = MockTelemetryService();
      TelemetryService.instance = mockTelemetry;
      SubmitFeedbackUseCase.ultimoEnvioConcluido = false;

      late BuildContext buildContext;
      await tester.pumpWidget(
        MaterialApp(
          home: BetterFeedback(
            child: TreeNavigationWrapper(
              key: TreeNavigationWrapper.navKey,
              datasetRepo: repo,
              syncService: syncService,
              child: Builder(
                builder: (context) {
                  buildContext = context;
                  return const Scaffold(body: Text('Base'));
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      BetterFeedback.of(buildContext).show((_) {});
      await tester.pumpAndSettle();
      expect(SubmitFeedbackUseCase.isFeedbackOpen.value, isTrue);

      BetterFeedback.of(buildContext).hide();
      await tester.pumpAndSettle();

      expect(mockTelemetry.recordedEvents, contains('acao_feedback'));
      final params = mockTelemetry.recordedParams['acao_feedback']!;
      expect(params['acao'], 'cancelar_feedback');
      expect(params['origem'], 'descarte_usuario');

      TelemetryService.resetForTesting();
    });

    testWidgets('não registra cancelar_feedback quando envio for concluído com sucesso', (tester) async {
      final mockTelemetry = MockTelemetryService();
      TelemetryService.instance = mockTelemetry;

      late BuildContext buildContext;
      await tester.pumpWidget(
        MaterialApp(
          home: BetterFeedback(
            child: TreeNavigationWrapper(
              key: TreeNavigationWrapper.navKey,
              datasetRepo: repo,
              syncService: syncService,
              child: Builder(
                builder: (context) {
                  buildContext = context;
                  return const Scaffold(body: Text('Base'));
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      BetterFeedback.of(buildContext).show((_) {});
      await tester.pumpAndSettle();

      SubmitFeedbackUseCase.ultimoEnvioConcluido = true;
      mockTelemetry.clear();

      BetterFeedback.of(buildContext).hide();
      await tester.pumpAndSettle();

      expect(mockTelemetry.recordedEvents, isNot(contains('acao_feedback')));

      TelemetryService.resetForTesting();
    });

    testWidgets(
      'tocar em VER MAIS -> no carrossel da Home alterna para aba Explorar sincronizada por distância e rola até o 7º pico',
      (tester) async {
        final controller = TreeNavigationController();
        final picos = List.generate(9, (i) {
          return <String, dynamic>{
            'id': 'pico_int_$i',
            'nome': 'Pico Integrado $i',
            'caminhoRelativo': 'picos/pico_int_$i/pico_int_$i.binarypb',
            'latitude': -20.0 - (i * 0.1),
            'longitude': -44.0,
            'isDownloaded': false,
            'thumbnailUrl': '',
          };
        });

        repo.activeDataset.value = TopoDataset(
          availablePicos: picos,
          downloadedPicos: [],
        );

        mockGeolocator.currentPositionResult = Position(
          latitude: -20.0,
          longitude: -44.0,
          timestamp: DateTime.now(),
          accuracy: 5.0,
          altitude: 1000.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: TreeNavigationWrapper(
              key: TreeNavigationWrapper.navKey,
              datasetRepo: repo,
              syncService: syncService,
              treeController: controller,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(controller.currentNode, isA<HomeNode>());

        // Rola o carrossel horizontal na Home até o card VER MAIS ->
        final listViewFinder = find.byType(ListView).first;
        await tester.drag(listViewFinder, const Offset(-2500, 0));
        await tester.pumpAndSettle();

        expect(find.text('VER MAIS ->'), findsOneWidget);
        await tester.tap(find.text('VER MAIS ->'));
        await tester.pumpAndSettle();

        // Deve ter mudado para a aba Explorar (BrowseNode)
        expect(controller.currentNode, isA<BrowseNode>());

        // O 7º pico (PICO INTEGRADO 6) está visível na tela após o auto-scroll e a rolagem vertical foi avançada
        expect(find.text('PICO INTEGRADO 6'), findsOneWidget);
        final scrollableState = tester.state<ScrollableState>(find.byType(Scrollable).last);
        expect(scrollableState.position.pixels, greaterThan(1000.0));
      },
    );

    testWidgets(
      'sincroniza picoAbertoId imediatamente ao montar já posicionado em um PicoNode e exibe SnackBar quando mensagemAvisoInicial for fornecida',
      (tester) async {
        final controller = TreeNavigationController();
        controller.navigateTo(
          const PicoNode(cragId: 'pico_cold_start', parent: HomeNode()),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: TreeNavigationWrapper(
              key: TreeNavigationWrapper.navKey,
              datasetRepo: repo,
              syncService: syncService,
              treeController: controller,
              linkInicialProcessado: Uri.parse('https://aresta.cc/pQ9mRt2Kx1Vw8L'),
              mensagemAvisoInicial: 'Aviso de teste do Cold Start',
              child: const Scaffold(body: Text('Tela Inicial Direta')),
            ),
          ),
        );
        await tester.pump();

        expect(syncService.picoAbertoId.value, equals('pico_cold_start'));
        expect(find.text('Aviso de teste do Cold Start'), findsOneWidget);
      },
    );

    testWidgets(
      'Task 2.2: no Cold Start apenas a aba inicial (HomePage) é construída no IndexedStack, montando abas secundárias sob demanda e preservando-as após visitadas',
      (tester) async {
        final controller = TreeNavigationController();
        repo.loadEmpty();

        await tester.pumpWidget(
          MaterialApp(
            home: TreeNavigationWrapper(
              key: TreeNavigationWrapper.navKey,
              datasetRepo: repo,
              syncService: syncService,
              treeController: controller,
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(HomePage, skipOffstage: false), findsOneWidget);
        expect(find.byType(BrowsePage, skipOffstage: false), findsNothing);
        expect(find.byType(MeusCroquisPage, skipOffstage: false), findsNothing);
        expect(find.byType(ComunidadePage, skipOffstage: false), findsNothing);

        // Visita a aba Explorar (índice 1)
        TreeNavigationWrapper.switchTab(1);
        await tester.pump();

        expect(find.byType(BrowsePage, skipOffstage: false), findsOneWidget);
        expect(find.byType(MeusCroquisPage, skipOffstage: false), findsNothing);
        expect(find.byType(ComunidadePage, skipOffstage: false), findsNothing);

        // Retorna para Home (índice 0): BrowsePage permanece montada
        TreeNavigationWrapper.switchTab(0);
        await tester.pump();

        expect(find.byType(HomePage, skipOffstage: false), findsOneWidget);
        expect(find.byType(BrowsePage, skipOffstage: false), findsOneWidget);
        expect(find.byType(MeusCroquisPage, skipOffstage: false), findsNothing);
      },
    );

    testWidgets(
      'Task 3.1: empilhar e desempilhar rotas filhas preserva a instância de Page e PicoViewModel das rotas subjacentes na pilha',
      (tester) async {
        final controller = TreeNavigationController();
        final setor = Setor(
          uid: 'setor_pilha',
          nome: 'Setor Pilha',
          escaladas: [
            Escalada(
              uid: 'via_pilha',
              viaEsportiva: ViaEsportiva(nome: 'Via Pilha'),
            ),
          ],
        );
        final pico = Pico(
          nome: 'Pico Pilha',
          setoresOuGrupos: [
            SetorOuGrupo(setor: ArquivoSetor(conteudo: setor)),
          ],
        );
        final croqui = Croqui(
          id: 'pico_pilha',
          nome: 'Pico Pilha',
          picos: [pico],
        );

        repo.activeDataset.value = ConjuntoDadosCroqui(
          picosDisponiveis: [
            ResumoPico(
              id: 'pico_pilha',
              nome: 'Pico Pilha',
              local: 'MG',
              isDownloaded: true,
              pico: pico,
              croqui: croqui,
            ),
          ],
          picosBaixados: [
            ResumoPico(
              id: 'pico_pilha',
              nome: 'Pico Pilha',
              local: 'MG',
              isDownloaded: true,
              pico: pico,
              croqui: croqui,
            ),
          ],
          croquisBaixados: [croqui],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: TreeNavigationWrapper(
              key: TreeNavigationWrapper.navKey,
              datasetRepo: repo,
              syncService: syncService,
              treeController: controller,
            ),
          ),
        );
        await tester.pump();

        final picoNode = const PicoNode(cragId: 'pico_pilha', parent: HomeNode());
        controller.navigateTo(picoNode);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        final navAntes = tester.widget<Navigator>(find.byType(Navigator).last);
        final pagePicoAntes = navAntes.pages[1];
        final picoPageAntes = tester.widget<PicoDetailsPage>(
          find.byType(PicoDetailsPage, skipOffstage: false),
        );
        final viewModelAntes = picoPageAntes.viewModel;

        // Empilha SetorNode por cima de PicoNode
        final setorNode = SetorNode(
          cragId: 'pico_pilha',
          setorNome: 'Setor Pilha',
          parent: picoNode,
        );
        controller.navigateTo(setorNode);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        final navDurante = tester.widget<Navigator>(find.byType(Navigator).last);
        expect(navDurante.pages.length, equals(3));
        expect(identical(navDurante.pages[1], pagePicoAntes), isTrue);

        final picoPageDurante = tester.widget<PicoDetailsPage>(
          find.byType(PicoDetailsPage, skipOffstage: false),
        );
        expect(identical(picoPageDurante.viewModel, viewModelAntes), isTrue);

        // Desempilha SetorNode de volta para PicoNode via Navigator.pop (exercitando onDidRemovePage)
        tester.state<NavigatorState>(find.byType(Navigator).last).pop();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        final navDepois = tester.widget<Navigator>(find.byType(Navigator).last);
        expect(navDepois.pages.length, equals(2));
        expect(identical(navDepois.pages[1], pagePicoAntes), isTrue);

        final picoPageDepois = tester.widget<PicoDetailsPage>(
          find.byType(PicoDetailsPage, skipOffstage: false),
        );
        expect(identical(picoPageDepois.viewModel, viewModelAntes), isTrue);
      },
    );

    testWidgets(
      'acionar botão Voltar do sistema na raiz da HomeNode minimiza a tarefa via canal de ciclo de vida sem destruir a Engine',
      (tester) async {
        final chamadasCicloVida = <String>[];
        final chamadasPlataforma = <String>[];

        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          AppNav.canalCicloVida,
          (MethodCall call) async {
            chamadasCicloVida.add(call.method);
            return true;
          },
        );
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (MethodCall call) async {
            chamadasPlataforma.add(call.method);
            return null;
          },
        );
        addTearDown(() {
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            AppNav.canalCicloVida,
            null,
          );
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          );
        });

        final controller = TreeNavigationController();
        repo.loadEmpty();

        await tester.pumpWidget(
          MaterialApp(
            home: TreeNavigationWrapper(
              key: TreeNavigationWrapper.navKey,
              datasetRepo: repo,
              syncService: syncService,
              treeController: controller,
            ),
          ),
        );
        await tester.pump();

        // Em uma aba secundária (Explorar), o primeiro Voltar retorna para a HomeNode
        TreeNavigationWrapper.switchTab(1);
        await tester.pump();
        expect(controller.currentNode, isA<BrowseNode>());

        await tester.binding.handlePopRoute();
        await tester.pump();
        expect(controller.currentNode, isA<HomeNode>());
        expect(chamadasCicloVida, isEmpty);

        // Na raiz da HomeNode, o Voltar invoca minimizarTarefa sem chamar SystemNavigator.pop
        await tester.binding.handlePopRoute();
        await tester.pump();

        expect(chamadasCicloVida, equals(['minimizarTarefa']));
        expect(chamadasPlataforma, isNot(contains('SystemNavigator.pop')));
      },
    );

    testWidgets(
      'cobre sincronização de picoAbertoId para modais textuais/mapas, reset da Home, SnackBars de sincronização e fechamento de feedback via Voltar',
      (tester) async {
        final controller = TreeNavigationController();
        repo.loadEmpty();

        late BuildContext ctxInterno;
        await tester.pumpWidget(
          BetterFeedback(
            child: MaterialApp(
              theme: ThemeData(extensions: const [AppColors.dark]),
              home: TreeNavigationWrapper(
                key: TreeNavigationWrapper.navKey,
                datasetRepo: repo,
                syncService: syncService,
                treeController: controller,
                child: Builder(
                  builder: (context) {
                    ctxInterno = context;
                    return const Scaffold(body: Text('Host'));
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        // 1. switchTab(0) já estando em HomeNode aciona triggerHomeReset
        final resetAntes = repo.homeResetTrigger.value;
        TreeNavigationWrapper.switchTab(0);
        await tester.pump();
        expect(repo.homeResetTrigger.value, equals(resetAntes + 1));

        // 2. _sincronizarPicoAbertoId para TextNode, TextCarouselNode e MapasCarrosselNode
        controller.navigateTo(
          const TextNode(
            title: 'Aviso',
            content: 'Texto',
            cragId: 'pico_txt',
            parent: HomeNode(),
          ),
        );
        await tester.pump();
        expect(syncService.picoAbertoId.value, equals('pico_txt'));

        controller.navigateTo(
          const TextCarouselNode(
            cragId: 'pico_carrossel_txt',
            texts: [TextCarouselData(title: 'T1', content: 'C1')],
            parent: HomeNode(),
          ),
        );
        await tester.pump();
        expect(syncService.picoAbertoId.value, equals('pico_carrossel_txt'));

        controller.navigateTo(
          const MapasCarrosselNode(
            cragId: 'pico_mapa_carrossel',
            initialIndex: 0,
            mapas: [],
            parent: HomeNode(),
          ),
        );
        await tester.pump();
        expect(syncService.picoAbertoId.value, equals('pico_mapa_carrossel'));
        controller.goHome();
        await tester.pump();

        // 3. SnackBars de atualização de croqui online e status de sincronização
        repo.editorDeCroqui.isExperimentalMode.value = false;
        repo.notificarCroquiOnlineAtualizadoNaUI('Serra do Cipó');
        await tester.pump();
        expect(find.text('O guia de Serra do Cipó foi atualizado!'), findsOneWidget);
        ScaffoldMessenger.of(ctxInterno).clearSnackBars();
        await tester.pump();

        syncService.lastSyncWasAuto.value = true;
        syncService.syncStatus.value = SyncStatus.error;
        await tester.pump();
        expect(
          find.text('Erro ao sincronizar os dados. Tente novamente mais tarde.'),
          findsOneWidget,
        );
        ScaffoldMessenger.of(ctxInterno).clearSnackBars();
        await tester.pump();

        syncService.quantidadeCroquisBaixadosAtualizadosNoUltimoSync.value = 1;
        syncService.syncStatus.value = SyncStatus.justUpdated;
        await tester.pump();
        expect(
          find.text('Seus croquis baixados foram atualizados!'),
          findsOneWidget,
        );

        // 4. Com SubmitFeedbackUseCase.isFeedbackOpen ativo, acionar Voltar no PopScope esconde o feedback
        SubmitFeedbackUseCase.isFeedbackOpen.value = true;
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(SubmitFeedbackUseCase.isFeedbackOpen.value, isFalse);
      },
    );
  });
}
