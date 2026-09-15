// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

/// Este arquivo atua como o 'Trabalhador' (Worker) de Rede de Feedback.
/// É responsável estritamente por pegar um payload de feedback e fazer a requisição HTTP POST para o endpoint seguro do Supabase.
library;

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../data/dtos/feedback_metadata_dto.dart';
import '../../data/models/feedback_metadata.dart';

/// Serviço de comunicação HTTP para despacho de feedbacks dos usuários.
///
/// Encapsula a construção do formulário multipart (`description`, `metadata`, `screenshot`),
/// a anexação do token criptográfico do Firebase App Check e a validação do status code de resposta.
class FeedbackNetworkService {
  /// Cliente HTTP injetável para permitir cancelamento, timeouts e mocks em testes.
  final http.Client httpClient;

  /// URL absoluta da Edge Function do Supabase (ex: `https://.../functions/v1/app-feedback`).
  final String edgeFunctionUrl;

  /// Token JWT dinâmico de atestação gerado pelo Firebase App Check.
  final String? appCheckToken;

  FeedbackNetworkService({
    required this.httpClient,
    required this.edgeFunctionUrl,
    this.appCheckToken,
  });

  /// Envia o feedback através de uma requisição HTTP multipart/form-data.
  ///
  /// Lança [Exception] caso o servidor retorne um status code fora da faixa 2xx (ex: 403, 429, 503),
  /// permitindo que a fila persistente local e o Workmanager apliquem a política de retentativa com backoff.
  Future<void> sendFeedback({
    required String description,
    required dynamic metadata,
    required String dispatcher,
    File? pngFile,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(edgeFunctionUrl));

    // Anexa o token de atestação do Firebase App Check se disponível
    if (appCheckToken != null && appCheckToken!.isNotEmpty) {
      request.headers['X-Firebase-AppCheck'] = appCheckToken!;
    }

    request.fields['description'] = description;

    final Map<String, dynamic> finalMetadata = metadata is FeedbackMetadata
        ? FeedbackMetadataDto.toJson(metadata)
        : Map<String, dynamic>.from(metadata as Map);
    finalMetadata['dispatcher'] = dispatcher;
    request.fields['metadata'] = jsonEncode(finalMetadata);

    if (pngFile != null && pngFile.existsSync()) {
      request.files.add(
        await http.MultipartFile.fromPath('screenshot', pngFile.path),
      );
    }

    // Envia a requisição com Timeout longo (120s) para não gerar falsos-positivos
    // (timeouts) em conexões muito lentas de montanha, o que causaria reenvio duplicado.
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
