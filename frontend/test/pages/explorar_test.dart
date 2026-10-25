// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/pages/explorar.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/firebase/telemetria.dart';
import 'package:frontend/view/view_models/explorar_view_model.dart';
import '../mocks/mock_telemetria.dart';

import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';

class FakeDatasetRepository extends DatasetRepository {
  FakeDatasetRepository(EditorDeCroqui editor) : super(editorDeCroqui: editor);

  @override
  Future<Croqui?> getCroqui(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return null;
  }
}

class FakeSyncService extends SyncService {
  FakeSyncService(DatasetRepository repo) : super(datasetRepository: repo);
  bool mockResult = true;
  bool syncIndexCalled = false;
  bool forceBypassCacheUsed = false;

  @override
  Future<bool> downloadCrag(ResumoCroqui resumo) async {
    return mockResult;
  }

  @override
  Future<List<String>> syncIndex({
    bool auto = true,
    bool forceBypassCache = false,
  }) async {
    syncIndexCalled = true;
    forceBypassCacheUsed = forceBypassCache;
    syncStatus.value = SyncStatus.justUpdated;
    return [];
  }
}

void main() {
  late FakeDatasetRepository mockRepo;
  late FakeSyncService mockSync;
  late EditorDeCroqui mockEditor;
  late MockTelemetryService mockTelemetry;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockEditor = EditorDeCroqui();
    mockRepo = FakeDatasetRepository(mockEditor);
    mockSync = FakeSyncService(mockRepo);

    mockTelemetry = MockTelemetryService();
    TelemetryService.instance = mockTelemetry;
  });

  testWidgets('BrowsePage shows success SnackBar when download succeeds', (
    WidgetTester tester,
  ) async {
    mockRepo.activeDataset.value = TopoDataset(
      availablePicos: [
        {'id': 'pico_1', 'nome': 'Pico Teste', 'url': 'fake.url'},
      ],
      downloadedPicos: [],
    );
    mockRepo.indiceData.value = Indice()
      ..croquis.add(
        ResumoCroqui()
          ..id = 'pico_1'
          ..nome = 'Pico Teste',
      );

    mockSync.mockResult = true;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BrowsePage(
            viewModel: BrowseViewModel(
              datasetRepo: mockRepo,
              syncService: mockSync,
              telemetria: mockTelemetry,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Aciona download do pico
    final browse = tester.widget<BrowsePage>(find.byType(BrowsePage));
    final element = tester.element(find.byType(BrowsePage));
    browse.handleDownload(element, {'id': 'pico_1', 'nome': 'Pico Teste'});

    // Wait for the async function to finish and SnackBar to appear
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Pico Teste baixado'), findsOneWidget);
  });

  testWidgets('BrowsePage shows error SnackBar when download fails', (
    WidgetTester tester,
  ) async {
    mockRepo.activeDataset.value = TopoDataset(
      availablePicos: [
        {'id': 'pico_1', 'nome': 'Pico Teste', 'url': 'fake.url'},
      ],
      downloadedPicos: [],
    );
    mockRepo.indiceData.value = Indice()
      ..croquis.add(
        ResumoCroqui()
          ..id = 'pico_1'
          ..nome = 'Pico Teste',
      );

    mockSync.mockResult = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BrowsePage(
            viewModel: BrowseViewModel(
              datasetRepo: mockRepo,
              syncService: mockSync,
              telemetria: mockTelemetry,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Aciona download do pico
    final browse = tester.widget<BrowsePage>(find.byType(BrowsePage));
    final element = tester.element(find.byType(BrowsePage));
    browse.handleDownload(element, {'id': 'pico_1', 'nome': 'Pico Teste'});

    // Wait for the async function to finish and SnackBar to appear
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Falha ao baixar Pico Teste'), findsOneWidget);
  });

  testWidgets('BrowsePage filters list based on search query', (
    WidgetTester tester,
  ) async {
    mockRepo.activeDataset.value = TopoDataset(
      availablePicos: [
        {'id': 'pico_1', 'nome': 'Pico Alpha', 'url': 'fake1.url'},
        {'id': 'pico_2', 'nome': 'Pico Beta', 'url': 'fake2.url'},
      ],
      downloadedPicos: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BrowsePage(
            viewModel: BrowseViewModel(
              datasetRepo: mockRepo,
              syncService: mockSync,
              telemetria: mockTelemetry,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PICO ALPHA'), findsOneWidget);
    expect(find.text('PICO BETA'), findsOneWidget);

    // Enter search query
    await tester.enterText(find.byType(TextField), 'Alpha');
    await tester.pump(const Duration(milliseconds: 600)); // wait for debounce
    await tester.pumpAndSettle();

    expect(find.text('PICO ALPHA'), findsOneWidget);
    expect(find.text('PICO BETA'), findsNothing);
  });

  testWidgets(
    'BrowsePage shows CircularProgressIndicator when tapping a downloaded crag',
    (WidgetTester tester) async {
      mockRepo.activeDataset.value = TopoDataset(
        availablePicos: [
          {
            'id': 'pico_1',
            'nome': 'Pico Baixado',
            'url': 'fake.url',
            'isDownloaded': true,
          },
        ],
        downloadedPicos: [
          {'id': 'pico_1', 'nome': 'Pico Baixado'},
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BrowsePage(
            viewModel: BrowseViewModel(
              datasetRepo: mockRepo,
              syncService: mockSync,
              telemetria: mockTelemetry,
            ),
          ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tapping a downloaded crag directly opens it (triggers AppNav.toPico which shows indicator in tests)
      await tester.tap(find.text('PICO BAIXADO'));

      // Process microtasks from async first-visit check and pump dialog frame
      await tester.pump();
      await tester.pump();

      // The CircularProgressIndicator should be visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Settle to let the dialog close
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'BrowsePage ordena por Mais próximos (padrão), Alfabético (A-Z) e Mais escaladas exibindo badges de distância',
    (WidgetTester tester) async {
      mockRepo.activeDataset.value = TopoDataset(
        availablePicos: [
          {
            'id': 'pico_c',
            'nome': 'C Pico',
            'latitude': -20.01,
            'longitude': -44.01,
            'estatisticas': {'totalVias': 10},
          },
          {
            'id': 'pico_a',
            'nome': 'A Pico',
            'latitude': -21.0,
            'longitude': -45.0,
            'estatisticas': {'totalVias': 5},
          },
          {
            'id': 'pico_b',
            'nome': 'B Pico',
            'latitude': -20.5,
            'longitude': -44.5,
            'estatisticas': {'totalVias': 50},
          },
        ],
        downloadedPicos: [],
      );
      mockRepo.indiceData.value = Indice();

      final vm = BrowseViewModel(
        datasetRepo: mockRepo,
        syncService: mockSync,
        telemetria: mockTelemetry,
      )..atualizarLocalizacaoUsuario(-20.0, -44.0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BrowsePage(viewModel: vm),
          ),
        ),
      );
      await tester.pumpAndSettle();

      double getPos(String text) => tester.getTopLeft(find.text(text)).dy;

      // Ordem padrão: Mais próximos -> C (mais perto), B (meio), A (mais longe)
      expect(
        getPos('C PICO') < getPos('B PICO'),
        true,
        reason: 'Mais próximos: C deve vir antes de B',
      );
      expect(
        getPos('B PICO') < getPos('A PICO'),
        true,
        reason: 'Mais próximos: B deve vir antes de A',
      );
      // Badges de distância visíveis nos 3 cards
      expect(find.byIcon(Icons.place), findsNWidgets(3));

      // Abre modal de ordenação
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Mais próximos'), findsOneWidget);
      expect(find.text('Alfabético (A-Z)'), findsOneWidget);
      expect(find.text('Mais escaladas'), findsOneWidget);

      // Seleciona Alfabético (A-Z)
      mockTelemetry.clear();
      await tester.tap(find.text('Alfabético (A-Z)'));
      await tester.pumpAndSettle();

      expect(mockTelemetry.recordedEvents, contains('alterar_ordenacao'));
      expect(mockTelemetry.recordedParams['alterar_ordenacao']!['origem'], 'browse');
      expect(mockTelemetry.recordedParams['alterar_ordenacao']!['detalhe'], 'alfabetico');

      expect(getPos('A PICO') < getPos('B PICO'), true);
      expect(getPos('B PICO') < getPos('C PICO'), true);
      expect(find.byIcon(Icons.place), findsNWidgets(3));

      // Abre modal novamente e seleciona Mais escaladas
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      mockTelemetry.clear();
      await tester.tap(find.text('Mais escaladas'));
      await tester.pumpAndSettle();

      expect(mockTelemetry.recordedEvents, contains('alterar_ordenacao'));
      expect(mockTelemetry.recordedParams['alterar_ordenacao']!['origem'], 'browse');
      expect(mockTelemetry.recordedParams['alterar_ordenacao']!['detalhe'], 'escaladas');

      expect(getPos('B PICO') < getPos('C PICO'), true);
      expect(getPos('C PICO') < getPos('A PICO'), true);
      expect(find.byIcon(Icons.place), findsNWidgets(3));
    },
  );

  testWidgets(
    'BrowsePage rola automaticamente até o 7º pico ao acionar focarSetimoPicoProximo e mantém os 6 primeiros ao rolar para cima',
    (WidgetTester tester) async {
      final picos = List.generate(10, (i) {
        return <String, dynamic>{
          'id': 'pico_$i',
          'nome': 'Pico Ordem $i',
          'latitude': -20.0 - (i * 0.1),
          'longitude': -44.0,
          'estatisticas': {'totalVias': 10},
        };
      });

      mockRepo.activeDataset.value = TopoDataset(
        availablePicos: picos,
        downloadedPicos: [],
      );
      mockRepo.indiceData.value = Indice();

      final vm = BrowseViewModel(
        datasetRepo: mockRepo,
        syncService: mockSync,
        telemetria: mockTelemetry,
      )..atualizarLocalizacaoUsuario(-20.0, -44.0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BrowsePage(viewModel: vm),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scrollViewFinder = find.byType(SingleChildScrollView);
      final scrollableState = tester.state<ScrollableState>(find.byType(Scrollable).last);
      expect(scrollableState.position.pixels, equals(0.0));

      vm.focarSetimoPicoProximo();
      await tester.pumpAndSettle();

      // Deve ter rolado para baixo posicionando o 7º pico (índice 6: PICO ORDEM 6) no topo
      expect(scrollableState.position.pixels, greaterThan(1000.0));
      expect(find.text('PICO ORDEM 6'), findsOneWidget);

      // Ao rolar para cima de volta ao início, o 1º pico (PICO ORDEM 0) está presente
      await tester.drag(scrollViewFinder, const Offset(0, 2000));
      await tester.pumpAndSettle();
      expect(find.text('PICO ORDEM 0'), findsOneWidget);

      // Ao atualizar a instância de BrowseViewModel (didUpdateWidget), o listener continua ativo na nova instância
      final vm2 = BrowseViewModel(
        datasetRepo: mockRepo,
        syncService: mockSync,
        telemetria: mockTelemetry,
      )..atualizarLocalizacaoUsuario(-20.0, -44.0);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BrowsePage(viewModel: vm2),
          ),
        ),
      );
      await tester.pumpAndSettle();
      vm2.focarSetimoPicoProximo();
      await tester.pumpAndSettle();
      expect(scrollableState.position.pixels, greaterThan(1000.0));
    },
  );

  testWidgets(
    'BrowsePage triggers handleSyncServing when sync button is tapped',
    (WidgetTester tester) async {
      mockRepo.activeDataset.value = TopoDataset(
        availablePicos: [
          {'id': 'pico_1', 'nome': 'Pico Teste'},
        ],
        downloadedPicos: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BrowsePage(
            viewModel: BrowseViewModel(
              datasetRepo: mockRepo,
              syncService: mockSync,
              telemetria: mockTelemetry,
            ),
          ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final syncButtonFinder = find.byTooltip('Sincronizar com serving');
      expect(syncButtonFinder, findsOneWidget);

      await tester.tap(syncButtonFinder);
      await tester.pumpAndSettle();

      expect(mockSync.syncIndexCalled, isTrue);
      expect(mockSync.forceBypassCacheUsed, isTrue);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Catálogo atualizado com o serving!'), findsOneWidget);
    },
  );

  testWidgets(
    'BrowsePage consome e renderiza BrowseViewModel customizado injetado',
    (WidgetTester tester) async {
      mockRepo.activeDataset.value = TopoDataset(
        availablePicos: [
          {'id': 'pico_injetado', 'nome': 'Pico Injetado'},
        ],
        downloadedPicos: [],
      );

      final vm = BrowseViewModel(
        datasetRepo: mockRepo,
        syncService: mockSync,
        telemetria: mockTelemetry,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BrowsePage(viewModel: vm),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PICO INJETADO'), findsOneWidget);
    },
  );
}
