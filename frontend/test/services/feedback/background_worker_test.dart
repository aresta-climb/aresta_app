import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/feedback/background_worker.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements http.Client {}

class FakeUri extends Fake implements Uri {}

class FakeBaseRequest extends Fake implements http.BaseRequest {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeUri());
    registerFallbackValue(FakeBaseRequest());
  });

  group('BackgroundWorker (Atomic File System Queue)', () {
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

    test(
      'processa fila com sucesso e deleta arquivos injetando o dispatcher',
      () async {
        when(
          () => mockClient.send(any()),
        ).thenAnswer((_) async => http.StreamedResponse(Stream.empty(), 200));

        createFeedbackFiles('uuid-1');

        final result = await BackgroundWorker.processFeedbackQueue(
          client: mockClient,
          getSupportDirectoryOverride: () async => tempDir,
          dispatcher: 'connectivity_plus',
        );

        expect(result, isTrue);

        // Verify files deleted
        final files = queueDir.listSync();
        expect(files.isEmpty, isTrue);

        // Verify metadata injection
        final captured = verify(() => mockClient.send(captureAny())).captured;
        final request = captured.first as http.MultipartRequest;

        final metadataStr = request.fields['metadata'];
        expect(metadataStr, isNotNull);
        final metadata = jsonDecode(metadataStr!);
        expect(metadata['dispatcher'], 'connectivity_plus');
        expect(metadata['feedbackId'], 'uuid-1');
        expect(metadata['os'], 'ios'); // Mantém o metadata original
      },
    );

    test('renomeia de volta para .json em caso de falha HTTP (500)', () async {
      when(
        () => mockClient.send(any()),
      ).thenAnswer((_) async => http.StreamedResponse(Stream.empty(), 500));

      createFeedbackFiles('uuid-3');

      // Deve dar throw de exceção para o Workmanager tentar de novo
      expect(
        () => BackgroundWorker.processFeedbackQueue(
          client: mockClient,
          getSupportDirectoryOverride: () async => tempDir,
          dispatcher: 'work_manager',
        ),
        throwsException,
      );

      // Os arquivos devem voltar a ser .json
      final jsonFile = File('${queueDir.path}/uuid-3.json');
      final pngFile = File('${queueDir.path}/uuid-3.png');

      expect(jsonFile.existsSync(), isTrue);
      expect(pngFile.existsSync(), isTrue);
    });

    test(
      'recupera arquivos .processing travados há mais de 15 minutos (Crash Recovery)',
      () async {
        // Simula sucesso quando finalmente enviar
        when(
          () => mockClient.send(any()),
        ).thenAnswer((_) async => http.StreamedResponse(Stream.empty(), 200));

        final oldProcessingFile = createFeedbackFiles(
          'uuid-stuck',
          isProcessing: true,
        );

        // Muda a data de modificação para 20 minutos atrás
        final pastTime = DateTime.now().subtract(const Duration(minutes: 20));
        oldProcessingFile.setLastModifiedSync(pastTime);

        await BackgroundWorker.processFeedbackQueue(
          client: mockClient,
          getSupportDirectoryOverride: () async => tempDir,
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

        await BackgroundWorker.processFeedbackQueue(
          client: mockClient,
          getSupportDirectoryOverride: () async => tempDir,
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

        await BackgroundWorker.processFeedbackQueue(
          client: mockClient,
          getSupportDirectoryOverride: () async => tempDir,
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

        // Cria um feedback velho, onde não havia feedbackId dentro do metadata
        final id = 'uuid-old-format';
        final pngFile = File('${queueDir.path}/$id.png');
        pngFile.writeAsBytesSync([1, 2, 3]);

        final jsonFile = File('${queueDir.path}/$id.json');
        jsonFile.writeAsStringSync(
          jsonEncode({
            'id': id,
            'description': 'bug velho',
            'metadata': {'os': 'ios'}, // sem feedbackId
            'timestamp': DateTime.now().toIso8601String(),
          }),
        );

        await BackgroundWorker.processFeedbackQueue(
          client: mockClient,
          getSupportDirectoryOverride: () async => tempDir,
        );

        // Não deve tentar enviar para a nuvem
        verifyNever(() => mockClient.send(any()));

        // Deve ter apagado tanto o .json quanto o .png da fila
        expect(queueDir.listSync().isEmpty, isTrue);
      },
    );
  });
}
