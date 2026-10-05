// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/feedback/feedback_local_repository.dart';
import 'package:frontend/services/feedback/tarefa_feedback.dart';
import 'package:path/path.dart' as p;

void main() {
  group('FeedbackLocalRepository', () {
    late Directory tempDir;
    late Directory queueDir;
    late FeedbackLocalRepository repo;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('feedback_local_repo_test');
      queueDir = Directory(p.join(tempDir.path, 'feedback_queue'));
      await queueDir.create(recursive: true);
      repo = FeedbackLocalRepository(getSupportDirectoryOverride: () async => tempDir);
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('lockAndGetPendingTasks carrega tarefa com screenshot em formato WebP', () async {
      final jsonFile = File(p.join(queueDir.path, 'task-webp.json'));
      await jsonFile.writeAsString(jsonEncode({
        'description': 'Erro no mapa',
        'metadata': {'feedbackId': 'task-webp'},
      }));
      final webpFile = File(p.join(queueDir.path, 'task-webp.webp'));
      await webpFile.writeAsBytes([82, 73, 70, 70]);

      final tasks = await repo.lockAndGetPendingTasks();

      expect(tasks.length, 1);
      final task = tasks.first;
      expect(task.id, 'task-webp');
      expect(task.descricao, 'Erro no mapa');
      expect(task.arquivoScreenshot?.path, webpFile.path);
      expect(task.pngFile?.path, webpFile.path);
      expect(task.arquivoProcessamento.path, '${jsonFile.path}.processing');
    });

    test('lockAndGetPendingTasks carrega tarefa legado com screenshot em formato PNG', () async {
      final jsonFile = File(p.join(queueDir.path, 'task-png.json'));
      await jsonFile.writeAsString(jsonEncode({
        'description': 'Erro na via',
        'metadata': {'feedbackId': 'task-png'},
      }));
      final pngFile = File(p.join(queueDir.path, 'task-png.png'));
      await pngFile.writeAsBytes([137, 80, 78, 71]);

      final tasks = await repo.lockAndGetPendingTasks();

      expect(tasks.length, 1);
      final task = tasks.first;
      expect(task.id, 'task-png');
      expect(task.arquivoScreenshot?.path, pngFile.path);
      expect(task.pngFile?.path, pngFile.path);
    });

    test('lockAndGetPendingTasks descarta feedback sem feedbackId e remove webp/png associados', () async {
      final jsonFile = File(p.join(queueDir.path, 'task-old.json'));
      await jsonFile.writeAsString(jsonEncode({
        'id': 'task-old',
        'description': 'Legado sem metadata',
      }));
      final webpFile = File(p.join(queueDir.path, 'task-old.webp'));
      await webpFile.writeAsBytes([1, 2]);
      final pngFile = File(p.join(queueDir.path, 'task-old.png'));
      await pngFile.writeAsBytes([3, 4]);

      final tasks = await repo.lockAndGetPendingTasks();

      expect(tasks, isEmpty);
      expect(jsonFile.existsSync(), isFalse);
      expect(webpFile.existsSync(), isFalse);
      expect(pngFile.existsSync(), isFalse);
    });

    test('completeTask deleta o arquivo de processamento e a imagem screenshot', () async {
      final procFile = File('${queueDir.path}/task-done.json.processing');
      await procFile.writeAsString('{}');
      final webpFile = File('${queueDir.path}/task-done.webp');
      await webpFile.writeAsBytes([1, 2]);

      final task = TarefaFeedback(
        arquivoProcessamento: procFile,
        id: 'task-done',
        conteudoJson: const {},
        arquivoScreenshot: webpFile,
      );

      repo.completeTask(task);

      expect(procFile.existsSync(), isFalse);
      expect(webpFile.existsSync(), isFalse);
    });

    test('unlockTask restaura arquivo .processing para .json', () async {
      final procFile = File('${queueDir.path}/task-stuck.json.processing');
      await procFile.writeAsString('{}');

      repo.unlockTask(procFile);

      expect(procFile.existsSync(), isFalse);
      expect(File('${queueDir.path}/task-stuck.json').existsSync(), isTrue);
    });

    test('performGarbageCollection destrava arquivos .processing com mais de 15 min', () async {
      final procFile = File('${queueDir.path}/stuck.json.processing');
      await procFile.writeAsString('{}');
      await procFile.setLastModified(DateTime.now().subtract(const Duration(minutes: 20)));

      await repo.performGarbageCollection();

      expect(procFile.existsSync(), isFalse);
      expect(File('${queueDir.path}/stuck.json').existsSync(), isTrue);
    });

    test('performGarbageCollection apaga arquivos com mais de 30 dias', () async {
      final oldFile = File('${queueDir.path}/ancient.json');
      await oldFile.writeAsString('{}');
      await oldFile.setLastModified(DateTime.now().subtract(const Duration(days: 35)));

      await repo.performGarbageCollection();

      expect(oldFile.existsSync(), isFalse);
    });
  });
}
