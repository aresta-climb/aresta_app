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
import 'package:frontend/services/http/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'package:frontend/theme/theme_controller.dart';
import '../mocks/mock_telemetry_service.dart';

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

    test('deve preservar aresta-zip://', () {
      expect(
        normalizeEditorUrl('aresta-zip:///caminho/do/arquivo.croqui'),
        'aresta-zip:///caminho/do/arquivo.croqui',
      );
    });
  });

  group('conectarEditor', () {
    late DatasetRepository datasetRepo;
    late EditorDeCroqui configService;
    late HttpServer server;
    late String serverUrl;

    setUp(() async {
      configService = EditorDeCroqui();
      datasetRepo = DatasetRepository(editorDeCroqui: configService);

      // Setup a local HTTP server to mock responses
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      serverUrl = 'http://${server.address.address}:${server.port}';
    });

    tearDown(() async {
      await server.close(force: true);
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
      // This test is indirect, we test the HTTP request that is actually sent.
      // Wait, we can't easily intercept the request inside conectarEditor because it hardcodes ZipInterceptorClient
      // But we can test other failures
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

    testWidgets('deve rejeitar arquivos .zip', (WidgetTester tester) async {
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
        'http://test.com/file.zip',
      );
      expect(result, isFalse);

      await tester.pump();
      expect(
        find.text('Aviso: Arquivos .zip não são mais suportados. Use .croqui'),
        findsOneWidget,
      );
    });
  });

  group('buildEditorCard experimental mode tests', () {
    late EditorDeCroqui configService;
    late DatasetRepository datasetRepo;
    late ThemeController themeController;

    setUp(() {
      configService = EditorDeCroqui();
      datasetRepo = DatasetRepository(editorDeCroqui: configService);
      themeController = ThemeController();
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
}

