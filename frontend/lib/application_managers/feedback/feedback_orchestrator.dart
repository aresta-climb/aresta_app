/// Este arquivo é o Gerente/Coordenador de background (Orchestrator).
/// É acionado pelo Workmanager (em segundo plano) para varrer a fila local de feedbacks
/// e tentar enviá-los à rede, coordenando o repositório local e o serviço de rede.
library;

import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:workmanager/workmanager.dart';

import '../../services/feedback/feedback_local_repository.dart';
import '../../services/feedback/feedback_network_service.dart';

// Constantes do Backend injetadas em tempo de compilação (CI/CD)
const String _edgeFunctionUrl = String.fromEnvironment(
  'FEEDBACK_EDGE_FUNCTION_URL',
  defaultValue:
      'https://sua-url-do-supabase.supabase.co/functions/v1/discord-feedback',
);

const String _edgeFunctionApiKey = String.fromEnvironment(
  'FEEDBACK_EDGE_FUNCTION_API_KEY',
  defaultValue: '',
);

/// Função de callback exigida pelo Workmanager para executar tarefas em background.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == 'send_feedback_task') {
        await FeedbackOrchestrator.processFeedbackQueue(dispatcher: 'work_manager');
      }
      return true; // Sucesso, finaliza a task
    } catch (e, stackTrace) {
      print(
        '=============================================\n'
        '❌ ERRO NO WORKMANAGER (FeedbackOrchestrator) ❌\n'
        '$e\n'
        '$stackTrace\n'
        '=============================================',
      );

      // Retornar throw faz o Workmanager acionar a política de Backoff
      // e reagendar a task para o futuro.
      throw Exception('Falha ao processar fila de feedback: $e');
    }
  });
}

/// Worker responsável por varrer a fila de feedbacks persistentes
/// e despachá-los de forma segura utilizando Travas Atômicas de Arquivos.
class FeedbackOrchestrator {
  static bool? debugIsConfiguredOverride;

  /// In-memory lock para evitar que o connectivity_plus chame a função múltiplas
  /// vezes concorrentemente dentro da MESMA isolate.
  static bool _isProcessing = false;

  static bool get isConfigured {
    if (debugIsConfiguredOverride != null) return debugIsConfiguredOverride!;

    return _edgeFunctionApiKey.isNotEmpty &&
        _edgeFunctionUrl !=
            'https://sua-url-do-supabase.supabase.co/functions/v1/discord-feedback';
  }

  /// Recupera o diretório da fila.
  static Future<Directory> _getQueueDirectory(
    Future<Directory> Function()? override,
  ) async {
    final Directory baseDir = override != null
        ? await override()
        : await getApplicationSupportDirectory();

    return Directory(p.join(baseDir.path, 'feedback_queue'));
  }

  /// Processa a fila de feedbacks utilizando Clean Architecture.
  ///
  /// **1. Cleanup & Crash Recovery:** Delega para o [FeedbackLocalRepository].
  /// **2. Lock Atômico:** Busca as tarefas pendentes através de rename atômico.
  /// **3. Upload:** Despacha para o [FeedbackNetworkService].
  static Future<bool> processFeedbackQueue({
    http.Client? client,
    Future<Directory> Function()? getSupportDirectoryOverride,
    String dispatcher = 'unknown',
  }) async {
    if (_isProcessing) return true; // Impede spam pelo connectivity_plus
    _isProcessing = true;

    final httpClient = client ?? http.Client();
    final localRepository = FeedbackLocalRepository(
      getSupportDirectoryOverride: getSupportDirectoryOverride,
    );
    final networkService = FeedbackNetworkService(
      httpClient: httpClient,
      edgeFunctionUrl: _edgeFunctionUrl,
      apiKey: _edgeFunctionApiKey,
    );

    try {
      // 1. Limpeza e destravamento
      await localRepository.performGarbageCollection();

      // 2. Busca e travamento
      final pendingTasks = await localRepository.lockAndGetPendingTasks();

      // 3. Processamento
      for (final task in pendingTasks) {
        try {
          await networkService.sendFeedback(
            description: task.jsonContent['description'] ?? '',
            metadata: task.jsonContent['metadata'] ?? {},
            dispatcher: dispatcher,
            pngFile: task.pngFile,
          );

          // Se sucesso, limpa os arquivos
          localRepository.completeTask(task);
        } catch (e) {
          // Se falhou (rede fraca, timeout, 500 do servidor), devolve para a fila
          localRepository.unlockTask(task.processingFile);
          
          // Relança a exceção para que o Workmanager aplique sua política de Backoff
          rethrow;
        }
      }

      return true;
    } finally {
      if (client == null) {
        httpClient.close();
      }
      _isProcessing = false;
    }
  }
}

