import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:workmanager/workmanager.dart';

// Constantes do Backend injetadas em tempo de compilação (CI/CD)
const String _edgeFunctionUrl = String.fromEnvironment(
  'FEEDBACK_EDGE_FUNCTION_URL',
  defaultValue: 'https://sua-url-do-supabase.supabase.co/functions/v1/discord-feedback',
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
        await BackgroundWorker.processFeedbackQueue(dispatcher: 'work_manager');
      }
      return true; // Sucesso, finaliza a task
    } catch (e, stackTrace) {
      print(
        '=============================================\n'
        '❌ ERRO NO WORKMANAGER (BackgroundWorker) ❌\n'
        '$e\n'
        '$stackTrace\n'
        '============================================='
      );
      
      // Retornar throw faz o Workmanager acionar a política de Backoff
      // e reagendar a task para o futuro.
      throw Exception('Falha ao processar fila de feedback: $e');
    }
  });
}

/// Worker responsável por varrer a fila de feedbacks persistentes
/// e despachá-los de forma segura utilizando Travas Atômicas de Arquivos.
class BackgroundWorker {
  static bool? debugIsConfiguredOverride;
  
  /// In-memory lock para evitar que o connectivity_plus chame a função múltiplas 
  /// vezes concorrentemente dentro da MESMA isolate.
  static bool _isProcessing = false;

  static bool get isConfigured {
    if (debugIsConfiguredOverride != null) return debugIsConfiguredOverride!;
    
    return _edgeFunctionApiKey.isNotEmpty && 
           _edgeFunctionUrl != 'https://sua-url-do-supabase.supabase.co/functions/v1/discord-feedback';
  }

  /// Recupera o diretório da fila.
  static Future<Directory> _getQueueDirectory(Future<Directory> Function()? override) async {
    final Directory baseDir = override != null
        ? await override()
        : await getApplicationSupportDirectory();

    return Directory(p.join(baseDir.path, 'feedback_queue'));
  }

  /// Processa a fila de feedbacks utilizando File-System Atomic Locks.
  /// 
  /// **1. Cleanup & Crash Recovery:** Varre arquivos `.processing` antigos (mais de 15 min)
  /// e os converte de volta para `.json`. Deleta arquivos com mais de 30 dias.
  /// **2. Lock Atômico:** Para cada arquivo `.json`, tenta fazer um `renameSync`
  /// para `.json.processing`. Como o POSIX garante atomicidade nesta operação,
  /// duas threads (ex: main app e background fetch) nunca conseguirão renomear o 
  /// mesmo arquivo simultaneamente com sucesso. Quem conseguir, processa o feedback.
  /// **3. Upload:** Faz upload HTTP (timeout de 30s) e deleta os arquivos em sucesso.
  static Future<bool> processFeedbackQueue({
    http.Client? client,
    Future<Directory> Function()? getSupportDirectoryOverride,
    String dispatcher = 'unknown',
  }) async {
    if (_isProcessing) return true; // Impede spam pelo connectivity_plus
    _isProcessing = true;
    
    final httpClient = client ?? http.Client();
    
    try {
      final queueDir = await _getQueueDirectory(getSupportDirectoryOverride);
      if (!queueDir.existsSync()) return true;

      // ---- FASE 1: Limpeza & Crash Recovery ----
      final now = DateTime.now();
      for (var fileEntity in queueDir.listSync()) {
        if (fileEntity is! File) continue;

        try {
          final lastModified = fileEntity.lastModifiedSync();
          final ageInMinutes = now.difference(lastModified).inMinutes;
          final ageInDays = now.difference(lastModified).inDays;

          // Garbage Collection: Joga fora tudo mais antigo que 30 dias
          if (ageInDays >= 30) {
            try { fileEntity.deleteSync(); } catch (_) {}
            continue;
          }

          // Crash Recovery: Destrava arquivos presos há mais de 15 min
          if (fileEntity.path.endsWith('.processing') && ageInMinutes >= 15) {
            final newPath = fileEntity.path.replaceAll('.processing', '');
            try { fileEntity.renameSync(newPath); } catch (_) {}
          }
        } catch (_) {
          // Ignora erros ao ler metadados do arquivo
        }
      }

      // ---- FASE 2: Processamento Atômico ----
      // Re-lê o diretório pois recuperamos arquivos
      for (var fileEntity in queueDir.listSync()) {
        if (fileEntity is! File || !fileEntity.path.endsWith('.json')) continue;

        File processingFile;
        try {
          // RENAME ATÔMICO: Apenas 1 thread no universo conseguirá fazer isso sem erro.
          processingFile = fileEntity.renameSync('${fileEntity.path}.processing');
        } catch (_) {
          // Outra thread já pegou esse arquivo ou ele foi deletado. Pula pro próximo.
          continue;
        }

        bool success = false;
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
            continue; // Pula para o próximo arquivo sem enviar
          }

          final id = feedbackId;
          final pngPath = p.join(queueDir.path, '$id.png');
          final pngFile = File(pngPath);

          final request = http.MultipartRequest('POST', Uri.parse(_edgeFunctionUrl));
          request.headers['x-api-key'] = _edgeFunctionApiKey;
          
          request.fields['description'] = jsonContent['description'] ?? '';
          
          final Map<String, dynamic> finalMetadata = Map<String, dynamic>.from(jsonContent['metadata'] ?? {});
          finalMetadata['dispatcher'] = dispatcher;
          request.fields['metadata'] = jsonEncode(finalMetadata);
          
          if (pngFile.existsSync()) {
            request.files.add(await http.MultipartFile.fromPath('screenshot', pngPath));
          }

          // Envia a requisição com Timeout longo (120s) para não gerar falsos-positivos
          // (timeouts) em conexões muito lentas, o que causaria reenvio duplicado.
          final response = await httpClient.send(request).timeout(const Duration(seconds: 120));

          if (response.statusCode >= 200 && response.statusCode < 300) {
            success = true;
          } else {
            final responseBody = await response.stream.bytesToString();
            throw Exception('HTTP Status ${response.statusCode} - Resposta: $responseBody');
          }
        } catch (e) {
          // Em caso de falha (rede fraca, timeout, 500 do servidor):
          // Desfazemos o rename atômico, devolvendo o feedback para a fila
          try {
            processingFile.renameSync(processingFile.path.replaceAll('.processing', ''));
          } catch (_) {}
          // Relança a exceção para que o Workmanager aplique sua política de Backoff
          rethrow;
        }

        // ---- FASE 3: Sucesso ----
        if (success) {
          try {
            processingFile.deleteSync();
          } catch (_) {}
          
          // Refazendo a leitura segura
          try {
             final id = processingFile.path.split(Platform.pathSeparator).last.replaceAll('.json.processing', '');
             final pngPath = p.join(queueDir.path, '$id.png');
             final pngFile = File(pngPath);
             if (pngFile.existsSync()) pngFile.deleteSync();
          } catch (_) {}
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
