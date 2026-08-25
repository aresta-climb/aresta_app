// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

/// Este arquivo define o DTO (Data Transfer Object) de uma Tarefa de Feedback.
/// É a planta baixa (blueprint) dos dados mantidos na fila local (SQLite/Arquivos) antes de serem enviados à rede.
library;

import 'dart:io';

class FeedbackTask {
  final File processingFile;
  final String id;
  final Map<String, dynamic> jsonContent;
  final File? pngFile;

  FeedbackTask({
    required this.processingFile,
    required this.id,
    required this.jsonContent,
    this.pngFile,
  });
}
