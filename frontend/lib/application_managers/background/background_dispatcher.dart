// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

/// Despachante global e centralizado de tarefas em segundo plano (WorkManager).
///
/// Este arquivo atua como o Ponto de Entrada (Entry Point) único para todas as
/// rotinas assíncronas em background disparadas pelo sistema operacional Android
/// ou agendadas via WorkManager.
library;

import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../feedback/feedback_orchestrator.dart';
import '../migracao/migracao_background_orchestrator.dart';
import '../../services/firebase/app_logger.dart';
import '../../services/firebase/init_firebase.dart';

/// Função de callback exigida pelo Workmanager como ponto de entrada em segundo plano.
///
/// Roteia a execução para o orquestrador apropriado baseado no nome da tarefa ([task]).
@pragma('vm:entry-point')
void callbackDispatcher({
  Workmanager? workmanager,
  Future<void> Function()? initFirebaseOverride,
}) {
  WidgetsFlutterBinding.ensureInitialized();
  final wm = workmanager ?? Workmanager();
  wm.executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      if (initFirebaseOverride != null) {
        await initFirebaseOverride();
      } else {
        await initFirebase();
      }
    } catch (e) {
      debugPrint('[BackgroundDispatcher] Falha ao inicializar Firebase no background: $e');
    }
    return await BackgroundDispatcher.executarTarefa(
      task,
      inputData: inputData,
    );
  });
}

/// Gerenciador estático para execução e roteamento de tarefas em segundo plano.
abstract class BackgroundDispatcher {
  /// Executa a rotina de negócio correspondente à [task] solicitada.
  ///
  /// Retorna [true] em caso de sucesso para que o WorkManager finalize a execução,
  /// ou propaga uma exceção para acionar a política de Backoff/Retentativa do sistema.
  static Future<bool> executarTarefa(
    String task, {
    Map<String, dynamic>? inputData,
    FeedbackOrchestratorRunner? feedbackRunner,
    MigracaoBackgroundRunner? migracaoRunner,
  }) async {
    try {
      debugPrint('[BackgroundDispatcher] Executando tarefa em segundo plano: $task');

      switch (task) {
        case 'send_feedback_task':
          if (feedbackRunner != null) {
            await feedbackRunner();
          } else {
            await FeedbackOrchestrator.processFeedbackQueue(
              dispatcher: 'work_manager',
            );
          }
          break;

        case MigracaoBackgroundOrchestrator.kNomeTarefaMigracao:
          if (migracaoRunner != null) {
            final sucesso = await migracaoRunner();
            if (!sucesso) {
              throw Exception('Migração em segundo plano retornou falha.');
            }
          } else {
            final sucesso =
                await MigracaoBackgroundOrchestrator.executarMigracaoPosAtualizacao();
            if (!sucesso) {
              throw Exception('Migração em segundo plano retornou falha.');
            }
          }
          break;

        default:
          debugPrint('[BackgroundDispatcher] Tarefa desconhecida recebida: $task');
          break;
      }

      return true;
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        '[BackgroundDispatcher] Falha ao executar tarefa ($task)',
        error: e,
        stackTrace: stackTrace,
      );
      // Lançar exceção faz o WorkManager acionar a política de Backoff / reagendamento
      throw Exception('Falha ao executar tarefa de background ($task): $e');
    }
  }
}

/// Assinatura de função para execução do FeedbackOrchestrator em testes.
typedef FeedbackOrchestratorRunner = Future<void> Function();

/// Assinatura de função para execução do MigracaoBackgroundOrchestrator em testes.
typedef MigracaoBackgroundRunner = Future<bool> Function();
