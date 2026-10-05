// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

/// Este arquivo é o Gerente/Coordenador acionado por ações do Usuário (UseCase).
/// Quando o usuário clica em 'Enviar', esta classe orquestra a coleta de metadados, 
/// registro de telemetria e o enfileiramento do feedback, sem se importar como esses serviços são implementados.
library;

import 'package:flutter/material.dart';
import 'package:feedback/feedback.dart';
import '../../../data/modelos/tipo_feedback.dart';
import '../../../services/firebase/telemetria.dart';
import '../../../services/feedback/feedback_metadata_collector.dart';
import '../../../services/feedback/feedback_queue_service.dart';
import '../../../theme/cores_app.dart';

class SubmitFeedbackUseCase {
  static final ValueNotifier<bool> isFeedbackOpen = ValueNotifier<bool>(false);

  /// Indica se o fechamento mais recente da folha de feedback ocorreu por submissão com sucesso.
  static bool ultimoEnvioConcluido = false;

  final FeedbackMetadataCollector _metadataCollector;
  final FeedbackQueueService _queueService;
  final TelemetryService _telemetryService;

  SubmitFeedbackUseCase({
    FeedbackMetadataCollector? metadataCollector,
    FeedbackQueueService? queueService,
    TelemetryService? telemetryService,
  })  : _metadataCollector = metadataCollector ?? FeedbackMetadataCollector(),
        _queueService = queueService ?? FeedbackQueueService(),
        _telemetryService = telemetryService ?? TelemetryService.instance;

  Future<void> execute(BuildContext context, UserFeedback feedback) async {
    // 1. Hide the feedback UI
    BetterFeedback.of(context).hide();
    isFeedbackOpen.value = false;
    ultimoEnvioConcluido = true;

    // 2. Collect domain metadata
    final rawMetadata = await _metadataCollector.collect(context: context);
    final tipoSelecionado = TipoFeedback.fromString(
      feedback.extra?['tipo_feedback'] as String?,
    );
    final metadata = rawMetadata.copyWith(tipoFeedback: tipoSelecionado);

    // 3. Log telemetry enriquecida
    _telemetryService.logAcaoFeedback(
      'enviar_feedback',
      tipoFeedback: tipoSelecionado.valor,
      idCroqui: metadata.croquiId,
      temCroqui: metadata.croquiId != null && metadata.croquiId!.isNotEmpty,
      qtdCaracteres: feedback.text.trim().length,
    );

    // 4. Enqueue in local storage for background processing
    await _queueService.enqueueFeedback(
      description: feedback.text,
      screenshot: feedback.screenshot,
      metadata: metadata,
    );

    // 5. Show success message to the user
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Feedback recebido! Muito obrigado por ajudar a melhorar o app.',
          ),
          backgroundColor: AppColors.light.beastHide,
        ),
      );
    }
  }
}
