import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:feedback/feedback.dart';

import 'package:frontend/application_managers/feedback/submit_feedback_usecase.dart';
import 'package:frontend/data/models/feedback_metadata.dart';
import 'package:frontend/services/feedback/feedback_metadata_collector.dart';
import 'package:frontend/services/feedback/feedback_queue_service.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';

class MockFeedbackMetadataCollector extends Mock
    implements FeedbackMetadataCollector {}

class MockFeedbackQueueService extends Mock implements FeedbackQueueService {}

class MockTelemetryService extends Mock implements TelemetryService {}

class MockBuildContext extends Mock implements BuildContext {}

void main() {
  group('SubmitFeedbackUseCase', () {
    late MockFeedbackMetadataCollector mockMetadataCollector;
    late MockFeedbackQueueService mockQueueService;
    late MockTelemetryService mockTelemetryService;
    late SubmitFeedbackUseCase useCase;
    late MockBuildContext mockContext;

    setUp(() {
      mockMetadataCollector = MockFeedbackMetadataCollector();
      mockQueueService = MockFeedbackQueueService();
      mockTelemetryService = MockTelemetryService();
      mockContext = MockBuildContext();

      useCase = SubmitFeedbackUseCase(
        metadataCollector: mockMetadataCollector,
        queueService: mockQueueService,
        telemetryService: mockTelemetryService,
      );

      // Necessário para o fallback do mocktail para não dar erro
      registerFallbackValue(
        const FeedbackMetadata(
          os: '',
          appVersion: '',
          feedbackId: '',
          submittedAt: '',
          submittedAtTimestamp: '',
          navigationTree: '',
          appInstanceId: '',
          osVersion: '',
          deviceModel: '',
          screenSize: '',
          deviceOrientation: '',
          isDarkMode: '',
          connectivity: '',
        ),
      );
      registerFallbackValue(Uint8List(0));
    });

    testWidgets('execute realiza a coleta e salva na fila corretamente', (
      tester,
    ) async {
      // Mock da telemetria
      when(
        () => mockTelemetryService.logAcaoFeedback(any()),
      ).thenAnswer((_) async {});

      // Mock da coleta de metadados
      final fakeMetadata = const FeedbackMetadata(
        navigationTree: 'Home',
        submittedAt: 'test',
        submittedAtTimestamp: 'test-ts',
        feedbackId: 'uuid-123',
        appInstanceId: 'instance',
        os: 'android',
        osVersion: '13',
        deviceModel: 'device',
        appVersion: '1.0',
        screenSize: '100x100',
        deviceOrientation: 'up',
        isDarkMode: 'false',
        connectivity: 'wifi',
      );

      when(
        () => mockMetadataCollector.collect(context: any(named: 'context')),
      ).thenAnswer((_) async => fakeMetadata);

      // Mock do QueueService
      when(
        () => mockQueueService.enqueueFeedback(
          description: any(named: 'description'),
          screenshot: any(named: 'screenshot'),
          metadata: any(named: 'metadata'),
        ),
      ).thenAnswer((_) async {});

      final fakeFeedback = UserFeedback(
        text: 'This is a test bug',
        screenshot: Uint8List.fromList([1, 2, 3]),
        extra: {},
      );

      // Precisamos montar a árvore de widgets com o BetterFeedback
      // para que BetterFeedback.of(context) não falhe e possa chamar hide().
      late BuildContext testContext;

      await tester.pumpWidget(
        MaterialApp(
          home: BetterFeedback(
            child: Builder(
              builder: (context) {
                testContext = context;
                return const Scaffold(body: Text('Test'));
              },
            ),
          ),
        ),
      );

      // Inicializa o processo do UseCase
      await useCase.execute(testContext, fakeFeedback);
      await tester.pumpAndSettle();

      // Verifica interações
      verify(
        () => mockTelemetryService.logAcaoFeedback('enviar_feedback'),
      ).called(1);
      verify(
        () => mockMetadataCollector.collect(context: testContext),
      ).called(1);
      verify(
        () => mockQueueService.enqueueFeedback(
          description: 'This is a test bug',
          screenshot: any(named: 'screenshot'),
          metadata: fakeMetadata,
        ),
      ).called(1);

      // Verifica se a Snackbar de sucesso apareceu
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Feedback recebido!'), findsOneWidget);
    });
  });
}
