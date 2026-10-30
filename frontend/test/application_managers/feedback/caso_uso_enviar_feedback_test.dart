// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feedback/feedback.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:frontend/application_managers/feedback/caso_uso_enviar_feedback.dart';
import 'package:frontend/main.dart';
import 'package:frontend/services/feedback/feedback_metadata_collector.dart';
import 'package:frontend/services/feedback/feedback_queue_service.dart';
import '../../mocks/mock_telemetria.dart';

void main() {
  group('SubmitFeedbackUseCase', () {
    late Directory diretorioTemp;
    late FeedbackMetadataCollector coletorMetadados;
    late FeedbackQueueService servicoFila;
    late MockTelemetryService mockTelemetryService;
    late SubmitFeedbackUseCase useCase;
    String? cragIdSimulado;

    setUp(() {
      diretorioTemp = Directory.systemTemp.createTempSync(
        'caso_uso_feedback_test_',
      );
      cragIdSimulado = null;
      SubmitFeedbackUseCase.ultimoEnvioConcluido = false;
      SubmitFeedbackUseCase.isFeedbackOpen.value = false;

      coletorMetadados = FeedbackMetadataCollector(
        getNavigationTreeOverride: () => 'Home',
        getUuidOverride: () => 'uuid-123',
        getAppInstanceIdOverride: () async => 'instancia-teste',
        getPackageInfoOverride: () async => PackageInfo(
          appName: 'Aresta Climb',
          packageName: 'com.arestaclimb.app',
          version: '1.0.0',
          buildNumber: '1',
        ),
        getConnectivityOverride: () async => [ConnectivityResult.wifi],
        getOSOverride: () => 'android',
        getCragIdOverride: () => cragIdSimulado,
        getDocsPathOverride: () async => diretorioTemp.path,
        getTempCachePathOverride: () async => diretorioTemp.path,
      );
      servicoFila = FeedbackQueueService(
        getSupportDirectoryOverride: () async => diretorioTemp,
        registerOneOffTaskOverride: (
          taskName, {
          uniqueName,
          initialDelay,
          constraints,
          backoffPolicy,
          backoffPolicyDelay,
          inputData,
        }) async {},
      );
      mockTelemetryService = MockTelemetryService();

      useCase = SubmitFeedbackUseCase(
        metadataCollector: coletorMetadados,
        queueService: servicoFila,
        telemetryService: mockTelemetryService,
      );
    });

    tearDown(() {
      if (diretorioTemp.existsSync()) {
        diretorioTemp.deleteSync(recursive: true);
      }
    });

    testWidgets('execute realiza a coleta, oculta o BetterFeedback e salva na fila local', (
      tester,
    ) async {
      final fakeFeedback = UserFeedback(
        text: 'Relato de bug de teste',
        screenshot: Uint8List.fromList([1, 2, 3]),
        extra: {},
      );

      late BuildContext contextoTeste;

      await tester.pumpWidget(
        BetterFeedback(
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                contextoTeste = context;
                return const Scaffold(body: Text('Tela Inicial'));
              },
            ),
          ),
        ),
      );

      BetterFeedback.of(contextoTeste).show((_) {});
      await tester.pumpAndSettle();
      expect(BetterFeedback.of(contextoTeste).isVisible, isTrue);

      await useCase.execute(contextoTeste, fakeFeedback);
      await tester.pumpAndSettle();

      expect(BetterFeedback.of(contextoTeste).isVisible, isFalse);
      expect(SubmitFeedbackUseCase.isFeedbackOpen.value, isFalse);
      expect(SubmitFeedbackUseCase.ultimoEnvioConcluido, isTrue);

      expect(mockTelemetryService.recordedEvents, contains('acao_feedback'));
      final params = mockTelemetryService.recordedParams['acao_feedback']!;
      expect(params['acao'], 'enviar_feedback');
      expect(params['tipo_feedback'], 'app');
      expect(params['qtd_caracteres'], 'Relato de bug de teste'.length);

      final arquivoJson = File(
        '${diretorioTemp.path}/feedback_queue/uuid-123.json',
      );
      expect(arquivoJson.existsSync(), isTrue);
      final conteudoFila =
          jsonDecode(arquivoJson.readAsStringSync()) as Map<String, dynamic>;
      expect(conteudoFila['description'], 'Relato de bug de teste');

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Feedback recebido!'), findsOneWidget);
    });

    testWidgets('execute propaga tipo_feedback: croqui dos extras para os metadados persistidos', (
      tester,
    ) async {
      cragIdSimulado = 'pedra-do-bau';

      final fakeFeedback = UserFeedback(
        text: 'Via com linha errada',
        screenshot: Uint8List.fromList([1, 2]),
        extra: {'tipo_feedback': 'croqui'},
      );

      late BuildContext contextoTeste;
      await tester.pumpWidget(
        BetterFeedback(
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                contextoTeste = context;
                return const Scaffold(body: Text('Tela Croqui'));
              },
            ),
          ),
        ),
      );

      await useCase.execute(contextoTeste, fakeFeedback);
      await tester.pumpAndSettle();

      final arquivoJson = File(
        '${diretorioTemp.path}/feedback_queue/uuid-123.json',
      );
      expect(arquivoJson.existsSync(), isTrue);
      final conteudoFila =
          jsonDecode(arquivoJson.readAsStringSync()) as Map<String, dynamic>;
      final metadadosSalvos =
          conteudoFila['metadata'] as Map<String, dynamic>;
      expect(metadadosSalvos['tipo_feedback'], 'croqui');
      expect(metadadosSalvos['croqui_id'], 'pedra-do-bau');

      expect(mockTelemetryService.recordedEvents, contains('acao_feedback'));
      final params = mockTelemetryService.recordedParams['acao_feedback']!;
      expect(params['acao'], 'enviar_feedback');
      expect(params['tipo_feedback'], 'croqui');
      expect(params['id_croqui'], 'pedra-do-bau');
      expect(params['tem_croqui'], 'true');
      expect(params['qtd_caracteres'], 'Via com linha errada'.length);
      expect(SubmitFeedbackUseCase.ultimoEnvioConcluido, isTrue);
    });

    testWidgets(
      'execute conclui o envio usando o contexto ativo do navegador quando o contexto de origem foi desmontado',
      (tester) async {
        BuildContext? contextoModalDesmontado;

        await tester.pumpWidget(
          BetterFeedback(
            child: MaterialApp(
              navigatorKey: appNavigatorKey,
              home: Builder(
                builder: (context) {
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () {
                        showModalBottomSheet<void>(
                          context: context,
                          builder: (modalContext) {
                            contextoModalDesmontado = modalContext;
                            return const SizedBox(height: 100);
                          },
                        );
                      },
                      child: const Text('Abrir Modal Temporário'),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Abrir Modal Temporário'));
        await tester.pumpAndSettle();
        expect(contextoModalDesmontado, isNotNull);

        final contextoRaiz = appNavigatorKey.currentContext!;
        BetterFeedback.of(contextoRaiz).show((_) {});
        Navigator.of(contextoModalDesmontado!).pop();
        await tester.pumpAndSettle();

        expect(contextoModalDesmontado!.mounted, isFalse);
        expect(BetterFeedback.of(contextoRaiz).isVisible, isTrue);

        final fakeFeedback = UserFeedback(
          text: 'Feedback após fechar modal',
          screenshot: Uint8List.fromList([7, 8, 9]),
          extra: {'tipo_feedback': 'app'},
        );

        await useCase.execute(contextoModalDesmontado!, fakeFeedback);
        await tester.pumpAndSettle();

        expect(BetterFeedback.of(contextoRaiz).isVisible, isFalse);
        expect(SubmitFeedbackUseCase.ultimoEnvioConcluido, isTrue);
        final arquivoJson = File(
          '${diretorioTemp.path}/feedback_queue/uuid-123.json',
        );
        expect(arquivoJson.existsSync(), isTrue);
        expect(find.textContaining('Feedback recebido!'), findsOneWidget);
      },
    );
  });
}
