import 'package:flutter/material.dart';
import 'package:feedback/feedback.dart';
import '../../../services/firebase/telemetry_service.dart';
import '../../../services/feedback/feedback_metadata_collector.dart';
import '../../../services/feedback/feedback_queue_service.dart';
import '../../../theme/app_colors.dart';

class SubmitFeedbackUseCase {
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

    // 2. Log telemetry
    _telemetryService.logAcaoFeedback('enviar_feedback');

    // 3. Collect domain metadata
    final metadata = await _metadataCollector.collect(context: context);

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
