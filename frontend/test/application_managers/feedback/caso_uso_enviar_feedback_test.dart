// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:feedback/feedback.dart';

import 'package:frontend/application_managers/feedback/caso_uso_enviar_feedback.dart';
import 'package:frontend/data/modelos/metadados_feedback.dart';
import 'package:frontend/data/modelos/tipo_feedback.dart';
import 'package:frontend/services/feedback/feedback_metadata_collector.dart';
import 'package:frontend/services/feedback/feedback_queue_service.dart';
import '../../mocks/mock_telemetria.dart';

class MockFeedbackMetadataCollector extends Mock
    implements FeedbackMetadataCollector {}

class MockFeedbackQueueService extends Mock implements FeedbackQueueService {}

void main() {
  group('SubmitFeedbackUseCase', () {
    late MockFeedbackMetadataCollector mockMetadataCollector;
    late MockFeedbackQueueService mockQueueService;
    late MockTelemetryService mockTelemetryService;
    late SubmitFeedbackUseCase useCase;

    setUp(() {
      mockMetadataCollector = MockFeedbackMetadataCollector();
      mockQueueService = MockFeedbackQueueService();
      mockTelemetryService = MockTelemetryService();

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
      // Mock da coleta de metadados
      const fakeMetadata = FeedbackMetadata(
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

      // Verifica telemetria e estado de envio
      expect(mockTelemetryService.recordedEvents, contains('acao_feedback'));
      final params = mockTelemetryService.recordedParams['acao_feedback']!;
      expect(params['acao'], 'enviar_feedback');
      expect(params['tipo_feedback'], 'app');
      expect(params['qtd_caracteres'], 'This is a test bug'.length);
      expect(SubmitFeedbackUseCase.ultimoEnvioConcluido, isTrue);

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

    testWidgets('execute propaga tipo_feedback: croqui dos extras para os metadados', (
      tester,
    ) async {
      const fakeMetadata = FeedbackMetadata(
        navigationTree: 'Croqui',
        submittedAt: 'test',
        submittedAtTimestamp: 'test-ts',
        feedbackId: 'uuid-456',
        croquiId: 'pedra-do-bau',
        appInstanceId: 'instance',
        os: 'android',
        osVersion: '14',
        deviceModel: 'device',
        appVersion: '1.0',
        screenSize: '100x100',
        deviceOrientation: 'up',
        isDarkMode: 'false',
        connectivity: 'wifi',
      );

      when(() => mockMetadataCollector.collect(context: any(named: 'context')))
          .thenAnswer((_) async => fakeMetadata);

      FeedbackMetadata? metadadosEnfileirados;
      when(
        () => mockQueueService.enqueueFeedback(
          description: any(named: 'description'),
          screenshot: any(named: 'screenshot'),
          metadata: any(named: 'metadata'),
        ),
      ).thenAnswer((invocation) async {
        metadadosEnfileirados = invocation.namedArguments[#metadata] as FeedbackMetadata?;
      });

      final fakeFeedback = UserFeedback(
        text: 'Via com linha errada',
        screenshot: Uint8List.fromList([1, 2]),
        extra: {'tipo_feedback': 'croqui'},
      );

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

      await useCase.execute(testContext, fakeFeedback);
      await tester.pumpAndSettle();

      expect(metadadosEnfileirados, isNotNull);
      expect(metadadosEnfileirados!.tipoFeedback, TipoFeedback.croqui);
      expect(mockTelemetryService.recordedEvents, contains('acao_feedback'));
      final params = mockTelemetryService.recordedParams['acao_feedback']!;
      expect(params['acao'], 'enviar_feedback');
      expect(params['tipo_feedback'], 'croqui');
      expect(params['id_croqui'], 'pedra-do-bau');
      expect(params['tem_croqui'], 'true');
      expect(params['qtd_caracteres'], 'Via com linha errada'.length);
      expect(SubmitFeedbackUseCase.ultimoEnvioConcluido, isTrue);
    });
  });
}
