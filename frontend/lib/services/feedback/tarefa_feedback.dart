// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

/// Modelo de domínio interno da fila de persistência local de feedback.
/// Representa uma tarefa de envio em disco aguardando transmissão à rede.
library;

import 'dart:io';
import '../../data/modelos/metadados_feedback.dart';

/// Tarefa de feedback pendente ou em processamento na fila local.
class TarefaFeedback {
  /// Arquivo temporário de processamento atômico (`.processing`).
  final File arquivoProcessamento;

  /// Identificador único da tarefa (UUID v4).
  final String id;

  /// Conteúdo decodificado do arquivo JSON correspondente.
  final Map<String, dynamic> conteudoJson;

  /// Arquivo da captura de tela associada, se houver.
  final File? arquivoPng;

  /// Cria uma nova instância de [TarefaFeedback].
  const TarefaFeedback({
    required this.arquivoProcessamento,
    required this.id,
    required this.conteudoJson,
    this.arquivoPng,
  });

  /// Construtor de compatibilidade para parâmetros nomeados em inglês.
  factory TarefaFeedback.legado({
    required File processingFile,
    required String id,
    required Map<String, dynamic> jsonContent,
    File? pngFile,
  }) =>
      TarefaFeedback(
        arquivoProcessamento: processingFile,
        id: id,
        conteudoJson: jsonContent,
        arquivoPng: pngFile,
      );

  /// Descrição textual informada pelo usuário.
  String get descricao => conteudoJson['description'] as String? ?? '';

  /// Metadados estruturados coletados no momento do envio.
  FeedbackMetadata get metadados => FeedbackMetadata.fromJson(
        (conteudoJson['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
      );

  // Acessores de conveniência
  File get processingFile => arquivoProcessamento;
  Map<String, dynamic> get jsonContent => conteudoJson;
  File? get pngFile => arquivoPng;
  String get description => descricao;
  FeedbackMetadata get metadata => metadados;
}

/// Apelido para manter consistência semântica com o modelo de tarefas de feedback.
typedef FeedbackTask = TarefaFeedback;
