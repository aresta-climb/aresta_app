// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/main.dart';
import 'package:frontend/navigation/funcoes_navegacao.dart';
import 'package:frontend/navigation/arvore_navegacao.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/configuracao_recursos.dart';
import 'package:frontend/pages/perfil.dart';
import 'package:frontend/theme/cores_app.dart';

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

class _ItemComId {
  final String id;
  const _ItemComId(this.id);
}

class _ItemQueLancaNoId {
  String get id => throw StateError('Sem id');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late DatasetRepository repo;
  late SyncService syncService;
  late EditorDeCroqui editor;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('funcoes_navegacao_test_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);

    editor = EditorDeCroqui();
    repo = DatasetRepository(editorDeCroqui: editor);
    syncService = SyncService(datasetRepository: repo);
    syncService.syncStatus.value = SyncStatus.updated;

    final via = ViaEsportiva()..nome = 'Via Teste';
    final escalada = Escalada()..viaEsportiva = via;
    final setor = Setor()
      ..nome = 'Setor Teste'
      ..escaladas.add(escalada);
    final arquivoSetor = ArquivoSetor()..conteudo = setor;

    final grupo = Grupo()
      ..nome = 'Grupo Teste'
      ..setores.add(arquivoSetor);
    final arquivoGrupo = ArquivoGrupo()..conteudo = grupo;

    final grupoNode = SetorOuGrupo()..grupo = arquivoGrupo;

    final pico = Pico()
      ..nome = 'Pico Teste'
      ..setoresOuGrupos.add(grupoNode);
    final croqui = Croqui()
      ..id = 'test_crag'
      ..nome = 'Pico Teste'
      ..picos.add(pico);

    repo.activeDataset.value = ConjuntoDadosCroqui(
      picosDisponiveis: [
        ResumoPico(
          id: 'test_crag',
          nome: 'Pico Teste',
          local: 'MG',
          isDownloaded: true,
          pico: pico,
          croqui: croqui,
        ),
      ],
      picosBaixados: [
        ResumoPico(
          id: 'test_crag',
          nome: 'Pico Teste',
          local: 'MG',
          isDownloaded: true,
          pico: pico,
          croqui: croqui,
        ),
      ],
      croquisBaixados: [croqui],
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('AppNav tests', () {
    testWidgets('toVia empilha ViaNode no TreeNavigationController para todas as modalidades de escalada', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TreeNavigationWrapper(
            key: TreeNavigationWrapper.navKey,
            datasetRepo: repo,
            syncService: syncService,
            child: const Scaffold(body: Text('Host')),
          ),
        ),
      );
      await tester.pump();

      final BuildContext context = tester.element(find.text('Host'));
      final controller =
          TreeNavigationWrapper.navKey.currentState!.treeController;

      controller.navigateTo(PicoNode(cragId: 'test_crag', parent: HomeNode()));
      await tester.pump();

      final setor = Setor()..nome = 'Setor Teste';
      final grupo = Grupo()..nome = 'Grupo Teste';

      // 1. Via Esportiva
      AppNav.toVia(
        context,
        escalada: Escalada()..viaEsportiva = (ViaEsportiva()..nome = 'Via Teste'),
        setor: setor,
        grupo: grupo,
      );
      expect((controller.currentNode as ViaNode).escaladaNome, 'Via Teste');

      // 2. Via Móvel
      AppNav.toVia(
        context,
        escalada: Escalada()..viaMovel = (ViaMovel()..nome = 'Via Movel Teste'),
      );
      expect((controller.currentNode as ViaNode).escaladaNome, 'Via Movel Teste');

      // 3. Boulder
      AppNav.toVia(
        context,
        escalada: Escalada()..boulder = (Boulder()..nome = 'Boulder Teste'),
      );
      expect((controller.currentNode as ViaNode).escaladaNome, 'Boulder Teste');

      // 4. Múltiplas Enfiadas
      AppNav.toVia(
        context,
        escalada: Escalada()
          ..viaMultiplasEnfiadas = (ViaMultiplasEnfiadas()..nome = 'Multi Teste'),
      );
      expect((controller.currentNode as ViaNode).escaladaNome, 'Multi Teste');

      // 5. Highline
      AppNav.toVia(
        context,
        escalada: Escalada()..highline = (Highline()..nome = 'Highline Teste'),
      );
      expect((controller.currentNode as ViaNode).escaladaNome, 'Highline Teste');

      // 6. Escalada vazia
      AppNav.toVia(context, escalada: Escalada());
      expect((controller.currentNode as ViaNode).escaladaNome, '');
    });

    testWidgets('toSetor, toGrupo, toIndiceEscaladas e toGPS empilham os respectivos nós herdando o contexto do pico', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TreeNavigationWrapper(
            key: TreeNavigationWrapper.navKey,
            datasetRepo: repo,
            syncService: syncService,
            child: const Scaffold(body: Text('Host')),
          ),
        ),
      );
      await tester.pump();

