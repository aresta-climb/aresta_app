// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

/// Este arquivo é o Gerente/Coordenador de background (Orchestrator) de Feedback.
/// É acionado pelo Workmanager (em segundo plano) ou por gatilhos de conectividade para varrer
/// a fila local de feedbacks persistentes e despachá-los para o servidor seguro.
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../services/feedback/feedback_local_repository.dart';
import '../../services/feedback/feedback_network_service.dart';
import '../../services/firebase/app_check_service.dart';
import '../../services/firebase/app_logger.dart';
import '../../services/firebase/remote_config_service.dart';

/// Gerenciador responsável por coordenar a leitura, travamento atômico e despacho
/// das tarefas de feedback salvas no disco local do dispositivo.
class FeedbackOrchestrator {
  /// Permite forçar o estado de configuração durante testes unitários.
  static bool? debugIsConfiguredOverride;

  /// In-memory lock para evitar que múltiplos gatilhos simultâneos (ex: ConnectivityPlus)
  /// disparem processamentos concorrentes dentro da mesma isolate do Flutter.
  static bool _isProcessing = false;

  /// Indica se o serviço de feedback está apto a operar.
  /// Com o Firebase App Check e Remote Config, o serviço é autoconfigurado por padrão.
  static bool get isConfigured {
    if (debugIsConfiguredOverride != null) return debugIsConfiguredOverride!;
    return true;
  }

  /// Processa a fila de feedbacks utilizando Clean Architecture.
  ///
  /// **1. Cleanup & Crash Recovery:** Remove arquivos antigos e destrava itens zumbis via [FeedbackLocalRepository].
  /// **2. Lock Atômico:** Busca e trava as tarefas pendentes através de renomeação atômica no sistema de arquivos.
  /// **3. Atestação de Integridade:** Obtém o token JWT dinâmico do [AppCheckService].
  /// **4. Mock Gracioso em Debug:** Se estiver em modo de desenvolvimento (`kDebugMode`) e não houver token cadastrado,
  ///    imprime os dados amigavelmente no console e finaliza a tarefa sem travar o aplicativo.
  /// **5. Despacho de Rede:** Envia o payload via [FeedbackNetworkService] para a Edge Function `app-feedback`,
  ///    anexando os arquivos binários locais `indice.binarypb` e `compilado.binarypb` quando disponíveis.
  static Future<bool> processFeedbackQueue({
    http.Client? client,
    Future<Directory> Function()? getSupportDirectoryOverride,
    Future<Directory> Function()? getDocumentsDirectoryOverride,
    Future<String?> Function()? getAppCheckTokenOverride,
    String dispatcher = 'unknown',
    bool? isDebugModeOverride,
  }) async {
    if (_isProcessing) return true;
    _isProcessing = true;

    final httpClient = client ?? http.Client();
    final localRepository = FeedbackLocalRepository(
      getSupportDirectoryOverride: getSupportDirectoryOverride,
    );

    final isDebug = isDebugModeOverride ?? kDebugMode;
    final edgeFunctionUrl =
        RemoteConfigService.instance.feedbackEdgeFunctionUrl;

    try {
      // 1. Limpeza de lixo e destravamento de crashes anteriores
      await localRepository.performGarbageCollection();

      // 2. Busca e travamento atômico das tarefas pendentes
      final pendingTasks = await localRepository.lockAndGetPendingTasks();
      if (pendingTasks.isEmpty) return true;

      // 3. Obtenção do token de atestação do App Check
      final appCheckToken = getAppCheckTokenOverride != null
          ? await getAppCheckTokenOverride()
          : await AppCheckService.instance.getToken();

      final networkService = FeedbackNetworkService(
        httpClient: httpClient,
        edgeFunctionUrl: edgeFunctionUrl,
        appCheckToken: appCheckToken,
      );

      Directory? docsDir;
      try {
        docsDir = getDocumentsDirectoryOverride != null
            ? await getDocumentsDirectoryOverride()
            : await getApplicationDocumentsDirectory();
      } catch (_) {}

      // 4. Processamento sequencial de cada tarefa travada
      for (final task in pendingTasks) {
        try {
          File? indiceFile;
          File? croquiFile;

          if (docsDir != null && docsDir.existsSync()) {
            final fileIndice = File('${docsDir.path}/indice.binarypb');
            if (fileIndice.existsSync()) {
              indiceFile = fileIndice;
            }

            final metadataMap =
                task.jsonContent['metadata'] as Map<String, dynamic>? ?? {};
            final croquiId = (metadataMap['croqui_id'] ?? metadataMap['croquiId'])
                as String?;
            if (croquiId != null && croquiId.isNotEmpty) {
              final caminhoPermanente =
                  File('${docsDir.path}/downloads/$croquiId/compilado.binarypb');
              final caminhoLegado =
                  File('${docsDir.path}/downloads/$croquiId/$croquiId.binarypb');
              if (caminhoPermanente.existsSync()) {
                croquiFile = caminhoPermanente;
              } else if (caminhoLegado.existsSync()) {
                croquiFile = caminhoLegado;
              } else {
                try {
                  final tempDir = await getTemporaryDirectory();
                  final hashEsperado = (metadataMap['croqui_sha256_esperado'] ??
                      metadataMap['croquiSha256Esperado']) as String?;
                  if (hashEsperado != null) {
                    final cacheHash = File(
                        '${tempDir.path}/temp_cache/$croquiId/compilado.binarypb.$hashEsperado');
                    if (cacheHash.existsSync()) {
                      croquiFile = cacheHash;
                    }
                  }
                  if (croquiFile == null) {
                    final cacheSemHash = File(
                        '${tempDir.path}/temp_cache/$croquiId/compilado.binarypb');
                    if (cacheSemHash.existsSync()) {
                      croquiFile = cacheSemHash;
                    }
                  }
                } catch (_) {}
              }
            }
          }

          // Em modo de depuração sem token do App Check registrado no Firebase Console,
          // realizamos um mock gracioso para não impedir contribuidores externos de testar o app.
          if (isDebug && (appCheckToken == null || appCheckToken.isEmpty)) {
            AppLogger.instance.logInfo(
              '📝 [DEBUG MOCK] Feedback concluído localmente (App Check não registrado em dev):\n'
              '   Descrição: ${task.jsonContent['description']}\n'
              '   Metadados: ${task.jsonContent['metadata']}\n'
              '   Dispatcher: $dispatcher',
            );
          } else {
            await networkService.sendFeedback(
              description: task.jsonContent['description'] ?? '',
              metadata: task.jsonContent['metadata'] ?? {},
              dispatcher: dispatcher,
              pngFile: task.pngFile,
              indiceFile: indiceFile,
              croquiFile: croquiFile,
            );
          }

          // Se a entrega foi confirmada (status 2xx), limpa os arquivos locais da tarefa
          localRepository.completeTask(task);
        } catch (e) {
          // Se falhou (timeout, rate limit 429 ou erro 503), destrava o arquivo para retentativa posterior
          localRepository.unlockTask(task.processingFile);

          // Relança a exceção para que o Workmanager aplique sua política de Backoff exponencial
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
