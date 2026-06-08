import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/services/firebase/app_logger.dart';
import '../../aresta_api/proto/generated/indice.pb.dart';

/// Resultado base para a busca do índice de croquis.
sealed class FetchIndiceResult {}

/// Retornado quando o índice não sofreu alterações no servidor (304 Not Modified).
class IndiceUnchanged extends FetchIndiceResult {}

/// Retornado quando o índice foi atualizado ou baixado pela primeira vez.
class IndiceUpdated extends FetchIndiceResult {
  final Indice newIndice;
  final Uint8List rawBytes;
  final String? newEtag;

  IndiceUpdated({required this.newIndice, required this.rawBytes, this.newEtag});
}



/// Gerencia as requisições de rede para sincronização,
/// ocultando detalhes como retries, cabeçalhos HTTP e caminhos de fallback.
class SyncNetwork {
  final http.Client client;

  SyncNetwork(this.client);

  /// Executa uma função [action] com repetições automáticas em caso de erro.
  Future<T?> _executeWithRetries<T>(
    Future<T> Function() action, {
    int retries = 3,
  }) async {
    while (retries > 0) {
      try {
        return await action();
      } catch (e) {
        AppLogger.instance.logError('[SyncNetwork] Erro na tentativa de fetch', error: e);
        retries--;
        if (retries > 0) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }
    return null;
  }

  /// Busca o arquivo de índice mestre (`indice.binarypb`) com suporte automático a retries.
  ///
  /// Retorna as uniões da classe [FetchIndiceResult] (Unchanged, Updated, ou Failed).
  Future<FetchIndiceResult?> fetchIndiceWithRetries(
    String baseUrl,
    String? localEtag, {
    int retries = 3,
  }) async {
    final response = await _executeWithRetries(() async {
      final request = http.Request('GET', Uri.parse('$baseUrl/indice.binarypb'));
      if (localEtag != null && localEtag.isNotEmpty) {
        request.headers['If-None-Match'] = localEtag;
      }
      final streamedResponse = await client.send(request);
      return await http.Response.fromStream(streamedResponse);
    }, retries: retries);

    if (response == null) {
      AppLogger.instance.logError('Falha de conexão após várias tentativas.');
      return null;
    }

    if (response.statusCode == 200) {
      try {
        final bytes = response.bodyBytes;
        final indice = Indice.fromBuffer(bytes);
        return IndiceUpdated(
          newIndice: indice,
          rawBytes: bytes,
          newEtag: response.headers['etag'],
        );
      } catch (e) {
        AppLogger.instance.logError('Falha ao parsear binário do índice: $e');
        return null;
      }
    } else if (response.statusCode == 304) {
      return IndiceUnchanged();
    } else {
      AppLogger.instance.logError('Server returned an error: ${response.statusCode}');
      return null;
    }
  }

  /// Realiza uma requisição GET para realizar o download de um arquivo.
  /// Oculta os códigos de status e retries, retornando os bytes binários do arquivo
  /// ou `null` caso ocorram erros ou falhas definitivas de rede.
  Future<Uint8List?> downloadFile(String url, {int retries = 3}) async {
    final response = await _executeWithRetries(() async {
      return await client.get(Uri.parse(url));
    }, retries: retries);

    if (response != null && response.statusCode == 200) {
      return response.bodyBytes;
    }

    if (response != null) {
       AppLogger.instance.logError('[SyncNetwork] Failed to download $url, status: ${response.statusCode}');
    }
    return null;
  }
}

