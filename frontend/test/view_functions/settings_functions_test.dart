// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/view_functions/settings_functions.dart';
import 'package:frontend/main.dart';
import 'package:frontend/navigation/navigation_tree.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/http/sync_isolate.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/services/notificacoes/gerenciador_notificacao_download.dart';
import 'package:geolocator/geolocator.dart';
import '../mocks/mock_geolocator_platform.dart';
import '../mocks/mock_telemetry_service.dart';

class FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String tempPath;
  FakePathProviderPlatform(this.tempPath);

  @override
  Future<String?> getTemporaryPath() async => tempPath;
  @override
  Future<String?> getApplicationDocumentsPath() async => tempPath;
  @override
  Future<String?> getApplicationSupportPath() async => tempPath;
  @override
  Future<String?> getLibraryPath() async => tempPath;
}

class MockGerenciadorNotificacaoDownload extends Mock
    implements GerenciadorNotificacaoDownload {}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    TelemetryService.instance = MockTelemetryService();
  });

  group('normalizeEditorUrl', () {
    test('deve manter a url vazia', () {
      expect(normalizeEditorUrl(''), '');
      expect(normalizeEditorUrl('   '), '');
    });

    test('deve adicionar https se não tiver scheme', () {
      expect(normalizeEditorUrl('example.com'), 'https://example.com');
      expect(
        normalizeEditorUrl('aresta-climb.github.io/aresta_serving'),
        'https://aresta-climb.github.io/aresta_serving',
      );

      // Deve adicionar http:// se for IP ou localhost
      expect(normalizeEditorUrl('10.0.2.2:8156'), 'http://10.0.2.2:8156');
      expect(normalizeEditorUrl('192.168.1.100'), 'http://192.168.1.100');
      expect(normalizeEditorUrl('localhost:8080'), 'http://localhost:8080');
      expect(normalizeEditorUrl('127.0.0.1'), 'http://127.0.0.1');
    });

    test(
      'não deve duplicar prefixo mesmo se o scheme estiver em MAIÚSCULO (QR Code bug)',
      () {
        expect(
          normalizeEditorUrl('HTTPS://example.com'),
          'HTTPS://example.com',
        );
        expect(
          normalizeEditorUrl('HTTP://192.168.0.1:8000'),
          'HTTP://192.168.0.1:8000',
        );
      },
    );

    test('deve remover a barra final', () {
      expect(normalizeEditorUrl('https://example.com/'), 'https://example.com');
      expect(normalizeEditorUrl('example.com/'), 'https://example.com');
    });
  });

  group('conectarEditor', () {
    late DatasetRepository datasetRepo;
    late EditorDeCroqui configService;

    setUp(() async {
      configService = EditorDeCroqui();
      datasetRepo = DatasetRepository(editorDeCroqui: configService);
    });

    testWidgets('deve rejeitar URLs vazias', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Container();
              },
            ),
          ),
        ),
      );
      final context = tester.element(find.byType(Container));

      final result = await conectarEditor(
        context,
        datasetRepo,
        configService,
        '',
      );
      expect(result, isFalse);
    });

    testWidgets('deve adicionar https se faltar e remover a barra final', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Container();
              },
            ),
          ),
        ),
      );
      final context = tester.element(find.byType(Container));

      final result = await conectarEditor(
        context,
        datasetRepo,
        configService,
        'invalid-url',
      );
      // Should fail connection
      expect(result, isFalse);
    });

    testWidgets(
      'deve falhar graciosamente quando URL for inválida ou inacessível',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return Container();
                },
              ),
            ),
          ),
        );
        final context = tester.element(find.byType(Container));

        final result = await conectarEditor(
          context,
          datasetRepo,
          configService,
          'http://127.0.0.1:9999/inexistente',
        );
        expect(result, isFalse);
      },
    );
  });

  group('buildEditorCard experimental mode tests', () {
    late EditorDeCroqui configService;
    late DatasetRepository datasetRepo;

    setUp(() {
      configService = EditorDeCroqui();
      datasetRepo = DatasetRepository(editorDeCroqui: configService);
      // Set to experimental mode
      configService.isExperimentalMode.value = true;
    });

    testWidgets(
      'Deve renderizar e acionar os botões de teste do AppVersionChecker',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return buildEditorCard(
                    context: context,
                    datasetRepo: datasetRepo,
                    clickCount: 10,
                    onSetClickCount: (val) {},
                  );
                },
              ),
            ),
          ),
        );

        // As we are in experimental mode, the buttons should be present.
        expect(find.text('TESTAR ALERTA DE OBSOLESCÊNCIA'), findsOneWidget);
        expect(find.text('TESTAR TELA DE BLOQUEIO'), findsOneWidget);

        // Testar Snackbar
        await tester.tap(find.text('TESTAR ALERTA DE OBSOLESCÊNCIA'));
        await tester.pump(); // flush microtask
        await tester.pump(const Duration(milliseconds: 100)); // for animation
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.textContaining('desatualizada'), findsOneWidget);

        // Limpar snackbar pra nao atrapalhar o proximo test
        ScaffoldMessenger.of(
          tester.element(find.byType(Scaffold)),
        ).clearSnackBars();
        await tester.pumpAndSettle();

        // Testar push da tela vermelha
        await tester.tap(find.text('TESTAR TELA DE BLOQUEIO'));
        await tester.pumpAndSettle();

        expect(find.text('ATUALIZAÇÃO\nNECESSÁRIA'), findsOneWidget);
      },
    );
  });

  group('navegarAposConexaoExperimental', () {
    late EditorDeCroqui configService;
    late DatasetRepository datasetRepo;

    setUp(() {
      configService = EditorDeCroqui();
      datasetRepo = DatasetRepository(editorDeCroqui: configService);
    });

    testWidgets(
      'deve navegar para PicoNode quando o índice contiver exatamente 1 croqui',
      (WidgetTester tester) async {
        final indice = Indice();
        indice.croquis.add(
          ResumoCroqui(
            id: 'br_mg_igarape_pedra_grande',
            nome: 'Pedra Grande',
          ),
        );
        datasetRepo.indiceData.value = indice;

        await tester.pumpWidget(
          MaterialApp(
            home: TreeNavigationWrapper(
              datasetRepo: datasetRepo,
              syncService: SyncService(datasetRepository: datasetRepo),
            ),
          ),
        );
        await tester.pump();

        final context = tester.element(find.byType(Scaffold).first);
        final controller = TreeNavigationWrapper.of(context).treeController;
        navegarAposConexaoExperimental(context, datasetRepo);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(controller.currentNode, isA<PicoNode>());
        expect(
          (controller.currentNode as PicoNode).cragId,
          'br_mg_igarape_pedra_grande',
        );
      },
    );

    testWidgets(
      'deve navegar para BrowseNode quando o índice contiver mais de 1 croqui',
      (WidgetTester tester) async {
        final indice = Indice();
        indice.croquis.addAll([
          ResumoCroqui(id: 'croqui_1', nome: 'Croqui 1'),
          ResumoCroqui(id: 'croqui_2', nome: 'Croqui 2'),
        ]);
        datasetRepo.indiceData.value = indice;

        await tester.pumpWidget(
          MaterialApp(
            home: TreeNavigationWrapper(
              datasetRepo: datasetRepo,
              syncService: SyncService(datasetRepository: datasetRepo),
            ),
          ),
        );
        await tester.pump();

        final context = tester.element(find.byType(Scaffold).first);
        final controller = TreeNavigationWrapper.of(context).treeController;
        navegarAposConexaoExperimental(context, datasetRepo);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(controller.currentNode, isA<BrowseNode>());
      },
    );

    testWidgets(
      'deve navegar para PicoNode mesmo quando chamado a partir de um contexto de diálogo ou fora da árvore direta',
      (WidgetTester tester) async {
        final indice = Indice();
        indice.croquis.add(
          ResumoCroqui(
            id: 'br_mg_igarape_pedra_grande',
            nome: 'Pedra Grande',
          ),
        );
        datasetRepo.indiceData.value = indice;

        await tester.pumpWidget(
          MaterialApp(
            home: TreeNavigationWrapper(
              key: TreeNavigationWrapper.navKey,
              datasetRepo: datasetRepo,
              syncService: SyncService(datasetRepository: datasetRepo),
            ),
          ),
        );
        await tester.pump();

        final pageContext = tester.element(find.byType(Scaffold).first);

        // Abre um diálogo padrão (cujo context fica no Overlay e não é filho de TreeNavigationWrapper)
        late BuildContext dialogContext;
        showDialog(
          context: pageContext,
          builder: (ctx) {
            dialogContext = ctx;
            return const AlertDialog(title: Text('Diálogo Teste'));
          },
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Diálogo Teste'), findsOneWidget);

        // Fecha o diálogo e chama a navegação com o context do diálogo
        Navigator.of(dialogContext).pop();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        navegarAposConexaoExperimental(dialogContext, datasetRepo);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final controller = TreeNavigationWrapper.currentTreeController;
        expect(controller?.currentNode, isA<PicoNode>());
        expect(
          (controller?.currentNode as PicoNode).cragId,
          'br_mg_igarape_pedra_grande',
        );
      },
    );
  });

  group('mostrarDialogConexao', () {
    late DatasetRepository datasetRepo;
    late EditorDeCroqui configService;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('settings_dialog_test_');
      PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
      final mockNotificador = MockGerenciadorNotificacaoDownload();
      when(() => mockNotificador.solicitarPermissoes()).thenAnswer((_) async => true);
      when(() => mockNotificador.atualizarProgresso(any(), any(), any())).thenAnswer((_) async {});
      when(() => mockNotificador.notificarConclusao(any(), any())).thenAnswer((_) async {});
      when(() => mockNotificador.notificarFalha(any(), any())).thenAnswer((_) async {});
      GerenciadorNotificacaoDownload.instancia = mockNotificador;
      GeolocatorPlatform.instance = MockGeolocatorPlatform();

      configService = EditorDeCroqui();
      datasetRepo = DatasetRepository(editorDeCroqui: configService);
    });

    tearDown(() async {
      await configService.nukeExperimentalData();
      GerenciadorNotificacaoDownload.instancia = null;
      try {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      } catch (_) {}
    });

    testWidgets(
      'ao conectar com sucesso com exatamente 1 croqui, deve fechar diálogo e navegar para PicoNode automaticamente',
      (WidgetTester tester) async {
        final croqui = Croqui(id: 'pico_unico', nome: 'Pedra Única');
        croqui.picos.add(Pico(nome: 'Pedra Única'));

        final indice = Indice();
        indice.croquis.add(
          ResumoCroqui(
            id: 'pico_unico',
            nome: 'Pedra Única',
            caminhoRelativo: 'pico_unico.binarypb',
          ),
        );

        final mockHttpClient = MockClient((request) async {
          if (request.url.path.endsWith('indice.binarypb')) {
            return http.Response.bytes(indice.writeToBuffer(), 200);
          } else if (request.url.path.endsWith('pico_unico.binarypb')) {
            return http.Response.bytes(croqui.writeToBuffer(), 200);
          }
          return http.Response('Not Found', 404);
        });

        final testSyncService = SyncService(
          datasetRepository: datasetRepo,
          client: mockHttpClient,
        );
        testSyncService.mockIsolateSpawn = (entryPoint, args) async {
          args.sendPort.send(DownloadIsolateResult(
            filesToDelete: [],
            filesToRename: {},
            newPicoDataBytes: croqui.writeToBuffer(),
          ));
        };

        await tester.pumpWidget(
          MaterialApp(
            home: TreeNavigationWrapper(
              key: TreeNavigationWrapper.navKey,
              datasetRepo: datasetRepo,
              syncService: testSyncService,
            ),
          ),
        );
        await tester.pump();

        final pageContext = tester.element(find.byType(Scaffold).first);

        // Abre o diálogo de conexão passando o mock client e syncService
        mostrarDialogConexao(
          pageContext,
          datasetRepo,
          client: mockHttpClient,
          syncService: testSyncService,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('CONECTAR'), findsOneWidget);

        // Digita a URL do servidor
        await tester.enterText(find.byType(TextField), 'http://editor.local:8000');
        await tester.pump();

        // Clica em CONECTAR
        await tester.tap(find.text('CONECTAR'));
        await tester.pump();

        for (int i = 0; i < 100; i++) {
          await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
          await tester.pump(const Duration(milliseconds: 100));
          if (find.text('Conectar Editor').evaluate().isEmpty) {
            break;
          }
        }

        // O diálogo deve ter sido fechado
        expect(find.text('Conectar Editor'), findsNothing);

        // O controlador de navegação deve ter aberto o PicoNode automaticamente
        final controller = TreeNavigationWrapper.currentTreeController;
        expect(controller?.currentNode, isA<PicoNode>());
        expect((controller?.currentNode as PicoNode).cragId, equals('pico_unico'));

        // Desativa modo experimental para cancelar timers periódicos de contagem regressiva e de reconexão
        await configService.nukeExperimentalData();
        await tester.pump(const Duration(seconds: 5));
      },
    );

    testWidgets(
      'ao conectar com sucesso com múltiplos croquis, deve fechar diálogo e navegar para BrowseNode automaticamente',
      (WidgetTester tester) async {
        final indice = Indice();
        indice.croquis.add(
          ResumoCroqui(
            id: 'pico_1',
            nome: 'Pedra 1',
            caminhoRelativo: 'pico_1.binarypb',
          ),
        );
        indice.croquis.add(
          ResumoCroqui(
            id: 'pico_2',
            nome: 'Pedra 2',
            caminhoRelativo: 'pico_2.binarypb',
          ),
        );

        final mockHttpClient = MockClient((request) async {
          if (request.url.path.endsWith('indice.binarypb')) {
            return http.Response.bytes(indice.writeToBuffer(), 200);
          }
          return http.Response('Not Found', 404);
        });

        final testSyncService = SyncService(
          datasetRepository: datasetRepo,
          client: mockHttpClient,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: TreeNavigationWrapper(
              key: TreeNavigationWrapper.navKey,
              datasetRepo: datasetRepo,
              syncService: testSyncService,
            ),
          ),
        );
        await tester.pump();

        final pageContext = tester.element(find.byType(Scaffold).first);

        mostrarDialogConexao(
          pageContext,
          datasetRepo,
          client: mockHttpClient,
          syncService: testSyncService,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        await tester.enterText(find.byType(TextField), 'http://editor.local:8000');
        await tester.pump();

        await tester.tap(find.text('CONECTAR'));
        await tester.pump();

        for (int i = 0; i < 100; i++) {
          await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
          await tester.pump(const Duration(milliseconds: 100));
          if (find.text('Conectar Editor').evaluate().isEmpty) {
            break;
          }
        }

        expect(find.text('Conectar Editor'), findsNothing);

        final controller = TreeNavigationWrapper.currentTreeController;
        expect(controller?.currentNode, isA<BrowseNode>());

        await configService.nukeExperimentalData();
        await tester.pump(const Duration(seconds: 5));
      },
    );

    testWidgets(
      'ao clicar em CANCELAR, deve fechar diálogo sem navegar nem conectar',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: TreeNavigationWrapper(
              key: TreeNavigationWrapper.navKey,
              datasetRepo: datasetRepo,
              syncService: SyncService(datasetRepository: datasetRepo),
            ),
          ),
        );
        await tester.pump();

        final pageContext = tester.element(find.byType(Scaffold).first);

        mostrarDialogConexao(pageContext, datasetRepo);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('Conectar Editor'), findsOneWidget);

        await tester.tap(find.text('CANCELAR'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Conectar Editor'), findsNothing);
        expect(configService.isExperimentalMode.value, isFalse);
      },
    );

    testWidgets(
      'ao clicar em ESCANEAR QR CODE, tela do scanner deve abrir no Root Navigator cobrindo o diálogo',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: TreeNavigationWrapper(
              key: TreeNavigationWrapper.navKey,
              datasetRepo: datasetRepo,
              syncService: SyncService(datasetRepository: datasetRepo),
            ),
          ),
        );
        await tester.pump();

        final pageContext = tester.element(find.byType(Scaffold).first);

        mostrarDialogConexao(
          pageContext,
          datasetRepo,
          construtorScannerQr: (context) => const Scaffold(
            body: Center(child: Text('TELA SCANNER SIMULADA')),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('Conectar Editor'), findsOneWidget);

        await tester.tap(find.text('ESCANEAR QR CODE'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('TELA SCANNER SIMULADA'), findsOneWidget);

        // A rota do diálogo deve ter sido sobreposta (isCurrent == false) e estar no mesmo Navigator raiz
        final elementoDialogo = tester.element(find.text('Conectar Editor'));
        final rotaDialogo = ModalRoute.of(elementoDialogo);
        expect(rotaDialogo?.isCurrent, isFalse);

        final elementoScanner = tester.element(find.text('TELA SCANNER SIMULADA'));
        final rotaScanner = ModalRoute.of(elementoScanner);
        expect(rotaScanner?.isCurrent, isTrue);
        expect(rotaScanner?.navigator, equals(rotaDialogo?.navigator));
      },
    );

    testWidgets(
      'ao cancelar o scanner sem ler QR Code, deve retornar ao diálogo mantendo texto prévio inalterado',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: TreeNavigationWrapper(
              key: TreeNavigationWrapper.navKey,
              datasetRepo: datasetRepo,
              syncService: SyncService(datasetRepository: datasetRepo),
            ),
          ),
        );
        await tester.pump();

        final pageContext = tester.element(find.byType(Scaffold).first);

        mostrarDialogConexao(
          pageContext,
          datasetRepo,
          construtorScannerQr: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('CANCELAR SCANNER'),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        await tester.enterText(find.byType(TextField), 'http://url-digitada-previamente.local');
        await tester.pump();

        await tester.tap(find.text('ESCANEAR QR CODE'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('CANCELAR SCANNER'), findsOneWidget);

        await tester.tap(find.text('CANCELAR SCANNER'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Conectar Editor'), findsOneWidget);
        expect(
          find.widgetWithText(TextField, 'http://url-digitada-previamente.local'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'ao escanear QR Code com sucesso, deve auto-conectar e navegar automaticamente para o croqui',
      (WidgetTester tester) async {
        final indice = Indice();
        indice.croquis.add(
          ResumoCroqui(
            id: 'pico_qr_sucesso',
            nome: 'Pedra do QR',
            caminhoRelativo: 'pico_qr_sucesso.binarypb',
          ),
        );

        final croqui = Croqui(id: 'pico_qr_sucesso', nome: 'Pedra do QR');
        croqui.picos.add(Pico(nome: 'Pedra do QR'));

        final mockHttpClient = MockClient((request) async {
          if (request.url.path.endsWith('indice.binarypb')) {
            return http.Response.bytes(indice.writeToBuffer(), 200);
          } else if (request.url.path.endsWith('pico_qr_sucesso.binarypb')) {
            return http.Response.bytes(croqui.writeToBuffer(), 200);
          }
          return http.Response('Not Found', 404);
        });

        final testSyncService = SyncService(
          datasetRepository: datasetRepo,
          client: mockHttpClient,
        );
        testSyncService.mockIsolateSpawn = (entryPoint, args) async {
          args.sendPort.send(DownloadIsolateResult(
            filesToDelete: [],
            filesToRename: {},
            newPicoDataBytes: croqui.writeToBuffer(),
          ));
        };

        await tester.pumpWidget(
          MaterialApp(
            home: TreeNavigationWrapper(
              key: TreeNavigationWrapper.navKey,
              datasetRepo: datasetRepo,
              syncService: testSyncService,
            ),
          ),
        );
        await tester.pump();

        final pageContext = tester.element(find.byType(Scaffold).first);

        mostrarDialogConexao(
          pageContext,
          datasetRepo,
          client: mockHttpClient,
          syncService: testSyncService,
          construtorScannerQr: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop('http://editor.local:8000'),
                child: const Text('SIMULAR LEITURA QR'),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        await tester.tap(find.text('ESCANEAR QR CODE'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('SIMULAR LEITURA QR'), findsOneWidget);

        // Dispara a leitura do QR Code
        await tester.tap(find.text('SIMULAR LEITURA QR'));
        await tester.pump();

        for (int i = 0; i < 100; i++) {
          await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
          await tester.pump(const Duration(milliseconds: 100));
          if (find.text('Conectar Editor').evaluate().isEmpty) {
            break;
          }
        }

        // Diálogo deve ter sido fechado automaticamente pela auto-conexão
        expect(find.text('Conectar Editor'), findsNothing);

        final controller = TreeNavigationWrapper.currentTreeController;
        expect(controller?.currentNode, isA<PicoNode>());
        expect((controller?.currentNode as PicoNode).cragId, equals('pico_qr_sucesso'));

        await configService.nukeExperimentalData();
        await tester.pump(const Duration(seconds: 5));
      },
    );

    testWidgets(
      'ao escanear QR Code quando servidor falha, deve tentar auto-conectar e manter diálogo aberto com a URL no campo',
      (WidgetTester tester) async {
        final mockHttpClient = MockClient((request) async {
          return http.Response('Server Error', 500);
        });

        final testSyncService = SyncService(
          datasetRepository: datasetRepo,
          client: mockHttpClient,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: TreeNavigationWrapper(
              key: TreeNavigationWrapper.navKey,
              datasetRepo: datasetRepo,
              syncService: testSyncService,
            ),
          ),
        );
        await tester.pump();

        final pageContext = tester.element(find.byType(Scaffold).first);

        mostrarDialogConexao(
          pageContext,
          datasetRepo,
          client: mockHttpClient,
          syncService: testSyncService,
          construtorScannerQr: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop('http://editor.falha.local:8000'),
                child: const Text('SIMULAR QR FALHA'),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        await tester.tap(find.text('ESCANEAR QR CODE'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        await tester.tap(find.text('SIMULAR QR FALHA'));
        await tester.pump();

        for (int i = 0; i < 20; i++) {
          await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
          await tester.pump(const Duration(milliseconds: 50));
        }

        // Diálogo deve permanecer aberto e a URL escaneada deve estar no campo
        expect(find.text('Conectar Editor'), findsOneWidget);
        expect(
          find.widgetWithText(TextField, 'http://editor.falha.local:8000'),
          findsOneWidget,
        );
      },
    );
  });
}

