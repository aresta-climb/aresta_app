import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class FeedbackNetworkService {
  final http.Client httpClient;
  final String edgeFunctionUrl;
  final String apiKey;

  FeedbackNetworkService({
    required this.httpClient,
    required this.edgeFunctionUrl,
    required this.apiKey,
  });

  Future<void> sendFeedback({
    required String description,
    required Map<String, dynamic> metadata,
    required String dispatcher,
    File? pngFile,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(edgeFunctionUrl));
    request.headers['x-api-key'] = apiKey;

    request.fields['description'] = description;

    final finalMetadata = Map<String, dynamic>.from(metadata);
    finalMetadata['dispatcher'] = dispatcher;
    request.fields['metadata'] = jsonEncode(finalMetadata);

    if (pngFile != null && pngFile.existsSync()) {
      request.files.add(
        await http.MultipartFile.fromPath('screenshot', pngFile.path),
      );
    }

    // Envia a requisição com Timeout longo (120s) para não gerar falsos-positivos
    // (timeouts) em conexões muito lentas, o que causaria reenvio duplicado.
    final response = await httpClient.send(request).timeout(
      const Duration(seconds: 120),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final responseBody = await response.stream.bytesToString();
      throw Exception(
        'HTTP Status ${response.statusCode} - Resposta: $responseBody',
      );
    }
  }
}
