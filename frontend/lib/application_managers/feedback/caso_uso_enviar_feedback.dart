// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

/// Este arquivo é o Gerente/Coordenador acionado por ações do Usuário (UseCase).
/// Quando o usuário clica em 'Enviar', esta classe orquestra a coleta de metadados,
/// registro de telemetria e o enfileiramento do feedback, sem se importar como esses serviços são implementados.
library;

import 'package:flutter/material.dart';
import 'package:feedback/feedback.dart';
import '../../../data/modelos/tipo_feedback.dart';
import '../../../main.dart';
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

  /// Executa o fluxo completo de envio de feedback: oculta a interface do [BetterFeedback],
  /// coleta metadados de diagnóstico, registra telemetria, persiste na fila local e exibe confirmação.
  ///
  /// Caso o [context] de origem tenha sido desmontado (por exemplo, quando o feedback foi
  /// aberto a partir de um modal que se fechou), utiliza [appNavigatorKey.currentContext]
  /// como fallback seguro para fechar a folha e exibir o [SnackBar].
  Future<void> execute(BuildContext context, UserFeedback feedback) async {
    final contextoAtivo = context.mounted
        ? context
        : appNavigatorKey.currentContext;

    // 1. Oculta a interface de feedback utilizando um contexto montado
    if (contextoAtivo != null && contextoAtivo.mounted) {
      BetterFeedback.of(contextoAtivo).hide();
    }
    isFeedbackOpen.value = false;
    ultimoEnvioConcluido = true;

    // 2. Coleta os metadados de domínio
    final rawMetadata = await _metadataCollector.collect(
      context: contextoAtivo,
    );
    final tipoSelecionado = TipoFeedback.fromString(
      feedback.extra?['tipo_feedback'] as String?,
    );
    final metadata = rawMetadata.copyWith(tipoFeedback: tipoSelecionado);

    // 3. Registra telemetria enriquecida
    _telemetryService.logAcaoFeedback(
      'enviar_feedback',
      tipoFeedback: tipoSelecionado.valor,
      idCroqui: metadata.croquiId,
      temCroqui: metadata.croquiId != null && metadata.croquiId!.isNotEmpty,
      qtdCaracteres: feedback.text.trim().length,
    );

    // 4. Enfileira no armazenamento local para processamento em segundo plano
    await _queueService.enqueueFeedback(
      description: feedback.text,
      screenshot: feedback.screenshot,
      metadata: metadata,
    );

    // 5. Exibe mensagem de sucesso para o usuário
    if (contextoAtivo != null && contextoAtivo.mounted) {
      ScaffoldMessenger.of(contextoAtivo).showSnackBar(
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
