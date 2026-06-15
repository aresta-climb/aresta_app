/// Suíte de testes de funções utilitárias.
/// Cobre safeString e isBoulderArea.
library;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:frontend/view_functions/common_functions.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/services/feedback/background_worker.dart';
import 'package:feedback/feedback.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import '../mocks/mock_telemetry_service.dart';

void main() {
  // ---------------------------------------------------------------------------
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
      expect(normalizeSearchString('Áéíóú Ãõ Âêîôû Àèìòù Çç Ññ'), 'aeiou ao aeiou aeiou cc nn');
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
    testWidgets('deve conter o botão de feedback (bug_report)', (WidgetTester tester) async {
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

    testWidgets('deve manter as actions passadas e adicionar o botão de feedback', (WidgetTester tester) async {
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
                    IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byIcon(Icons.bug_report), findsOneWidget);
    });

    testWidgets('deve mostrar SnackBar de erro se não estiver configurado', (WidgetTester tester) async {
      BackgroundWorker.debugIsConfiguredOverride = false;

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
      expect(find.text('Envio de feedback indisponível neste ambiente de desenvolvimento.'), findsOneWidget);

      BackgroundWorker.debugIsConfiguredOverride = null; // cleanup
    });

    testWidgets('NÃO deve mostrar SnackBar de erro se ESTIVER configurado (abre a UI)', (WidgetTester tester) async {
      BackgroundWorker.debugIsConfiguredOverride = true;

      await tester.pumpWidget(
        MaterialApp(
          home: BetterFeedback( // <-- Adicionado wrapper BetterFeedback
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
      await tester.pumpAndSettle(); // Aguarda a animação de abertura do BetterFeedback terminar

      // Apenas garantimos que o SnackBar de erro NÃO apareceu
      expect(find.text('Envio de feedback indisponível neste ambiente de desenvolvimento.'), findsNothing);

      // Fecha o feedback para a animação de dismiss ocorrer e a árvore ser destruída limpa
      // O plugin BetterFeedback coloca um botão de fechar, mas como estamos apenas testando,
      // podemos destruir explicitamente passando null no override.
      BackgroundWorker.debugIsConfiguredOverride = null; // cleanup
    });


    // Teste de telemetria
    testWidgets('deve registrar telemetria ao clicar no botão de feedback', (WidgetTester tester) async {
      BackgroundWorker.debugIsConfiguredOverride = true;
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
      expect(mockTelemetry.recordedParams['acao_feedback']?['acao'], 'abrir_feedback');

      BackgroundWorker.debugIsConfiguredOverride = null; // cleanup
    });
  });
}

