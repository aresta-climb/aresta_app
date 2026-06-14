import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
/// 
/// O Workmanager precisa de uma função global ou estática registrada no momento da
/// inicialização (`main.dart`). Esta função é chamada isoladamente pelo SO nativo (Android/iOS)
/// sempre que a condição de rede/agendamento for satisfeita, executando o envio da fila de feedback.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == 'send_feedback_task') {
        await BackgroundWorker.processFeedbackQueue();
      }
      return true;
    } catch (e, stackTrace) {
      // Imprime o erro explicitamente no console do flutter/logcat
      // pois exceções não-capturadas em background isolates as vezes são ocultadas pelo Workmanager nativo.
      print(
        '=============================================\n'
        '❌ ERRO NO WORKMANAGER (BackgroundWorker) ❌\n'
        '$e\n'
        '$stackTrace\n'
        '============================================='
      );
      
      // Retornar throw faz o Workmanager agendar um retry (Backoff)
      throw Exception('Falha ao processar fila de feedback: $e');
    }
  });
}

/// Worker responsável por ler a fila de feedbacks pendentes do [SharedPreferences]
/// e despachá-los como requisições `multipart/form-data` para a Edge Function do Supabase.
class BackgroundWorker {
  /// Override utilizado apenas em testes para forçar o comportamento configurado/desconfigurado.
  static bool? debugIsConfiguredOverride;

  /// Verifica se as credenciais de envio de feedback (URL e API KEY) foram passadas na compilação.
  static bool get isConfigured {
    if (debugIsConfiguredOverride != null) return debugIsConfiguredOverride!;
    
    return _edgeFunctionApiKey.isNotEmpty && 
           _edgeFunctionUrl != 'https://sua-url-do-supabase.supabase.co/functions/v1/discord-feedback';
  }

  /// Itera sobre a fila de feedbacks salvos localmente e tenta enviá-los.
  /// 
  /// Para cada item na fila:
  /// 1. Constrói uma requisição POST `multipart/form-data`.
  /// 2. Anexa os metadados (JSON), descrição (texto) e o arquivo de imagem da screenshot.
  /// 3. Em caso de sucesso (HTTP 200/201), o arquivo local da imagem é deletado e
  ///    o item é removido da fila persistente.
  /// 4. Em caso de falha (ex: sem rede no momento ou erro 500 do servidor),
  ///    a execução é abortada lançando uma exceção. Isso indica ao Workmanager que
  ///    ele deve realizar um *retry backoff* (tentar novamente mais tarde).
  ///
  /// O [client] opcional é utilizado primariamente para injetar um MockHttpClient em testes.
  static Future<bool> processFeedbackQueue({http.Client? client}) async {
    final httpClient = client ?? http.Client();
    final prefs = await SharedPreferences.getInstance();
    
    // Força a recarga do disco para o cache da isolate, garantindo que o worker
    // veja as adições recentes da isolate da UI e vice-versa.
    await prefs.reload();
    
    final String? queueStr = prefs.getString('feedback_queue');
    if (queueStr == null || queueStr.isEmpty) return true;

    List<dynamic> queue = [];
    try {
      queue = jsonDecode(queueStr) as List<dynamic>;
    } catch (_) {
      return true;
    }

    if (queue.isEmpty) return true;

    List<dynamic> remainingQueue = List.from(queue);

    for (var item in queue) {
      final feedback = item as Map<String, dynamic>;
      final screenshotPath = feedback['screenshotPath'] as String;
      
      final request = http.MultipartRequest('POST', Uri.parse(_edgeFunctionUrl));
      request.headers['x-api-key'] = _edgeFunctionApiKey;
      
      request.fields['description'] = feedback['description'] ?? '';
      request.fields['metadata'] = jsonEncode(feedback['metadata'] ?? {});
      
      final file = File(screenshotPath);
      if (file.existsSync()) {
        request.files.add(await http.MultipartFile.fromPath('screenshot', screenshotPath));
      }

      final response = await httpClient.send(request);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Sucesso: deleta arquivo local e remove da fila
        if (file.existsSync()) {
          try {
            await file.delete();
          } catch (_) {} // Ignore delete errors
        }
        remainingQueue.removeWhere((qItem) => qItem['id'] == feedback['id']);
        await prefs.setString('feedback_queue', jsonEncode(remainingQueue));
      } else {
        // Falha HTTP (ex: 500), joga exceção para parar o processamento e fazer o workmanager tentar depois
        final responseBody = await response.stream.bytesToString();
        throw Exception('HTTP Status ${response.statusCode} - Resposta do Servidor: $responseBody');
      }
    }

    if (client == null) {
      httpClient.close();
    }
    
    return true;
  }
}
