import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/feedback/feedback_queue_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('FeedbackQueueService', () {
    late Directory tempDir;
    late List<Map<String, dynamic>> registeredTasks;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('feedback_test');
      SharedPreferences.setMockInitialValues({});
      registeredTasks = [];
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('adiciona feedback na fila, salva imagem e registra task', () async {
      final service = FeedbackQueueService(
        getTemporaryDirectoryOverride: () async => tempDir,
        registerOneOffTaskOverride: (taskName, {uniqueName, inputData}) async {
          registeredTasks.add({
            'taskName': taskName,
            'uniqueName': uniqueName,
            'inputData': inputData,
          });
        },
      );

      final screenshot = Uint8List.fromList([1, 2, 3, 4, 5]);
      final metadata = {'os': 'ios', 'appVersion': '1.0.0'};

      await service.enqueueFeedback(
        description: 'Test bug',
        screenshot: screenshot,
        metadata: metadata,
      );

      // Verify file is saved
      final files = tempDir.listSync();
      expect(files.length, 1);
      final file = files.first as File;
      expect(file.readAsBytesSync(), [1, 2, 3, 4, 5]);

      // Verify SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final queueStr = prefs.getString('feedback_queue');
      expect(queueStr, isNotNull);
      final queue = jsonDecode(queueStr!) as List;
      expect(queue.length, 1);
      
      final queuedItem = queue.first as Map<String, dynamic>;
      expect(queuedItem['description'], 'Test bug');
      expect(queuedItem['metadata']['os'], 'ios');
      expect(queuedItem['screenshotPath'], file.path);
      expect(queuedItem['id'], isNotNull);

      // Verify Workmanager task registration
      expect(registeredTasks.length, 1);
      expect(registeredTasks.first['taskName'], 'send_feedback_task');
    });
  });
}
