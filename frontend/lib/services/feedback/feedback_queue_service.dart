import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:workmanager/workmanager.dart';

/// Serviço responsável por gerenciar a persistência local (fila) de feedbacks
/// antes deles serem despachados pelo `FeedbackOrchestrator`.
///
/// **Arquitetura (File-System Queue):**
/// Ao invés de usar `SharedPreferences` que é propenso a falhas de concorrência e
/// corrupção, este serviço grava cada feedback como um conjunto de arquivos individuais
/// (`.json` e `.png`) num diretório isolado gerado via `getApplicationSupportDirectory()`.
/// O Sistema Operacional garante que este diretório não seja apagado aleatoriamente para
/// liberar cache.
class FeedbackQueueService {
  /// Override opcional para injeção de dependência do diretório base em testes unitários.
  final Future<Directory> Function()? getSupportDirectoryOverride;

  /// Override opcional para injeção de dependência do agendamento nativo do Workmanager.
  final Future<void> Function(
    String taskName, {
    String? uniqueName,
    Duration? initialDelay,
    Constraints? constraints,
    BackoffPolicy? backoffPolicy,
    Duration? backoffPolicyDelay,
    Map<String, dynamic>? inputData,
  })?
  registerOneOffTaskOverride;

  /// Nome da pasta dedicada exclusivamente para a fila de feedbacks.
  static const String queueDirectoryName = 'feedback_queue';

  /// Nome da tarefa registrada no Workmanager para despachar o feedback.
  static const String sendTaskName = 'send_feedback_task';

  /// Construtor que aceita overrides para facilitar testes (Injeção de Dependências).
  FeedbackQueueService({
    this.getSupportDirectoryOverride,
    this.registerOneOffTaskOverride,
  });

  /// Retorna o diretório base da fila, criando-o se não existir.
  Future<Directory> _getQueueDirectory() async {
    final Directory baseDir = getSupportDirectoryOverride != null
        ? await getSupportDirectoryOverride!()
        : await getApplicationSupportDirectory();

    final queueDir = Directory(p.join(baseDir.path, queueDirectoryName));
    if (!queueDir.existsSync()) {
      await queueDir.create(recursive: true);
    }
    return queueDir;
  }

  /// Salva um novo feedback localmente e agenda o seu envio no background.
  ///
  /// 1. Gera um UUID único para esta ocorrência de feedback.
  /// 2. Salva a imagem ([screenshot]) como `UUID.png` no diretório de suporte.
  /// 3. Salva os metadados como `UUID.json` no mesmo diretório.
  /// 4. Dispara/Agenda uma task `send_feedback_task` no Workmanager.
  ///
  /// O Workmanager é agendado com a política nativa de **Backoff Exponencial**.
  /// Caso haja falhas de rede no envio, o sistema tentará novamente em 10s, 20s, 40s
  /// até atingir o limite do SO (aprox. 5 horas), e continuará indefinidamente.
  Future<void> enqueueFeedback({
    required String description,
    required Uint8List screenshot,
    required Map<String, dynamic> metadata,
  }) async {
    final uuid = metadata['feedbackId'] as String;
    final queueDir = await _getQueueDirectory();

    // 1. Salvar a imagem .png
    final File imageFile = File(p.join(queueDir.path, '$uuid.png'));
    await imageFile.writeAsBytes(screenshot);

    // 2. Criar e salvar o arquivo .json atômico correspondente
    final Map<String, dynamic> feedbackData = {
      'description': description,
      'metadata': metadata,
      'timestamp': metadata['submittedAtTimestamp'],
    };

    final File jsonFile = File(p.join(queueDir.path, '$uuid.json'));
    await jsonFile.writeAsString(jsonEncode(feedbackData));

    // 3. Agendar o envio via Workmanager com Backoff Exponencial
    if (registerOneOffTaskOverride != null) {
      await registerOneOffTaskOverride!(
        sendTaskName,
        uniqueName: 'feedback_$uuid',
        initialDelay: const Duration(seconds: 10),
        constraints: Constraints(networkType: NetworkType.connected),
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 1),
      );
    } else {
      await Workmanager().registerOneOffTask(
        'feedback_$uuid', // uniqueName para garantir rastreabilidade
        sendTaskName, // taskName capturada no `main.dart`
        initialDelay: const Duration(
          seconds: 10,
        ), // Espera leve para o O.S. respirar
        constraints: Constraints(
          networkType:
              NetworkType.connected, // Só executa se houver conexão atestada
        ),
        backoffPolicy: BackoffPolicy
            .exponential, // Recuperação de falhas (1min, 2min, 4min...)
        backoffPolicyDelay: const Duration(minutes: 1),
      );
    }
  }
}
