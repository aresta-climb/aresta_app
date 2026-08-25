// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

/// Este arquivo atua como o "Trabalhador" (Worker) responsável pela persistência local dos feedbacks.
/// Ele manipula a leitura, gravação, e sistema de travas (lock) no sistema de arquivos local.
library;

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../data/dtos/feedback_task.dart';

class FeedbackLocalRepository {
  final Future<Directory> Function()? getSupportDirectoryOverride;

  FeedbackLocalRepository({this.getSupportDirectoryOverride});

  Future<Directory> getQueueDirectory() async {
    final Directory baseDir = getSupportDirectoryOverride != null
        ? await getSupportDirectoryOverride!()
        : await getApplicationSupportDirectory();
    return Directory(p.join(baseDir.path, 'feedback_queue'));
  }

  Future<void> performGarbageCollection() async {
    final queueDir = await getQueueDirectory();
    if (!queueDir.existsSync()) return;

    final now = DateTime.now();
    for (var fileEntity in queueDir.listSync()) {
      if (fileEntity is! File) continue;

      try {
        final lastModified = fileEntity.lastModifiedSync();
        final ageInMinutes = now.difference(lastModified).inMinutes;
        final ageInDays = now.difference(lastModified).inDays;

        // Garbage Collection: Joga fora tudo mais antigo que 30 dias
        if (ageInDays >= 30) {
          try {
            fileEntity.deleteSync();
          } catch (_) {}
          continue;
        }

        // Crash Recovery: Destrava arquivos presos há mais de 15 min
        if (fileEntity.path.endsWith('.processing') && ageInMinutes >= 15) {
          final newPath = fileEntity.path.replaceAll('.processing', '');
          try {
            fileEntity.renameSync(newPath);
          } catch (_) {}
        }
      } catch (_) {
        // Ignora erros ao ler metadados do arquivo
      }
    }
  }

  Future<List<FeedbackTask>> lockAndGetPendingTasks() async {
    final queueDir = await getQueueDirectory();
    if (!queueDir.existsSync()) return [];

    final List<FeedbackTask> tasks = [];

    for (var fileEntity in queueDir.listSync()) {
      if (fileEntity is! File || !fileEntity.path.endsWith('.json')) continue;

      File processingFile;
      try {
        // RENAME ATÔMICO: Apenas 1 thread no universo conseguirá fazer isso sem erro.
        processingFile = fileEntity.renameSync('${fileEntity.path}.processing');
      } catch (_) {
        continue; // Outra thread pegou esse arquivo ou ele foi deletado. Pula pro próximo.
      }

      try {
        final jsonContent = jsonDecode(processingFile.readAsStringSync());

        // O usuário preferiu descartar sumariamente os feedbacks gerados
        // em versões anteriores à v0.0.24, que não possuíam id nos metadados.
        final feedbackId = jsonContent['metadata']?['feedbackId'];
        if (feedbackId == null) {
          try {
            processingFile.deleteSync();
            final oldId = jsonContent['id'];
            if (oldId != null) {
              final pngFile = File(p.join(queueDir.path, '$oldId.png'));
              if (pngFile.existsSync()) pngFile.deleteSync();
            }
          } catch (_) {}
          continue; // Pula para o próximo arquivo
        }

        final pngPath = p.join(queueDir.path, '$feedbackId.png');
        final pngFile = File(pngPath);

        tasks.add(
          FeedbackTask(
            processingFile: processingFile,
            id: feedbackId,
            jsonContent: jsonContent,
            pngFile: pngFile.existsSync() ? pngFile : null,
          ),
        );
      } catch (e) {
        // Em caso de corrupção ou erro de parse, destrava para tentar novamente mais tarde
        unlockTask(processingFile);
      }
    }

    return tasks;
  }

  void unlockTask(File processingFile) {
    try {
      if (processingFile.existsSync()) {
        processingFile.renameSync(
          processingFile.path.replaceAll('.processing', ''),
        );
      }
    } catch (_) {}
  }

  void completeTask(FeedbackTask task) {
    try {
      if (task.processingFile.existsSync()) {
        task.processingFile.deleteSync();
      }
      if (task.pngFile != null && task.pngFile!.existsSync()) {
        task.pngFile!.deleteSync();
      }
    } catch (_) {}
  }
}
