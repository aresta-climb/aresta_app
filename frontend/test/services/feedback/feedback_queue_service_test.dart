// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/feedback/feedback_queue_service.dart';
import 'package:workmanager/workmanager.dart';

import 'package:frontend/data/models/feedback_metadata.dart';

void main() {
  group('FeedbackQueueService', () {
    late Directory tempDir;
    late List<Map<String, dynamic>> registeredTasks;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'feedback_test_support_dir',
      );
      registeredTasks = [];
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'adiciona feedback criando arquivos json e png individualmente e agenda backoff',
      () async {
        final service = FeedbackQueueService(
          getSupportDirectoryOverride: () async => tempDir,
          registerOneOffTaskOverride:
              (
                taskName, {
                uniqueName,
                initialDelay,
                constraints,
                backoffPolicy,
                backoffPolicyDelay,
                inputData,
              }) async {
                registeredTasks.add({
                  'taskName': taskName,
                  'uniqueName': uniqueName,
                  'backoffPolicy': backoffPolicy,
                  'backoffPolicyDelay': backoffPolicyDelay,
                });
              },
        );

        final screenshot = Uint8List.fromList([1, 2, 3, 4, 5]);
        final metadata = const FeedbackMetadata(
          os: 'ios',
          appVersion: '1.0.0',
          feedbackId: 'test-uuid',
          submittedAt: '16 de junho de 2026 às 21:00:00 (GMT-3)',
          submittedAtTimestamp: '2026-06-16T21:00:00.000-03:00',
          navigationTree: 'unknown',
          appInstanceId: 'unknown',
          osVersion: 'unknown',
          deviceModel: 'unknown',
          screenSize: 'unknown',
          deviceOrientation: 'unknown',
          isDarkMode: 'unknown',
          connectivity: 'unknown',
        );

        await service.enqueueFeedback(
          description: 'Test bug',
          screenshot: screenshot,
          metadata: metadata,
        );

        // Verifica se a pasta feedback_queue foi criada
        final queueDir = Directory('${tempDir.path}/feedback_queue');
        expect(queueDir.existsSync(), isTrue);

        final files = queueDir.listSync();
        expect(files.length, 2, reason: 'Deve haver um arquivo JSON e um PNG');

        // Localiza o JSON e o PNG
        File? jsonFile;
        File? pngFile;
        for (var file in files) {
          if (file.path.endsWith('.json')) jsonFile = file as File;
          if (file.path.endsWith('.png')) pngFile = file as File;
        }

        expect(jsonFile, isNotNull);
        expect(pngFile, isNotNull);

        // O UUID (nome base) deve ser o mesmo
        final basenameJson = jsonFile!.path
            .split(Platform.pathSeparator)
            .last
            .replaceAll('.json', '');
        final basenamePng = pngFile!.path
            .split(Platform.pathSeparator)
            .last
            .replaceAll('.png', '');
        expect(basenameJson, basenamePng);

        // Verifica conteúdo do PNG
        expect(pngFile.readAsBytesSync(), [1, 2, 3, 4, 5]);

        // Verifica conteúdo do JSON
        final jsonContent = jsonDecode(jsonFile.readAsStringSync());
        expect(jsonContent['metadata']['feedbackId'], basenameJson);
        expect(jsonContent['description'], 'Test bug');
        expect(jsonContent['metadata']['os'], 'ios');
        expect(jsonContent['timestamp'], '2026-06-16T21:00:00.000-03:00');

        // Verifica registro do Workmanager
        expect(registeredTasks.length, 1);
        final task = registeredTasks.first;
        expect(task['taskName'], 'send_feedback_task');
        expect(task['backoffPolicy'], BackoffPolicy.exponential);
        expect(task['backoffPolicyDelay'], const Duration(minutes: 1));
      },
    );
  });
}