      final BuildContext context = tester.element(find.text('Host'));
      final controller =
          TreeNavigationWrapper.navKey.currentState!.treeController;

      // Sem contexto de pico, chamadas sem cragId não alteram o nó atual
      AppNav.toPico(context);
      AppNav.toSetor(context, setor: Setor()..nome = 'S');
      AppNav.toGrupo(context, grupo: Grupo()..nome = 'G');
      AppNav.toIndiceEscaladas(context);
      AppNav.toVia(context, escalada: Escalada());
      AppNav.toGPS(context);
      expect(controller.currentNode, isA<HomeNode>());

      // Navega para PicoNode
      AppNav.toPico(
        context,
        cragId: 'test_crag',
        returnToSetor: Setor()..nome = 'Setor Retorno',
      );
      expect(controller.currentNode, isA<PicoNode>());

      // toPico sem cragId explícito herda do contexto do pico atual
      AppNav.toPico(context);
      expect(controller.currentNode, isA<PicoNode>());

      final setor = Setor()..nome = 'Setor Teste';
      final escalada = Escalada()..viaEsportiva = (ViaEsportiva()..nome = 'Via Alvo');
      AppNav.toSetor(
        context,
        setor: setor,
        grupoContext: Grupo()..nome = 'Grupo Pai',
        scrollToEscalada: escalada,
      );
      expect(controller.currentNode, isA<SetorNode>());
      expect((controller.currentNode as SetorNode).scrollToEscaladaNome, 'Via Alvo');

      AppNav.toGrupo(context, grupo: Grupo()..nome = 'Grupo Teste');
      expect(controller.currentNode, isA<GrupoNode>());

      AppNav.toIndiceEscaladas(context);
      expect(controller.currentNode, isA<IndiceEscaladasNode>());

