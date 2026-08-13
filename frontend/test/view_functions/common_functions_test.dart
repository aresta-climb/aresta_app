/// Suíte de testes de funções utilitárias.
/// Cobre safeString e isBoulderArea.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:frontend/view_functions/common_functions.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/services/feedback/feedback_orchestrator.dart';
import 'package:feedback/feedback.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import '../mocks/mock_telemetry_service.dart';
import 'package:flutter/services.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/theme/app_colors.dart';

class MockDatasetRepository implements DatasetRepository {
  @override
  final ValueNotifier<TopoDataset?> activeDataset = ValueNotifier(
    TopoDataset(availablePicos: [], downloadedPicos: [{}]),
  );
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSyncService implements SyncService {
  bool networkDisabled = false;
  List<String> mockFailed = [];
  final ValueNotifier<SyncStatus> _status = ValueNotifier(SyncStatus.updated);

  @override
  Future<bool> isNetworkDisabled() async => networkDisabled;

  @override
  Future<List<String>> syncIndex({bool auto = true, bool forceBypassCache = false}) async {
    return mockFailed;
  }

  @override
  ValueNotifier<SyncStatus> get syncStatus => _status;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  // safeString
  // ---------------------------------------------------------------------------

  group('safeString', () {
    test('deve retornar a string do valor quando não nulo', () {
      expect(safeString('Pedra Bonita'), 'Pedra Bonita');
    });

    test('deve retornar string vazia para valores nulos por padrão', () {
      expect(safeString(null), '');
    });

    test('deve retornar o fallback especificado para valores nulos', () {
      expect(safeString(null, fallback: 'Desconhecido'), 'Desconhecido');
    });

    test('deve converter números para string corretamente', () {
      expect(safeString(42), '42');
    });

    test('deve converter booleans para string corretamente', () {
      expect(safeString(true), 'true');
    });
  });

  // ---------------------------------------------------------------------------
  // isBoulderArea
  // ---------------------------------------------------------------------------

  group('isBoulderArea', () {
    test('deve retornar false para lista vazia', () {
      expect(isBoulderArea([]), isFalse);
    });

    test('deve retornar true quando metade ou mais são boulders', () {
      // 2 boulders, 1 via esportiva → 66% boulder
      final escaladas = [
        Escalada()..boulder = Boulder(),
        Escalada()..boulder = Boulder(),
        Escalada()..viaEsportiva = ViaEsportiva(),
      ];
      expect(isBoulderArea(escaladas), isTrue);
    });

    test('deve retornar false quando menos da metade são boulders', () {
      // 1 boulder, 2 vias esportivas → 33% boulder
      final escaladas = [
        Escalada()..boulder = Boulder(),
        Escalada()..viaEsportiva = ViaEsportiva(),
        Escalada()..viaEsportiva = ViaEsportiva(),
      ];
      expect(isBoulderArea(escaladas), isFalse);
    });

    test('deve retornar true quando todas são boulders', () {
      final escaladas = [
        Escalada()..boulder = Boulder(),
        Escalada()..boulder = Boulder(),
      ];
      expect(isBoulderArea(escaladas), isTrue);
    });

    test('deve retornar false quando nenhuma é boulder', () {
      final escaladas = [
        Escalada()..viaEsportiva = ViaEsportiva(),
        Escalada()..viaEsportiva = ViaEsportiva(),
      ];
      expect(isBoulderArea(escaladas), isFalse);
    });

    test('caso de empate (50%) deve retornar true', () {
      final escaladas = [
        Escalada()..boulder = Boulder(),
        Escalada()..viaEsportiva = ViaEsportiva(),
      ];
      expect(isBoulderArea(escaladas), isTrue);
    });

    test('deve tratar viaMovel como não-boulder', () {
      final escaladas = [
        Escalada()..viaMovel = ViaMovel(),
        Escalada()..boulder = Boulder(),
      ];
      // 1 de 2 → 50% → retorna true
      expect(isBoulderArea(escaladas), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // normalizeSearchString
  // ---------------------------------------------------------------------------

  group('normalizeSearchString', () {
    test('deve converter string para letras minúsculas', () {
      expect(normalizeSearchString('PICO'), 'pico');
    });

    test('deve remover acentos e diacríticos corretamente', () {
      expect(normalizeSearchString('Píco'), 'pico');
      expect(normalizeSearchString('Coração'), 'coracao');
      expect(
        normalizeSearchString('Áéíóú Ãõ Âêîôû Àèìòù Çç Ññ'),
        'aeiou ao aeiou aeiou cc nn',
      );
    });

    test('deve retornar string vazia caso o input seja vazio', () {
      expect(normalizeSearchString(''), '');
    });

    test('não deve alterar caracteres especiais não mapeados e números', () {
      expect(normalizeSearchString('123@#%'), '123@#%');
    });
  });

  // ---------------------------------------------------------------------------
  // buildCommonAppBar
  // ---------------------------------------------------------------------------

  group('buildCommonAppBar', () {
    testWidgets('deve conter o botão de feedback (bug_report)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: Builder(
                builder: (context) => buildCommonAppBar(context, 'Test Title'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.byIcon(Icons.bug_report), findsOneWidget);
    });

    testWidgets(
      'deve manter as actions passadas e adicionar o botão de feedback',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: Builder(
                  builder: (context) => buildCommonAppBar(
                    context,
                    'Test Title',
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.settings), findsOneWidget);
        expect(find.byIcon(Icons.bug_report), findsOneWidget);
      },
    );

    testWidgets('deve mostrar SnackBar de erro se não estiver configurado', (
      WidgetTester tester,
    ) async {
      FeedbackOrchestrator.debugIsConfiguredOverride = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: Builder(
                builder: (context) => buildCommonAppBar(context, 'Test'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.bug_report));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text(
          'Envio de feedback indisponível neste ambiente de desenvolvimento.',
        ),
        findsOneWidget,
      );

      FeedbackOrchestrator.debugIsConfiguredOverride = null; // cleanup
    });

    testWidgets(
      'NÃO deve mostrar SnackBar de erro se ESTIVER configurado (abre a UI)',
      (WidgetTester tester) async {
        FeedbackOrchestrator.debugIsConfiguredOverride = true;

        await tester.pumpWidget(
          MaterialApp(
            home: BetterFeedback(
              // <-- Adicionado wrapper BetterFeedback
              child: Scaffold(
                appBar: PreferredSize(
                  preferredSize: const Size.fromHeight(kToolbarHeight),
                  child: Builder(
                    builder: (context) => buildCommonAppBar(context, 'Test'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.bug_report));
        await tester
            .pumpAndSettle(); // Aguarda a animação de abertura do BetterFeedback terminar

        // Apenas garantimos que o SnackBar de erro NÃO apareceu
        expect(
          find.text(
            'Envio de feedback indisponível neste ambiente de desenvolvimento.',
          ),
          findsNothing,
        );

        // Fecha o feedback para a animação de dismiss ocorrer e a árvore ser destruída limpa
        // O plugin BetterFeedback coloca um botão de fechar, mas como estamos apenas testando,
        // podemos destruir explicitamente passando null no override.
        FeedbackOrchestrator.debugIsConfiguredOverride = null; // cleanup
      },
    );

    // Teste de telemetria
    testWidgets('deve registrar telemetria ao clicar no botão de feedback', (
      WidgetTester tester,
    ) async {
      FeedbackOrchestrator.debugIsConfiguredOverride = true;
      final mockTelemetry = MockTelemetryService();
      TelemetryService.instance = mockTelemetry;

      await tester.pumpWidget(
        MaterialApp(
          home: BetterFeedback(
            child: Scaffold(
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: Builder(
                  builder: (context) => buildCommonAppBar(context, 'Test'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.bug_report));
      await tester.pumpAndSettle();

      expect(mockTelemetry.recordedEvents.contains('acao_feedback'), isTrue);
      expect(
        mockTelemetry.recordedParams['acao_feedback']?['acao'],
        'abrir_feedback',
      );

      FeedbackOrchestrator.debugIsConfiguredOverride = null; // cleanup
    });

    testWidgets(
      'deve chamar hide() e logar telemetria em processFeedbackSubmission',
      (WidgetTester tester) async {
        FeedbackOrchestrator.debugIsConfiguredOverride = true;
        final mockTelemetry = MockTelemetryService();
        TelemetryService.instance = mockTelemetry;

        // Mock method channels to prevent MissingPluginException
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async => '.',
        );
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('be.tramckrijte.workmanager/workmanager'),
          (MethodCall methodCall) async => true,
        );
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/package_info'),
          (MethodCall methodCall) async => {
            'appName': 'Aresta',
            'packageName': 'com.aresta.app',
            'version': '1.0.0',
            'buildNumber': '1',
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BetterFeedback(
              child: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () async {
                      // Open feedback first so we have the overlay
                      BetterFeedback.of(context).show((_) {});

                      final dummyFeedback = UserFeedback(
                        text: 'Test text',
                        screenshot: Uint8List(0),
                      );
                      await processFeedbackSubmission(context, dummyFeedback);
                    },
                    child: const Text('Simulate'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Simulate'));
        await tester.pumpAndSettle();

        // Ensure Telemetry logged 'enviar_feedback'
        expect(mockTelemetry.recordedEvents.contains('acao_feedback'), isTrue);
        expect(
          mockTelemetry.recordedParams['acao_feedback']?['acao'],
          'enviar_feedback',
        );

        // Ensure FeedbackUI is not visible anymore
        final ScaffoldState scaffoldState = tester.state(find.byType(Scaffold));
        expect(BetterFeedback.of(scaffoldState.context).isVisible, isFalse);

        FeedbackOrchestrator.debugIsConfiguredOverride = null; // cleanup
      },
    );
  });

  // ---------------------------------------------------------------------------
  // showDeprecatedAppVersionSnackBar
  // ---------------------------------------------------------------------------

  group('showDeprecatedAppVersionSnackBar', () {
    testWidgets('deve exibir SnackBar com a mensagem de versão descontinuada', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => showDeprecatedAppVersionSnackBar(context),
                  child: const Text('Show'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text(
          'Sua versão do Aresta está desatualizada. Atualize para continuar baixando croquis.',
        ),
        findsOneWidget,
      );
    });
  });



group('handleManualSync', () {
  testWidgets('deve exibir SnackBar de erro de rede se offline (isNetworkDisabled = true)', (WidgetTester tester) async {
    final mockSync = MockSyncService();
    final mockRepo = MockDatasetRepository();
    mockSync.networkDisabled = true;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => handleManualSync(context, mockRepo, mockSync),
            child: const Text('Update'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Update'));
    await tester.pump(); // Inicia a snacbkbar

    expect(find.text('Sua versão do Aresta está desatualizada. Atualize para continuar baixando croquis.'), findsOneWidget);
  });

  testWidgets('deve exibir SnackBar de offline se syncStatus for offline', (WidgetTester tester) async {
    final mockSync = MockSyncService();
    final mockRepo = MockDatasetRepository();
    mockSync._status.value = SyncStatus.offline;

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => handleManualSync(context, mockRepo, mockSync),
            child: const Text('Update'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle(); // Aguarda os asyncs

    expect(find.text('Sem conexão com a internet.'), findsOneWidget);
  });

  testWidgets('deve exibir SnackBar de falhas se failed.isNotEmpty', (WidgetTester tester) async {
    final mockSync = MockSyncService();
    final mockRepo = MockDatasetRepository();
    mockSync.mockFailed = ['Croqui 1'];
    mockSync._status.value = SyncStatus.updated;

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => handleManualSync(context, mockRepo, mockSync),
            child: const Text('Update'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();

    expect(find.text('Concluído com falhas: Croqui 1'), findsOneWidget);
  });

  testWidgets('deve exibir SnackBar de sucesso se status for updated', (WidgetTester tester) async {
    final mockSync = MockSyncService();
    final mockRepo = MockDatasetRepository();
    mockSync._status.value = SyncStatus.justUpdated; // Qualquer coisa diferente de noNewUpdates e updated

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => handleManualSync(context, mockRepo, mockSync),
            child: const Text('Update'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();

    expect(find.text('Croquis foram atualizados!'), findsOneWidget);
  });
});

}
