import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/feedback/background_worker.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockHttpClient extends Mock implements http.Client {}

class FakeUri extends Fake implements Uri {}
class FakeBaseRequest extends Fake implements http.BaseRequest {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeUri());
    registerFallbackValue(FakeBaseRequest());
  });

  group('BackgroundWorker', () {
    late MockHttpClient mockClient;
    late Directory tempDir;
    late File imageFile1;
    late File imageFile2;

    setUp(() async {
      mockClient = MockHttpClient();
      tempDir = await Directory.systemTemp.createTemp('worker_test');
      
      imageFile1 = File('${tempDir.path}/img1.png');
      await imageFile1.writeAsBytes([1]);
      
      imageFile2 = File('${tempDir.path}/img2.png');
      await imageFile2.writeAsBytes([2]);

      final queue = [
        {
          'id': 'uuid-1',
          'description': 'bug 1',
          'screenshotPath': imageFile1.path,
          'metadata': {'os': 'ios'},
          'timestamp': '2026-06-14T12:00:00Z',
        },
        {
          'id': 'uuid-2',
          'description': 'bug 2',
          'screenshotPath': imageFile2.path,
          'metadata': {'os': 'android'},
          'timestamp': '2026-06-14T12:01:00Z',
        }
      ];

      SharedPreferences.setMockInitialValues({
        'feedback_queue': jsonEncode(queue),
      });
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('processa fila com sucesso e remove itens', () async {
      when(() => mockClient.send(any())).thenAnswer((_) async => http.StreamedResponse(Stream.empty(), 200));

      final result = await BackgroundWorker.processFeedbackQueue(client: mockClient);

      expect(result, isTrue);

      // Verify files deleted
      expect(imageFile1.existsSync(), isFalse);
      expect(imageFile2.existsSync(), isFalse);

      // Verify queue is empty
      final prefs = await SharedPreferences.getInstance();
      final queueStr = prefs.getString('feedback_queue');
      expect(queueStr, '[]');
      
      verify(() => mockClient.send(any())).called(2);
    });

    test('recarrega os shared preferences antes de processar para evitar condição de corrida', () async {
      when(() => mockClient.send(any())).thenAnswer((_) async => http.StreamedResponse(Stream.empty(), 200));
      
      // Simula a adição de um novo item em outra isolate antes do worker rodar
      SharedPreferences.setMockInitialValues({
        'feedback_queue': jsonEncode([
          {
            'id': 'uuid-3',
            'description': 'bug concorrente',
            'screenshotPath': imageFile1.path,
            'metadata': {},
            'timestamp': '2026-06-14T12:05:00Z',
          }
        ]),
      });

      await BackgroundWorker.processFeedbackQueue(client: mockClient);

      // O worker DEVE limpar a fila após enviar, caso contrário o reload não funcionou no código de produção
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('feedback_queue'), '[]');
    });

    test('interrompe processamento em caso de falha', () async {
      // Primeira request falha (500)
      when(() => mockClient.send(any())).thenAnswer((_) async => http.StreamedResponse(Stream.empty(), 500));

      // Deve dar throw de exceção para o Workmanager tentar de novo
      expect(
        () => BackgroundWorker.processFeedbackQueue(client: mockClient),
        throwsException,
      );

      // Arquivo e fila não devem ter sido alterados
      expect(imageFile1.existsSync(), isTrue);
      
      final prefs = await SharedPreferences.getInstance();
      final queue = jsonDecode(prefs.getString('feedback_queue')!) as List;
      expect(queue.length, 2);
    });
  });
}