      AppNav.toGPS(context);
      expect(controller.currentNode, isA<GPSNode>());
      final gpsNode = controller.currentNode;
      // Chamar toGPS já estando em GPSNode é idempotente
      AppNav.toGPS(context);
      expect(identical(controller.currentNode, gpsNode), isTrue);
    });

    testWidgets(
      'toMapas e toMapaGlobal empilham os nós de mapa normalizando identificadores',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: TreeNavigationWrapper(
              key: TreeNavigationWrapper.navKey,
              datasetRepo: repo,
              syncService: syncService,
              child: const Scaffold(body: Text('Host')),
            ),
          ),
        );
        await tester.pump();

        final BuildContext context = tester.element(find.text('Host'));
        final controller =
            TreeNavigationWrapper.navKey.currentState!.treeController;

        controller.navigateTo(
          PicoNode(cragId: 'test_crag', parent: HomeNode()),
        );
        await tester.pump();

        AppNav.toMapas(
          context,
          cragId: 'test_crag',
          initialIndex: 1,
          mapas: const [
            CarrosselItemData(
              mapaCaminhoImagem: 'assets/map1.png',
              initialSelectedId: 'a',
            ),
            CarrosselItemData(
              mapaCaminhoImagem: 'assets/map2.png',
              initialSelectedId: 'b',
            ),
          ],
        );

        expect(controller.currentNode, isA<MapasCarrosselNode>());

        // toMapaGlobal extraindo IDs de String, objeto com .id e Map
        AppNav.toMapaGlobal(
          context,
          crags: [
            'pico_1',
            const _ItemComId('pico_2'),
            {'id': 'pico_3'},
            _ItemQueLancaNoId(),
          ],
        );
        expect(controller.currentNode, isA<MapaGlobalNode>());
        expect(
          (controller.currentNode as MapaGlobalNode).picoIds,
          equals(['pico_1', 'pico_2', 'pico_3']),
        );

        // toMapaGlobal com picoIds explícitos e crags não-iterável
        AppNav.toMapaGlobal(context, picoIds: ['explicito_1']);
        expect(
          (controller.currentNode as MapaGlobalNode).picoIds,
          equals(['explicito_1']),
        );
      },
    );

    testWidgets(
      'toBrowse, home, back e canGoBack operam sobre o controlador e suportam fallback sem TreeNavigationWrapper',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: TreeNavigationWrapper(
              key: TreeNavigationWrapper.navKey,
              datasetRepo: repo,
              syncService: syncService,
              child: const Scaffold(body: Text('Host')),
            ),
          ),
        );
        await tester.pump();

        final BuildContext context = tester.element(find.text('Host'));
        final controller =
            TreeNavigationWrapper.navKey.currentState!.treeController;

        expect(AppNav.canGoBack(context), isFalse);

        AppNav.toBrowse(context);
        expect(controller.currentNode, isA<BrowseNode>());
        expect(AppNav.canGoBack(context), isTrue);

        AppNav.back(context);
        expect(controller.currentNode, isA<HomeNode>());

        AppNav.toBrowse(context);
        AppNav.home(context);
        expect(controller.currentNode, isA<HomeNode>());
      },
    );

    testWidgets(
      'AppNav resolve controlador via TreeNavigationWrapper.currentTreeController quando chamado de diálogo/overlay',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: TreeNavigationWrapper(
              key: TreeNavigationWrapper.navKey,
              datasetRepo: repo,
              syncService: syncService,
              child: const Scaffold(body: Text('Host')),
            ),
          ),
        );
        await tester.pump();

        final BuildContext context = tester.element(find.text('Host'));

        late BuildContext dialogContext;
        showDialog(
          context: context,
          builder: (ctx) {
            dialogContext = ctx;
            return const AlertDialog(title: Text('Overlay'));
          },
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        AppNav.toPico(dialogContext, cragId: 'test_crag');
        await tester.pump();

        final controller = TreeNavigationWrapper.currentTreeController;
        expect(controller?.currentNode, isA<PicoNode>());
        expect((controller?.currentNode as PicoNode).cragId, 'test_crag');
      },
    );

    testWidgets(
      'AppNav.toPerfil, toCaderneta e canGoBack funcionam quando não há TreeNavigationWrapper montado',
      (tester) async {
        ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(false);
        addTearDown(ConfiguracaoRecursos.redefinirParaTestes);

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(extensions: const [AppColors.dark]),
            home: const Scaffold(body: Text('Tela Inicial')),
          ),
        );
        await tester.pump();

        final context = tester.element(find.text('Tela Inicial'));
        expect(AppNav.canGoBack(context), isFalse);
        AppNav.toMapas(context, cragId: 'test_crag', mapas: const []);

        // Com perfil desabilitado, toPerfil não navega
        AppNav.toPerfil(context);
        await tester.pumpAndSettle();
        expect(find.byType(PerfilPage), findsNothing);

        // Com perfil habilitado e sem TreeNavigationWrapper, faz push de MaterialPageRoute
        ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(true);
        AppNav.toPerfil(context);
        await tester.pumpAndSettle();
        expect(find.byType(PerfilPage), findsOneWidget);

        AppNav.back(tester.element(find.byType(PerfilPage)));
        await tester.pumpAndSettle();
        expect(find.byType(PerfilPage), findsNothing);

        // toCaderneta sem TreeNavigationWrapper faz push de MaterialPageRoute
        AppNav.toCaderneta(context);
        await tester.pumpAndSettle();
        expect(find.byType(CadernetaPage), findsOneWidget);
      },
    );

    testWidgets(
      'AppNav.toPerfil, toCaderneta e toSettings empilham nós quando TreeNavigationController está presente',
      (tester) async {
        ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(true);
        addTearDown(ConfiguracaoRecursos.redefinirParaTestes);

        await tester.pumpWidget(
          MaterialApp(
            home: TreeNavigationWrapper(
              key: TreeNavigationWrapper.navKey,
              datasetRepo: repo,
              syncService: syncService,
              child: const Scaffold(body: Text('Host')),
            ),
          ),
        );
        await tester.pump();

        final context = tester.element(find.text('Host'));
        final controller = TreeNavigationWrapper.currentTreeController!;

        AppNav.toPerfil(context);
        expect(controller.currentNode, isA<PerfilNode>());

        AppNav.toCaderneta(context);
        expect(controller.currentNode, isA<CadernetaNode>());

        AppNav.toSettings(context);
        expect(controller.currentNode, isA<SettingsNode>());
      },
    );

    testWidgets(
      'AppNav.minimizarAplicativo invoca minimizarTarefa no canal de ciclo de vida sem chamar SystemNavigator.pop quando suportado',
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

        await AppNav.minimizarAplicativo();

        expect(chamadasCicloVida, equals(['minimizarTarefa']));
        expect(chamadasPlataforma, isNot(contains('SystemNavigator.pop')));
      },
    );

    testWidgets(
      'AppNav.minimizarAplicativo realiza fallback para SystemNavigator.pop quando o canal retorna false ou não está registrado',
      (tester) async {
        final chamadasPlataforma = <String>[];

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

        // Caso 1: canal lança MissingPluginException / falha
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          AppNav.canalCicloVida,
          (MethodCall call) async => throw MissingPluginException('Canal indisponível'),
        );
        await AppNav.minimizarAplicativo();
        expect(chamadasPlataforma, contains('SystemNavigator.pop'));

        // Caso 2: canal registrado, porém retorna false
        chamadasPlataforma.clear();
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          AppNav.canalCicloVida,
          (MethodCall call) async => false,
        );

        await AppNav.minimizarAplicativo();
        expect(chamadasPlataforma, contains('SystemNavigator.pop'));
      },
    );

    testWidgets(
      'AppNav.back em página declarativa da árvore delega para treeController.goBack respeitando onBackInterceptor sem desmontar a página',
      (tester) async {
        final treeController = TreeNavigationController(
          estadoInicial: const ArvoreNavegacao(
            noAtual: PicoNode(cragId: 'test_crag', parent: HomeNode()),
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: construirTemaEscuro(),
            home: TreeNavigationWrapper(
              key: TreeNavigationWrapper.navKey,
              datasetRepo: repo,
              syncService: syncService,
              treeController: treeController,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        final picoFinder = find.text('PICO TESTE');
        expect(picoFinder, findsOneWidget);

        var interceptorAcionado = false;
        treeController.onBackInterceptor = () {
          interceptorAcionado = true;
          return true;
        };

        final pageContext = tester.element(picoFinder);
        AppNav.back(pageContext);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // O interceptor bloqueou a saída: a página declarativa NÃO pode ter sido arrancada do Navigator!
        expect(interceptorAcionado, isTrue);
        expect(treeController.currentNode, isA<PicoNode>());
        expect(find.text('PICO TESTE'), findsOneWidget);

        // Quando o interceptor é liberado, AppNav.back retrocede normalmente para a HomeNode
        treeController.onBackInterceptor = null;
        AppNav.back(tester.element(find.text('PICO TESTE')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(treeController.currentNode, isA<HomeNode>());
        expect(find.text('PICO TESTE'), findsNothing);
      },
    );

    testWidgets(
      'AppNav.back em rota imperativa sobreposta desempilha apenas o overlay sem retroceder o nó da árvore',
      (tester) async {
        final treeController = TreeNavigationController(
          estadoInicial: const ArvoreNavegacao(
            noAtual: PicoNode(cragId: 'test_crag', parent: HomeNode()),
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: construirTemaEscuro(),
            home: TreeNavigationWrapper(
              key: TreeNavigationWrapper.navKey,
              datasetRepo: repo,
              syncService: syncService,
              treeController: treeController,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        final pageContext = tester.element(find.text('PICO TESTE'));
        late BuildContext overlayContext;
        showDialog<void>(
          context: pageContext,
          useRootNavigator: false,
          builder: (ctx) {
            overlayContext = ctx;
            return const AlertDialog(title: Text('Dialog Imperativo'));
          },
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Dialog Imperativo'), findsOneWidget);

        AppNav.back(overlayContext);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Dialog Imperativo'), findsNothing);
        expect(treeController.currentNode, isA<PicoNode>());
        expect(find.text('PICO TESTE'), findsOneWidget);
      },
    );
  });
}
