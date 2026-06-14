import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:workmanager/workmanager.dart';

/// Serviço responsável por gerenciar a persistência local (fila) de feedbacks
/// antes deles serem despachados pelo [BackgroundWorker].
class FeedbackQueueService {
  /// Override opcional para injeção de dependência em testes do diretório temporário.
  final Future<Directory> Function()? getTemporaryDirectoryOverride;
  /// Override opcional para injeção de dependência do agendamento do Workmanager.
  final Future<void> Function(String taskName, {String? uniqueName, Map<String, dynamic>? inputData})? registerOneOffTaskOverride;

  /// Chave utilizada para salvar a lista de feedbacks no SharedPreferences.
  static const String queueKey = 'feedback_queue';
  /// Nome da tarefa registrada no Workmanager para despachar o feedback.
  static const String sendTaskName = 'send_feedback_task';

  /// Cria uma instância do serviço de fila.
  /// 
  /// Permite injetar [getTemporaryDirectoryOverride] e [registerOneOffTaskOverride]
  /// para testes unitários isolados.
  FeedbackQueueService({
    this.getTemporaryDirectoryOverride,
    this.registerOneOffTaskOverride,
  });

  /// Salva um novo feedback localmente e agenda o seu envio no background.
  /// 
  /// 1. Salva a imagem ([screenshot]) fisicamente na pasta temporária.
  /// 2. Associa a imagem aos dados de [description] e [metadata], criando um JSON.
  /// 3. Grava o JSON na fila local persistente (SharedPreferences).
  /// 4. Dispara/Agenda uma task `send_feedback_task` no Workmanager que exigirá
  ///    acesso à internet para rodar.
  Future<void> enqueueFeedback({
    required String description,
    required Uint8List screenshot,
    required Map<String, dynamic> metadata,
  }) async {
    final uuid = const Uuid().v4();
    
    // 1. Salvar a imagem no diretório temporário
    final Directory tempDir = getTemporaryDirectoryOverride != null
        ? await getTemporaryDirectoryOverride!()
        : await getTemporaryDirectory();
        
    final File imageFile = File(p.join(tempDir.path, 'feedback_$uuid.png'));
    await imageFile.writeAsBytes(screenshot);

    // 2. Criar o objeto de feedback
    final Map<String, dynamic> feedbackData = {
      'id': uuid,
      'description': description,
      'screenshotPath': imageFile.path,
      'metadata': metadata,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // 3. Salvar na fila do SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    
    // Força a recarga do disco para garantir que a isolate da UI
    // não sobrescreva um arquivo que acabou de ser limpo pelo background worker
    await prefs.reload();
    
    final String? queueStr = prefs.getString(queueKey);
    List<dynamic> queue = [];
    if (queueStr != null) {
      try {
        queue = jsonDecode(queueStr) as List<dynamic>;
      } catch (_) {}
    }
    
    queue.add(feedbackData);
    await prefs.setString(queueKey, jsonEncode(queue));

    // 4. Agendar envio em background via Workmanager
    if (registerOneOffTaskOverride != null) {
      await registerOneOffTaskOverride!(sendTaskName, uniqueName: 'feedback_$uuid');
    } else {
      await Workmanager().registerOneOffTask(
        'feedback_$uuid', // uniqueName
        sendTaskName,     // taskName
        constraints: Constraints(
          networkType: NetworkType.connected, // Exige internet
        ),
      );
    }
  }
}
