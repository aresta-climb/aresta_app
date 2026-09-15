// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/application_managers/feedback/feedback_orchestrator.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements http.Client {}

class FakeUri extends Fake implements Uri {}

class FakeBaseRequest extends Fake implements http.BaseRequest {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeUri());
    registerFallbackValue(FakeBaseRequest());
  });

  group('FeedbackOrchestrator (Atomic File System Queue & App Check)', () {
    late MockHttpClient mockClient;
    late Directory tempDir;
    late Directory queueDir;

    setUp(() async {
      mockClient = MockHttpClient();
      tempDir = await Directory.systemTemp.createTemp('worker_test');
      queueDir = Directory('${tempDir.path}/feedback_queue');
      await queueDir.create();
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    File createFeedbackFiles(String id, {bool isProcessing = false}) {
      final pngFile = File('${queueDir.path}/$id.png');
      pngFile.writeAsBytesSync([1, 2, 3]);

      final ext = isProcessing ? '.json.processing' : '.json';
      final jsonFile = File('${queueDir.path}/$id$ext');
      jsonFile.writeAsStringSync(
        jsonEncode({
          'id': id,
          'description': 'bug $id',
          'metadata': {'os': 'ios', 'feedbackId': id},
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      return jsonFile;
    }

    test('isConfigured retorna true por padrão e respeita debugIsConfiguredOverride', () {
      expect(FeedbackOrchestrator.isConfigured, isTrue);

      FeedbackOrchestrator.debugIsConfiguredOverride = false;
      expect(FeedbackOrchestrator.isConfigured, isFalse);

      FeedbackOrchestrator.debugIsConfiguredOverride = true;
      expect(FeedbackOrchestrator.isConfigured, isTrue);

      FeedbackOrchestrator.debugIsConfiguredOverride = null;
      expect(FeedbackOrchestrator.isConfigured, isTrue);
    });

    test(
      'processa fila com sucesso e anexa token do App Check e dispatcher',
      () async {
        when(
          () => mockClient.send(any()),
        ).thenAnswer((_) async => http.StreamedResponse(Stream.empty(), 200));

        createFeedbackFiles('uuid-1');

        final result = await FeedbackOrchestrator.processFeedbackQueue(
          client: mockClient,
          getSupportDirectoryOverride: () async => tempDir,
          getAppCheckTokenOverride: () async => 'test-app-check-jwt',
          dispatcher: 'connectivity_plus',
          isDebugModeOverride: false,
        );

        expect(result, isTrue);

        // Verifica se os arquivos foram deletados da fila após sucesso
        final files = queueDir.listSync();
        expect(files.isEmpty, isTrue);

        // Verifica injeção do cabeçalho do App Check e metadados
        final captured = verify(() => mockClient.send(captureAny())).captured;
        final request = captured.first as http.MultipartRequest;

        expect(request.headers['X-Firebase-AppCheck'], 'test-app-check-jwt');
        final metadataStr = request.fields['metadata'];
        expect(metadataStr, isNotNull);
        final metadata = jsonDecode(metadataStr!);
        expect(metadata['dispatcher'], 'connectivity_plus');
        expect(metadata['feedbackId'], 'uuid-1');
        expect(metadata['os'], 'ios');
      },
    );

    test(
      'processa fila anexando indice_file e croqui_file quando presentes no diretório de documentos',
      () async {
        when(
          () => mockClient.send(any()),
        ).thenAnswer((_) async => http.StreamedResponse(Stream.empty(), 200));

        final docsDir = Directory('${tempDir.path}/documents')..createSync();
        final indiceFile = File('${docsDir.path}/indice.binarypb')..writeAsBytesSync([1, 2, 3]);
        final croquiDir = Directory('${docsDir.path}/downloads/pico_teste')..createSync(recursive: true);
        final croquiFile = File('${croquiDir.path}/compilado.binarypb')..writeAsBytesSync([4, 5, 6]);

        final pngFile = File('${queueDir.path}/uuid-anexos.png')..writeAsBytesSync([7, 8]);
        final jsonFile = File('${queueDir.path}/uuid-anexos.json');
        jsonFile.writeAsStringSync(
          jsonEncode({
            'id': 'uuid-anexos',
            'description': 'bug com binarios',
            'metadata': {'croqui_id': 'pico_teste', 'feedbackId': 'uuid-anexos'},
            'timestamp': DateTime.now().toIso8601String(),
          }),
        );

        final result = await FeedbackOrchestrator.processFeedbackQueue(
          client: mockClient,
          getSupportDirectoryOverride: () async => tempDir,
          getDocumentsDirectoryOverride: () async => docsDir,
          getAppCheckTokenOverride: () async => 'test-token',
          dispatcher: 'manual',
          isDebugModeOverride: false,
        );

        expect(result, isTrue);

        final captured = verify(() => mockClient.send(captureAny())).captured;
        final request = captured.first as http.MultipartRequest;

        final campos = request.files.map((f) => f.field).toList();
        expect(campos, contains('screenshot'));
        expect(campos, contains('indice_file'));
        expect(campos, contains('croqui_file'));
      },
    );

    test(
      'em modo debug sem token do App Check, executa mock gracioso e completa a tarefa',
      () async {
        createFeedbackFiles('uuid-dev');

        final result = await FeedbackOrchestrator.processFeedbackQueue(
          client: mockClient,
          getSupportDirectoryOverride: () async => tempDir,
          getAppCheckTokenOverride: () async => null, // Sem token (dev não cadastrado)
          dispatcher: 'manual_debug',
          isDebugModeOverride: true, // Modo debug ativo
        );

        expect(result, isTrue);

        // Não deve disparar chamada HTTP externa para a Edge Function
        verifyNever(() => mockClient.send(any()));

        // Os arquivos devem ter sido limpos da fila normalmente
        expect(queueDir.listSync().isEmpty, isTrue);
      },
    );

    test('renomeia de volta para .json em caso de falha HTTP (500/503)', () async {
      when(
        () => mockClient.send(any()),
      ).thenAnswer((_) async => http.StreamedResponse(Stream.empty(), 500));

      createFeedbackFiles('uuid-3');

      // Deve lançar exceção para o Workmanager aplicar retry com backoff
      expect(
        () => FeedbackOrchestrator.processFeedbackQueue(
          client: mockClient,
          getSupportDirectoryOverride: () async => tempDir,
          getAppCheckTokenOverride: () async => 'valid-token',
          dispatcher: 'work_manager',
          isDebugModeOverride: false,
        ),
        throwsException,
      );

      // Os arquivos devem voltar a ser .json desbloqueados
      final jsonFile = File('${queueDir.path}/uuid-3.json');
      final pngFile = File('${queueDir.path}/uuid-3.png');

      expect(jsonFile.existsSync(), isTrue);
      expect(pngFile.existsSync(), isTrue);
    });

    test(
      'recupera arquivos .processing travados há mais de 15 minutos (Crash Recovery)',
      () async {
        when(
          () => mockClient.send(any()),
        ).thenAnswer((_) async => http.StreamedResponse(Stream.empty(), 200));

        final oldProcessingFile = createFeedbackFiles(
          'uuid-stuck',
          isProcessing: true,
        );

        final pastTime = DateTime.now().subtract(const Duration(minutes: 20));
        oldProcessingFile.setLastModifiedSync(pastTime);

        await FeedbackOrchestrator.processFeedbackQueue(
          client: mockClient,
          getSupportDirectoryOverride: () async => tempDir,
          getAppCheckTokenOverride: () async => 'valid-token',
          isDebugModeOverride: false,
        );

        expect(queueDir.listSync().isEmpty, isTrue);
        verify(() => mockClient.send(any())).called(1);
      },
    );

    test(
      'ignora arquivos .processing recentes (outro isolate trabalhando)',
      () async {
        when(
          () => mockClient.send(any()),
        ).thenAnswer((_) async => http.StreamedResponse(Stream.empty(), 200));

        final recentProcessingFile = createFeedbackFiles(
          'uuid-busy',
          isProcessing: true,
        );

        final pastTime = DateTime.now().subtract(const Duration(minutes: 2));
        recentProcessingFile.setLastModifiedSync(pastTime);

        await FeedbackOrchestrator.processFeedbackQueue(
          client: mockClient,
          getSupportDirectoryOverride: () async => tempDir,
          getAppCheckTokenOverride: () async => 'valid-token',
          isDebugModeOverride: false,
        );

        verifyNever(() => mockClient.send(any()));
        expect(recentProcessingFile.existsSync(), isTrue);
      },
    );

    test(
      'deleta silenciosamente arquivos com mais de 30 dias (Garbage Collection)',
      () async {
        when(
          () => mockClient.send(any()),
        ).thenAnswer((_) async => http.StreamedResponse(Stream.empty(), 200));

        final veryOldJson = createFeedbackFiles('uuid-trash');
        final veryOldPng = File('${queueDir.path}/uuid-trash.png');

        final pastTime = DateTime.now().subtract(const Duration(days: 35));
        veryOldJson.setLastModifiedSync(pastTime);
        veryOldPng.setLastModifiedSync(pastTime);

        await FeedbackOrchestrator.processFeedbackQueue(
          client: mockClient,
          getSupportDirectoryOverride: () async => tempDir,
          getAppCheckTokenOverride: () async => 'valid-token',
          isDebugModeOverride: false,
        );

        verifyNever(() => mockClient.send(any()));
        expect(queueDir.listSync().isEmpty, isTrue);
      },
    );

    test(
      'deleta silenciosamente feedbacks antigos sem feedbackId nos metadados',
      () async {
        when(
          () => mockClient.send(any()),
        ).thenAnswer((_) async => http.StreamedResponse(Stream.empty(), 200));

        final id = 'uuid-old-format';
        final pngFile = File('${queueDir.path}/$id.png');
        pngFile.writeAsBytesSync([1, 2, 3]);

        final jsonFile = File('${queueDir.path}/$id.json');
        jsonFile.writeAsStringSync(
          jsonEncode({
            'id': id,
            'description': 'bug velho',
            'metadata': {'os': 'ios'},
            'timestamp': DateTime.now().toIso8601String(),
          }),
        );

        await FeedbackOrchestrator.processFeedbackQueue(
          client: mockClient,
          getSupportDirectoryOverride: () async => tempDir,
          getAppCheckTokenOverride: () async => 'valid-token',
          isDebugModeOverride: false,
        );

        verifyNever(() => mockClient.send(any()));
        expect(queueDir.listSync().isEmpty, isTrue);
      },
    );
  });
}
